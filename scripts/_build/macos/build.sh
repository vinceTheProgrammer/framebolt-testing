cmake -S . -B build-macos -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"
cmake --build build-macos --config Release
