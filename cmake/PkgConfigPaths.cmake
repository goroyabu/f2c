# Compute a pkg-config path from the directory containing the installed .pc
# file. Relative GNUInstallDirs values remain relocatable. Explicit absolute
# destinations remain absolute by design.
function(f2c_pkgconfig_path output_variable pc_install_dir destination prefix)
  if(IS_ABSOLUTE "${destination}")
    set(_resolved "${destination}")
  elseif(IS_ABSOLUTE "${pc_install_dir}")
    set(_resolved "${prefix}/${destination}")
  else()
    set(_synthetic_root "/f2c-install-root")
    file(RELATIVE_PATH _relative_path
      "${_synthetic_root}/${pc_install_dir}"
      "${_synthetic_root}/${destination}")
    string(REGEX REPLACE "/$" "" _relative_path "${_relative_path}")
    set(_resolved "\${pcfiledir}/${_relative_path}")
  endif()

  set("${output_variable}" "${_resolved}" PARENT_SCOPE)
endfunction()
