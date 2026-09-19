foreach(required_var IN ITEMS F2C_PROGRAM EXPECTED_UPSTREAM_VERSION)
  if(NOT DEFINED ${required_var} OR "${${required_var}}" STREQUAL "")
    message(FATAL_ERROR "${required_var} is required")
  endif()
endforeach()

execute_process(
  COMMAND "${F2C_PROGRAM}" --version
  RESULT_VARIABLE _result
  OUTPUT_VARIABLE _stdout
  ERROR_VARIABLE _stderr)
if(NOT _result EQUAL 0)
  message(FATAL_ERROR
    "f2c --version failed with exit ${_result}:\n${_stdout}\n${_stderr}")
endif()

set(_output "${_stdout}\n${_stderr}")
string(REGEX MATCH "version[ \t]+([0-9]+)" _match "${_output}")
if(NOT CMAKE_MATCH_1 STREQUAL EXPECTED_UPSTREAM_VERSION)
  message(FATAL_ERROR
    "Installed f2c version mismatch: expected ${EXPECTED_UPSTREAM_VERSION}, "
    "got '${CMAKE_MATCH_1}' from:\n${_output}")
endif()
