# Copyright (c) Alpaca Core
# SPDX-License-Identifier: MIT
#
cmake_minimum_required(VERSION 3.22 FATAL_ERROR)

# standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_C_STANDARD_REQUIRED ON)

# misc config
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_LINK_DEPENDS_NO_SHARED ON) # only relink exe if so interface changes
set_property(GLOBAL PROPERTY USE_FOLDERS ON) # use solution folders
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin) # binaries to bin
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin) # modules to bin

# add cmake modules
include(./cmake/ac_dep.cmake)

project(demo-ios-ai-chat
    LANGUAGES CXX Swift
)

######################
# subdirs

set(AC_COCOA_WRAPPER ON)
set(AC_SWIFT_WRAPPER ON)
set(BUILD_SHARED_LIBS OFF)

add_subdirectory(ac-local)

if(CMAKE_GENERATOR STREQUAL Xcode)
    # The demo is only for Xcode since we set specific flags for it
    add_subdirectory(demo-ai-chat)
endif()

