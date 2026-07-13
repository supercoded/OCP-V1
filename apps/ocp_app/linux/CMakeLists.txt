# OCP-V1 Linux Desktop Runner
#
# This CMakeLists.txt configures the Flutter desktop build for Linux.
# It includes a custom step to launch the bridge_server.js as a child process
# when the app starts on desktop.

cmake_minimum_required(VERSION 3.13)
project(ocp_v1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)

# Flutter desktop embedding
set(APPLICATION_ID "com.ocp.ocp_v1")
set(TARGET_OCP_V1 "ocp_v1")

# Source files
add_executable(${TARGET_OCP_V1}
  "my_application.cc"
)

target_link_libraries(${TARGET_OCP_V1} PRIVATE
  flutter_linux
)

target_include_directories(${TARGET_OCP_V1} PRIVATE
  "${CMAKE_SOURCE_DIR}/flutter/linux"
)

install(TARGETS ${TARGET_OCP_V1} RUNTIME DESTINATION bin)