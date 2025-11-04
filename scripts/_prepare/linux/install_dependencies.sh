echo "🧱 Installing Linux build dependencies..."
sudo apt-get update || true
sudo apt-get install -y \
    build-essential cmake zip git \
    libx11-dev libxext-dev libxrandr-dev libxrender-dev libxss-dev \
    libxcursor-dev libxi-dev libxinerama-dev libxtst-dev libwayland-dev libxkbcommon-dev \
    libdrm-dev libgbm-dev libasound2-dev libpulse-dev libudev-dev libdbus-1-dev \
    libibus-1.0-dev fcitx-libs-dev gstreamer1.0-dev libgstreamer-plugins-base1.0-dev
