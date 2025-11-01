#!/bin/bash
# ============================================================
# make_macos_icons.sh
# Generate all required macOS .app icon sizes from a 1024x1024 source image
# Requires: ImageMagick (`magick` command)
# ============================================================

set -e

SOURCE_ICON="icon-1024.png"
DEST_DIR="./AppIcon.appiconset"

# Allow custom source path or output directory as arguments
if [ $# -ge 1 ]; then
    SOURCE_ICON="$1"
fi

if [ $# -ge 2 ]; then
    DEST_DIR="$2"
fi

# Ensure ImageMagick is available
if ! command -v magick &> /dev/null; then
    echo "❌ Error: ImageMagick 'magick' command not found."
    echo "Install it with: brew install imagemagick"
    exit 1
fi

# Ensure source image exists
if [ ! -f "$SOURCE_ICON" ]; then
    echo "❌ Error: Source icon '$SOURCE_ICON' not found."
    echo "Usage: ./make_macos_icons.sh [source.png] [destination_directory]"
    exit 1
fi

mkdir -p "$DEST_DIR"

echo "🎨 Generating macOS icon set from: $SOURCE_ICON"
echo "📁 Output directory: $DEST_DIR"
echo ""

# Array of size/filename pairs
declare -A ICON_SIZES=(
  [icon_16x16.png]=16
  [icon_16x16@2x.png]=32
  [icon_32x32.png]=32
  [icon_32x32@2x.png]=64
  [icon_128x128.png]=128
  [icon_128x128@2x.png]=256
  [icon_256x256.png]=256
  [icon_256x256@2x.png]=512
  [icon_512x512.png]=512
  [icon_512x512@2x.png]=1024
)

# Generate icons
for filename in "${!ICON_SIZES[@]}"; do
    size=${ICON_SIZES[$filename]}
    echo "🖼️  Creating $filename (${size}x${size})"
    magick "$SOURCE_ICON" -resize ${size}x${size} "$DEST_DIR/$filename"
done

# Optionally copy the macOS Contents.json file if available
if [ ! -f "$DEST_DIR/Contents.json" ]; then
    echo ""
    echo "ℹ️  No Contents.json found, writing macOS-compatible one..."
    cat > "$DEST_DIR/Contents.json" <<'JSON'
{
  "images": [
    {"size":"16x16","idiom":"mac","filename":"icon_16x16.png","scale":"1x"},
    {"size":"16x16","idiom":"mac","filename":"icon_16x16@2x.png","scale":"2x"},
    {"size":"32x32","idiom":"mac","filename":"icon_32x32.png","scale":"1x"},
    {"size":"32x32","idiom":"mac","filename":"icon_32x32@2x.png","scale":"2x"},
    {"size":"128x128","idiom":"mac","filename":"icon_128x128.png","scale":"1x"},
    {"size":"128x128","idiom":"mac","filename":"icon_128x128@2x.png","scale":"2x"},
    {"size":"256x256","idiom":"mac","filename":"icon_256x256.png","scale":"1x"},
    {"size":"256x256","idiom":"mac","filename":"icon_256x256@2x.png","scale":"2x"},
    {"size":"512x512","idiom":"mac","filename":"icon_512x512.png","scale":"1x"},
    {"size":"512x512","idiom":"mac","filename":"icon_512x512@2x.png","scale":"2x"}
  ],
  "info": {"version":1,"author":"xcode"}
}
JSON
fi

echo ""
echo "✅ Done! Generated icons in: $DEST_DIR"
echo "You can now add this AppIcon.appiconset to your Xcode or CMake macOS bundle."
