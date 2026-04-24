cmake_minimum_required(VERSION 3.25)

set(APP_NAME barrel-explosion)

project(${APP_NAME} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

file(GLOB_RECURSE APP_SOURCES CONFIGURE_DEPENDS src/*.cpp)

add_executable(${APP_NAME} ${APP_SOURCES})

target_include_directories(${APP_NAME} PRIVATE src)

target_compile_options(${APP_NAME} PRIVATE
    $<$<CXX_COMPILER_ID:GNU,Clang>:-Wall -Wextra -Wpedantic>
    $<$<CXX_COMPILER_ID:MSVC>:/W4>
)
