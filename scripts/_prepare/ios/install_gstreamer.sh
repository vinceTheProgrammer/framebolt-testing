GST_IOS_URL="https://gstreamer.freedesktop.org/data/pkg/ios/1.26.7/gstreamer-1.0-devel-1.26.7-ios-universal.pkg"
echo "Downloading $GST_IOS_URL..."
curl -L "$GST_IOS_URL" -o gstreamer-ios.pkg

echo "Expanding package..."
pkgutil --expand-full gstreamer-ios.pkg extracted_pkg

echo "Extracting payload..."
mkdir -p $HOME/gstreamer-ios
cd $HOME/gstreamer-ios
tar -xf ../extracted_pkg/gstreamer-1.0-devel-1.26.7-ios-universal.pkg/Payload

echo "GStreamer extracted to: $HOME/gstreamer-ios"
ls -R $HOME/gstreamer-ios | head -50
