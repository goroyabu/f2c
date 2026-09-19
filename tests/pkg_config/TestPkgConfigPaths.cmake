if(NOT DEFINED HELPER_FILE OR "${HELPER_FILE}" STREQUAL "")
  message(FATAL_ERROR "HELPER_FILE is required")
endif()

include("${HELPER_FILE}")

function(assert_pkgconfig_path name expected pc_install_dir destination prefix)
  f2c_pkgconfig_path(_actual
    "${pc_install_dir}"
    "${destination}"
    "${prefix}")
  if(NOT "${_actual}" STREQUAL "${expected}")
    message(FATAL_ERROR
      "${name}: expected '${expected}', got '${_actual}'")
  endif()
endfunction()

assert_pkgconfig_path(
  default_libdir "\${pcfiledir}/.." "lib/pkgconfig" "lib" "/opt/f2c")
assert_pkgconfig_path(
  default_includedir "\${pcfiledir}/../../include"
  "lib/pkgconfig" "include" "/opt/f2c")
assert_pkgconfig_path(
  lib64 "\${pcfiledir}/.." "lib64/pkgconfig" "lib64" "/opt/f2c")
assert_pkgconfig_path(
  multi_level "\${pcfiledir}/.." "lib/test-triplet/pkgconfig"
  "lib/test-triplet" "/opt/f2c")
assert_pkgconfig_path(
  absolute_destination "/srv/f2c/include"
  "lib/pkgconfig" "/srv/f2c/include" "/opt/f2c")
assert_pkgconfig_path(
  absolute_pc_dir "/opt/f2c/include"
  "/srv/pkgconfig" "include" "/opt/f2c")
