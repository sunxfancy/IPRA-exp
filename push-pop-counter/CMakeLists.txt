cmake_minimum_required(VERSION 3.6)
project(ppcount)


find_package(DynamoRIO)
if (NOT DynamoRIO_FOUND)
  message(FATAL_ERROR "DynamoRIO package required to build")
endif(NOT DynamoRIO_FOUND)

add_library(ppcount SHARED main.cpp)
configure_DynamoRIO_client(ppcount)

use_DynamoRIO_extension(ppcount drmgr)
use_DynamoRIO_extension(ppcount drreg)
use_DynamoRIO_extension(ppcount drx)
use_DynamoRIO_extension(ppcount droption)
