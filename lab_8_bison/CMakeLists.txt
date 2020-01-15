cmake_minimum_required(VERSION 3.8)

project(cpn_calculator)

set(CMAKE_C_STANDARD 11)

SET(CMAKE_C_FLAGS "-m64 -g -O0 -D_DEBUG -Wall")

set(SOURCE_FILES
        src/calc.c
        ${CMAKE_CURRENT_BINARY_DIR}/scanner.c
        ${CMAKE_CURRENT_BINARY_DIR}/parser.c
)

include_directories(AFTER src ${CMAKE_CURRENT_BINARY_DIR})

find_package(BISON)
find_package(FLEX)

FLEX_TARGET(scanner src/calc.l ${CMAKE_CURRENT_BINARY_DIR}/scanner.c)
BISON_TARGET(parser src/calc.y ${CMAKE_CURRENT_BINARY_DIR}/parser.c VERBOSE)

ADD_FLEX_BISON_DEPENDENCY(scanner parser)

add_executable(
        calc
        ${SOURCE_FILES}
        ${BISON_parser_OUTPUTS}
        ${FLEX_scanner_OUTPUTS}
)