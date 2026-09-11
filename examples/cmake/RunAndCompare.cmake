if(NOT DEFINED PROGRAM)
  message(FATAL_ERROR "PROGRAM is required")
endif()

execute_process(
  COMMAND "${PROGRAM}"
  RESULT_VARIABLE result
  OUTPUT_VARIABLE stdout
  ERROR_VARIABLE stderr)

if(NOT result EQUAL 0)
  message(FATAL_ERROR
    "Example exited with ${result}.\nstdout:\n${stdout}\nstderr:\n${stderr}")
endif()

set(expected "F2C CMAKE EXAMPLE OK\n")
if(NOT stdout STREQUAL expected)
  message(FATAL_ERROR
    "Unexpected stdout.\nExpected:\n${expected}Actual:\n${stdout}")
endif()

if(NOT stderr STREQUAL "")
  message(FATAL_ERROR "Unexpected stderr:\n${stderr}")
endif()
