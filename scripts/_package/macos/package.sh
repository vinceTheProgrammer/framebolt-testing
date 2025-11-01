mkdir -p artifacts
cp -R build-macos/framebolt.app artifacts/
cd artifacts && zip -r ../framebolt-macos.zip framebolt.app
