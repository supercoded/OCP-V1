cmake_minimum_required(VERSION 3.15)
project(ocp_v1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Application name
set(APPLICATION_ID "io.ocp.v1")
set(APPLICATION_NAME "OCP-V1")

# Flutter-specific paths
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")

# Build configuration
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(INSTALL_BUNDLE_DIR "${CMAKE_INSTALL_PREFIX}/${APPLICATION_ID}")
else()
  set(INSTALL_BUNDLE_DIR "${CMAKE_INSTALL_PREFIX}/${APPLICATION_ID}")
endif()

# Find Flutter libraries
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK3 REQUIRED gtk+-3.0)

# Flutter engine and Dart VM
add_executable(${APPLICATION_NAME}
  "main.cc"
  "my_application.cc"
)

apply_default_settings(${APPLICATION_NAME})

target_compile_definitions(${APPLICATION_NAME} PRIVATE
  "APPLICATION_ID=\"${APPLICATION_ID}\""
  "NDEBUG"
)

target_include_directories(${APPLICATION_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}"
)

target_link_libraries(${APPLICATION_NAME} PRIVATE
  PkgConfig::GTK3
)

# Flutter plugin registration
add_subdirectory("${FLUTTER_MANAGED_DIR}" "${CMAKE_BINARY_DIR}/flutter")

# Install
install(TARGETS ${APPLICATION_NAME} RUNTIME DESTINATION "${INSTALL_BUNDLE_DIR}")