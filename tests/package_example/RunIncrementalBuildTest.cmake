foreach(required_variable IN ITEMS EXAMPLE_SOURCE_DIR F2C_PREFIX TEST_ROOT)
  if(NOT DEFINED "${required_variable}")
    message(FATAL_ERROR "${required_variable} is required")
  endif()
endforeach()

file(REMOVE_RECURSE "${TEST_ROOT}")
file(MAKE_DIRECTORY "${TEST_ROOT}")
file(COPY "${EXAMPLE_SOURCE_DIR}/" DESTINATION "${TEST_ROOT}/source")

set(source_dir "${TEST_ROOT}/source")
set(build_dir "${TEST_ROOT}/build")
set(generated_main "${build_dir}/generated/main/main.c")
set(generated_source "${build_dir}/generated/hypotenuse/hypotenuse.c")

execute_process(
  COMMAND "${CMAKE_COMMAND}" -S "${source_dir}" -B "${build_dir}"
          "-DCMAKE_PREFIX_PATH=${F2C_PREFIX}"
  RESULT_VARIABLE configure_result)
if(NOT configure_result EQUAL 0)
  message(FATAL_ERROR "Initial example configuration failed")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" --build "${build_dir}" --parallel
  RESULT_VARIABLE initial_build_result)
if(NOT initial_build_result EQUAL 0)
  message(FATAL_ERROR "Initial example build failed")
endif()

file(SHA256 "${generated_source}" initial_hash)
file(SHA256 "${generated_main}" initial_main_hash)

file(READ "${source_dir}/hypotenuse.f" fortran_source)
string(REPLACE "A * A + B * B" "B * B + A * A"
  updated_fortran_source "${fortran_source}")
if(updated_fortran_source STREQUAL fortran_source)
  message(FATAL_ERROR "The incremental-test source expression was not found")
endif()
execute_process(COMMAND "${CMAKE_COMMAND}" -E sleep 1)
file(WRITE "${source_dir}/hypotenuse.f" "${updated_fortran_source}")

execute_process(
  COMMAND "${CMAKE_COMMAND}" --build "${build_dir}" --parallel
  RESULT_VARIABLE rebuild_result)
if(NOT rebuild_result EQUAL 0)
  message(FATAL_ERROR "Example rebuild failed after changing Fortran input")
endif()

file(SHA256 "${generated_source}" rebuilt_hash)
if(rebuilt_hash STREQUAL initial_hash)
  message(FATAL_ERROR "Generated C was not updated after changing Fortran input")
endif()

file(SHA256 "${generated_main}" rebuilt_main_hash)
if(NOT rebuilt_main_hash STREQUAL initial_main_hash)
  message(FATAL_ERROR "Unchanged Fortran input produced different generated C")
endif()

foreach(unexpected_source IN ITEMS main.c hypotenuse.c)
  if(EXISTS "${source_dir}/${unexpected_source}")
    message(FATAL_ERROR
      "Generated file was written into the example source tree: ${unexpected_source}")
  endif()
endforeach()

execute_process(
  COMMAND "${CMAKE_CTEST_COMMAND}" --test-dir "${build_dir}"
          --output-on-failure
  RESULT_VARIABLE test_result)
if(NOT test_result EQUAL 0)
  message(FATAL_ERROR "Example test failed after incremental rebuild")
endif()
