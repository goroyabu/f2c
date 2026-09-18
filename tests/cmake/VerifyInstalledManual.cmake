if(NOT DEFINED INSTALL_PREFIX OR INSTALL_PREFIX STREQUAL "")
  message(FATAL_ERROR "INSTALL_PREFIX is required")
endif()

if(NOT DEFINED INSTALL_MANIFEST OR INSTALL_MANIFEST STREQUAL "")
  message(FATAL_ERROR "INSTALL_MANIFEST is required")
endif()

if(NOT DEFINED MAN_INSTALL_DIR OR MAN_INSTALL_DIR STREQUAL "")
  set(MAN_INSTALL_DIR "share/man")
endif()

set(_manual "${INSTALL_PREFIX}/${MAN_INSTALL_DIR}/man1/f2c.1")
if(NOT EXISTS "${_manual}")
  message(FATAL_ERROR "Installed manual page not found: ${_manual}")
endif()

file(SIZE "${_manual}" _manual_size)
if(_manual_size EQUAL 0)
  message(FATAL_ERROR "Installed manual page is empty: ${_manual}")
endif()

file(READ "${_manual}" _manual_source)
if(NOT _manual_source MATCHES "^\\.")
  message(FATAL_ERROR "Installed manual page does not begin as roff source")
endif()
if(NOT _manual_source MATCHES "\\.TH[ \t]+F2C[ \t]+1")
  message(FATAL_ERROR "Installed manual page lacks the expected .TH F2C 1 declaration")
endif()

if(NOT EXISTS "${INSTALL_MANIFEST}")
  message(FATAL_ERROR "Install manifest not found: ${INSTALL_MANIFEST}")
endif()
file(READ "${INSTALL_MANIFEST}" _manifest)
string(FIND "${_manifest}" "${_manual}" _manifest_index)
if(_manifest_index EQUAL -1)
  message(FATAL_ERROR "Install manifest does not record the manual page: ${_manual}")
endif()

find_program(_mandoc NAMES mandoc)
find_program(_groff NAMES groff)
if(_mandoc)
  execute_process(
    COMMAND "${_mandoc}" -Tascii "${_manual}"
    RESULT_VARIABLE _render_result
    OUTPUT_VARIABLE _rendered
    ERROR_VARIABLE _render_stderr)
elseif(_groff)
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E env "GROFF_NO_SGR=1"
            "${_groff}" -man -Tascii "${_manual}"
    RESULT_VARIABLE _render_result
    OUTPUT_VARIABLE _rendered
    ERROR_VARIABLE _render_stderr)
else()
  message(STATUS "No mandoc or groff executable found; skipping rendering check")
  return()
endif()

if(NOT _render_result EQUAL 0)
  message(FATAL_ERROR
    "Manual-page rendering failed (${_render_result}): ${_render_stderr}")
endif()
string(ASCII 8 _backspace)
string(REGEX REPLACE ".${_backspace}" "" _rendered_plain "${_rendered}")
foreach(_section IN ITEMS NAME SYNOPSIS DESCRIPTION)
  if(NOT _rendered_plain MATCHES "(^|\n)[ \t]*${_section}([ \t]|\n)")
    message(FATAL_ERROR
      "Rendered manual page lacks the ${_section} section")
  endif()
endforeach()

message(STATUS "Verified installed manual page: ${_manual}")
