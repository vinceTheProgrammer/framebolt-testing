echo "🔍 BEGIN FULL GSTREAMER PATH DUMP"
echo "==================================="

echo "🏠 HOME directory: $HOME"
echo "📦 GStreamer expected path: $HOME/gstreamer-ios"

if [ -d "$HOME/gstreamer-ios" ]; then
  echo ""
  echo "📁 Listing top-level contents:"
  ls -al "$HOME/gstreamer-ios"

  echo ""
  echo "📂 Recursive structure (depth 3):"
  find "$HOME/gstreamer-ios" -maxdepth 3 -type d | sed 's/^/  📂 /'

  echo ""
  echo "🔎 Searching for key framework and lib files:"
  echo "  - GStreamer.framework:"
  find "$HOME/gstreamer-ios" -type d -name "GStreamer.framework" | sed 's/^/    📍 /'

  echo ""
  echo "  - Static libraries (*.a):"
  find "$HOME/gstreamer-ios" -name "*.a" | sed 's/^/    📦 /'

  echo ""
  echo "  - Header directories (gst, glib, gobject):"
  find "$HOME/gstreamer-ios" -type d \( -name "gst" -o -name "glib-2.0" -o -name "gobject" \) | sed 's/^/    📚 /'

  echo ""
  echo "📄 Sample of headers found:"
  find "$HOME/gstreamer-ios" -name "gst.h" -o -name "glib.h" -o -name "gobject.h" | head -20 | sed 's/^/    📄 /'

  echo ""
  echo "✅ Done. Directory scan complete."
else
  echo "❌ Directory $HOME/gstreamer-ios does not exist!"
  echo "🧭 Here’s what’s under $HOME for context:"
  ls -al "$HOME"
fi

echo "==================================="
echo "🔚 END FULL GSTREAMER PATH DUMP"
