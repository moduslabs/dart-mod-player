cmake_minimum_required(VERSION 3.17 FATAL_ERROR)
project(openmpt_library VERSION 1.0.0)


SET(CMAKE_CXX_STANDARD 17)
SET(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -Wno-implicit-exception-spec-mismatch")
SET(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -Wno-implicit-exception-spec-mismatch")

include(ProcessorCount)
ProcessorCount(N)
if (NOT N EQUAL 0)
  set(${PROJECT_NAME}_FLAGS -j${N})
  set(${PROJECT_NAME}_BUILD_FLAGS -j${N})
  set(${PROJECT_NAME}_args ${${PROJECT_NAME}_args} PARALLEL_LEVEL ${N})
endif ()

file(GLOB MY_SOURCES ${CMAKE_SOURCE_DIR}/src/*.cpp)
include_directories(${CMAKE_SOURCE_DIR}/src)
add_library(openmpt_library SHARED ${MY_SOURCES} OpenMPT.def)
add_executable(OpenMPT-test ${MY_SOURCES})


## libopenmpt
set(OPENMPT_LIB_DIR "${CMAKE_SOURCE_DIR}/../cpp-lib/libopenmpt")
set(OPENMPT_SOURCE_DIR "${CMAKE_SOURCE_DIR}/../cpp-lib-sources/open-mpt")

message("OPENMPT_SOURCE_DIR = ${OPENMPT_SOURCE_DIR}")
include_directories(${OPENMPT_SOURCE_DIR}/libopenmpt/)
file(GLOB OPENMPT_LIBRARIES "${OPENMPT_LIB_DIR}/*.dylib")
message("OPENMPT_LIBRARIES = ${OPENMPT_LIBRARIES}")
target_link_libraries(OpenMPT-test ${OPENMPT_LIBRARIES})
target_link_libraries(openmpt_library ${OPENMPT_LIBRARIES})

## libportaudio
set(TEST_PROGRAM_NAME OpenMPT-test)
set(PORTAUDIO_LIB_DIR "${CMAKE_SOURCE_DIR}/../cpp-lib/libportaudio")
set(PORTAUDIO_SOURCE_DIR "${CMAKE_SOURCE_DIR}/../cpp-lib-sources/portaudio")
message("PORTAUDIO_SOURCE_DIR = ${PORTAUDIO_SOURCE_DIR}")
include_directories(${PORTAUDIO_SOURCE_DIR}/include)
file(GLOB PORTAUDIO_LIBRARIES "${PORTAUDIO_LIB_DIR}/*.dylib")
message("PORTAUDIO_LIBRARIES = ${PORTAUDIO_LIBRARIES}")
target_link_libraries(${TEST_PROGRAM_NAME} ${PORTAUDIO_LIBRARIES})
target_link_libraries(openmpt_library ${PORTAUDIO_LIBRARIES})


set_target_properties(openmpt_library PROPERTIES
    PUBLIC_HEADER OpenMpt.h
    VERSION ${PROJECT_VERSION}
    SOVERSION 1
    OUTPUT_NAME "OpenMPT"
    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "Hex_Identity_ID_Goes_Here"
)



add_custom_command(
    TARGET ${TEST_PROGRAM_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy
    ${CMAKE_SOURCE_DIR}/songs/*.xm
    ${CMAKE_CURRENT_BINARY_DIR}/
)

