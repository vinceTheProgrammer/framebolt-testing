GST_ANDROID_URL="https://github.com/vinceTheProgrammer/gstreamer-android-universal-dynamic-build/releases/download/v1.27.2.1/gstreamer-1.0-android-universal-1.27.2.1-runtime.tar.xz"
echo "Downloading $GST_ANDROID_URL..."
curl -L "$GST_ANDROID_URL" -o gstreamer-android.tar.xz
tar -xf gstreamer-android.tar.xz
