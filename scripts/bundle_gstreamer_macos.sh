#!/bin/bash
set -euo pipefail

echo "=== Starting GStreamer bundling process ==="

APP_PATH="build-macos/framebolt.app"
GST_PREFIX="/Library/Frameworks/GStreamer.framework/Versions/Current"
FRAMEWORKS_DIR="$APP_PATH/Contents/Frameworks"
PLUGIN_SRC="$GST_PREFIX/lib/gstreamer-1.0"
PLUGIN_DEST="$APP_PATH/Contents/Resources/lib/gstreamer-1.0"
APP_BIN="$APP_PATH/Contents/MacOS/framebolt"

mkdir -p "$FRAMEWORKS_DIR" "$PLUGIN_DEST"

COPIED_LIBS_FILE="$(mktemp)"

# --- Helpers ---
has_copied() { grep -Fxq "$1" "$COPIED_LIBS_FILE" 2>/dev/null; }
mark_copied() { echo "$1" >> "$COPIED_LIBS_FILE"; }

# --- Recursive copy function ---
copy_dylib_recursive() {
  local dylib_path="$1"

  if has_copied "$dylib_path"; then
    echo "  [skip] Already copied: $dylib_path"
    return
  fi
  mark_copied "$dylib_path"

  local dylib_name
  dylib_name=$(basename "$dylib_path")

  echo "  [copy] $dylib_path → $FRAMEWORKS_DIR/$dylib_name"
  if [[ ! -f "$dylib_path" ]]; then
    echo "  [warn] Dylib not found on disk: $dylib_path"
    return
  fi

  cp -a "$dylib_path" "$FRAMEWORKS_DIR/$dylib_name"

  echo "  [set-id] install_name_tool -id @rpath/$dylib_name"
  install_name_tool -id "@rpath/$dylib_name" "$FRAMEWORKS_DIR/$dylib_name" || true

  echo "  [deps] Inspecting dependencies of $dylib_name..."
  otool -L "$dylib_path" | awk 'NR>1 {print $1}' | while read -r dep; do
    if [[ "$dep" == *".dylib" ]]; then
      dep_basename=$(basename "$dep")
      echo "     - Found dependency: $dep"

      if [[ "$dep" == "$GST_PREFIX/lib/"*".dylib" || "$dep" == /Library/Frameworks/GStreamer.framework/* ]]; then
        echo "       ↳ GStreamer dylib detected → relinking to @rpath/$dep_basename"
        install_name_tool -change "$dep" "@rpath/$dep_basename" "$FRAMEWORKS_DIR/$dylib_name" || true

        if [[ ! -f "$FRAMEWORKS_DIR/$dep_basename" ]]; then
          copy_dylib_recursive "$dep"
        fi
      else
        echo "       ↳ Skipping (system or external): $dep"
      fi
    fi
  done
}

# --- Scan app binary dependencies ---
echo "🔍 Scanning app binary dependencies..."
otool -L "$APP_BIN" | awk 'NR>1 {print $1}' | while read -r dep; do
  echo "  [app-dep] $dep"
  if [[ "$dep" == *"GStreamer.framework"*".dylib" ]]; then
    echo "  [match] GStreamer dylib found: $dep"
    copy_dylib_recursive "$dep"
    dep_basename=$(basename "$dep")
    echo "  [relink] install_name_tool -change $dep @rpath/$dep_basename $APP_BIN"
    install_name_tool -change "$dep" "@rpath/$dep_basename" "$APP_BIN" || true
  else
    echo "  [skip] Non-GStreamer dependency: $dep"
  fi
done

echo "📦 Adding RPATH to app binary..."
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_BIN" || true

echo "🧩 Copying GStreamer plugins (excluding .a and .pc)..."
rsync -av --exclude='*.a' --exclude='*.pc' "$PLUGIN_SRC/" "$PLUGIN_DEST/"

# --- Relink plugin dependencies ---
echo "🔗 Relinking plugin dependencies..."
find "$PLUGIN_DEST" -type f -perm +111 -name "*.so" | while read -r plugin; do
  echo "  [plugin] $(basename "$plugin")"
  otool -L "$plugin" | awk 'NR>1 {print $1}' | while read -r dep; do
    if [[ "$dep" == *"GStreamer.framework"*".dylib" ]]; then
      dep_basename=$(basename "$dep")
      echo "    ↳ Relinking $dep → @rpath/$dep_basename"
      install_name_tool -change "$dep" "@rpath/$dep_basename" "$plugin" || true
      if [[ ! -f "$FRAMEWORKS_DIR/$dep_basename" ]]; then
        copy_dylib_recursive "$dep"
      fi
    fi
  done
done

COPIED_COUNT=$(wc -l < "$COPIED_LIBS_FILE")
rm -f "$COPIED_LIBS_FILE"

echo "✅ Done!"
echo "   → Copied $COPIED_COUNT GStreamer dylibs to $FRAMEWORKS_DIR"
echo "   → Plugins copied and relinked successfully"
echo "=== GStreamer bundling process complete ==="
