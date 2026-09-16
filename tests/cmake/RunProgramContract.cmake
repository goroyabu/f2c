foreach(required_variable IN ITEMS PROGRAM EXPECTED_STDOUT_FILE WORK_DIR)
  if(NOT DEFINED "${required_variable}")
    message(FATAL_ERROR
      "Preparation phase failed: ${required_variable} is required")
  endif()
endforeach()

file(READ "${EXPECTED_STDOUT_FILE}" expected_stdout)
file(REMOVE_RECURSE "${WORK_DIR}")
file(MAKE_DIRECTORY "${WORK_DIR}")

set(input_arguments)
if(DEFINED STDIN_FILE AND NOT STDIN_FILE STREQUAL "")
  if(NOT EXISTS "${STDIN_FILE}")
    message(FATAL_ERROR
      "Preparation phase failed: standard-input file does not exist: "
      "${STDIN_FILE}")
  endif()
  list(APPEND input_arguments INPUT_FILE "${STDIN_FILE}")
endif()

execute_process(
  COMMAND "${PROGRAM}"
  WORKING_DIRECTORY "${WORK_DIR}"
  ${input_arguments}
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
