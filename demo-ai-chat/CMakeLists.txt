# Copyright (c) Alpaca Core
# SPDX-License-Identifier: MIT
#
cmake_minimum_required(VERSION 3.22 FATAL_ERROR)

set(APP_NAME "demo-llama-chat")
set(APP_BUNDLE_IDENTIFIER "LLamaChat")
set(DEVELOPMENT_TEAM_ID "F6YK5TUHJ7")
set(CODE_SIGN_IDENTITY "Apple Development")
set(APP_BUNDLE_DISPLAY_NAME "LLama chat")
set(DEPLOYMENT_TARGET 16.6)

set(PRODUCT_NAME ${APP_NAME})
set(EXECUTABLE_NAME ${APP_NAME})

set(MACOSX_BUNDLE_EXECUTABLE_NAME ${APP_NAME})
set(MACOSX_BUNDLE_INFO_STRING ${APP_BUNDLE_IDENTIFIER})
set(MACOSX_BUNDLE_GUI_IDENTIFIER ${APP_BUNDLE_IDENTIFIER})
set(MACOSX_BUNDLE_BUNDLE_NAME ${APP_BUNDLE_IDENTIFIER})

set(MACOSX_FRAMEWORK_BUNDLE_VERSION 1.0.0)
set(MACOSX_FRAMEWORK_SHORT_VERSION_STRING 1.0.0)
set(MACOSX_FRAMEWORK_IDENTIFIER ${APP_BUNDLE_IDENTIFIER})

set(APP_HEADER_FILES
)

set(APP_SOURCE_FILES
    ./LlamaChatApp.swift
    ./DownloadManager.swift
    ./ModelRegistry.swift
    ./ChatInference.swift
    ./ModelSelectorView.swift
    ./TypingIndicatorView.swift
    ./ChatScreenView.swift
)

ac_dep(test-data-llama)

set(RESOURCES
    ${ac-test-data-llama_SOURCE_DIR}/gpt2-117m-q6_k.gguf
)

add_executable(
    ${APP_NAME}
    MACOSX_BUNDLE
    ${APP_HEADER_FILES}
    ${APP_SOURCE_FILES}
    ${RESOURCES}
)

target_compile_options(${APP_NAME}
PUBLIC
  $<$<COMPILE_LANGUAGE:Swift>:-cxx-interoperability-mode=default -Xcc -std=c++20 -Onone>
)

if(CMAKE_GENERATOR STREQUAL Xcode)
target_include_directories(${APP_NAME}
    PRIVATE
        "${CMAKE_BINARY_DIR}/ac-local/wrapper/swift/code/CxxAlpacaCore/Debug$(EFFECTIVE_PLATFORM_NAME)"
)
endif()

# From the Root CMAKE there are C++ compile options which conflict with Swift compiler
# so we clear them here
# set_target_properties(${APP_NAME} PROPERTIES COMPILE_OPTIONS "")

# Link the AlpacaCore's Swift wrapper
target_link_libraries(${APP_NAME}
    PRIVATE
        AlpacaCoreSwift
)

# Create the app target
set_target_properties(${APP_NAME} PROPERTIES
                      XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT "dwarf-with-dsym"
                      RESOURCE "${RESOURCES}"
                      XCODE_ATTRIBUTE_GCC_PRECOMPILE_PREFIX_HEADER "YES"
                      XCODE_ATTRIBUTE_CODE_SIGN_STYLE “Automatic”
                      XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET ${DEPLOYMENT_TARGET}
                      XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY ${CODE_SIGN_IDENTITY}
                      XCODE_ATTRIBUTE_DEVELOPMENT_TEAM ${DEVELOPMENT_TEAM_ID}
                      XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
                      MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/app.plist.in"
                      XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC YES
                      XCODE_ATTRIBUTE_COMBINE_HIDPI_IMAGES NO
                      XCODE_ATTRIBUTE_INSTALL_PATH "$(LOCAL_APPS_DIR)"
                      XCODE_ATTRIBUTE_ENABLE_TESTABILITY YES
                      XCODE_ATTRIBUTE_GCC_SYMBOLS_PRIVATE_EXTERN YES
                      XCODE_ATTRIBUTE_SWIFT_OPTIMIZATION_LEVEL "-Onone"  # Set optimization level for Swift
)
