# Comments and messages are written in English for maintainability.
include(CTest)

# Add one smoke test case.
# Usage: add_f2c_case(<name> <fortran_src> <expected_txt>)
function(add_f2c_case name fortran_src expected_txt)
  # 1) Per-case working directory in the build tree (keeps source tree clean)
  set(WORK "${CMAKE_BINARY_DIR}/tests/${name}")
  file(MAKE_DIRECTORY "${WORK}")

  # 2) Convert .f -> .c using the built f2c
  set(INPUT_F "${CMAKE_CURRENT_SOURCE_DIR}/cases/${name}/${fortran_src}")
  get_filename_component(_base "${fortran_src}" NAME_WE)
  set(OUT_C "${WORK}/${_base}.c")
  add_custom_command(
    OUTPUT "${OUT_C}"
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "${INPUT_F}" "${WORK}/${fortran_src}"
    COMMAND "${CMAKE_COMMAND}" -E chdir "${WORK}"
            "$<TARGET_FILE:f2c>" "${fortran_src}"
    DEPENDS f2c "${INPUT_F}"
    COMMENT "Translation phase: ${fortran_src} -> ${_base}.c"
    VERBATIM)

  # 3) Build the program against libf2c runtime
  add_executable("${name}_exe" "${OUT_C}")
  target_include_directories("${name}_exe" PRIVATE "${GEN_DIR}")
  target_link_libraries("${name}_exe" PRIVATE f2c_runtime)
  if(ENABLE_SANITIZERS AND CMAKE_C_COMPILER_ID MATCHES "Clang|GNU")
    target_compile_options("${name}_exe" PRIVATE -fsanitize=address,undefined -fno-omit-frame-pointer)
    target_link_options("${name}_exe" PRIVATE -fsanitize=address,undefined)
  endif()

  # 4) Register the test with exact process-output verification.
  add_test(
    NAME "pipeline.${name}"
    COMMAND "${CMAKE_COMMAND}"
      "-DPROGRAM=$<TARGET_FILE:${name}_exe>"
      "-DEXPECTED_STDOUT_FILE=${CMAKE_CURRENT_SOURCE_DIR}/cases/${name}/${expected_txt}"
      "-DWORK_DIR=${WORK}/run"
      -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunProgramContract.cmake")
  set_tests_properties("pipeline.${name}" PROPERTIES
    LABELS "pipeline"
    ENVIRONMENT "LC_ALL=C;TZ=UTC"
    TIMEOUT 10
  )
endfunction()

# ---- Cases ----
add_f2c_case(01_hello      hello.f      expected.txt)
add_f2c_case(02_print_int  prog.f       expected.txt)
add_f2c_case(03_sum        prog.f       expected.txt)

# Add a black-box command-line contract test.
function(add_f2c_cli_case name)
  set(options EXPECT_STDOUT_EMPTY COMPILE_STDOUT)
  set(one_value_args
    MODE SOURCE EXPECTED_EXIT EXPECTED_STDERR_FILE EXPECTED_GENERATED_FILE)
  cmake_parse_arguments(CLI
    "${options}" "${one_value_args}" "" ${ARGN})

  add_test(
    NAME "cli.${name}"
    COMMAND "${CMAKE_COMMAND}"
      "-DCASE_NAME=${name}"
      "-DF2C_PROGRAM=$<TARGET_FILE:f2c>"
      "-DSOURCE_FILE=${CLI_SOURCE}"
      "-DWORK_DIR=${CMAKE_CURRENT_BINARY_DIR}/cli/${name}"
      "-DMODE=${CLI_MODE}"
      "-DEXPECTED_EXIT=${CLI_EXPECTED_EXIT}"
      "-DEXPECT_STDOUT_EMPTY=${CLI_EXPECT_STDOUT_EMPTY}"
      "-DEXPECTED_STDERR_FILE=${CLI_EXPECTED_STDERR_FILE}"
      "-DEXPECTED_GENERATED_FILE=${CLI_EXPECTED_GENERATED_FILE}"
      "-DCOMPILE_STDOUT=${CLI_COMPILE_STDOUT}"
      "-DC_COMPILER=${CMAKE_C_COMPILER}"
      "-DF2C_INCLUDE_DIR=${GEN_DIR}"
      -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunCliContract.cmake")
  set_tests_properties("cli.${name}" PROPERTIES
    LABELS "cli"
    ENVIRONMENT "LC_ALL=C;TZ=UTC"
    TIMEOUT 10)
endfunction()

add_f2c_cli_case(file_input
  MODE FILE
  SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/cases/01_hello/hello.f"
  EXPECTED_EXIT 0
  EXPECT_STDOUT_EMPTY
  EXPECTED_GENERATED_FILE hello.c)

add_f2c_cli_case(stdin_stdout
  MODE STDIN
  SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/cases/01_hello/hello.f"
  EXPECTED_EXIT 0
  COMPILE_STDOUT)

add_f2c_cli_case(invalid_suffix
  MODE FILE
  SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/cases/cli_invalid_suffix/input.txt"
  EXPECTED_EXIT 1
  EXPECT_STDOUT_EMPTY
  EXPECTED_STDERR_FILE
    "${CMAKE_CURRENT_SOURCE_DIR}/cases/cli_invalid_suffix/expected-stderr.txt")

# Verify archive selection and SHA256 enforcement without touching the
# repository's real archive or download-cache directories.
function(add_archive_hash_test case_name)
  add_test(
    NAME "archive_hash.${case_name}"
    COMMAND "${CMAKE_COMMAND}"
      "-DTEST_CASE=${case_name}"
      "-DFETCH_MODULE=${PROJECT_SOURCE_DIR}/cmake/FetchAndUnpack.cmake"
      "-DTEST_ROOT=${CMAKE_CURRENT_BINARY_DIR}/archive-hash-tests/${case_name}"
      "-DRESOLVE_SCRIPT=${CMAKE_CURRENT_SOURCE_DIR}/archive_hash/ResolveArchive.cmake"
      -P "${CMAKE_CURRENT_SOURCE_DIR}/archive_hash/RunArchiveHashTest.cmake")
  set_tests_properties("archive_hash.${case_name}" PROPERTIES
    LABELS "archive-integrity"
    TIMEOUT 30)
endfunction()

add_archive_hash_test(local_valid_src)
add_archive_hash_test(local_valid_libf2c)
add_archive_hash_test(local_mismatch_strict)
add_archive_hash_test(cache_valid)
add_archive_hash_test(cache_mismatch_strict)
add_archive_hash_test(download_valid)
add_archive_hash_test(download_mismatch_strict)
add_archive_hash_test(no_fallback_after_mismatch)
add_archive_hash_test(local_mismatch_allowed)
add_archive_hash_test(cache_mismatch_allowed)
add_archive_hash_test(download_mismatch_allowed)
add_archive_hash_test(valid_archive_allowed_mode_warning)
add_archive_hash_test(no_fallback_after_mismatch_allowed)
add_archive_hash_test(missing_input_allowed)
add_archive_hash_test(download_failure_allowed)
