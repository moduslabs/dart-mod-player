cmake_minimum_required(VERSION 3.16 FATAL_ERROR)
project(dartopenmpt VERSION 1.0.0)
set(TEST_PROGRAM_NAME openmpt-test)

find_package(PkgConfig REQUIRED)

# There HAS to be a better way to do this :(
set(SO_SUFFIX "so")
if (APPLE)
  set(SO_SUFFIX "dylib")
endif (APPLE)


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
add_library(dartopenmpt SHARED ${MY_SOURCES} OpenMPT.def)
add_executable(openmpt-test ${MY_SOURCES})


## libopenmpt
message("--- OpenMPT -----")
set(OPENMPT_PKG_DIR "${CMAKE_SOURCE_DIR}/../lib/libopenmpt/lib/pkgconfig")
set(ENV{PKG_CONFIG_PATH} "$ENV{PKG_CONFIG_PATH};${OPENMPT_PKG_DIR}")
message("ENV{PKG_CONFIG_PATH} = $ENV{PKG_CONFIG_PATH}")
pkg_search_module(LIBOPENMPT REQUIRED libopenmpt)


message("LIBOPENMPT_INCLUDE_DIRS = ${LIBOPENMPT_INCLUDE_DIRS}")
message("LIBOPENMPT_LIBRARY_DIRS = ${LIBOPENMPT_LIBRARY_DIRS}")
message("LIBOPENMPT_LDFLAGS = ${LIBOPENMPT_LDFLAGS}")

include_directories(${LIBOPENMPT_INCLUDE_DIRS}/libopenmpt)

target_link_libraries(openmpt-test "${LIBOPENMPT_LIBRARY_DIRS}/libopenmpt.${SO_SUFFIX}")
target_link_libraries(dartopenmpt "${LIBOPENMPT_LIBRARY_DIRS}/libopenmpt.${SO_SUFFIX}")

message("")

## libportaudio
message("--- PortAudio2 -----")
set(PORTAUDIO_PKG_DIR "${CMAKE_SOURCE_DIR}/../lib/libportaudio/lib/pkgconfig")
set(ENV{PKG_CONFIG_PATH} "$ENV{PKG_CONFIG_PATH};${PORTAUDIO_PKG_DIR}")
message("ENV{PKG_CONFIG_PATH} = $ENV{PKG_CONFIG_PATH}")

pkg_search_module(PORTAUDIO REQUIRED portaudio-2.0)

message("PORTAUDIO_INCLUDE_DIRS = ${PORTAUDIO_INCLUDE_DIRS}")
message("PORTAUDIO_LDFLAGS = ${PORTAUDIO_LDFLAGS}")
message("PORTAUDIO_LIBRARY_DIRS = ${PORTAUDIO_LIBRARY_DIRS}")

include_directories(${PORTAUDIO_INCLUDE_DIRS})
target_link_libraries(openmpt-test "${PORTAUDIO_LIBRARY_DIRS}/libportaudio.${SO_SUFFIX}")
target_link_libraries(dartopenmpt "${PORTAUDIO_LIBRARY_DIRS}/libportaudio.${SO_SUFFIX}")

set_target_properties(${PROJECT} PROPERTIES
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

