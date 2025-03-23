cmake_minimum_required(VERSION 3.28)
project(relog-basic LANGUAGES CXX)

include("../../cmake/win_copy_deps_to_target_dir.cmake")

if(PROJECT_IS_TOP_LEVEL)
    find_package(relog REQUIRED)
endif()

set(sources main.cpp)
source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}" FILES ${sources})

add_executable(relog-basic)
target_sources(relog-basic PRIVATE ${sources})
target_link_libraries(relog-basic PRIVATE relog::relog)

if(NOT PROJECT_IS_TOP_LEVEL)
    win_copy_deps_to_target_dir(relog-basic relog::relog)
endif()