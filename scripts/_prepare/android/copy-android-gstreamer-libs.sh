# Create expected structure
# mkdir -p android-project/app/src/main/jni/
# mkdir -p android-project/app/libs/{arm64-v8a,armeabi-v7a,x86,x86_64}
# mkdir -p android-project/app/src/main/jni/gstreamer

# Copy includes (they’re same across ABIs)
# mv arm64/include/* android-project/app/src/main/jni/gstreamer/

# Copy .so files into jniLibs
# mv arm64/lib/*.so android-project/app/libs/arm64-v8a/
# mv armv7/lib/*.so android-project/app/libs/armeabi-v7a/
# mv x86/lib/*.so android-project/app/libs/x86/
# mv x86_64/lib/*.so android-project/app/libs/x86_64/

mv armv7 armeabi-v7a
mv arm64 arm64-v8a

#gstreamer_runtime_dir=gstreamer-1.0-android-universal-1.27.2.1-runtime
#gstreamer_devel_dir=gstreamer-1.0-android-universal-1.27.2.1

for abi in armeabi-v7a arm64-v8a x86 x86_64; do
  mkdir -p android-project/app/libs/$abi

  cp -v ./$abi/lib/*.so android-project/app/libs/$abi/
done

mkdir -p android-project/app/src/main/jni/gstreamer/include
mkdir -p android-project/app/src/main/jni/gstreamer/lib/glib-2.0/include

cp -r -v ./arm64-v8a/include/* android-project/app/src/main/jni/gstreamer/include/
cp -r -v ./arm64-v8a/lib/glib-2.0/include/* android-project/app/src/main/jni/gstreamer/lib/glib-2.0/include/
