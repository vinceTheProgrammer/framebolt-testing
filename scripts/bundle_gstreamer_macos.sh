APP_BIN="$APP_PATH/Contents/MacOS/Framebolt"

for lib in "$FRAMEWORKS_DIR"/*.dylib; do
  BASENAME=$(basename "$lib")
  install_name_tool -id "@rpath/$BASENAME" "$lib"
  install_name_tool -change "$GST_PREFIX/lib/$BASENAME" "@rpath/$BASENAME" "$APP_BIN"
done

# Add the rpath for your app to search its Frameworks folder
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_BIN"
