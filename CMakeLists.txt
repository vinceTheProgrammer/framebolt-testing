cmake_minimum_required(VERSION 3.16)
project(framebolt)

# Set the output directory for built objects
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<CONFIGURATION>")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<CONFIGURATION>")

if(NOT ANDROID)
    set(SDL_SHARED OFF CACHE BOOL "Build shared SDL library" FORCE)
    set(SDL_STATIC ON CACHE BOOL "Build static SDL library" FORCE)
endif()

# Add SDL subdirectory
add_subdirectory(vendored/SDL EXCLUDE_FROM_ALL)

# Define the main target
if(IOS)
    add_executable(framebolt MACOSX_BUNDLE main.c)
elseif(ANDROID)
    add_library(main SHARED main.c)
else()
    add_executable(framebolt WIN32 main.c)
endif()

# Link to SDL3
target_link_libraries(framebolt PRIVATE SDL3::SDL3)

# iOS-specific bundle properties
if(IOS)
    set_target_properties(framebolt PROPERTIES
        MACOSX_BUNDLE YES
        XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2" # iPhone + iPad
        XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "-"
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/ios-project/Info.plist"
        XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon"
        RESOURCE "${CMAKE_CURRENT_SOURCE_DIR}/ios-project/LaunchScreen.storyboard"
    )
    # Add asset catalog and storyboard as sources
    target_sources(framebolt PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/ios-project/LaunchScreen.storyboard"
        "${CMAKE_CURRENT_SOURCE_DIR}/ios-project/Assets.xcassets"
    )
endif()
