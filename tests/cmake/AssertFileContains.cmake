if(NOT DEFINED INPUT_FILE OR INPUT_FILE STREQUAL "")
  message(FATAL_ERROR
    "Generated-C validation phase failed: INPUT_FILE is required.")
endif()

if(NOT EXISTS "${INPUT_FILE}")
  message(FATAL_ERROR
    "Generated-C validation phase failed: ${INPUT_FILE} does not exist.")
endif()

if(NOT DEFINED EXPECTED_SUBSTRING OR EXPECTED_SUBSTRING STREQUAL "")
  return()
endif()

file(READ "${INPUT_FILE}" generated_c)
string(FIND "${generated_c}" "${EXPECTED_SUBSTRING}" substring_position)
if(substring_position EQUAL -1)
  message(FATAL_ERROR
    "Generated-C validation phase failed: ${INPUT_FILE} does not contain "
    "the expected substring: ${EXPECTED_SUBSTRING}")
endif()
