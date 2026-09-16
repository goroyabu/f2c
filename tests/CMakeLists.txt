# Comments and messages are written in English for maintainability.
include(CTest)

# Add one translated-program contract case.
# Usage: add_f2c_case(<name> <case_dir> <fortran_src> <expected_txt>
#                      [F2C_ARGS <arg>...]
#                      [EXPECTED_C_SUBSTRING <text>]
#                      [STDIN_FILE <path>])
function(add_f2c_case name case_dir fortran_src expected_txt)
  cmake_parse_arguments(CASE ""
    "EXPECTED_C_SUBSTRING;STDIN_FILE" "F2C_ARGS" ${ARGN})

  # 1) Per-case working directory in the build tree (keeps source tree clean)
  set(WORK "${CMAKE_BINARY_DIR}/tests/${name}")
  file(MAKE_DIRECTORY "${WORK}")

  # 2) Convert .f -> .c using the built f2c
  set(CASE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/cases/${case_dir}")
  set(INPUT_F "${CASE_SOURCE_DIR}/${fortran_src}")
  if(DEFINED CASE_STDIN_FILE AND NOT CASE_STDIN_FILE STREQUAL "")
    set(STDIN_FILE "${CASE_SOURCE_DIR}/${CASE_STDIN_FILE}")
  else()
    set(STDIN_FILE "")
  endif()
  get_filename_component(_base "${fortran_src}" NAME_WE)
  set(OUT_C "${WORK}/${_base}.c")
  add_custom_command(
    OUTPUT "${OUT_C}"
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "${INPUT_F}" "${WORK}/${fortran_src}"
    COMMAND "${CMAKE_COMMAND}" -E chdir "${WORK}"
            "$<TARGET_FILE:f2c>" ${CASE_F2C_ARGS} "${fortran_src}"
    COMMAND "${CMAKE_COMMAND}"
            "-DINPUT_FILE=${OUT_C}"
            "-DEXPECTED_SUBSTRING=${CASE_EXPECTED_C_SUBSTRING}"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/AssertFileContains.cmake"
    DEPENDS f2c "${INPUT_F}"
            "${CMAKE_CURRENT_SOURCE_DIR}/cmake/AssertFileContains.cmake"
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
      "-DEXPECTED_STDOUT_FILE=${CASE_SOURCE_DIR}/${expected_txt}"
      "-DSTDIN_FILE=${STDIN_FILE}"
      "-DWORK_DIR=${WORK}/run"
      -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunProgramContract.cmake")
  set_tests_properties("pipeline.${name}" PROPERTIES
    LABELS "pipeline"
    ENVIRONMENT "LC_ALL=C;TZ=UTC"
    TIMEOUT 10
  )
endfunction()

# Add one generated-C ABI contract case with an independent C caller.
# Usage: add_f2c_abi_case(<name> <case_dir> <fortran_src> <c_harness>
#                        <expected_txt>)
function(add_f2c_abi_case
    name case_dir fortran_src c_harness expected_txt)
  set(WORK "${CMAKE_BINARY_DIR}/tests/abi/${name}")
  file(MAKE_DIRECTORY "${WORK}")

  set(CASE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/cases/${case_dir}")
  set(INPUT_F "${CASE_SOURCE_DIR}/${fortran_src}")
  get_filename_component(_base "${fortran_src}" NAME_WE)
  set(OUT_C "${WORK}/${_base}.c")
  add_custom_command(
    OUTPUT "${OUT_C}"
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "${INPUT_F}" "${WORK}/${fortran_src}"
    COMMAND "${CMAKE_COMMAND}" -E chdir "${WORK}"
            "$<TARGET_FILE:f2c>" "${fortran_src}"
    DEPENDS f2c "${INPUT_F}"
    COMMENT "ABI translation phase: ${fortran_src} -> ${_base}.c"
    VERBATIM)

  set(_target "abi_${name}_exe")
  add_executable("${_target}"
    "${OUT_C}"
    "${CASE_SOURCE_DIR}/${c_harness}")
  target_include_directories("${_target}" PRIVATE "${GEN_DIR}")
  target_link_libraries("${_target}" PRIVATE f2c_runtime)
  if(ENABLE_SANITIZERS AND CMAKE_C_COMPILER_ID MATCHES "Clang|GNU")
    target_compile_options("${_target}" PRIVATE
      -fsanitize=address,undefined -fno-omit-frame-pointer)
    target_link_options("${_target}" PRIVATE -fsanitize=address,undefined)
  endif()

  add_test(
    NAME "abi.${name}"
    COMMAND "${CMAKE_COMMAND}"
      "-DPROGRAM=$<TARGET_FILE:${_target}>"
      "-DEXPECTED_STDOUT_FILE=${CASE_SOURCE_DIR}/${expected_txt}"
      "-DWORK_DIR=${WORK}/run"
      -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunProgramContract.cmake")
  set_tests_properties("abi.${name}" PROPERTIES
    LABELS "abi"
    ENVIRONMENT "LC_ALL=C;TZ=UTC"
    TIMEOUT 10)
endfunction()

# ---- Cases ----
add_f2c_case(01_hello pipeline/smoke/01_hello hello.f expected.txt)
add_f2c_case(02_print_int pipeline/smoke/02_print_int prog.f expected.txt)
add_f2c_case(03_sum pipeline/smoke/03_sum prog.f expected.txt)
add_f2c_case(04_expr_precedence
  semantics/scalar_control/04_expr_precedence prog.f expected.txt)
add_f2c_case(05_integer_division
  semantics/scalar_control/05_integer_division prog.f expected.txt)
add_f2c_case(06_real_assignment_conversion
  semantics/scalar_control/06_real_assignment_conversion prog.f expected.txt)
add_f2c_case(07_double_assignment_conversion
  semantics/scalar_control/07_double_assignment_conversion prog.f expected.txt)
add_f2c_case(08_block_if
  semantics/scalar_control/08_block_if prog.f expected.txt)
add_f2c_case(09_logical_if
  semantics/scalar_control/09_logical_if prog.f expected.txt)
add_f2c_case(10_do_negative_step
  semantics/scalar_control/10_do_negative_step prog.f expected.txt)
add_f2c_case(11_do_zero_trip
  semantics/scalar_control/11_do_zero_trip prog.f expected.txt)
add_f2c_case(12_array_1d_access
  semantics/arrays/12_array_1d_access prog.f expected.txt)
add_f2c_case(13_array_lower_bound
  semantics/arrays/13_array_lower_bound prog.f expected.txt)
add_f2c_case(14_array_2d_order
  semantics/arrays/14_array_2d_order prog.f expected.txt)
add_f2c_case(15_array_data_init
  semantics/arrays/15_array_data_init prog.f expected.txt)
add_f2c_case(16_subroutine_scalar_argument
  semantics/procedures/16_subroutine_scalar_argument prog.f expected.txt)
add_f2c_case(17_integer_function
  semantics/procedures/17_integer_function prog.f expected.txt)
add_f2c_case(18_array_argument
  semantics/procedures/18_array_argument prog.f expected.txt)
add_f2c_case(19_named_common
  semantics/shared_state/19_named_common prog.f expected.txt)
add_f2c_case(20_saved_local
  semantics/shared_state/20_saved_local prog.f expected.txt
  F2C_ARGS -a
  EXPECTED_C_SUBSTRING "static integer counter;")
add_f2c_case(21_equivalence_array_element
  semantics/shared_state/21_equivalence_array_element prog.f expected.txt)
add_f2c_case(22_block_data_common_init
  semantics/shared_state/22_block_data_common_init prog.f expected.txt)
add_f2c_case(23_character_assignment
  semantics/character/23_character_assignment prog.f expected.txt)
add_f2c_case(24_substring_reference
  semantics/character/24_substring_reference prog.f expected.txt)
add_f2c_case(25_substring_assignment
  semantics/character/25_substring_assignment prog.f expected.txt)
add_f2c_case(26_character_concatenation
  semantics/character/26_character_concatenation prog.f expected.txt)
add_f2c_case(27_character_comparison
  semantics/character/27_character_comparison prog.f expected.txt)
add_f2c_case(28_complex_assignment_components
  semantics/complex/28_complex_assignment_components prog.f expected.txt)
add_f2c_case(29_complex_multiplication
  semantics/complex/29_complex_multiplication prog.f expected.txt)
add_f2c_case(30_complex_division
  semantics/complex/30_complex_division prog.f expected.txt)
add_f2c_case(31_generic_abs
  semantics/complex/31_generic_abs prog.f expected.txt)
add_f2c_case(32_complex_conjugate
  semantics/complex/32_complex_conjugate prog.f expected.txt)
add_f2c_case(33_complex_square_root
  semantics/complex/33_complex_square_root prog.f expected.txt)
add_f2c_case(34_formatted_output_fields
  semantics/io/34_formatted_output_fields prog.f expected.txt)
add_f2c_case(35_formatted_input_fields
  semantics/io/35_formatted_input_fields prog.f expected.txt
  STDIN_FILE input.txt)
add_f2c_case(36_format_reversion
  semantics/io/36_format_reversion prog.f expected.txt)
add_f2c_case(37_list_directed_input
  semantics/io/37_list_directed_input prog.f expected.txt
  STDIN_FILE input.txt)
add_f2c_case(38_list_directed_controls
  semantics/io/38_list_directed_controls prog.f expected.txt
  STDIN_FILE input.txt)

add_f2c_abi_case(scalar_subroutine
  abi/basic/01_scalar_subroutine routine.f harness.c expected.txt)
add_f2c_abi_case(integer_function
  abi/basic/02_integer_function routine.f harness.c expected.txt)
add_f2c_abi_case(default_real_function
  abi/basic/03_default_real_function routine.f harness.c expected.txt)
add_f2c_abi_case(matrix_argument
  abi/basic/04_matrix_argument routine.f harness.c expected.txt)

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
  SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/cases/pipeline/smoke/01_hello/hello.f"
  EXPECTED_EXIT 0
  EXPECT_STDOUT_EMPTY
  EXPECTED_GENERATED_FILE hello.c)

add_f2c_cli_case(stdin_stdout
  MODE STDIN
  SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/cases/pipeline/smoke/01_hello/hello.f"
  EXPECTED_EXIT 0
  COMPILE_STDOUT)

add_f2c_cli_case(invalid_suffix
  MODE FILE
  SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/cases/cli/invalid_suffix/input.txt"
  EXPECTED_EXIT 1
  EXPECT_STDOUT_EMPTY
  EXPECTED_STDERR_FILE
    "${CMAKE_CURRENT_SOURCE_DIR}/cases/cli/invalid_suffix/expected-stderr.txt")

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
