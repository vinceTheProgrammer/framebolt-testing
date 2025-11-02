GST_IOS_URL="https://gstreamer.freedesktop.org/data/pkg/ios/1.26.7/gstreamer-1.0-devel-1.26.7-ios-universal.pkg"
echo "Downloading $GST_IOS_URL..."
curl -L "$GST_IOS_URL" -o gstreamer-ios.tar.xz
tar -xf gstreamer-ios.tar.xz
ls .
sudo installer -pkg ios-framework-1.26.7-universal.pkg -target /
