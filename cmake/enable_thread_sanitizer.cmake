#source: https://github.com/gabime/spdlog/blob/v1.x/cmake/utils.cmake

# Enable thread sanitizer (gcc/clang only)
function(enable_thread_sanitizer target_name)
    if(NOT CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        message(FATAL_ERROR "Sanitizer supported only for gcc/clang")
    endif()
    message(STATUS "Thread sanitizer enabled")
    target_compile_options(${target_name} PRIVATE -fsanitize=thread)
    target_compile_options(${target_name} PRIVATE -fno-omit-frame-pointer)
    target_link_libraries(${target_name} PRIVATE -fsanitize=thread)
endfunction()