#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <SDL3_ttf/SDL_ttf.h>
#include <SDL3/SDL_log.h>
#include <gst/gst.h>
#include <stdio.h>
#include "imgui.h"
#include "backends/imgui_impl_sdl3.h"
#include "backends/imgui_impl_sdlrenderer3.h"

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

    SDL_SetLogPriorities(SDL_LOG_PRIORITY_VERBOSE);

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

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO &io = ImGui::GetIO(); (void)io;
    ImGui::StyleColorsDark();

    if (!ImGui_ImplSDL3_InitForSDLRenderer(window, renderer))
    {
        SDL_Log("Failed to init ImGui SDL3 backend!");
    }

    if (!ImGui_ImplSDLRenderer3_Init(renderer))
    {
        SDL_Log("Failed to init ImGui SDLRenderer3 backend!");
    }

    // --- Render loop ---
    SDL_Event e;
    int running = 1;
    while (running) {
        while (SDL_PollEvent(&e)) {
            ImGui_ImplSDL3_ProcessEvent(&e);
            if (e.type == SDL_EVENT_QUIT)
                running = 0;
        }

        // Start a new ImGui frame
        ImGui_ImplSDLRenderer3_NewFrame();
        ImGui_ImplSDL3_NewFrame();
        ImGui::NewFrame();

        // --- Your world rendering ---
        SDL_SetRenderDrawColor(renderer, 20, 20, 20, 255);
        SDL_RenderClear(renderer);

        // --- Your UI ---
        ImGui::Begin("GStreamer Plugins");

        GList *plugins = gst_registry_get_plugin_list(gst_registry_get());
        for (GList *l = plugins; l != NULL; l = l->next) {
            GstPlugin *plugin = GST_PLUGIN(l->data);
            const gchar *name = gst_plugin_get_name(plugin);
            const gchar *desc = gst_plugin_get_description(plugin);
            const gchar *filename = gst_plugin_get_filename(plugin);

            if (ImGui::TreeNode(name)) {
                ImGui::Text("Description: %s", desc ? desc : "(none)");
                ImGui::Text("Filename: %s", filename ? filename : "(none)");
                ImGui::TreePop();
            }
        }
        gst_plugin_list_free(plugins);

        ImGui::End();

        // --- Rendering ---
        ImGui::Render();
        ImGui_ImplSDLRenderer3_RenderDrawData(ImGui::GetDrawData(), renderer);
        SDL_RenderPresent(renderer);

        SDL_Delay(16);
    }

    // --- Cleanup ---
    // Destroy ImGui
    ImGui_ImplSDLRenderer3_Shutdown();
    ImGui_ImplSDL3_Shutdown();
    ImGui::DestroyContext();

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    TTF_Quit();
    SDL_Quit();

    return 0;
}
