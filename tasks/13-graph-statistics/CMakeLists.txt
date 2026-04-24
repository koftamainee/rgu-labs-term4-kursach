cmake_minimum_required(VERSION 3.20)
project(graph)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(spdlog)

file(GLOB_RECURSE SRC_FILES CONFIGURE_DEPENDS
        ${CMAKE_SOURCE_DIR}/src/*.cpp
)

add_executable(graph ${SRC_FILES})

target_include_directories(graph PRIVATE
        ${CMAKE_SOURCE_DIR}/src
)

target_link_libraries(graph PRIVATE spdlog::spdlog)