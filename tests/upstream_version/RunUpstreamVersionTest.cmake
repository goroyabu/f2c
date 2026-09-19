cmake_minimum_required(VERSION 3.20)

foreach(required_var IN ITEMS TEST_CASE TEST_ROOT READ_VERSION_MODULE)
  if(NOT DEFINED ${required_var} OR "${${required_var}}" STREQUAL "")
    message(FATAL_ERROR "${required_var} is required")
  endif()
endforeach()

file(REMOVE_RECURSE "${TEST_ROOT}")
file(MAKE_DIRECTORY "${TEST_ROOT}/input/src")

set(_expect_success FALSE)
set(_expected_text "")
if(TEST_CASE STREQUAL "valid")
  file(WRITE "${TEST_ROOT}/input/src/version.c"
    "char F2C_version[] = \"20240504\";\n")
  set(_expect_success TRUE)
  set(_expected_text "UPSTREAM_VERSION=20240504")
elseif(TEST_CASE STREQUAL "missing_version_file")
  file(WRITE "${TEST_ROOT}/input/src/README" "no version source\n")
  set(_expected_text
    "Could not extract src/version.c from the upstream f2c archive.")
elseif(TEST_CASE STREQUAL "malformed_declaration")
  file(WRITE "${TEST_ROOT}/input/src/version.c"
    "char F2C_version[] = \"development\";\n")
  set(_expected_text
    "does not contain exactly one valid F2C_version declaration")
elseif(TEST_CASE STREQUAL "duplicate_declaration")
  file(WRITE "${TEST_ROOT}/input/src/version.c"
    "char F2C_version[] = \"20240504\";\n"
    "char F2C_version[] = \"20240505\";\n")
  set(_expected_text
    "does not contain exactly one valid F2C_version declaration")
else()
  message(FATAL_ERROR "Unknown TEST_CASE: ${TEST_CASE}")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" -E tar czf "${TEST_ROOT}/src.tgz" src
  WORKING_DIRECTORY "${TEST_ROOT}/input"
  RESULT_VARIABLE _archive_result
  ERROR_VARIABLE _archive_error)
if(NOT _archive_result EQUAL 0)
  message(FATAL_ERROR "Could not create test archive: ${_archive_error}")
endif()

file(WRITE "${TEST_ROOT}/read.cmake" [=[
include("${READ_VERSION_MODULE}")
read_f2c_upstream_version(
  _version "${TEST_ARCHIVE}" "${TEST_EXTRACT_DIR}")
message(STATUS "UPSTREAM_VERSION=${_version}")
]=])

execute_process(
  COMMAND "${CMAKE_COMMAND}"
    "-DREAD_VERSION_MODULE=${READ_VERSION_MODULE}"
    "-DTEST_ARCHIVE=${TEST_ROOT}/src.tgz"
    "-DTEST_EXTRACT_DIR=${TEST_ROOT}/extract"
    -P "${TEST_ROOT}/read.cmake"
  RESULT_VARIABLE _result
  OUTPUT_VARIABLE _stdout
  ERROR_VARIABLE _stderr)
set(_output "${_stdout}\n${_stderr}")

if(_expect_success AND NOT _result EQUAL 0)
  message(FATAL_ERROR "Expected success, got exit ${_result}:\n${_output}")
elseif(NOT _expect_success AND _result EQUAL 0)
  message(FATAL_ERROR "Expected failure, but parsing succeeded:\n${_output}")
endif()

string(REGEX REPLACE "[\r\n\t ]+" " " _normalized_output "${_output}")
string(FIND "${_normalized_output}" "${_expected_text}" _match)
if(_match EQUAL -1)
  message(FATAL_ERROR
    "Expected output to contain '${_expected_text}', got:\n${_output}")
endif()
