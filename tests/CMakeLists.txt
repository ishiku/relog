cmake_minimum_required(VERSION 3.14)
project(relog-tests)

#----------------------------------------------------------------------------------------------------------------------
# general settings and options
#----------------------------------------------------------------------------------------------------------------------

include("../cmake/win_copy_deps_to_target_dir.cmake")
string(COMPARE EQUAL "${CMAKE_SOURCE_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}" PROJECT_IS_TOP_LEVEL)

if(PROJECT_IS_TOP_LEVEL)
    enable_testing()
endif()

#----------------------------------------------------------------------------------------------------------------------
# testing framework
#----------------------------------------------------------------------------------------------------------------------

include(FetchContent)
FetchContent_Declare(googletest 
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG v1.16.0)

set(gtest_force_shared_crt ON CACHE BOOL "" FORCE) # do not override parent project's runtime settings on Windows
set(INSTALL_GTEST OFF)

# For simplicity, always build googletest as static library. This prevents relog-tests executable from
# complaining about missing googletest DLLs on Windows.
set(BUILD_SHARED_LIBS OFF)

FetchContent_MakeAvailable(googletest)

#----------------------------------------------------------------------------------------------------------------------
# tests dependencies
#----------------------------------------------------------------------------------------------------------------------

if(PROJECT_IS_TOP_LEVEL)
    find_package(relog REQUIRED)
endif()

#----------------------------------------------------------------------------------------------------------------------
# tests sources
#----------------------------------------------------------------------------------------------------------------------

set(sources
    dummy_test.cpp)
source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}" FILES ${sources})

#----------------------------------------------------------------------------------------------------------------------
# tests target
#----------------------------------------------------------------------------------------------------------------------

add_executable(relog-tests)
target_sources(relog-tests PRIVATE ${sources})

target_link_libraries(relog-tests
    PRIVATE
        relog::relog
        gtest_main)

if(NOT PROJECT_IS_TOP_LEVEL)
    win_copy_deps_to_target_dir(relog-tests relog::relog)
endif()

include(GoogleTest)
gtest_discover_tests(relog-tests)