cmake_minimum_required(VERSION 3.20)
project(f2c_package_smoke LANGUAGES C)

find_package(f2c CONFIG REQUIRED)

add_executable(package_smoke main.c)
target_link_libraries(package_smoke PRIVATE f2c::f2c_runtime)
