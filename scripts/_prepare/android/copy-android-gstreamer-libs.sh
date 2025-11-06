mv armv7 armeabi-v7a
mv arm64 arm64-v8a

for abi in armeabi-v7a arm64-v8a x86 x86_64; do
  SRC_DIR="./${abi}/lib"
  DST_DIR="android-project/app/libs/${abi}"

  mkdir -p $DST_DIR

  # Copy core libs
  cp -v $SRC_DIR/*.so $DST_DIR/

  # Copy gstreamer plugins
  find $SRC_DIR/gstreamer-1.0 -name "*.so" -exec cp -v {} $DST_DIR/ \;

  # Copy GIO modules
  find $SRC_DIR/gio/modules -name "*.so" -exec cp -v {} $DST_DIR/ \;
done

# ---- Headers ----
echo "Copying include headers..."
mkdir -p android-project/app/src/main/jni/gstreamer/include
mkdir -p android-project/app/src/main/jni/gstreamer/lib/glib-2.0/include

cp -r -v ./arm64-v8a/include/* android-project/app/src/main/jni/gstreamer/include/
cp -r -v ./arm64-v8a/lib/glib-2.0/include/* android-project/app/src/main/jni/gstreamer/lib/glib-2.0/include/

echo "✅ All ABIs and headers copied successfully!"
