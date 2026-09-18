if(NOT DEFINED BUILD_DIR OR BUILD_DIR STREQUAL "")
  message(FATAL_ERROR "BUILD_DIR is required")
endif()

if(NOT DEFINED INSTALL_PREFIX OR INSTALL_PREFIX STREQUAL "")
  message(FATAL_ERROR "INSTALL_PREFIX is required")
endif()

if(NOT DEFINED MAN_INSTALL_DIR OR MAN_INSTALL_DIR STREQUAL "")
  set(MAN_INSTALL_DIR "share/man")
endif()

set(_manual "${INSTALL_PREFIX}/${MAN_INSTALL_DIR}/man1/f2c.1")
set(_sentinel "${INSTALL_PREFIX}/uninstall-sentinel.txt")
if(NOT EXISTS "${_manual}")
  message(FATAL_ERROR "Manual page is missing before uninstall: ${_manual}")
endif()
file(WRITE "${_sentinel}" "This file is not managed by the f2c installation.\n")

execute_process(
  COMMAND "${CMAKE_COMMAND}" --build "${BUILD_DIR}" --target uninstall
  RESULT_VARIABLE _uninstall_result
  OUTPUT_VARIABLE _uninstall_stdout
  ERROR_VARIABLE _uninstall_stderr)
if(NOT _uninstall_result EQUAL 0)
  message(FATAL_ERROR
    "Uninstall failed (${_uninstall_result}):\n"
    "${_uninstall_stdout}\n${_uninstall_stderr}")
endif()

if(EXISTS "${_manual}")
  message(FATAL_ERROR "Uninstall did not remove the manual page: ${_manual}")
endif()
if(NOT EXISTS "${_sentinel}")
  message(FATAL_ERROR "Uninstall removed an unrelated file: ${_sentinel}")
endif()

message(STATUS "Verified uninstall behavior for: ${_manual}")
