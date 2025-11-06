#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <SDL3_ttf/SDL_ttf.h>
#include <SDL3/SDL_log.h>
#include <SDL3/SDL_system.h>
#include <gst/gst.h>
#include <stdio.h>
#include <string>
#include "SDL3/SDL_init.h"
#include "gst/gstinfo.h"
#include "gst/gstplugin.h"
#include "gst/gstregistry.h"
#include "imgui.h"
#include "backends/imgui_impl_sdl3.h"
#include "backends/imgui_impl_sdlrenderer3.h"
#include <gio/gio.h>

#if defined(__APPLE__)
#if TARGET_OS_OSX
#else
G_BEGIN_DECLS
GST_PLUGIN_STATIC_DECLARE(videoconvertscale);
GST_PLUGIN_STATIC_DECLARE(coreelements);
G_END_DECLS
#endif
#endif


#if defined(__ANDROID__)
#include <jni.h>
#include <android/log.h>

#define GST_TAG "GStreamer"

static void G_GNUC_NO_INSTRUMENT
android_gst_log_function(GstDebugCategory *category,
                         GstDebugLevel level,
                         const gchar *file,
                         const gchar *function,
                         gint line,
                         GObject *object,
                         GstDebugMessage *message,
                         gpointer user_data)
{

    SDL_Log("hello");

    const gchar *cat_name = gst_debug_category_get_name(category);
    const gchar *msg = gst_debug_message_get(message);
    int android_log_level;

    switch (level) {
        case GST_LEVEL_ERROR:
            android_log_level = ANDROID_LOG_ERROR; break;
        case GST_LEVEL_WARNING:
            android_log_level = ANDROID_LOG_WARN; break;
        case GST_LEVEL_INFO:
            android_log_level = ANDROID_LOG_INFO; break;
        case GST_LEVEL_DEBUG:
            android_log_level = ANDROID_LOG_DEBUG; break;
        default:
            android_log_level = ANDROID_LOG_VERBOSE; break;
    }

    __android_log_print(android_log_level, GST_TAG,
                        "[%s] %s:%d:%s() %s",
                        cat_name, file, line, function, msg);
}
#endif

int main(int argc, char *argv[])
{
    #if defined(__ANDROID__)
    JNIEnv* env = static_cast<JNIEnv*>(SDL_GetAndroidJNIEnv());
    jobject activity = (jobject)SDL_GetAndroidActivity();

    // Get the ApplicationInfo.nativeLibraryDir
    jclass clazz(env->GetObjectClass(activity));
    jmethodID getAppInfo = env->GetMethodID(clazz, "getApplicationInfo", "()Landroid/content/pm/ApplicationInfo;");
    jobject appInfo = env->CallObjectMethod(activity, getAppInfo);
    jclass appInfoClass = env->GetObjectClass(appInfo);
    jfieldID nativeLibDirField = env->GetFieldID(appInfoClass, "nativeLibraryDir", "Ljava/lang/String;");
    jstring nativeLibDir = (jstring)env->GetObjectField(appInfo, nativeLibDirField);

    std::string libDir = env->GetStringUTFChars(nativeLibDir, nullptr);
    setenv("GST_PLUGIN_PATH", libDir.c_str(), 1);

    gst_debug_remove_log_function (NULL);
    gst_debug_set_default_threshold (GST_LEVEL_DEBUG);
    gst_debug_add_log_function ((GstLogFunction) android_gst_log_function, NULL, NULL);
    #endif

    #if defined(__APPLE__)
    #include "TargetConditionals.h"
    #if TARGET_OS_OSX
    const char* sdl_path = SDL_GetBasePath();
    if (!sdl_path) {
        printf("SDL_GetBasePath Error: %s\n", SDL_GetError());
        SDL_Quit();
        return 1;
    }
    std::string base_path = sdl_path;
    SDL_free((void*)sdl_path);
    setenv("GST_PLUGIN_PATH", (base_path + "/lib/gstreamer-1.0").c_str(), 1);
    #endif
    #endif

    // --- Initialize GStreamer ---
    gst_init(&argc, &argv);

    #if defined(__APPLE__)
    #if TARGET_OS_OSX
    #else
    GST_PLUGIN_STATIC_REGISTER(videoconvertscale);
    GST_PLUGIN_STATIC_REGISTER(coreelements);
    #endif
    #endif

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
