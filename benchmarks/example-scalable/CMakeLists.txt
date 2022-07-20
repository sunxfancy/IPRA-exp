cmake_minimum_required(VERSION 3.15)
project(example)

add_library(report STATIC test.c)
add_executable(example main.c)

target_link_libraries(example report)
