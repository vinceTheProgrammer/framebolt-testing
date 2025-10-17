#include <SDL3/SDL.h>
#include <SDL3_ttf/SDL_ttf.h>
#include <gst/gst.h>
#include <stdio.h>

int main(int argc, char *argv[])
{
    // --- Initialize GStreamer ---
    gst_init(&argc, &argv);

    guint major, minor, micro, nano;
    gst_version(&major, &minor, &micro, &nano);

    char version_text[128];
    snprintf(version_text, sizeof(version_text),
             "GStreamer version: %u.%u.%u", major, minor, micro);

    // --- Initialize SDL and TTF ---
    if (!SDL_Init(SDL_INIT_VIDEO)) {
        SDL_Log("SDL_Init failed: %s", SDL_GetError());
        return 1;
    }

    if (!TTF_Init()) {
        SDL_Log("TTF_Init failed: %s", SDL_GetError());
        SDL_Quit();
        return 1;
    }

    SDL_Window *window = SDL_CreateWindow(
        "Framebolt GStreamer Test",
        800, 480,
        SDL_WINDOW_RESIZABLE
    );

    if (!window) {
        SDL_Log("SDL_CreateWindow failed: %s", SDL_GetError());
        TTF_Quit();
        SDL_Quit();
        return 1;
    }

    SDL_Renderer *renderer = SDL_CreateRenderer(window, NULL);
    if (!renderer) {
        SDL_Log("SDL_CreateRenderer failed: %s", SDL_GetError());
        SDL_DestroyWindow(window);
        TTF_Quit();
        SDL_Quit();
        return 1;
    }

    // --- Load font (use bundled font or system one) ---
    const char *font_path = "DejaVuSans.ttf";  // include this in your assets folder
    TTF_Font *font = TTF_OpenFont(font_path, 32);
    if (!font) {
        SDL_Log("Failed to load font: %s", SDL_GetError());
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        TTF_Quit();
        SDL_Quit();
        return 1;
    }

    // --- Create texture from version text ---
    SDL_Color white = {255, 255, 255, 255};
    SDL_Surface *surface = TTF_RenderText_Blended(font, version_text, 0, white);
    if (!surface) {
        SDL_Log("Failed to render text: %s", SDL_GetError());
        TTF_CloseFont(font);
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        TTF_Quit();
        SDL_Quit();
        return 1;
    }
    SDL_Texture *texture = SDL_CreateTextureFromSurface(renderer, surface);

    SDL_FRect dst_rect = {
        .x = 50.0f,
        .y = 200.0f,
        .w = (float)surface->w,
        .h = (float)surface->h
    };

    SDL_DestroySurface(surface);

    // --- Render loop ---
    SDL_Event e;
    int running = 1;
    while (running) {
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_EVENT_QUIT)
                running = 0;
        }

        SDL_SetRenderDrawColor(renderer, 20, 20, 20, 255);
        SDL_RenderClear(renderer);

        SDL_RenderTexture(renderer, texture, NULL, &dst_rect);
        SDL_RenderPresent(renderer);

        SDL_Delay(16);
    }

    // --- Cleanup ---
    SDL_DestroyTexture(texture);
    TTF_CloseFont(font);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    TTF_Quit();
    SDL_Quit();

    return 0;
}
