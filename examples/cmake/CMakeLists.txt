cmake_minimum_required(VERSION 3.20)
project(f2c_cmake_example LANGUAGES C)

include(CTest)

find_package(f2c CONFIG REQUIRED)

foreach(required_variable IN ITEMS F2C_VERSION_STRING F2C_UPSTREAM_VERSION)
  if(NOT DEFINED ${required_variable} OR "${${required_variable}}" STREQUAL "")
    message(FATAL_ERROR
      "The installed package does not define ${required_variable}")
  endif()
endforeach()

# Package compatibility remains based on this repository's release version,
# not the upstream translator date.
find_package(f2c "${F2C_VERSION_STRING}" EXACT CONFIG REQUIRED)

foreach(required_target IN ITEMS f2c::f2c f2c::f2c_runtime)
  if(NOT TARGET "${required_target}")
    message(FATAL_ERROR "The installed package does not provide ${required_target}")
  endif()
endforeach()

if(DEFINED F2C_EXPECTED_PREFIX AND NOT F2C_EXPECTED_PREFIX STREQUAL "")
  include("${CMAKE_CURRENT_SOURCE_DIR}/VerifyResolvedPrefix.cmake")
  f2c_verify_resolved_prefix("${F2C_EXPECTED_PREFIX}")
endif()

if(UNIX)
  get_target_property(runtime_link_libraries
    f2c::f2c_runtime INTERFACE_LINK_LIBRARIES)
  if(NOT "m" IN_LIST runtime_link_libraries)
    message(FATAL_ERROR
      "f2c::f2c_runtime does not propagate the platform math library")
  endif()
endif()

set(F2C_GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")

function(f2c_translate output_variable source_file)
  get_filename_component(source_name "${source_file}" NAME)
  get_filename_component(source_stem "${source_file}" NAME_WE)
  set(work_dir "${F2C_GENERATED_DIR}/${source_stem}")
  set(staged_source "${work_dir}/${source_name}")
  set(generated_source "${work_dir}/${source_stem}.c")

  add_custom_command(
    OUTPUT "${generated_source}"
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${work_dir}"
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "${source_file}" "${staged_source}"
    COMMAND "${CMAKE_COMMAND}" -E chdir "${work_dir}"
            "$<TARGET_FILE:f2c::f2c>" "${source_name}"
    DEPENDS "${source_file}" f2c::f2c
    COMMENT "Translating ${source_name} with f2c"
    VERBATIM)

  set("${output_variable}" "${generated_source}" PARENT_SCOPE)
endfunction()

f2c_translate(main_c "${CMAKE_CURRENT_SOURCE_DIR}/main.f")
f2c_translate(hypotenuse_c "${CMAKE_CURRENT_SOURCE_DIR}/hypotenuse.f")

add_executable(f2c_cmake_example "${main_c}" "${hypotenuse_c}")
target_link_libraries(f2c_cmake_example PRIVATE f2c::f2c_runtime)

add_test(
  NAME f2c_cmake_example.run
  COMMAND "${CMAKE_COMMAND}"
    "-DPROGRAM=$<TARGET_FILE:f2c_cmake_example>"
    -P "${CMAKE_CURRENT_SOURCE_DIR}/RunAndCompare.cmake")
set_tests_properties(f2c_cmake_example.run PROPERTIES
  ENVIRONMENT "LC_ALL=C;TZ=UTC"
  TIMEOUT 10)

add_test(
  NAME f2c_cmake_example.package_versions
  COMMAND "${CMAKE_COMMAND}"
    "-DF2C_PROGRAM=$<TARGET_FILE:f2c::f2c>"
    "-DEXPECTED_UPSTREAM_VERSION=${F2C_UPSTREAM_VERSION}"
    -P "${CMAKE_CURRENT_SOURCE_DIR}/VerifyPackageVersions.cmake")
set_tests_properties(f2c_cmake_example.package_versions PROPERTIES
  ENVIRONMENT "LC_ALL=C;TZ=UTC"
  TIMEOUT 10)
