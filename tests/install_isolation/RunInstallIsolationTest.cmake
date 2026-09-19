foreach(_required IN ITEMS
    SOURCE_ROOT
    TEST_ROOT
    SRC_ARCHIVE
    LIBF2C_ARCHIVE
    C_COMPILER)
  if(NOT DEFINED ${_required} OR "${${_required}}" STREQUAL "")
    message(FATAL_ERROR "${_required} is required")
  endif()
endforeach()

file(REAL_PATH "${SOURCE_ROOT}" _source_root)
get_filename_component(_test_root_leaf "${TEST_ROOT}" NAME)
get_filename_component(_test_root_parent "${TEST_ROOT}" DIRECTORY)
if(_test_root_parent STREQUAL "")
  set(_test_root_parent ".")
endif()
file(REAL_PATH "${_test_root_parent}" _test_root_parent_real)
if(EXISTS "${TEST_ROOT}")
  file(REAL_PATH "${TEST_ROOT}" _canonical_test_root)
else()
  set(_canonical_test_root "${_test_root_parent_real}/${_test_root_leaf}")
endif()
get_filename_component(_canonical_test_root_leaf
  "${_canonical_test_root}" NAME)
if(NOT _canonical_test_root_leaf STREQUAL "f2c-install-isolation")
  message(FATAL_ERROR
    "TEST_ROOT must end in a directory named f2c-install-isolation: "
    "${TEST_ROOT}")
endif()

file(RELATIVE_PATH _test_relative_to_source
  "${_source_root}" "${_canonical_test_root}")
if(_test_relative_to_source STREQUAL "" OR
   (NOT IS_ABSOLUTE "${_test_relative_to_source}" AND
    NOT _test_relative_to_source MATCHES "^\\.\\.($|/)") )
  message(FATAL_ERROR
    "TEST_ROOT must not be equal to or inside SOURCE_ROOT: "
    "${TEST_ROOT}")
endif()
file(RELATIVE_PATH _source_relative_to_test
  "${_canonical_test_root}" "${_source_root}")
if(_source_relative_to_test STREQUAL "" OR
   (NOT IS_ABSOLUTE "${_source_relative_to_test}" AND
    NOT _source_relative_to_test MATCHES "^\\.\\.($|/)") )
  message(FATAL_ERROR
    "TEST_ROOT must not be an ancestor of SOURCE_ROOT: "
    "${TEST_ROOT}")
endif()
foreach(_input IN ITEMS "${SRC_ARCHIVE}" "${LIBF2C_ARCHIVE}")
  if(NOT EXISTS "${_input}")
    message(FATAL_ERROR "Required archive not found: ${_input}")
  endif()
endforeach()

set(_snapshot "${_canonical_test_root}/source")
set(_build "${_canonical_test_root}/build")
set(_prefix_a "${_canonical_test_root}/unused-prefix-a")
set(_prefix_b "${_canonical_test_root}/prefix-b")
set(_consumer_source "${_canonical_test_root}/consumer-source")
set(_consumer_build "${_canonical_test_root}/consumer-build")
set(_ownership_marker
  "${_canonical_test_root}/.f2c-install-isolation-owned")

if(EXISTS "${_canonical_test_root}")
  if(NOT IS_DIRECTORY "${_canonical_test_root}")
    message(FATAL_ERROR
      "TEST_ROOT exists but is not a directory: ${_canonical_test_root}")
  endif()
  if(NOT EXISTS "${_ownership_marker}")
    message(FATAL_ERROR
      "TEST_ROOT is not owned by this test (missing marker): "
      "${_ownership_marker}")
  endif()
else()
  file(MAKE_DIRECTORY "${_canonical_test_root}")
  file(WRITE "${_ownership_marker}"
    "Owned by RunInstallIsolationTest.cmake.\n")
endif()

file(REMOVE_RECURSE
  "${_snapshot}"
  "${_build}"
  "${_prefix_a}"
  "${_prefix_b}"
  "${_consumer_source}"
  "${_consumer_build}")

function(run_checked description)
  execute_process(
    COMMAND ${ARGN}
    RESULT_VARIABLE _result
    OUTPUT_VARIABLE _stdout
    ERROR_VARIABLE _stderr)
  if(NOT _result EQUAL 0)
    message(FATAL_ERROR
      "${description} failed with exit ${_result}.\n"
      "stdout:\n${_stdout}\n"
      "stderr:\n${_stderr}")
  endif()
endfunction()

function(assert_path_under_prefix label path expected_prefix)
  file(REAL_PATH "${path}" _actual_path)
  file(REAL_PATH "${expected_prefix}" _expected_prefix)
  file(RELATIVE_PATH _relative "${_expected_prefix}" "${_actual_path}")
  if(IS_ABSOLUTE "${_relative}" OR _relative MATCHES "^\\.\\.($|/)")
    message(FATAL_ERROR
      "${label} is outside the expected prefix.\n"
      "  Expected prefix: ${_expected_prefix}\n"
      "  Actual path: ${_actual_path}")
  endif()
endfunction()

file(MAKE_DIRECTORY "${_snapshot}" "${_consumer_source}")
file(COPY "${_source_root}/"
  DESTINATION "${_snapshot}"
  PATTERN ".git" EXCLUDE
  PATTERN ".cache" EXCLUDE
  PATTERN "archives" EXCLUDE
  PATTERN "build" EXCLUDE
  PATTERN "build-*" EXCLUDE
  PATTERN "out" EXCLUDE
  PATTERN "stage" EXCLUDE
  PATTERN "generated" EXCLUDE)
file(COPY "${_source_root}/examples/cmake/"
  DESTINATION "${_consumer_source}")

get_filename_component(_src_archive_dir "${SRC_ARCHIVE}" DIRECTORY)
get_filename_component(_libf2c_archive_dir "${LIBF2C_ARCHIVE}" DIRECTORY)
if(NOT "${_src_archive_dir}" STREQUAL "${_libf2c_archive_dir}")
  message(FATAL_ERROR "Both upstream archives must share one ARCHIVE_DIR")
endif()
set(_archive_dir "${_src_archive_dir}")

run_checked("isolated project configuration"
  "${CMAKE_COMMAND}"
  -S "${_snapshot}"
  -B "${_build}"
  "-DCMAKE_C_COMPILER=${C_COMPILER}"
  -DCMAKE_BUILD_TYPE=Release
  -DBUILD_TESTING=OFF
  -DNET_FETCH=OFF
  "-DARCHIVE_DIR=${_archive_dir}"
  "-DCMAKE_INSTALL_PREFIX=${_prefix_a}")

run_checked("isolated project build"
  "${CMAKE_COMMAND}" --build "${_build}" --parallel)

run_checked("install-time prefix override"
  "${CMAKE_COMMAND}" --install "${_build}" --prefix "${_prefix_b}")

if(EXISTS "${_prefix_a}")
  message(FATAL_ERROR
    "The unused configuration-time prefix was unexpectedly created: "
    "${_prefix_a}")
endif()

file(STRINGS "${_build}/install_manifest.txt" _installed_files)
function(find_manifest_entry output pattern)
  set(_match "")
  foreach(_entry IN LISTS _installed_files)
    if(_entry MATCHES "${pattern}")
      set(_match "${_entry}")
      break()
    endif()
  endforeach()
  if(_match STREQUAL "")
    message(FATAL_ERROR "Install manifest lacks ${pattern}")
  endif()
  set("${output}" "${_match}" PARENT_SCOPE)
endfunction()

foreach(_manifest_pattern IN ITEMS
    "/bin/f2c$"
    "/libf2c\\.a$"
    "/include/f2c\\.h$"
    "/f2cConfig\\.cmake$"
    "/f2cConfigVersion\\.cmake$"
    "/f2cTargets\\.cmake$")
  find_manifest_entry(_manifest_entry "${_manifest_pattern}")
  assert_path_under_prefix("Installed ${_manifest_pattern}"
    "${_manifest_entry}" "${_prefix_b}")
endforeach()

set(_installed_cmake_files "")
foreach(_installed_file IN LISTS _installed_files)
  if(_installed_file MATCHES "\\.cmake$")
    list(APPEND _installed_cmake_files "${_installed_file}")
  endif()
endforeach()
if(NOT _installed_cmake_files)
  message(FATAL_ERROR "Install manifest contains no installed CMake metadata")
endif()

file(REMOVE_RECURSE "${_snapshot}" "${_build}" "${_prefix_a}")
foreach(_removed IN ITEMS "${_snapshot}" "${_build}" "${_prefix_a}")
  if(EXISTS "${_removed}")
    message(FATAL_ERROR "Disposable input still exists: ${_removed}")
  endif()
endforeach()

foreach(_metadata_file IN LISTS _installed_cmake_files)
  if(NOT EXISTS "${_metadata_file}")
    message(FATAL_ERROR "Installed CMake metadata is missing: ${_metadata_file}")
  endif()
  file(READ "${_metadata_file}" _contents)
  foreach(_forbidden IN ITEMS
      "${_snapshot}"
      "${_build}"
      "${_prefix_a}"
      "${_source_root}")
    string(FIND "${_contents}" "${_forbidden}" _position)
    if(NOT _position EQUAL -1)
      message(FATAL_ERROR
        "Installed CMake metadata embeds forbidden path ${_forbidden}: "
        "${_metadata_file}")
    endif()
  endforeach()
endforeach()

run_checked("isolated consumer configuration"
  "${CMAKE_COMMAND}"
  -S "${_consumer_source}"
  -B "${_consumer_build}"
  "-DCMAKE_C_COMPILER=${C_COMPILER}"
  -DCMAKE_BUILD_TYPE=Release
  "-DCMAKE_PREFIX_PATH=${_prefix_b}"
  "-DF2C_EXPECTED_PREFIX=${_prefix_b}"
  -DCMAKE_FIND_USE_PACKAGE_REGISTRY=FALSE
  -DCMAKE_FIND_PACKAGE_NO_SYSTEM_PACKAGE_REGISTRY=TRUE)

unset(_cache_f2c_dir)
file(STRINGS "${_consumer_build}/CMakeCache.txt" _cache_f2c_dir
  REGEX "^f2c_DIR:")
if(NOT _cache_f2c_dir)
  message(FATAL_ERROR
    "Consumer cache does not define f2c_DIR")
endif()
list(GET _cache_f2c_dir 0 _cache_f2c_dir_entry)
string(REGEX REPLACE "^[^=]*=" "" _cached_f2c_dir
  "${_cache_f2c_dir_entry}")
if(_cached_f2c_dir STREQUAL "")
  message(FATAL_ERROR "Consumer cache defines an empty f2c_DIR")
endif()
assert_path_under_prefix("cached f2c_DIR" "${_cached_f2c_dir}" "${_prefix_b}")

run_checked("isolated consumer build"
  "${CMAKE_COMMAND}" --build "${_consumer_build}" --parallel)

run_checked("isolated consumer tests"
  "${CMAKE_CTEST_COMMAND}"
  --test-dir "${_consumer_build}"
  --output-on-failure)

message(STATUS
  "Installed CMake package passed isolated-prefix verification")
