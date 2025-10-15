cmake_minimum_required(VERSION 3.16)
project(framebolt)

# Set the output directory for built objects
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<CONFIGURATION>")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<CONFIGURATION>")

# Add SDL subdirectory
add_subdirectory(vendored/SDL EXCLUDE_FROM_ALL)

# Define the main target
if(IOS)
    add_executable(framebolt MACOSX_BUNDLE main.c)
elseif(ANDROID)
    add_library(framebolt SHARED main.c)
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
    )
    add_subdirectory(ios-project)
endif()