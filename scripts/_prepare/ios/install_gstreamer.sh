set -euxo pipefail

GST_IOS_URL="https://gstreamer.freedesktop.org/data/pkg/ios/1.26.7/gstreamer-1.0-devel-1.26.7-ios-universal.pkg"
echo "🚀 Downloading GStreamer iOS SDK from: $GST_IOS_URL"
curl -L "$GST_IOS_URL" -o gstreamer-ios.pkg

echo "📦 Expanding package structure..."
pkgutil --expand-full gstreamer-ios.pkg extracted_pkg

echo "🧭 Listing top-level contents of extracted_pkg:"
ls -l extracted_pkg || true
echo ""
echo "📂 Full directory tree (up to depth 4):"
find extracted_pkg -maxdepth 4 -print || true

echo ""
echo "🔍 Searching for Payload (file or directory)..."
PAYLOAD_PATH=$(find extracted_pkg -name Payload -type f -o -type d | head -n 1 || true)

if [ -z "$PAYLOAD_PATH" ]; then
  echo "❌ No Payload found. Dumping directory contents for debugging:"
  find extracted_pkg -maxdepth 6 -print
  exit 1
fi

echo "✅ Found Payload at: $PAYLOAD_PATH"

# Create destination
DEST_DIR="$HOME/gstreamer-ios"
mkdir -p "$DEST_DIR"

# If Payload is a directory, copy it.
if [ -d "$PAYLOAD_PATH" ]; then
  echo "📁 Payload is a directory. Copying its contents..."
  cp -R "$PAYLOAD_PATH"/* "$DEST_DIR/"
else
  echo "📦 Payload is a file. Extracting using tar..."
  tar -xvf "$GITHUB_WORKSPACE/$PAYLOAD_PATH" -C "$DEST_DIR"
fi

echo ""
echo "✅ Extraction complete. Verifying structure..."
ls -l "$DEST_DIR" || true
echo ""
echo "📂 Framework structure (depth 4):"
find "$DEST_DIR/Library/Frameworks" -maxdepth 4 -print || true

# Optional sanity checks
echo ""
echo "🔎 Checking for static libs (*.a):"
find "$DEST_DIR" -name "*.a" | head -20 || true

echo ""
echo "🔎 Checking for headers:"
find "$DEST_DIR" -name "gstreamer*" -type d | head -10 || true

echo ""
echo "🎯 GStreamer iOS SDK successfully extracted to: $DEST_DIR"
