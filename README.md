# Framebolt

## Prepare To Build (for all cases below)
```
git clone https://github.com/vinceTheProgrammer/framebolt-testing
cd framebolt-testing
git clone https://github.com/libsdl-org/SDL.git vendored/SDL
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
