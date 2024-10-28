# dem-ios-llama-chat

iOS AI chat demo of the [Alpaca Core Local SDK](https://github.com/alpaca-core/ac-local)

## Requirements

To build the project you'll need:
- Xcode support for iOS platform

## Build

To generate the Xcode project run the following commands:

```
mkdir out
cd out
cmake ../ -DCMAKE_OSX_ARCHITECTURES="arm64" -DCMAKE_TOOLCHAIN_FILE=./toolchains/iOS.cmake -DCMAKE_OSX_SYSROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk -DBUILD_SHARED_LIBS=OFF -G Xcode
```

- CMAKE_TOOLCHAIN_FILE - setups environment variables for the iOS
- CMAKE_OSX_SYSROOT - sets the correct SDK path
- BUILD_SHARED_LIBS - controls what kind of libraries should be build. For iOS we need static libraries, so we need to turn off the option

## License

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

This software is distributed under the MIT Software License. See accompanying file LICENSE or copy [here](https://opensource.org/licenses/MIT).

Copyright &copy; 2024 [Alpaca Core, Inc](https://github.com/alpaca-core)
