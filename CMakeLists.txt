cmake_minimum_required(VERSION 3.16)

set(PROJECT_NAME app)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Helpful for compile_commands.json consumers
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ESP-IDF build system (provided by the container via $IDF_PATH)
include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(${PROJECT_NAME})
