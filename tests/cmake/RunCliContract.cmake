foreach(required_variable IN ITEMS
    CASE_NAME F2C_PROGRAM SOURCE_FILE WORK_DIR MODE EXPECTED_EXIT)
  if(NOT DEFINED "${required_variable}" OR "${${required_variable}}" STREQUAL "")
    message(FATAL_ERROR
      "Preparation phase failed: ${required_variable} is required")
  endif()
endforeach()

if(NOT EXISTS "${F2C_PROGRAM}")
  message(FATAL_ERROR
    "Preparation phase failed: f2c does not exist at ${F2C_PROGRAM}")
endif()
if(NOT EXISTS "${SOURCE_FILE}")
  message(FATAL_ERROR
    "Preparation phase failed: input does not exist at ${SOURCE_FILE}")
endif()

file(REMOVE_RECURSE "${WORK_DIR}")
file(MAKE_DIRECTORY "${WORK_DIR}")
get_filename_component(source_name "${SOURCE_FILE}" NAME)
set(staged_source "${WORK_DIR}/${source_name}")
file(COPY "${SOURCE_FILE}" DESTINATION "${WORK_DIR}")
file(SHA256 "${SOURCE_FILE}" original_source_hash)
file(SHA256 "${staged_source}" staged_source_hash_before)

if(NOT original_source_hash STREQUAL staged_source_hash_before)
  message(FATAL_ERROR
    "Preparation phase failed: staged input differs from its source")
endif()

if(MODE STREQUAL "FILE")
  execute_process(
    COMMAND "${F2C_PROGRAM}" "${source_name}"
    WORKING_DIRECTORY "${WORK_DIR}"
    RESULT_VARIABLE result
    OUTPUT_VARIABLE stdout
    ERROR_VARIABLE stderr)
elseif(MODE STREQUAL "STDIN")
  execute_process(
    COMMAND "${F2C_PROGRAM}"
    WORKING_DIRECTORY "${WORK_DIR}"
    INPUT_FILE "${staged_source}"
    RESULT_VARIABLE result
    OUTPUT_VARIABLE stdout
    ERROR_VARIABLE stderr)
else()
  message(FATAL_ERROR
    "Preparation phase failed: unsupported test mode ${MODE}")
endif()

if(NOT "${result}" STREQUAL "${EXPECTED_EXIT}")
  message(FATAL_ERROR
    "Translation phase failed for ${CASE_NAME}: expected exit status "
    "${EXPECTED_EXIT}, got ${result}.\nstdout:\n${stdout}\nstderr:\n${stderr}")
endif()

if(EXPECT_STDOUT_EMPTY AND NOT stdout STREQUAL "")
  message(FATAL_ERROR
    "Result comparison phase failed for ${CASE_NAME}: expected empty "
    "stdout.\nActual:\n${stdout}")
endif()

if(DEFINED EXPECTED_STDERR_FILE AND NOT EXPECTED_STDERR_FILE STREQUAL "")
  file(READ "${EXPECTED_STDERR_FILE}" expected_stderr)
  if(NOT stderr STREQUAL expected_stderr)
    message(FATAL_ERROR
      "Result comparison phase failed for ${CASE_NAME} stderr.\n"
      "Expected:\n${expected_stderr}"
      "Actual:\n${stderr}")
  endif()
endif()

file(GLOB converter_c_files "${WORK_DIR}/*.c")
if(DEFINED EXPECTED_GENERATED_FILE AND NOT EXPECTED_GENERATED_FILE STREQUAL "")
  set(expected_generated_path "${WORK_DIR}/${EXPECTED_GENERATED_FILE}")
  if(NOT EXISTS "${expected_generated_path}")
    message(FATAL_ERROR
      "Generated-file validation phase failed for ${CASE_NAME}: "
      "${EXPECTED_GENERATED_FILE} was not created")
  endif()
  file(SIZE "${expected_generated_path}" generated_size)
  if(generated_size EQUAL 0)
    message(FATAL_ERROR
      "Generated-file validation phase failed for ${CASE_NAME}: "
      "${EXPECTED_GENERATED_FILE} is empty")
  endif()
  list(LENGTH converter_c_files generated_count)
  if(NOT generated_count EQUAL 1)
    message(FATAL_ERROR
      "Generated-file validation phase failed for ${CASE_NAME}: expected "
      "one C file, found ${generated_count}: ${converter_c_files}")
  endif()
elseif(converter_c_files)
  message(FATAL_ERROR
    "Generated-file validation phase failed for ${CASE_NAME}: unexpected "
    "C output was created: ${converter_c_files}")
endif()

file(SHA256 "${staged_source}" staged_source_hash_after)
if(NOT staged_source_hash_after STREQUAL staged_source_hash_before)
  message(FATAL_ERROR
    "Generated-file validation phase failed for ${CASE_NAME}: f2c modified "
    "the staged input")
endif()

if(COMPILE_STDOUT)
  if(stdout STREQUAL "")
    message(FATAL_ERROR
      "Generated-file validation phase failed for ${CASE_NAME}: stdout is "
      "empty")
  endif()
  foreach(required_compile_variable IN ITEMS C_COMPILER F2C_INCLUDE_DIR)
    if(NOT DEFINED "${required_compile_variable}"
        OR "${${required_compile_variable}}" STREQUAL "")
      message(FATAL_ERROR
        "C compilation phase failed: ${required_compile_variable} is required")
    endif()
  endforeach()
  set(captured_source "${WORK_DIR}/captured-stdout.c")
  set(captured_object "${WORK_DIR}/captured-stdout.o")
  file(WRITE "${captured_source}" "${stdout}")
  execute_process(
    COMMAND "${C_COMPILER}" -I "${F2C_INCLUDE_DIR}" -c
            "${captured_source}" -o "${captured_object}"
    RESULT_VARIABLE compile_result
    OUTPUT_VARIABLE compile_stdout
    ERROR_VARIABLE compile_stderr)
  if(NOT compile_result EQUAL 0)
    message(FATAL_ERROR
      "C compilation phase failed for ${CASE_NAME} with exit status "
      "${compile_result}.\nstdout:\n${compile_stdout}\n"
      "stderr:\n${compile_stderr}")
  endif()
  if(NOT EXISTS "${captured_object}")
    message(FATAL_ERROR
      "C compilation phase failed for ${CASE_NAME}: no object was produced")
  endif()
endif()
