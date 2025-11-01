git clone https://github.com/libsdl-org/SDL.git external/SDL
git clone https://github.com/libsdl-org/SDL_ttf.git external/SDL_ttf
cd external/SDL_ttf
./external/download.sh
cd ../..
git clone https://github.com/bytecodealliance/wasm-micro-runtime.git external/wamr
git clone --single-branch --branch docking https://github.com/ocornut/imgui.git external/imgui
