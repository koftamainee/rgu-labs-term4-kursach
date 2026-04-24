cmake_minimum_required(VERSION 3.25)

set(APP_NAME random-walk-2d)

project(${APP_NAME} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Concurrent)
qt_standard_project_setup()

set(TARGET_DIR ${CMAKE_BINARY_DIR}/target)

file(GLOB_RECURSE APP_SOURCES CONFIGURE_DEPENDS src/*.cpp)

qt_add_executable(${APP_NAME} ${APP_SOURCES})

target_include_directories(${APP_NAME} PRIVATE src)

target_link_libraries(${APP_NAME} PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Concurrent
)

target_compile_options(${APP_NAME} PRIVATE
    $<$<CXX_COMPILER_ID:GNU,Clang>:-Wall -Wextra -Wpedantic>
    $<$<CXX_COMPILER_ID:MSVC>:/W4>
)

set_target_properties(${APP_NAME} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${TARGET_DIR}
)

file(GLOB_RECURSE QML_FILES CONFIGURE_DEPENDS qml/*)

foreach(QML_FILE ${QML_FILES})
    file(RELATIVE_PATH REL_PATH ${CMAKE_SOURCE_DIR}/qml ${QML_FILE})
    add_custom_command(TARGET ${APP_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${QML_FILE}
            ${TARGET_DIR}/qml/${REL_PATH}
        COMMENT "Copying ${REL_PATH}"
    )
endforeach()
