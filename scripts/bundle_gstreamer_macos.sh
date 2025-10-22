#!/bin/bash
set -euo pipefail

APP_PATH="build-macos/framebolt.app"
GST_PREFIX="/Library/Frameworks/GStreamer.framework/Versions/Current"
FRAMEWORKS_DIR="$APP_PATH/Contents/Frameworks"
PLUGIN_SRC="$GST_PREFIX/lib/gstreamer-1.0"
PLUGIN_DEST="$APP_PATH/Contents/Resources/lib/gstreamer-1.0"
APP_BIN="$APP_PATH/Contents/MacOS/framebolt"

mkdir -p "$FRAMEWORKS_DIR" "$PLUGIN_DEST"

declare -A COPIED_LIBS

# --- Function: recursively copy a dylib and its dependencies ---
copy_dylib_recursive() {
  local dylib_path="$1"

  # Skip if already copied
  if [[ -n "${COPIED_LIBS["$dylib_path"]+x}" ]]; then
    return
  fi
  COPIED_LIBS["$dylib_path"]=1

  local dylib_name
  dylib_name=$(basename "$dylib_path")

  echo "→ Copying $dylib_name"
  cp -a "$dylib_path" "$FRAMEWORKS_DIR/$dylib_name"

  # Update its install name
  install_name_tool -id "@rpath/$dylib_name" "$FRAMEWORKS_DIR/$dylib_name"

  # Inspect and relink dependencies
  otool -L "$dylib_path" | awk 'NR>1 {print $1}' | while read -r dep; do
    if [[ "$dep" == "$GST_PREFIX/lib/"*".dylib" ]]; then
      dep_basename=$(basename "$dep")
      install_name_tool -change "$dep" "@rpath/$dep_basename" "$FRAMEWORKS_DIR/$dylib_name"
      if [[ ! -f "$FRAMEWORKS_DIR/$dep_basename" ]]; then
        copy_dylib_recursive "$dep"
      fi
    fi
  done
}

# --- Scan main binary dependencies ---
echo "🔍 Scanning app binary dependencies..."
otool -L "$APP_BIN" | awk 'NR>1 {print $1}' | while read -r dep; do
  if [[ "$dep" == "$GST_PREFIX/lib/"*".dylib" ]]; then
    copy_dylib_recursive "$dep"
    dep_basename=$(basename "$dep")
    install_name_tool -change "$dep" "@rpath/$dep_basename" "$APP_BIN"
  fi
done

echo "📦 Adding RPATH to app binary..."
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_BIN"

# --- Copy GStreamer plugins (excluding .a and .pc files) ---
echo "🧩 Copying GStreamer plugins..."
rsync -a --exclude='*.a' --exclude='*.pc' "$PLUGIN_SRC/" "$PLUGIN_DEST/"

# --- Relink plugin dependencies to @rpath paths ---
echo "🔗 Relinking plugin dependencies..."
find "$PLUGIN_DEST" -type f -perm +111 -name "*.so" | while read -r plugin; do
  echo "→ Relinking $(basename "$plugin")"
  otool -L "$plugin" | awk 'NR>1 {print $1}' | while read -r dep; do
    if [[ "$dep" == "$GST_PREFIX/lib/"*".dylib" ]]; then
      dep_basename=$(basename "$dep")
      install_name_tool -change "$dep" "@rpath/$dep_basename" "$plugin"
      if [[ ! -f "$FRAMEWORKS_DIR/$dep_basename" ]]; then
        copy_dylib_recursive "$dep"
      fi
    fi
  done
done

echo "✅ Done!"
echo "   → Copied ${#COPIED_LIBS[@]} GStreamer dylibs to $FRAMEWORKS_DIR"
echo "   → Plugins copied and relinked to use @rpath"
echo "   → Your app should now run standalone 🎉"
