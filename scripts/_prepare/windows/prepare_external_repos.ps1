git clone https://github.com/libsdl-org/SDL.git external/SDL
git clone https://github.com/libsdl-org/SDL_ttf.git external/SDL_ttf
git clone https://github.com/bytecodealliance/wasm-micro-runtime.git external/wamr
cd external/SDL_ttf
./external/Get-GitModules.ps1
cd ../..
git clone https://github.com/bytecodealliance/wasm-micro-runtime.git external/wamr
git clone --single-branch --branch docking https://github.com/ocornut/imgui.git external/imgui
