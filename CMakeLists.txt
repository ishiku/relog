cmake_minimum_required(VERSION 3.28)

project(relog
    DESCRIPTION "Training project. The goal is to recreate spdlog from screatch."
    LANGUAGES CXX)

include(cmake/get_version_from_git.cmake)
get_version_from_git()
    
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

#----------------------------------------------------------------------------------------------------------------------
# general settings and options
#----------------------------------------------------------------------------------------------------------------------

include(cmake/set_if_undefined.cmake)
include(GNUInstallDirs)

option(RELOG_BUILD_TESTS "Build relog tests" OFF)
option(RELOG_BUILD_EXAMPLES "Build relog examples" OFF)
option(RELOG_BUILD_DOCS "Build relog documentation" OFF)
option(RELOG_TIDY "run clang-tidy" OFF)
option(RELOG_SANITIZE_ADDRESS "Enable address sanitizer in tests" OFF)
option(RELOG_SANITIZE_THREAD "Enable thread sanitizer in tests" OFF)

option(RELOG_INSTALL "Generate target for installing relog" ${PROJECT_IS_TOP_LEVEL})
set_if_undefined(RELOG_INSTALL_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake/relog" CACHE STRING
    "Install path for relog package-related CMake files")

if(DEFINED RELOG_SHARED_LIBS)
set(BUILD_SHARED_LIBS ${RELOG_SHARED_LIBS})
endif()

if(NOT DEFINED CMAKE_BUILD_TYPE AND NOT DEFINED CMAKE_CONFIGURATION_TYPES)
set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

set_if_undefined(CMAKE_CXX_VISIBILITY_PRESET hidden)
set_if_undefined(CMAKE_VISIBILITY_INLINES_HIDDEN ON)

add_library(relog)
add_library(relog::relog ALIAS relog)

#----------------------------------------------------------------------------------------------------------------------
# relog dependencies
#----------------------------------------------------------------------------------------------------------------------

#----------------------------------------------------------------------------------------------------------------------
# relog sources
#----------------------------------------------------------------------------------------------------------------------

include(GenerateExportHeader)
set(export_file_name "export_shared.h")

if(NOT BUILD_SHARED_LIBS)
    set(export_file_name "export_static.h")
endif()

generate_export_header(relog EXPORT_FILE_NAME include/relog/${export_file_name})

configure_file(
    ${CMAKE_SOURCE_DIR}/cmake/version.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/include/relog/version.h
)
message(STATUS "PROJECT_VERSION: ${PROJECT_VERSION}")

set(sources
    include/relog/export.h
    include/relog/relog.h
    include/relog/version.h
    src/relog.cpp)
source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}" FILES ${sources})

#----------------------------------------------------------------------------------------------------------------------
# relog target
#----------------------------------------------------------------------------------------------------------------------

include(CMakePackageConfigHelpers)

target_sources(relog PRIVATE ${sources})
target_compile_definitions(relog PUBLIC "$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:RELOG_STATIC_DEFINE>")

target_include_directories(relog
    PUBLIC
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>")

set_target_properties(relog PROPERTIES
        SOVERSION ${PROJECT_VERSION_MAJOR}
        VERSION ${PROJECT_VERSION})

        if(RELOG_INSTALL AND NOT CMAKE_SKIP_INSTALL_RULES)
        configure_package_config_file(cmake/relog-config.cmake.in relog-config.cmake
            INSTALL_DESTINATION "${RELOG_INSTALL_CMAKEDIR}")
    
        write_basic_package_version_file(relog-config-version.cmake
            COMPATIBILITY SameMajorVersion)
    
        install(TARGETS relog EXPORT relog_export
            RUNTIME COMPONENT relog
            LIBRARY COMPONENT relog NAMELINK_COMPONENT relog-dev
            ARCHIVE COMPONENT relog-dev
            INCLUDES DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")
        install(DIRECTORY include/
            TYPE INCLUDE
            COMPONENT relog-dev)
        install(FILES "${CMAKE_CURRENT_BINARY_DIR}/include/relog/${export_file_name}"
            COMPONENT relog-dev
            DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/relog")
    
        set(targets_file "relog-shared-targets.cmake")
    
        if(NOT BUILD_SHARED_LIBS)
            set(targets_file "relog-static-targets.cmake")
        endif()
    
        install(EXPORT relog_export
            COMPONENT relog-dev
            FILE "${targets_file}"
            DESTINATION "${RELOG_INSTALL_CMAKEDIR}"
            NAMESPACE relog::)
    
        install(FILES
            "${CMAKE_CURRENT_BINARY_DIR}/relog-config.cmake"
            "${CMAKE_CURRENT_BINARY_DIR}/relog-config-version.cmake"
            COMPONENT relog-dev
            DESTINATION "${RELOG_INSTALL_CMAKEDIR}")
    
        if(MSVC)
            set(pdb_file "")
            set(pdb_file_destination "")
    
            if(BUILD_SHARED_LIBS)
                set(pdb_file "$<TARGET_PDB_FILE:relog>")
                set(pdb_file_destination "${CMAKE_INSTALL_BINDIR}")
            else()
                # TARGET_PDB_FILE does not work for pdb file generated for static library build, determining it manually
                set(pdb_file "$<TARGET_FILE_DIR:relog>/$<TARGET_FILE_PREFIX:relog>$<TARGET_FILE_BASE_NAME:relog>.pdb")
                set(pdb_file_destination "${CMAKE_INSTALL_LIBDIR}")
            endif()
    
            install(FILES "${pdb_file}"
                COMPONENT relog-dev
                CONFIGURATIONS Debug RelWithDebInfo
                DESTINATION "${pdb_file_destination}"
                OPTIONAL)
        endif()
    endif()


#----------------------------------------------------------------------------------------------------------------------
# other targets
#----------------------------------------------------------------------------------------------------------------------
if(RELOG_TIDY)
    set(CMAKE_CXX_CLANG_TIDY "clang-tidy")
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
    message(STATUS "Enabled clang-tidy")
endif()

if (TPLOG_SANITIZE_ADDRESS AND TPLOG_SANITIZE_THREAD)
    message(FATAL_ERROR "TPLOG_SANITIZE_ADDRESS and TPLOG_SANITIZE_THREAD are mutually exclusive")
endif ()

if(RELOG_BUILD_TESTS)
    if (RELOG_SANITIZE_ADDRESS)
        enable_addr_sanitizer(relog)
    elseif (RELOG_SANITIZE_THREAD)
        enable_thread_sanitizer(relog)
    endif ()

    enable_testing()
    add_subdirectory(tests)
endif()

if(RELOG_BUILD_EXAMPLES)
add_subdirectory(examples)
endif()

if(RELOG_BUILD_DOCS)
find_package(Doxygen REQUIRED)
doxygen_add_docs(docs include)
endif()