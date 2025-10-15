cmake_minimum_required(VERSION 3.16)
project(vincepong_ios LANGUAGES C)

# Include your top-level build logic
include(${CMAKE_SOURCE_DIR}/CMakeLists.txt)

# Only proceed if this is an iOS build
if(IOS)
    # Change executable to shared lib called "main"
    set_target_properties(main PROPERTIES
        MACOSX_BUNDLE YES
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_SOURCE_DIR}/ios-project/Info.plist"
        XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon"
        RESOURCE "${CMAKE_SOURCE_DIR}/ios-project/LaunchScreen.storyboard"
    )

    # Copy the asset catalog so Xcode can bundle it
    target_sources(main PRIVATE
        "${CMAKE_SOURCE_DIR}/ios-project/LaunchScreen.storyboard"
    )
endif()
