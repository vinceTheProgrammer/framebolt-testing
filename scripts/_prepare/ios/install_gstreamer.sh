set -euxo pipefail

GST_IOS_URL="https://gstreamer.freedesktop.org/data/pkg/ios/1.26.7/gstreamer-1.0-devel-1.26.7-ios-universal.pkg"
echo "🚀 Downloading GStreamer iOS SDK from: $GST_IOS_URL"
curl -L "$GST_IOS_URL" -o gstreamer-ios.pkg

echo "📦 Expanding package structure..."
pkgutil --expand-full gstreamer-ios.pkg extracted_pkg

echo "🧭 Listing top-level contents of extracted_pkg:"
ls -l extracted_pkg || true
echo ""
echo "📂 Full directory tree (first few levels):"
find extracted_pkg -maxdepth 3 -type f -print || true

echo ""
echo "🔍 Searching for Payload file..."
PAYLOAD_PATH=$(find extracted_pkg -name Payload -type f | head -n 1 || true)

if [ -z "$PAYLOAD_PATH" ]; then
  echo "❌ No Payload file found. Printing expanded_pkg contents for debugging..."
  find extracted_pkg -maxdepth 5 -print
  exit 1
fi

echo "✅ Found Payload file at: $PAYLOAD_PATH"
echo "📦 Extracting Payload to \$HOME/gstreamer-ios..."
mkdir -p "$HOME/gstreamer-ios"
cd "$HOME/gstreamer-ios"
tar -xvf "$GITHUB_WORKSPACE/$PAYLOAD_PATH" || {
  echo "❌ Extraction failed. Printing directory listing for context..."
  ls -R "$GITHUB_WORKSPACE/extracted_pkg"
  exit 1
}

echo ""
echo "✅ Extraction complete. GStreamer contents at:"
ls -l "$HOME/gstreamer-ios" || true

echo ""
echo "📂 Framework structure (showing first few levels):"
find "$HOME/gstreamer-ios/Library/Frameworks" -maxdepth 4 -print || true

# Optional: check for libs and headers
echo ""
echo "🔎 Checking for static libraries (*.a):"
find "$HOME/gstreamer-ios" -name "*.a" | head -20 || true

echo ""
echo "🔎 Checking for headers:"
find "$HOME/gstreamer-ios" -name "gstreamer*" -type d | head -10 || true

echo ""
echo "🎯 GStreamer iOS SDK setup complete at: $HOME/gstreamer-ios"
