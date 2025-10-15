cmake_minimum_required(VERSION 3.16)

# Only apply iOS-specific settings if building for iOS
if(IOS)
    set_target_properties(main PROPERTIES
        MACOSX_BUNDLE YES
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist"
        XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon"
        RESOURCE "${CMAKE_CURRENT_SOURCE_DIR}/LaunchScreen.storyboard"
    )

    # Add asset catalog and storyboard as sources
    target_sources(main PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/LaunchScreen.storyboard"
        "${CMAKE_CURRENT_SOURCE_DIR}/Assets.xcassets"
    )
endif()