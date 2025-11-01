mkdir -p artifacts
find build-ios -name "*.app" -exec cp -R {} artifacts/ \;
cd artifacts && zip -r ../framebolt-ios.zip ./*
