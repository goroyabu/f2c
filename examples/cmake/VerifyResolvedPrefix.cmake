function(f2c_assert_path_under_prefix label path expected_prefix)
  if("${path}" STREQUAL "" OR "${path}" MATCHES "-NOTFOUND$")
    message(FATAL_ERROR "${label} is missing")
  endif()

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

function(f2c_assert_imported_locations target expected_prefix)
  get_target_property(_configurations "${target}" IMPORTED_CONFIGURATIONS)
  set(_locations "")

  get_target_property(_generic_location "${target}" IMPORTED_LOCATION)
  if(_generic_location AND NOT _generic_location MATCHES "-NOTFOUND$")
    list(APPEND _locations "${_generic_location}")
  endif()

  foreach(_configuration IN LISTS _configurations)
    string(TOUPPER "${_configuration}" _configuration_upper)
    get_target_property(_location "${target}"
      "IMPORTED_LOCATION_${_configuration_upper}")
    if(_location AND NOT _location MATCHES "-NOTFOUND$")
      list(APPEND _locations "${_location}")
    endif()
  endforeach()

  list(REMOVE_DUPLICATES _locations)
  if(NOT _locations)
    message(FATAL_ERROR "${target} has no imported location")
  endif()

  foreach(_location IN LISTS _locations)
    f2c_assert_path_under_prefix(
      "${target} imported location" "${_location}" "${expected_prefix}")
  endforeach()
endfunction()

function(f2c_verify_resolved_prefix expected_prefix)
  f2c_assert_path_under_prefix("f2c_DIR" "${f2c_DIR}" "${expected_prefix}")
  f2c_assert_imported_locations(f2c::f2c "${expected_prefix}")
  f2c_assert_imported_locations(f2c::f2c_runtime "${expected_prefix}")

  get_target_property(_include_dirs
    f2c::f2c_runtime INTERFACE_INCLUDE_DIRECTORIES)
  if(NOT _include_dirs)
    message(FATAL_ERROR
      "f2c::f2c_runtime has no INTERFACE_INCLUDE_DIRECTORIES")
  endif()
  foreach(_include_dir IN LISTS _include_dirs)
    if(_include_dir MATCHES "^\\$<")
      message(FATAL_ERROR
        "Unexpected generator expression in installed include path: "
        "${_include_dir}")
    endif()
    f2c_assert_path_under_prefix(
      "f2c::f2c_runtime include directory"
      "${_include_dir}" "${expected_prefix}")
  endforeach()
endfunction()
