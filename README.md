# Framebolt

## Prepare To Build (for all platforms)
```
git clone https://github.com/vinceTheProgrammer/framebolt-testing
cd framebolt-testing
git clone https://github.com/libsdl-org/SDL.git external/SDL
git clone https://github.com/libsdl-org/SDL_ttf.git external/SDL_ttf
cd external/SDL_ttf
./external/download.sh
cd ../..
git clone https://github.com/bytecodealliance/wasm-micro-runtime.git external/wamr
git clone --single-branch --branch docking https://github.com/ocornut/imgui.git external/imgui
```

## Build Desktop
```
cmake -S . -B build
cmake --build build
```
executable should be in build directory

## Build Android
```
cd android-project
./gradlew build
```
apks should be in `android-project/app/build/outputs/apk` `debug` and `release`

## Build iOS
```
cmake -S . -B build-ios -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_SYSROOT=iphonesimulator \
  -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"
cmake --build build-ios --config Debug
```
I believe this builds an app bundle debug build targeted for an iphone simulator. I guess you need certs setup or something to build targeted for a physical device(?)

# Other
find . -type f -name '*.sh' -exec chmod +x {} +

xcrun simctl list devices
xcrun simctl boot "iPhone 15 Pro"
open -a Simulator
xcrun simctl install booted build-ios/Debug/framebolt.app
xcrun simctl launch booted com.vinceTheProgrammer.framebolt


xcrun simctl uninstall booted com.vinceTheProgrammer.framebolt
xcrun simctl erase all



# ci draft
# Choose a simulator (first booted or default)
DEVICE=$(xcrun simctl list devices | grep -m1 "iPhone 15" | awk -F '[()]' '{print $2}')

# Boot it (safe even if already running)
xcrun simctl boot "$DEVICE" || true

# Install and launch
xcrun simctl install booted build-ios/Debug/framebolt.app
xcrun simctl launch booted com.vinceTheProgrammer.framebolt
