# Read the upstream f2c translator version from src/version.c in src.tgz.
function(read_f2c_upstream_version output_variable archive_path extract_dir)
  if(NOT EXISTS "${archive_path}")
    message(FATAL_ERROR
      "Cannot read the upstream f2c version: archive not found: ${archive_path}")
  endif()

  file(REMOVE_RECURSE "${extract_dir}")
  file(MAKE_DIRECTORY "${extract_dir}")
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E tar xzf
            "${archive_path}" "src/version.c"
    WORKING_DIRECTORY "${extract_dir}"
    RESULT_VARIABLE _extract_result
    OUTPUT_VARIABLE _extract_stdout
    ERROR_VARIABLE _extract_stderr)
  if(NOT _extract_result EQUAL 0)
    message(FATAL_ERROR
      "Could not extract src/version.c from the upstream f2c archive.\n"
      "  Archive: ${archive_path}\n"
      "  Reason: ${_extract_stderr}")
  endif()

  set(_version_file "${extract_dir}/src/version.c")

  file(STRINGS "${_version_file}" _declarations
    REGEX "^[ \t]*char[ \t]+F2C_version\\[\\][ \t]*=[ \t]*\"[0-9]+\"[ \t]*;")
  list(LENGTH _declarations _declaration_count)
  if(NOT _declaration_count EQUAL 1)
    message(FATAL_ERROR
      "Upstream src/version.c does not contain exactly one valid "
      "F2C_version declaration: ${_version_file}")
  endif()

  list(GET _declarations 0 _declaration)
  string(REGEX REPLACE
    ".*F2C_version\\[\\][ \t]*=[ \t]*\"([0-9]+)\".*"
    "\\1" _version "${_declaration}")
  set("${output_variable}" "${_version}" PARENT_SCOPE)
endfunction()
