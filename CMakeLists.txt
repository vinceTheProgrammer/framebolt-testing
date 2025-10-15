cmake_minimum_required(VERSION 3.16)
project(framebolt)

# set the output directory for built objects.
# This makes sure that the dynamic library goes into the build directory automatically.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<CONFIGURATION>")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/$<CONFIGURATION>")

# This assumes the SDL source is available in vendored/SDL
add_subdirectory(vendored/SDL EXCLUDE_FROM_ALL)

# Use a shared library instead of an executable for Android
if(ANDROID OR IOS)
    add_library(main SHARED main.c)
else()
    add_executable(main WIN32 main.c)
endif()

# Link to the actual SDL3 library.
target_link_libraries(main PRIVATE SDL3::SDL3)
