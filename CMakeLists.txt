# Copyright (c) Alpaca Core
# SPDX-License-Identifier: MIT
#
cmake_minimum_required(VERSION 3.22 FATAL_ERROR)

# misc config
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_LINK_DEPENDS_NO_SHARED ON) # only relink exe if so interface changes
set_property(GLOBAL PROPERTY USE_FOLDERS ON) # use solution folders
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin) # binaries to bin
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin) # modules to bin

project(poc-ios-dm
    LANGUAGES CXX Swift
)

######################
# subdirs

add_subdirectory(ac-local)
add_subdirectory(demo-llama-chat)

