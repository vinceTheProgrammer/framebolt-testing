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
PAYLOAD_PATH=$(find extracted_pkg -type d -name Payload | head -n 1 || true)

if [ -z "$PAYLOAD_PATH" ]; then
  echo "❌ No Payload found. Dumping directory contents for debugging:"
  find extracted_pkg -maxdepth 6 -print
  exit 1
fi

echo "✅ Found Payload at: $PAYLOAD_PATH"

# DEST_DIR="$HOME/gstreamer-ios"
# mkdir -p "$DEST_DIR"

# if [ -d "$PAYLOAD_PATH" ]; then
#   echo "📁 Payload is a directory. Copying its contents..."
#   cp -R "$PAYLOAD_PATH"/* "$DEST_DIR/"
# else
#   echo "📦 Payload is a file. Extracting using tar..."
#   tar -xvf "$PAYLOAD_PATH" -C "$DEST_DIR"
# fi

# echo ""
# echo "✅ Extraction complete. Verifying structure..."
# ls -l "$DEST_DIR" || true
# echo ""
# echo "📂 Framework structure (depth 4):"
# find "$DEST_DIR" -maxdepth 4 -type d | grep -E "Framework|Versions" || true
