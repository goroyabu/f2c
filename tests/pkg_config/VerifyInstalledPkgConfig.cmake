foreach(required_var IN ITEMS
    INSTALL_PREFIX
    INSTALL_MANIFEST
    PACKAGE_EXPECTATIONS
    SOURCE_FILE
    EXPECTED_STDOUT_FILE
    C_COMPILER
    SOURCE_ROOT
    BUILD_ROOT
    TEST_ROOT)
  if(NOT DEFINED ${required_var} OR "${${required_var}}" STREQUAL "")
    message(FATAL_ERROR "${required_var} is required")
  endif()
endforeach()

include("${PACKAGE_EXPECTATIONS}")

file(STRINGS "${INSTALL_MANIFEST}" _installed_files)
set(_pc_file "")
foreach(_installed_file IN LISTS _installed_files)
  if(_installed_file MATCHES "/libf2c\\.pc$")
    set(_pc_file "${_installed_file}")
  endif()
endforeach()
if(_pc_file STREQUAL "")
  message(FATAL_ERROR
    "The install manifest does not contain an installed libf2c.pc")
endif()
if(NOT EXISTS "${_pc_file}")
  message(FATAL_ERROR "Installed pkg-config file not found: ${_pc_file}")
endif()

file(READ "${_pc_file}" _pc_contents)
function(assert_pc_contains expected)
  string(FIND "${_pc_contents}" "${expected}" _position)
  if(_position EQUAL -1)
    message(FATAL_ERROR
      "Installed libf2c.pc does not contain '${expected}':\n${_pc_contents}")
  endif()
endfunction()

assert_pc_contains("Name: libf2c")
assert_pc_contains("Version: ${EXPECTED_PACKAGE_VERSION}")
assert_pc_contains("Libs: -L\${libdir} -lf2c")
assert_pc_contains("Cflags: -I\${includedir}")
if(EXPECTED_UNIX)
  assert_pc_contains("Libs.private: -lm")
endif()

foreach(forbidden_path IN ITEMS
    "${SOURCE_ROOT}"
    "${BUILD_ROOT}"
    "${INSTALL_PREFIX}")
  string(FIND "${_pc_contents}" "${forbidden_path}" _position)
  if(NOT _position EQUAL -1)
    message(FATAL_ERROR
      "Installed libf2c.pc embeds forbidden path: ${forbidden_path}")
  endif()
endforeach()

find_program(_pkg_config_program NAMES pkg-config pkgconf)
if(NOT _pkg_config_program)
  if(REQUIRE_PKG_CONFIG)
    message(FATAL_ERROR "pkg-config or pkgconf is required for this check")
  endif()
  message(STATUS
    "pkg-config is unavailable; structural metadata checks passed")
  return()
endif()

file(REMOVE_RECURSE "${TEST_ROOT}")
file(MAKE_DIRECTORY "${TEST_ROOT}")
set(_relocated_prefix "${TEST_ROOT}/relocated")
file(COPY "${INSTALL_PREFIX}/" DESTINATION "${_relocated_prefix}")

file(RELATIVE_PATH _pc_relative "${INSTALL_PREFIX}" "${_pc_file}")
set(_relocated_pc "${_relocated_prefix}/${_pc_relative}")
get_filename_component(_relocated_pc_dir "${_relocated_pc}" DIRECTORY)
set(_pkg_env
  "PKG_CONFIG_PATH="
  "PKG_CONFIG_LIBDIR=${_relocated_pc_dir}")

execute_process(
  COMMAND "${CMAKE_COMMAND}" -E env ${_pkg_env}
          "${_pkg_config_program}" --modversion libf2c
  RESULT_VARIABLE _version_result
  OUTPUT_VARIABLE _reported_version
  ERROR_VARIABLE _version_error
  OUTPUT_STRIP_TRAILING_WHITESPACE)
if(NOT _version_result EQUAL 0)
  message(FATAL_ERROR "pkg-config version query failed: ${_version_error}")
endif()
if(NOT "${_reported_version}" STREQUAL "${EXPECTED_PACKAGE_VERSION}")
  message(FATAL_ERROR
    "pkg-config reported version '${_reported_version}', expected "
    "'${EXPECTED_PACKAGE_VERSION}'")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" -E env ${_pkg_env}
          "${_pkg_config_program}" --cflags libf2c
  RESULT_VARIABLE _cflags_result
  OUTPUT_VARIABLE _cflags
  ERROR_VARIABLE _cflags_error
  OUTPUT_STRIP_TRAILING_WHITESPACE)
if(NOT _cflags_result EQUAL 0)
  message(FATAL_ERROR "pkg-config cflags query failed: ${_cflags_error}")
endif()
execute_process(
  COMMAND "${CMAKE_COMMAND}" -E env ${_pkg_env}
          "${_pkg_config_program}" --static --libs libf2c
  RESULT_VARIABLE _libs_result
  OUTPUT_VARIABLE _libs
  ERROR_VARIABLE _libs_error
  OUTPUT_STRIP_TRAILING_WHITESPACE)
if(NOT _libs_result EQUAL 0)
  message(FATAL_ERROR "pkg-config library query failed: ${_libs_error}")
endif()

string(FIND "${_cflags} ${_libs}" "${INSTALL_PREFIX}" _old_prefix_position)
if(NOT _old_prefix_position EQUAL -1)
  message(FATAL_ERROR
    "Relocated pkg-config output refers to the original prefix: "
    "${_cflags} ${_libs}")
endif()

separate_arguments(_cflag_list UNIX_COMMAND "${_cflags}")
separate_arguments(_lib_list UNIX_COMMAND "${_libs}")
set(_work_dir "${TEST_ROOT}/consumer")
file(MAKE_DIRECTORY "${_work_dir}")
get_filename_component(_source_name "${SOURCE_FILE}" NAME)
file(COPY "${SOURCE_FILE}" DESTINATION "${_work_dir}")
get_filename_component(_source_stem "${SOURCE_FILE}" NAME_WE)
set(_generated_c "${_work_dir}/${_source_stem}.c")
set(_program "${_work_dir}/pkg_config_consumer")

set(_f2c_program "${_relocated_prefix}/${EXPECTED_BINDIR}/f2c")
execute_process(
  COMMAND "${_f2c_program}" "${_source_name}"
  WORKING_DIRECTORY "${_work_dir}"
  RESULT_VARIABLE _translate_result
  OUTPUT_VARIABLE _translate_stdout
  ERROR_VARIABLE _translate_stderr)
if(NOT _translate_result EQUAL 0)
  message(FATAL_ERROR
    "Installed f2c translation failed:\n${_translate_stdout}\n${_translate_stderr}")
endif()

execute_process(
  COMMAND "${C_COMPILER}" "${_generated_c}" ${_cflag_list} ${_lib_list}
          -o "${_program}"
  RESULT_VARIABLE _compile_result
  OUTPUT_VARIABLE _compile_stdout
  ERROR_VARIABLE _compile_stderr)
if(NOT _compile_result EQUAL 0)
  message(FATAL_ERROR
    "pkg-config consumer compilation failed:\n"
    "${_compile_stdout}\n${_compile_stderr}")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" -E env LC_ALL=C TZ=UTC "${_program}"
  RESULT_VARIABLE _run_result
  OUTPUT_VARIABLE _actual_stdout
  ERROR_VARIABLE _actual_stderr)
if(NOT _run_result EQUAL 0)
  message(FATAL_ERROR
    "pkg-config consumer failed with exit ${_run_result}: ${_actual_stderr}")
endif()
file(READ "${EXPECTED_STDOUT_FILE}" _expected_stdout)
if(NOT "${_actual_stdout}" STREQUAL "${_expected_stdout}")
  message(FATAL_ERROR
    "pkg-config consumer output mismatch.\n"
    "Expected:\n${_expected_stdout}\nActual:\n${_actual_stdout}")
endif()

message(STATUS
  "Installed and relocated libf2c pkg-config verification passed")
