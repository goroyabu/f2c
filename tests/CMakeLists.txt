# Comments and messages are written in English for maintainability.
include(CTest)

# Add one smoke test case.
# Usage: add_f2c_case(<name> <fortran_src> <expected_txt>)
function(add_f2c_case name fortran_src expected_txt)
  # 1) Per-case working directory in the build tree (keeps source tree clean)
  set(WORK "${CMAKE_BINARY_DIR}/tests/${name}")
  file(MAKE_DIRECTORY "${WORK}")

  # 2) Convert .f -> .c using the built f2c
  get_filename_component(_base "${fortran_src}" NAME_WE)
  set(OUT_C "${WORK}/${_base}.c")
  add_custom_command(
    OUTPUT "${OUT_C}"
    BYPRODUCTS "${WORK}/f2c.out" "${WORK}/f2c.err"
    COMMAND "${CMAKE_COMMAND}" -E copy
            "${CMAKE_CURRENT_SOURCE_DIR}/cases/${name}/${fortran_src}"
            "${WORK}/${fortran_src}"
    COMMAND ${CMAKE_COMMAND} -E chdir "${WORK}" "${CMAKE_BINARY_DIR}/f2c" "${fortran_src}"
    # COMMAND "${CMAKE_COMMAND}" -E rm -f "${WORK}/${_base}.c" "${WORK}/f2c.out" "${WORK}/f2c.err"
    # COMMAND ${CMAKE_COMMAND} -E chdir "${WORK}" /bin/sh -c "\"$<TARGET_FILE:f2c>\" < \"${fortran_src}\" > f2c.out 2> f2c.err"
    # COMMAND ${CMAKE_COMMAND} -E chdir "${WORK}" /bin/sh -c "test -s f2c.out || ( echo 'f2c failed; stderr follows:' ; /bin/cat f2c.err ; exit 3 )"
    # COMMAND "${CMAKE_COMMAND}" -E rename "${WORK}/f2c.out" "${OUT_C}"
    DEPENDS f2c
    COMMENT "Converting ${fortran_src} -> ${name}.c"
    VERBATIM)

  # Create a per-case generation target for serialization
  add_custom_target("gen_${name}" DEPENDS "${OUT_C}")
  # Chain generation targets so that f2c conversions run sequentially
  get_property(_prev GLOBAL PROPERTY F2C_LAST_GEN_TARGET)
  if(_prev)
    add_dependencies("gen_${name}" "${_prev}")
  endif()
  set_property(GLOBAL PROPERTY F2C_LAST_GEN_TARGET "gen_${name}")

  # 3) Build the program against libf2c runtime
  add_executable("${name}_exe" "${OUT_C}")
  # Ensure each test executable waits for serialized conversion to complete
  add_dependencies("${name}_exe" "gen_${name}")
  add_dependencies("${name}_exe" f2c_runtime)
  target_include_directories("${name}_exe" PRIVATE "${GEN_DIR}")
  target_link_libraries("${name}_exe" PRIVATE f2c_runtime m)
  if(ENABLE_SANITIZERS AND CMAKE_C_COMPILER_ID MATCHES "Clang|GNU")
    target_compile_options("${name}_exe" PRIVATE -fsanitize=address,undefined -fno-omit-frame-pointer)
    target_link_options("${name}_exe" PRIVATE -fsanitize=address,undefined)
  endif()

  # 4) Register the test; read expected stdout and use it as a regex (escaped)
  file(READ "${CMAKE_CURRENT_SOURCE_DIR}/cases/${name}/${expected_txt}" _exp_raw)
  string(STRIP "${_exp_raw}" _exp_raw)

  add_test(NAME "${name}" COMMAND "${name}_exe")
  set_tests_properties("${name}" PROPERTIES
    LABELS "smoke"
    PASS_REGULAR_EXPRESSION "${_exp_raw}"
    ENVIRONMENT "LC_ALL=C;TZ=UTC"
    TIMEOUT 10
  )
endfunction()

# ---- Cases ----
add_f2c_case(01_hello      hello.f      expected.txt)
add_f2c_case(02_print_int  prog.f       expected.txt)
add_f2c_case(03_sum        prog.f       expected.txt)

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
