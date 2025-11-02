GST_IOS_URL="https://gstreamer.freedesktop.org/data/pkg/ios/1.26.7/gstreamer-1.0-devel-1.26.7-ios-universal.pkg"
echo "Downloading $GST_IOS_URL..."
curl -L "$GST_IOS_URL" -o gstreamer-ios.pkg

ls .

echo "Installing GStreamer iOS SDK..."
sudo installer -pkg gstreamer-ios.pkg -target /

ls /Library/Frameworks/GStreamer.framework/Versions/
lipo -info /Library/Frameworks/GStreamer.framework/Versions/1.0/lib/libgstreamer-1.0.a
