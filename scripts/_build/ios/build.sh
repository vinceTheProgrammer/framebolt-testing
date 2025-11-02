# Path where you extracted GStreamer in your script
export GST_IOS_DIR="$HOME/gstreamer-ios/Library/Frameworks/GStreamer.framework/Versions/1.0"

echo "📍 Using GStreamer iOS SDK at: $GST_IOS_DIR"
ls -R "$GST_IOS_DIR" | head -n 40  # (optional) debug listing

# Configure for iOS (simulator build here — change SYSROOT/arch for device)
cmake -S . -B build-ios -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT=iphonesimulator \
    -DCMAKE_OSX_ARCHITECTURES="x86_64" \
    -DCMAKE_PREFIX_PATH="$GST_IOS_DIR" \
    -DGSTREAMER_ROOT="$GST_IOS_DIR"

# Build
set -euxo pipefail
cmake --build build-ios --config Debug --verbose \
    | tee build-ios.log
echo "✅ Build completed successfully"
