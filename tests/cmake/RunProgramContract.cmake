foreach(required_variable IN ITEMS PROGRAM EXPECTED_STDOUT_FILE WORK_DIR)
  if(NOT DEFINED "${required_variable}")
    message(FATAL_ERROR
      "Preparation phase failed: ${required_variable} is required")
  endif()
endforeach()

file(READ "${EXPECTED_STDOUT_FILE}" expected_stdout)
file(REMOVE_RECURSE "${WORK_DIR}")
file(MAKE_DIRECTORY "${WORK_DIR}")

execute_process(
  COMMAND "${PROGRAM}"
  WORKING_DIRECTORY "${WORK_DIR}"
  RESULT_VARIABLE result
  OUTPUT_VARIABLE stdout
  ERROR_VARIABLE stderr)

if(NOT "${result}" STREQUAL "0")
  message(FATAL_ERROR
    "Execution phase failed with exit status ${result}.\n"
    "stdout:\n${stdout}\n"
    "stderr:\n${stderr}")
endif()

if(NOT stdout STREQUAL expected_stdout)
  message(FATAL_ERROR
    "Result comparison phase failed for stdout.\n"
    "Expected:\n${expected_stdout}"
    "Actual:\n${stdout}")
endif()

if(NOT stderr STREQUAL "")
  message(FATAL_ERROR
    "Result comparison phase failed: expected empty stderr.\n"
    "Actual:\n${stderr}")
endif()
