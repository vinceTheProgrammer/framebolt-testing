echo "🍎 Installing GStreamer for macOS..."
mkdir -p gst-installer
cd gst-installer

echo "Downloading GStreamer runtime..."
curl -L "${{ matrix.gst_pkg_runtime_url }}" -o gstreamer-runtime.pkg

echo "Downloading GStreamer devel..."
curl -L "${{ matrix.gst_pkg_devel_url }}" -o gstreamer-devel.pkg

echo "Installing both packages..."
sudo installer -pkg gstreamer-runtime.pkg -target /
sudo installer -pkg gstreamer-devel.pkg -target /

echo "✅ GStreamer framework installed to /Library/Frameworks/"
cd ..
