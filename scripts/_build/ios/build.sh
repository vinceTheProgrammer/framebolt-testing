GST_IOS_DIR=$(find . -type d -name "gstreamer-1.0-ios-universal-*")
cmake -S . -B build-ios -G Xcode \
                -DCMAKE_SYSTEM_NAME=iOS \
                -DCMAKE_OSX_SYSROOT=iphonesimulator \
                -DCMAKE_OSX_ARCHITECTURES="x86_64" \
                -DCMAKE_PREFIX_PATH="$GST_IOS_DIR"
cmake --build build-ios --config Debug
