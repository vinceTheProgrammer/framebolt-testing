cmake_minimum_required(VERSION 3.16)
project(framebolt)

# --- General build setup ---
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<CONFIGURATION>")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<CONFIGURATION>")

set(SDLTTF_VENDORED ON)

if(NOT ANDROID)
    set(BUILD_SHARED_LIBS OFF CACHE INTERNAL "")
    set(SDL_SHARED OFF CACHE BOOL "" FORCE)
    set(SDL_STATIC ON CACHE BOOL "" FORCE)
endif()

# --- SDL setup ---
add_subdirectory(vendored/SDL EXCLUDE_FROM_ALL)
add_subdirectory(vendored/SDL_ttf EXCLUDE_FROM_ALL)

# -----------------------------------------------------------
# 🧠 GStreamer setup
# -----------------------------------------------------------
if(LINUX)
    option(USE_SYSTEM_GSTREAMER "Use system GStreamer instead of bundled SDK" ON)
else()
    option(USE_SYSTEM_GSTREAMER "Use system GStreamer instead of bundled SDK" OFF)
endif()

set(GSTREAMER_MIN_VERSION "1.18")

if(USE_SYSTEM_GSTREAMER)
    message(STATUS "Using system-installed GStreamer")
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(GSTREAMER REQUIRED gstreamer-1.0>=${GSTREAMER_MIN_VERSION})
else()
    message(STATUS "Using bundled GStreamer SDK")

    if(WIN32)
        # Default install path from GitHub Actions workflow
        set(GSTREAMER_ROOT "C:/gstreamer/1.0/msvc_x86_64")
    elseif(APPLE)
        # macOS and iOS GStreamer SDKs install into /Library/Frameworks or local path
        set(GSTREAMER_ROOT "/Library/Frameworks/GStreamer.framework/Versions/Current")
        if(NOT EXISTS "${GSTREAMER_ROOT}")
            # fallback: if extracted manually, try in source dir or env
            if(DEFINED ENV{GSTREAMER_ROOT})
                set(GSTREAMER_ROOT $ENV{GSTREAMER_ROOT})
            elseif(EXISTS "${CMAKE_SOURCE_DIR}/gstreamer")
                set(GSTREAMER_ROOT "${CMAKE_SOURCE_DIR}/gstreamer")
            endif()
        endif()
    elseif(ANDROID)
        # Assume pre-extracted GStreamer NDK-style bundle inside android-project
        set(GSTREAMER_ROOT "${CMAKE_SOURCE_DIR}/android-project/app/src/main/jni/gstreamer")
        include_directories("${GSTREAMER_ROOT}/include")
        link_directories("${CMAKE_SOURCE_DIR}/android-project/app/src/main/jniLibs/${ANDROID_ABI}")
    else()
        message(FATAL_ERROR "Bundled GStreamer mode not supported on this platform.")
    endif()

    # Include and link paths
    set(GSTREAMER_INCLUDE_DIRS
        "${GSTREAMER_ROOT}/include/gstreamer-1.0"
        "${GSTREAMER_ROOT}/include/glib-2.0"
        "${GSTREAMER_ROOT}/lib/glib-2.0/include"
        "${GSTREAMER_ROOT}/lib/gstreamer-1.0/include"
    )
    if(WIN32)
        set(GSTREAMER_LIBRARY_DIRS "${GSTREAMER_ROOT}/lib")
    elseif(APPLE)
        set(GSTREAMER_LIBRARY_DIRS "${GSTREAMER_ROOT}/lib")
    elseif(ANDROID)
        set(GSTREAMER_LIBRARY_DIRS "${GSTREAMER_ROOT}/arm64/lib")
    endif()

    # Libraries
    find_library(GSTREAMER_LIBRARIES
        NAMES gstreamer-1.0
        PATHS ${GSTREAMER_LIBRARY_DIRS}
    )

    if(NOT GSTREAMER_LIBRARIES)
        message(FATAL_ERROR "GStreamer not found in ${GSTREAMER_LIBRARY_DIRS}")
    endif()
endif()

if(NOT ANDROID)
    include_directories(${GSTREAMER_INCLUDE_DIRS})
    link_directories(${GSTREAMER_LIBRARY_DIRS})
endif()

# -----------------------------------------------------------
# Target setup
# -----------------------------------------------------------
if(IOS)
    add_executable(framebolt MACOSX_BUNDLE main.c)
elseif(ANDROID)
    add_library(main SHARED main.c)
else()
    add_executable(framebolt WIN32 main.c)
endif()

# -----------------------------------------------------------
# Link libraries
# -----------------------------------------------------------
if(ANDROID)
    target_link_libraries(main
        PRIVATE
            SDL3_ttf::SDL3_ttf
            SDL3::SDL3
            ${GSTREAMER_LIBRARIES}
    )
else()
    target_link_libraries(framebolt
        PRIVATE
            SDL3_ttf::SDL3_ttf
            SDL3::SDL3
            ${GSTREAMER_LIBRARIES}
    )
endif()

# -----------------------------------------------------------
# iOS-specific bundle settings
# -----------------------------------------------------------
if(IOS)
    set_target_properties(framebolt PROPERTIES
        MACOSX_BUNDLE YES
        XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2" # iPhone + iPad
        XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "-"
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/ios-project/Info.plist"
        XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon"
        RESOURCE "${CMAKE_CURRENT_SOURCE_DIR}/ios-project/LaunchScreen.storyboard"
    )

    target_sources(framebolt PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/ios-project/LaunchScreen.storyboard"
        "${CMAKE_CURRENT_SOURCE_DIR}/ios-project/Assets.xcassets"
    )
endif()

# -----------------------------------------------------------
# Diagnostic output
# -----------------------------------------------------------
message(STATUS "GStreamer include dirs: ${GSTREAMER_INCLUDE_DIRS}")
message(STATUS "GStreamer library dirs: ${GSTREAMER_LIBRARY_DIRS}")
message(STATUS "GStreamer libs: ${GSTREAMER_LIBRARIES}")
