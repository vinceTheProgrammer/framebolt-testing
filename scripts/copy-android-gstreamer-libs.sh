gstreamer_runtime_dir=gstreamer-1.0-android-universal-1.27.2.1-runtime
gstreamer_devel_dir=gstreamer-1.0-android-universal-1.27.2.1

for abi in armeabi-v7a arm64-v8a x86 x86_64; do
  mkdir -p android-project/app/libs/$abi

  cp -v $gstreamer_runtime_dir/$abi/lib/*.so android-project/app/libs/$abi/
done

mkdir -p android-project/app/src/main/jni/gstreamer/include
mkdir -p android-project/app/src/main/jni/gstreamer/lib/glib-2.0/include

cp -r -v $gstreamer_devel_dir/arm64-v8a/include/* android-project/app/src/main/jni/gstreamer/include/
cp -r -v $gstreamer_devel_dir/arm64-v8a/lib/glib-2.0/include/* android-project/app/src/main/jni/gstreamer/lib/glib-2.0/include/
