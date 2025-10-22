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

# Use vendored builds for SDL3 and SDL_ttf
add_subdirectory(vendored/SDL EXCLUDE_FROM_ALL)
add_subdirectory(vendored/SDL_ttf EXCLUDE_FROM_ALL)

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
else()
    message(STATUS "Using bundled GStreamer SDK")

    # Auto-detect GStreamer root
    if(PLATFORM_WINDOWS)
        set(GSTREAMER_ROOT "C:/gstreamer/1.0/msvc_x86_64")
    elseif(PLATFORM_MAC)
        set(GSTREAMER_ROOT "/Library/Frameworks/GStreamer.framework/Versions/Current")
        if(NOT EXISTS "${GSTREAMER_ROOT}" AND EXISTS "${CMAKE_SOURCE_DIR}/gstreamer")
            set(GSTREAMER_ROOT "${CMAKE_SOURCE_DIR}/gstreamer")
        endif()
    elseif(PLATFORM_IOS)
        set(GSTREAMER_ROOT "${CMAKE_SOURCE_DIR}/gstreamer-ios")
    elseif(PLATFORM_ANDROID)
        set(GSTREAMER_ROOT "${CMAKE_SOURCE_DIR}/android-project/app/src/main/jni/gstreamer")
    endif()

    set(GSTREAMER_INCLUDE_DIRS
        "${GSTREAMER_ROOT}/include/gstreamer-1.0"
        "${GSTREAMER_ROOT}/include/glib-2.0"
        "${GSTREAMER_ROOT}/lib/glib-2.0/include"
    )

    if(PLATFORM_WINDOWS OR PLATFORM_MAC)
        set(GSTREAMER_LIBRARY_DIRS "${GSTREAMER_ROOT}/lib")
    elseif(PLATFORM_ANDROID)
        set(GSTREAMER_LIBRARY_DIRS "${GSTREAMER_ROOT}/arm64/lib")
    endif()
endif()

include_directories(${GSTREAMER_INCLUDE_DIRS})
link_directories(${GSTREAMER_LIBRARY_DIRS})

#-----------------------------------------------------------
# WebAssembly Micro Runtime (WAMR)
#-----------------------------------------------------------
set(WAMR_ROOT_DIR "${CMAKE_SOURCE_DIR}/external/wamr")

# Configure WAMR build features
# You can adjust these per-platform as needed
if(PLATFORM_LINUX)
    set(WAMR_BUILD_PLATFORM "linux")
elseif(PLATFORM_WINDOWS)
    set(WAMR_BUILD_PLATFORM "windows")
elseif(PLATFORM_MAC)
    set(WAMR_BUILD_PLATFORM "darwin")
elseif(PLATFORM_ANDROID)
    set(WAMR_BUILD_PLATFORM "android")
elseif(PLATFORM_IOS)
    set(WAMR_BUILD_PLATFORM "darwin") # iOS uses Darwin platform too
endif()

set(WAMR_BUILD_TARGET "X86_64")        # or "AARCH64" on ARM64 devices
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

#-----------------------------------------------------------
# Target setup
#-----------------------------------------------------------
file(GLOB SRC src/*.c src/*.cpp)

if(PLATFORM_IOS)
    add_executable(framebolt MACOSX_BUNDLE ${SRC})
elseif(PLATFORM_ANDROID)
    add_library(main SHARED ${SRC})
else()
    add_executable(framebolt WIN32 ${SRC})
endif()

#-----------------------------------------------------------
# Linking rules
#-----------------------------------------------------------

# SDL3 static everywhere except Linux
if(PLATFORM_LINUX)
    target_link_libraries(framebolt PRIVATE SDL3::SDL3 SDL3_ttf::SDL3_ttf)
else()
    target_link_libraries(framebolt PRIVATE SDL3::SDL3-static SDL3_ttf::SDL3_ttf)
endif()

# GStreamer dynamic everywhere except iOS
if(PLATFORM_IOS)
    message(STATUS "Static linking GStreamer on iOS")
    target_link_libraries(framebolt PRIVATE
        ${GSTREAMER_LIBRARY_DIRS}/libgstreamer-1.0.a
        ${GSTREAMER_LIBRARY_DIRS}/libgstbase-1.0.a
        ${GSTREAMER_LIBRARY_DIRS}/libgobject-2.0.a
        ${GSTREAMER_LIBRARY_DIRS}/libglib-2.0.a
    )
else()
    message(STATUS "Dynamic linking GStreamer")
    target_link_libraries(framebolt PRIVATE ${GSTREAMER_LIBRARIES})
endif()

# Link your app with the WAMR runtime
target_link_libraries(framebolt PRIVATE vmlib)

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
endif()

#-----------------------------------------------------------
# Diagnostics
#-----------------------------------------------------------
message(STATUS "GStreamer include dirs: ${GSTREAMER_INCLUDE_DIRS}")
message(STATUS "GStreamer library dirs: ${GSTREAMER_LIBRARY_DIRS}")
message(STATUS "GStreamer libs: ${GSTREAMER_LIBRARIES}")
