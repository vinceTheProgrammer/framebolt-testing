cmake_minimum_required(VERSION 3.22)
project(framebolt LANGUAGES C CXX)

#-----------------------------------------------------------
# General setup
#-----------------------------------------------------------
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<CONFIGURATION>")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<CONFIGURATION>")

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

#-----------------------------------------------------------
# Platform detection
#-----------------------------------------------------------
if(APPLE)
    if(IOS)
        set(PLATFORM_IOS TRUE)
    else()
        set(PLATFORM_MAC TRUE)
    endif()
elseif(ANDROID)
    set(PLATFORM_ANDROID TRUE)
elseif(WIN32)
    set(PLATFORM_WINDOWS TRUE)
elseif(UNIX)
    set(PLATFORM_LINUX TRUE)
endif()

#-----------------------------------------------------------
# SDL3 + SDL_ttf vendored
#-----------------------------------------------------------
set(SDLTTF_VENDORED ON)

set(BUILD_SHARED_LIBS OFF CACHE INTERNAL "")
set(SDL_SHARED OFF CACHE BOOL "" FORCE)
set(SDL_STATIC ON CACHE BOOL "" FORCE)

# Use vendored builds for SDL3 and SDL_ttf
add_subdirectory(external/SDL EXCLUDE_FROM_ALL)
add_subdirectory(external/SDL_ttf EXCLUDE_FROM_ALL)
include_directories(
    ${CMAKE_SOURCE_DIR}/external/SDL/include
    ${CMAKE_SOURCE_DIR}/external/SDL_ttf/include
    )

#-----------------------------------------------------------
# Dear ImGui setup
#-----------------------------------------------------------
file(GLOB IMGUI_SRC
    external/imgui/*.cpp
    external/imgui/backends/imgui_impl_sdlrenderer3.cpp
    external/imgui/backends/imgui_impl_sdl3.cpp
    external/imgui/backends/imgui_impl_sdlgpu3.cpp
    external/imgui/misc/cpp/imgui_stdlib.*
)
add_library(imgui STATIC ${IMGUI_SRC})
target_include_directories(imgui PUBLIC external/imgui external/imgui/backends)

#-----------------------------------------------------------
# GStreamer setup
#-----------------------------------------------------------
if(PLATFORM_LINUX)
    option(USE_SYSTEM_GSTREAMER "Use system GStreamer instead of bundled SDK" ON)
else()
    option(USE_SYSTEM_GSTREAMER "Use system GStreamer instead of bundled SDK" OFF)
endif()

set(GSTREAMER_MIN_VERSION "1.18")

if(USE_SYSTEM_GSTREAMER)
    message(STATUS "Using system-installed GStreamer")
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(GSTREAMER REQUIRED gstreamer-1.0>=${GSTREAMER_MIN_VERSION})
    set(GSTREAMER_INCLUDE_DIRS ${GSTREAMER_INCLUDE_DIRS} ${GSTREAMER_INCLUDE_DIRS})
    set(GSTREAMER_LIBRARIES ${GSTREAMER_LIBRARIES})
    include_directories(${GSTREAMER_INCLUDE_DIRS})
    link_directories(${GSTREAMER_LIBRARY_DIRS})
elseif(PLATFORM_IOS)
    message(STATUS "Using GStreamer SDK .framework")

    # Tell CMake where the framework is
    set(GSTREAMER_FRAMEWORK_DIR "${CMAKE_SOURCE_DIR}/extracted_pkg/ios-framework-1.26.7-universal.pkg/Payload")

    set(GSTREAMER_FRAMEWORK "${GSTREAMER_FRAMEWORK_DIR}/GStreamer.framework")

    if(NOT GSTREAMER_FRAMEWORK)
        message(FATAL_ERROR "GStreamer.framework not found in ${GSTREAMER_FRAMEWORK_DIR}")
    endif()
else()
    message(STATUS "Using bundled GStreamer SDK")

    if(PLATFORM_WINDOWS)
        set(GSTREAMER_ROOT "C:/gstreamer/1.0/msvc_x86_64")
        set(GSTREAMER_LIBRARY_DIRS "${GSTREAMER_ROOT}/lib")
    elseif(PLATFORM_MAC)
        set(GSTREAMER_ROOT "/Library/Frameworks/GStreamer.framework/Versions/Current")
        set(GSTREAMER_LIBRARY_DIRS "${GSTREAMER_ROOT}/lib")
    elseif(PLATFORM_ANDROID)
        set(GSTREAMER_ROOT "${CMAKE_SOURCE_DIR}/android-project/app/src/main/jni/gstreamer")
        set(GSTREAMER_LIBRARY_DIRS "${CMAKE_SOURCE_DIR}/android-project/app/libs/${ANDROID_ABI}")
    endif()

    message(STATUS "GStreamer library dirs: ${GSTREAMER_LIBRARY_DIRS}")

    set(GSTREAMER_INCLUDE_DIRS
        "${GSTREAMER_ROOT}/include/gstreamer-1.0"
        "${GSTREAMER_ROOT}/include/glib-2.0"
        "${GSTREAMER_ROOT}/lib/glib-2.0/include"
    )

    include_directories(${GSTREAMER_INCLUDE_DIRS})
    link_directories(${GSTREAMER_LIBRARY_DIRS})

    # Explicitly find the core GStreamer and GLib libs
    if(PLATFORM_ANDROID)
        set(GSTREAMER_CORE_LIB  "${GSTREAMER_LIBRARY_DIRS}/libgstreamer-1.0.so")
        set(GST_BASE_LIB        "${GSTREAMER_LIBRARY_DIRS}/libgstbase-1.0.so")
        set(GLIB_LIB            "${GSTREAMER_LIBRARY_DIRS}/libglib-2.0.so")
        set(GOBJECT_LIB         "${GSTREAMER_LIBRARY_DIRS}/libgobject-2.0.so")
    else()
        find_library(GSTREAMER_CORE_LIB gstreamer-1.0 HINTS ${GSTREAMER_LIBRARY_DIRS})
        find_library(GST_BASE_LIB gstbase-1.0 HINTS ${GSTREAMER_LIBRARY_DIRS})
        find_library(GLIB_LIB glib-2.0 HINTS ${GSTREAMER_LIBRARY_DIRS})
        find_library(GOBJECT_LIB gobject-2.0 HINTS ${GSTREAMER_LIBRARY_DIRS})
    endif()

    message(STATUS "GStreamer core: ${GSTREAMER_CORE_LIB}")
    message(STATUS "GStreamer base: ${GST_BASE_LIB}")
    message(STATUS "GLib: ${GLIB_LIB}")
    message(STATUS "GObject: ${GOBJECT_LIB}")


    set(GSTREAMER_LIBRARIES
        ${GSTREAMER_CORE_LIB}
        ${GST_BASE_LIB}
        ${GOBJECT_LIB}
        ${GLIB_LIB}
    )
endif()
if(NOT PLATFORM_IOS)
    #-----------------------------------------------------------
    # WebAssembly Micro Runtime (WAMR)
    #-----------------------------------------------------------
    set(WAMR_ROOT_DIR "${CMAKE_SOURCE_DIR}/external/wamr")

    # Configure WAMR build features
    # You can adjust these per-platform as needed
    if(PLATFORM_LINUX)
        set(WAMR_BUILD_PLATFORM "linux")
        set(WAMR_BUILD_TARGET "X86_64")
    elseif(PLATFORM_WINDOWS)
        set(WAMR_BUILD_PLATFORM "windows")
        set(WAMR_BUILD_TARGET "X86_64")
    elseif(PLATFORM_MAC)
        set(WAMR_BUILD_PLATFORM "darwin")
        set(WAMR_BUILD_TARGET "X86_64")
    elseif(PLATFORM_ANDROID)
        set(WAMR_BUILD_PLATFORM "android")

        # Set WAMR target based on ANDROID_ABI
        if(ANDROID_ABI STREQUAL "arm64-v8a")
            set(WAMR_BUILD_TARGET "AARCH64")
        elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
            set(WAMR_BUILD_TARGET "ARM32")
        elseif(ANDROID_ABI STREQUAL "x86")
            set(WAMR_BUILD_TARGET "X86_32")
        elseif(ANDROID_ABI STREQUAL "x86_64")
            set(WAMR_BUILD_TARGET "X86_64")
        else()
            message(FATAL_ERROR "Unsupported ANDROID_ABI: ${ANDROID_ABI}")
        endif()

        # Disable MAP_32BIT for Android builds
        # add_definitions(-DWASM_USE_MAP_32BIT=0)

    elseif(PLATFORM_IOS)
        set(WAMR_BUILD_PLATFORM "darwin")  # iOS uses Darwin base

        # Handle both simulator architectures
        if(CMAKE_OSX_SYSROOT MATCHES "iphonesimulator")
            if(CMAKE_OSX_ARCHITECTURES MATCHES "arm64")
                set(WAMR_BUILD_TARGET "AARCH64")  # Apple Silicon simulator
            elseif(CMAKE_OSX_ARCHITECTURES MATCHES "x86_64")
                set(WAMR_BUILD_TARGET "X86_64")   # Intel simulator
            else()
                message(FATAL_ERROR "Unsupported simulator architecture: ${CMAKE_OSX_ARCHITECTURES}")
            endif()
        else()
            # In case you ever build for real devices later
            set(WAMR_BUILD_TARGET "AARCH64")
        endif()

        # iOS sandbox and linker differences
        add_definitions(
            -DWASM_USE_MAP_32BIT=0
            -DWASM_DISABLE_HW_BOUND_CHECK=1
            -DWASM_DISABLE_PTHREAD_SETNAME=1
        )

        message(STATUS "Building WAMR for iOS (${WAMR_BUILD_PLATFORM}, target=${WAMR_BUILD_TARGET})")
    endif()

    set(WAMR_BUILD_INTERP 1)
    set(WAMR_BUILD_FAST_INTERP 1)
    set(WAMR_BUILD_AOT 1)
    set(WAMR_BUILD_LIBC_BUILTIN 1)
    set(WAMR_BUILD_LIBC_WASI 1)
    set(WAMR_BUILD_SIMD 1)

    # Include WAMR build script
    include(${WAMR_ROOT_DIR}/build-scripts/runtime_lib.cmake)

    # Define the static library target for WAMR
    add_library(vmlib STATIC ${WAMR_RUNTIME_LIB_SOURCE})
    target_include_directories(vmlib PUBLIC ${WAMR_RUNTIME_LIB_INCLUDE_DIRS})

endif()

#-----------------------------------------------------------
# Target setup
#-----------------------------------------------------------
file(GLOB_RECURSE SRC CONFIGURE_DEPENDS
    src/*.c
    src/*.cpp
)

if(PLATFORM_IOS)
    add_executable(framebolt MACOSX_BUNDLE ${SRC})
elseif(PLATFORM_ANDROID)
    add_library(main SHARED ${SRC})
elseif(PLATFORM_MAC)
    add_executable(framebolt MACOSX_BUNDLE ${SRC})
else()
    add_executable(framebolt WIN32 ${SRC})
endif()

#-----------------------------------------------------------
# Linking rules
#-----------------------------------------------------------

# SDL3 static everywhere except Linux
if(PLATFORM_LINUX)
    target_link_libraries(framebolt PRIVATE SDL3::SDL3 SDL3_ttf::SDL3_ttf imgui)
elseif(PLATFORM_ANDROID)
    target_link_libraries(main PRIVATE SDL3::SDL3-static SDL3_ttf::SDL3_ttf imgui)
    target_compile_definitions(main PRIVATE SDL_STATIC)
elseif(PLATFORM_IOS)
    target_link_libraries(framebolt PRIVATE SDL3::SDL3-static SDL3_ttf::SDL3_ttf imgui)
else()
    target_link_libraries(framebolt PRIVATE SDL3::SDL3-static SDL3_ttf::SDL3_ttf imgui)
endif()

# GStreamer dynamic everywhere except iOS
if(PLATFORM_IOS)
    message(STATUS "Dynamic linking GStreamer .framework (iOS)")

    target_link_libraries(framebolt PRIVATE
        "${GSTREAMER_FRAMEWORK}/GStreamer"
        iconv
        z
        bz2
        resolv
    )
    # Include headers
    target_include_directories(framebolt PRIVATE
        "${GSTREAMER_FRAMEWORK}/Headers"
    )
elseif(PLATFORM_ANDROID)
    message(STATUS "Dynamic linking GStreamer")
    target_link_libraries(main PRIVATE ${GSTREAMER_LIBRARIES})
else()
    message(STATUS "Dynamic linking GStreamer")
    target_link_libraries(framebolt PRIVATE ${GSTREAMER_LIBRARIES})
endif()

# Link your app with the WAMR runtime
if(PLATFORM_ANDROID)
    target_link_libraries(main PRIVATE vmlib)
elseif(NOT PLATFORM_IOS)
    target_link_libraries(framebolt PRIVATE vmlib)
endif()

#-----------------------------------------------------------
# iOS-specific bundle properties
#-----------------------------------------------------------
if(PLATFORM_IOS)
    set_target_properties(framebolt PROPERTIES
        MACOSX_BUNDLE YES
        XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
        XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "-"
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/ios-project/Info.plist"
        XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon"
        RESOURCE "${CMAKE_CURRENT_SOURCE_DIR}/ios-project/LaunchScreen.storyboard"
    )
    target_sources(framebolt PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/ios-project/LaunchScreen.storyboard"
        "${CMAKE_CURRENT_SOURCE_DIR}/ios-project/Assets.xcassets"
    )
elseif(PLATFORM_MAC)
    set_target_properties(framebolt PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_SOURCE_DIR}/macos-project/Info.plist"
        RESOURCE "${CMAKE_SOURCE_DIR}/macos-project/Assets.xcassets"
    )
endif()

#-----------------------------------------------------------
# Diagnostics
#-----------------------------------------------------------
message(STATUS "GStreamer include dirs: ${GSTREAMER_INCLUDE_DIRS}")
message(STATUS "GStreamer library dirs: ${GSTREAMER_LIBRARY_DIRS}")
message(STATUS "GStreamer libs: ${GSTREAMER_LIBRARIES}")
