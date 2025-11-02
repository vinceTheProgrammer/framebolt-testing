cmake -S . -B build-ios -G Xcode \
                -DCMAKE_SYSTEM_NAME=iOS \
                -DCMAKE_OSX_SYSROOT=iphonesimulator \
                -DCMAKE_OSX_ARCHITECTURES="x86_64" \
                -DCMAKE_SUPPRESS_REGENERATION=ON \
cmake --build build-ios --config Debug
