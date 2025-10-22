APP_PATH="build-macos/framebolt.app"
GST_PREFIX="/Library/Frameworks/GStreamer.framework/Versions/Current"
FRAMEWORKS_DIR="$APP_PATH/Contents/Frameworks"

mkdir -p "$FRAMEWORKS_DIR"

# Copy core GStreamer dylibs you depend on
cp -a "$GST_PREFIX/lib/libgstreamer-1.0.dylib" "$FRAMEWORKS_DIR/"
cp -a "$GST_PREFIX/lib/libgstbase-1.0.dylib" "$FRAMEWORKS_DIR/"
cp -a "$GST_PREFIX/lib/libgobject-2.0.dylib" "$FRAMEWORKS_DIR/"
cp -a "$GST_PREFIX/lib/libglib-2.0.dylib" "$FRAMEWORKS_DIR/"
# add others your app links against (see `otool -L`)

# Copy the plugin directory
mkdir -p "$APP_PATH/Contents/Resources/lib/gstreamer-1.0"
cp -a "$GST_PREFIX/lib/gstreamer-1.0/"* "$APP_PATH/Contents/Resources/lib/gstreamer-1.0/"

APP_BIN="$APP_PATH/Contents/MacOS/framebolt"

for lib in "$FRAMEWORKS_DIR"/*.dylib; do
  BASENAME=$(basename "$lib")
  install_name_tool -id "@rpath/$BASENAME" "$lib"
  install_name_tool -change "$GST_PREFIX/lib/$BASENAME" "@rpath/$BASENAME" "$APP_BIN"
done

# Add the rpath for your app to search its Frameworks folder
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_BIN"
