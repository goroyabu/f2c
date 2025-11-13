cmake_minimum_required(VERSION 3.15)
project(f2c LANGUAGES C)

include(GNUInstallDirs)

# Options
option(ENABLE_SANITIZERS "Enable Address/UB sanitizers for dev builds" OFF)
option(NET_FETCH "Allow network fetch if local tarballs are missing" ON)

# Tarball directory (users can override)
set(TARBALL_DIR "${CMAKE_SOURCE_DIR}/third_party/tarballs" CACHE PATH "Local tarballs directory")
file(MAKE_DIRECTORY "${TARBALL_DIR}")

# Upstream locations and checksums (fill real SHA256 values)
set(F2C_SRC_URL   "https://www.netlib.org/f2c/src.tgz")
set(LIBF2C_URL    "https://www.netlib.org/f2c/libf2c.zip")
set(F2C_SRC_SHA256   "b2824a6f7b75ffe0193ce9ba55463191a7af7c2ffe10e371e372451e2b527e09")
set(LIBF2C_SHA256    "cc84253b47b5c036aa1d529332a6c218a39ff71c76974296262b03776f822695")

# Helper: resolve a file from local hint or download to build/_dl
function(resolve_input_file OUT_VAR URL SHA LOCAL_HINT)
  get_filename_component(_name "${URL}" NAME)
  if(EXISTS "${LOCAL_HINT}")
    set(${OUT_VAR} "${LOCAL_HINT}" PARENT_SCOPE)
    return()
  endif()
  if(NET_FETCH)
    set(_dl "${CMAKE_BINARY_DIR}/_dl")
    file(MAKE_DIRECTORY "${_dl}")
    set(_dest "${_dl}/${_name}")
    if(NOT EXISTS "${_dest}")
      message(STATUS "Downloading ${URL} -> ${_dest}")
      file(DOWNLOAD "${URL}" "${_dest}" SHOW_PROGRESS EXPECTED_HASH "SHA256=${SHA}")
    else()
      message(STATUS "Using cached download: ${_dest}")
    endif()
    set(${OUT_VAR} "${_dest}" PARENT_SCOPE)
  else()
    message(FATAL_ERROR "Required file not found and NET_FETCH=OFF. Please place it at: ${LOCAL_HINT}")
  endif()
endfunction()

# Resolve archives (prefer local; else download)
set(F2C_SRC_LOCAL   "${TARBALL_DIR}/src.tgz")
set(LIBF2C_LOCAL    "${TARBALL_DIR}/libf2c.zip")
resolve_input_file(F2C_SRC_TGZ  "${F2C_SRC_URL}"  "${F2C_SRC_SHA256}"  "${F2C_SRC_LOCAL}")
resolve_input_file(LIBF2C_ZIP   "${LIBF2C_URL}"   "${LIBF2C_SHA256}"   "${LIBF2C_LOCAL}")

# Unpack archives into the build tree (vendor directories)
set(VENDOR_ROOT "${CMAKE_BINARY_DIR}/vendor")
set(F2C_SRC_ROOT "${VENDOR_ROOT}/f2c_src")
set(LIBF2C_ROOT  "${VENDOR_ROOT}/libf2c")

add_custom_command(OUTPUT "${F2C_SRC_ROOT}.stamp"
  COMMAND ${CMAKE_COMMAND} -E make_directory "${F2C_SRC_ROOT}"
  COMMAND ${CMAKE_COMMAND} -E chdir "${F2C_SRC_ROOT}" ${CMAKE_COMMAND} -E tar xzf "${F2C_SRC_TGZ}"
  COMMAND ${CMAKE_COMMAND} -E touch "${F2C_SRC_ROOT}.stamp"
  DEPENDS "${F2C_SRC_TGZ}"
  COMMENT "Unpacking src.tgz"
  VERBATIM)

add_custom_command(OUTPUT "${LIBF2C_ROOT}.stamp"
  COMMAND ${CMAKE_COMMAND} -E make_directory "${LIBF2C_ROOT}"
  COMMAND ${CMAKE_COMMAND} -E chdir "${LIBF2C_ROOT}" ${CMAKE_COMMAND} -E tar xvf "${LIBF2C_ZIP}"
  COMMAND ${CMAKE_COMMAND} -E touch "${LIBF2C_ROOT}.stamp"
  DEPENDS "${LIBF2C_ZIP}"
  COMMENT "Unpacking libf2c.zip"
  VERBATIM)

add_custom_target(unpack ALL
  DEPENDS "${F2C_SRC_ROOT}.stamp" "${LIBF2C_ROOT}.stamp")

# Now point to the extracted sources
set(F2C_SRC_DIR "${F2C_SRC_ROOT}/src")
set(LIBF2C_DIR  "${LIBF2C_ROOT}")

# Generated files directory
set(GEN_DIR "${CMAKE_BINARY_DIR}/generated")
file(MAKE_DIRECTORY "${GEN_DIR}")

# ---------------------------------------------------------------------------
# Generate headers needed by the classic build
# ---------------------------------------------------------------------------

add_custom_command(
  OUTPUT "${GEN_DIR}/tokdefs.h"
  COMMAND /bin/sh -c "awk 'NF{printf \"#define %s %d\\n\", $0, NR}' \"${F2C_SRC_DIR}/tokens\" > \"${GEN_DIR}/tokdefs.h\""
  DEPENDS "${F2C_SRC_ROOT}.stamp" "${F2C_SRC_DIR}/tokens"
  COMMENT "Generating tokdefs.h"
  VERBATIM)

add_custom_command(
  OUTPUT "${GEN_DIR}/sysdep.hd"
  COMMAND /bin/sh -c "printf '/*OK*/' > \"${GEN_DIR}/sysdep.hd\""
  DEPENDS "${F2C_SRC_ROOT}.stamp"
  COMMENT "Generating sysdep.hd placeholder"
  VERBATIM)

set_source_files_properties("${LIBF2C_DIR}/arithchk.c" PROPERTIES GENERATED TRUE)
add_executable(arithchk "${LIBF2C_DIR}/arithchk.c")
add_dependencies(arithchk unpack)
target_include_directories(arithchk PRIVATE "${LIBF2C_DIR}")
target_compile_options(arithchk PRIVATE -DNO_FPINIT -DNO_LONG_LONG)

add_custom_command(
  OUTPUT "${GEN_DIR}/arith.h"
  COMMAND /bin/sh -c "\"$<TARGET_FILE:arithchk>\" > \"${GEN_DIR}/arith.h\""
  DEPENDS arithchk "${LIBF2C_ROOT}.stamp"
  COMMENT "Generating arith.h using arithchk"
  VERBATIM)

add_custom_command(
  OUTPUT "${GEN_DIR}/f2c.h"
  COMMAND /bin/sh -c "cat \"${LIBF2C_DIR}/f2c.h0\" \"${LIBF2C_DIR}/f2ch.add\" > \"${GEN_DIR}/f2c.h\""
  DEPENDS "${LIBF2C_ROOT}.stamp" "${LIBF2C_DIR}/f2c.h0" "${LIBF2C_DIR}/f2ch.add"
  COMMENT "Generating f2c.h"
  VERBATIM)

add_custom_command(
  OUTPUT "${GEN_DIR}/signal1.h"
  COMMAND ${CMAKE_COMMAND} -E copy_if_different "${LIBF2C_DIR}/signal1.h0" "${GEN_DIR}/signal1.h"
  DEPENDS "${LIBF2C_ROOT}.stamp" "${LIBF2C_DIR}/signal1.h0"
  COMMENT "Generating signal1.h from signal1.h0"
  VERBATIM)

add_custom_command(
  OUTPUT "${GEN_DIR}/sysdep1.h"
  COMMAND ${CMAKE_COMMAND} -E copy_if_different "${LIBF2C_DIR}/sysdep1.h0" "${GEN_DIR}/sysdep1.h"
  DEPENDS "${LIBF2C_ROOT}.stamp" "${LIBF2C_DIR}/sysdep1.h0"
  COMMENT "Generating sysdep1.h from sysdep1.h0"
  VERBATIM)

# ---------------------------------------------------------------------------
# Build f2c (converter) natively with CMake
# ---------------------------------------------------------------------------
set(F2C_SOURCES
  "${F2C_SRC_DIR}/main.c"
  "${F2C_SRC_DIR}/init.c"
  "${F2C_SRC_DIR}/gram.c"
  "${F2C_SRC_DIR}/lex.c"
  "${F2C_SRC_DIR}/proc.c"
  "${F2C_SRC_DIR}/equiv.c"
  "${F2C_SRC_DIR}/data.c"
  "${F2C_SRC_DIR}/format.c"
  "${F2C_SRC_DIR}/expr.c"
  "${F2C_SRC_DIR}/exec.c"
  "${F2C_SRC_DIR}/intr.c"
  "${F2C_SRC_DIR}/io.c"
  "${F2C_SRC_DIR}/misc.c"
  "${F2C_SRC_DIR}/error.c"
  "${F2C_SRC_DIR}/mem.c"
  "${F2C_SRC_DIR}/names.c"
  "${F2C_SRC_DIR}/output.c"
  "${F2C_SRC_DIR}/p1output.c"
  "${F2C_SRC_DIR}/pread.c"
  "${F2C_SRC_DIR}/put.c"
  "${F2C_SRC_DIR}/putpcc.c"
  "${F2C_SRC_DIR}/vax.c"
  "${F2C_SRC_DIR}/formatdata.c"
  "${F2C_SRC_DIR}/parse_args.c"
  "${F2C_SRC_DIR}/niceprintf.c"
  "${F2C_SRC_DIR}/cds.c"
  "${F2C_SRC_DIR}/sysdep.c"
  "${F2C_SRC_DIR}/version.c"
  "${GEN_DIR}/tokdefs.h"
  "${GEN_DIR}/sysdep.hd"
)
set_source_files_properties(${F2C_SOURCES} PROPERTIES GENERATED TRUE)
add_executable(f2c ${F2C_SOURCES})
add_dependencies(f2c unpack)
target_include_directories(f2c PRIVATE "${F2C_SRC_DIR}" "${GEN_DIR}")
set_target_properties(f2c PROPERTIES OUTPUT_NAME "f2c")

if(ENABLE_SANITIZERS AND CMAKE_C_COMPILER_ID MATCHES "Clang|GNU")
  target_compile_options(f2c PRIVATE -fsanitize=address,undefined -fno-omit-frame-pointer)
  target_link_options(f2c PRIVATE -fsanitize=address,undefined)
endif()

# ---------------------------------------------------------------------------
# Build libf2c (runtime) as a static library (no upstream makefiles)
# ---------------------------------------------------------------------------
set(LIBF2C_SOURCES
  "${LIBF2C_DIR}/f77vers.c" "${LIBF2C_DIR}/i77vers.c" "${LIBF2C_DIR}/main.c"
  "${LIBF2C_DIR}/s_rnge.c" "${LIBF2C_DIR}/abort_.c" "${LIBF2C_DIR}/exit_.c" "${LIBF2C_DIR}/getarg_.c" "${LIBF2C_DIR}/iargc_.c"
  "${LIBF2C_DIR}/getenv_.c" "${LIBF2C_DIR}/signal_.c" "${LIBF2C_DIR}/s_stop.c" "${LIBF2C_DIR}/s_paus.c" "${LIBF2C_DIR}/system_.c"
  "${LIBF2C_DIR}/cabs.c" "${LIBF2C_DIR}/ctype.c" "${LIBF2C_DIR}/derf_.c" "${LIBF2C_DIR}/derfc_.c" "${LIBF2C_DIR}/erf_.c" "${LIBF2C_DIR}/erfc_.c"
  "${LIBF2C_DIR}/sig_die.c" "${LIBF2C_DIR}/uninit.c" "${LIBF2C_DIR}/pow_ci.c" "${LIBF2C_DIR}/pow_dd.c" "${LIBF2C_DIR}/pow_di.c"
  "${LIBF2C_DIR}/pow_hh.c" "${LIBF2C_DIR}/pow_ii.c" "${LIBF2C_DIR}/pow_ri.c" "${LIBF2C_DIR}/pow_zi.c" "${LIBF2C_DIR}/pow_zz.c"
  "${LIBF2C_DIR}/c_abs.c" "${LIBF2C_DIR}/c_cos.c" "${LIBF2C_DIR}/c_div.c" "${LIBF2C_DIR}/c_exp.c" "${LIBF2C_DIR}/c_log.c" "${LIBF2C_DIR}/c_sin.c" "${LIBF2C_DIR}/c_sqrt.c"
  "${LIBF2C_DIR}/z_abs.c" "${LIBF2C_DIR}/z_cos.c" "${LIBF2C_DIR}/z_div.c" "${LIBF2C_DIR}/z_exp.c" "${LIBF2C_DIR}/z_log.c" "${LIBF2C_DIR}/z_sin.c" "${LIBF2C_DIR}/z_sqrt.c"
  "${LIBF2C_DIR}/r_abs.c" "${LIBF2C_DIR}/r_acos.c" "${LIBF2C_DIR}/r_asin.c" "${LIBF2C_DIR}/r_atan.c" "${LIBF2C_DIR}/r_atn2.c"
  "${LIBF2C_DIR}/r_cnjg.c" "${LIBF2C_DIR}/r_cos.c" "${LIBF2C_DIR}/r_cosh.c" "${LIBF2C_DIR}/r_dim.c" "${LIBF2C_DIR}/r_exp.c" "${LIBF2C_DIR}/r_imag.c"
  "${LIBF2C_DIR}/r_int.c" "${LIBF2C_DIR}/r_lg10.c" "${LIBF2C_DIR}/r_log.c" "${LIBF2C_DIR}/r_mod.c" "${LIBF2C_DIR}/r_nint.c" "${LIBF2C_DIR}/r_sign.c"
  "${LIBF2C_DIR}/r_sin.c" "${LIBF2C_DIR}/r_sinh.c" "${LIBF2C_DIR}/r_sqrt.c" "${LIBF2C_DIR}/r_tan.c" "${LIBF2C_DIR}/r_tanh.c"
  "${LIBF2C_DIR}/d_abs.c" "${LIBF2C_DIR}/d_acos.c" "${LIBF2C_DIR}/d_asin.c" "${LIBF2C_DIR}/d_atan.c" "${LIBF2C_DIR}/d_atn2.c"
  "${LIBF2C_DIR}/d_cnjg.c" "${LIBF2C_DIR}/d_cos.c" "${LIBF2C_DIR}/d_cosh.c" "${LIBF2C_DIR}/d_dim.c" "${LIBF2C_DIR}/d_exp.c" "${LIBF2C_DIR}/d_imag.c"
  "${LIBF2C_DIR}/d_int.c" "${LIBF2C_DIR}/d_lg10.c" "${LIBF2C_DIR}/d_log.c" "${LIBF2C_DIR}/d_mod.c" "${LIBF2C_DIR}/d_nint.c" "${LIBF2C_DIR}/d_prod.c" "${LIBF2C_DIR}/d_sign.c"
  "${LIBF2C_DIR}/d_sin.c" "${LIBF2C_DIR}/d_sinh.c" "${LIBF2C_DIR}/d_sqrt.c" "${LIBF2C_DIR}/d_tan.c" "${LIBF2C_DIR}/d_tanh.c"
  "${LIBF2C_DIR}/i_abs.c" "${LIBF2C_DIR}/i_dim.c" "${LIBF2C_DIR}/i_dnnt.c" "${LIBF2C_DIR}/i_indx.c" "${LIBF2C_DIR}/i_len.c"
  "${LIBF2C_DIR}/i_mod.c" "${LIBF2C_DIR}/i_nint.c" "${LIBF2C_DIR}/i_sign.c"
  "${LIBF2C_DIR}/lbitbits.c" "${LIBF2C_DIR}/lbitshft.c"
  "${LIBF2C_DIR}/h_abs.c" "${LIBF2C_DIR}/h_dim.c" "${LIBF2C_DIR}/h_dnnt.c" "${LIBF2C_DIR}/h_indx.c" "${LIBF2C_DIR}/h_len.c" "${LIBF2C_DIR}/h_mod.c" "${LIBF2C_DIR}/h_nint.c" "${LIBF2C_DIR}/h_sign.c"
  "${LIBF2C_DIR}/l_ge.c" "${LIBF2C_DIR}/l_gt.c" "${LIBF2C_DIR}/l_le.c" "${LIBF2C_DIR}/l_lt.c" "${LIBF2C_DIR}/hl_ge.c" "${LIBF2C_DIR}/hl_gt.c" "${LIBF2C_DIR}/hl_le.c" "${LIBF2C_DIR}/hl_lt.c"
  "${LIBF2C_DIR}/ef1asc_.c" "${LIBF2C_DIR}/ef1cmc_.c" "${LIBF2C_DIR}/f77_aloc.c" "${LIBF2C_DIR}/s_cat.c" "${LIBF2C_DIR}/s_cmp.c" "${LIBF2C_DIR}/s_copy.c"
  "${LIBF2C_DIR}/backspac.c" "${LIBF2C_DIR}/close.c" "${LIBF2C_DIR}/dfe.c" "${LIBF2C_DIR}/dolio.c" "${LIBF2C_DIR}/due.c" "${LIBF2C_DIR}/endfile.c" "${LIBF2C_DIR}/err.c" "${LIBF2C_DIR}/fmt.c"
  "${LIBF2C_DIR}/fmtlib.c" "${LIBF2C_DIR}/ftell_.c" "${LIBF2C_DIR}/iio.c" "${LIBF2C_DIR}/ilnw.c" "${LIBF2C_DIR}/inquire.c" "${LIBF2C_DIR}/lread.c" "${LIBF2C_DIR}/lwrite.c" "${LIBF2C_DIR}/open.c"
  "${LIBF2C_DIR}/rdfmt.c" "${LIBF2C_DIR}/rewind.c" "${LIBF2C_DIR}/rsfe.c" "${LIBF2C_DIR}/rsli.c" "${LIBF2C_DIR}/rsne.c" "${LIBF2C_DIR}/sfe.c" "${LIBF2C_DIR}/sue.c" "${LIBF2C_DIR}/typesize.c"
  "${LIBF2C_DIR}/uio.c" "${LIBF2C_DIR}/util.c" "${LIBF2C_DIR}/wref.c" "${LIBF2C_DIR}/wrtfmt.c" "${LIBF2C_DIR}/wsfe.c" "${LIBF2C_DIR}/wsle.c" "${LIBF2C_DIR}/wsne.c" "${LIBF2C_DIR}/xwsne.c"
  "${LIBF2C_DIR}/dtime_.c" "${LIBF2C_DIR}/etime_.c"
  # optional extras:
  # "${LIBF2C_DIR}/pow_qq.c" "${LIBF2C_DIR}/qbitbits.c" "${LIBF2C_DIR}/qbitshft.c" "${LIBF2C_DIR}/ftell64_.c"
  "${GEN_DIR}/arith.h"
  "${GEN_DIR}/f2c.h"
  "${GEN_DIR}/signal1.h"
  "${GEN_DIR}/sysdep1.h"
)
set_source_files_properties(${LIBF2C_SOURCES} PROPERTIES GENERATED TRUE)
add_library(f2c_runtime STATIC ${LIBF2C_SOURCES})
add_dependencies(f2c_runtime unpack)
target_include_directories(f2c_runtime PRIVATE "${LIBF2C_DIR}" "${GEN_DIR}")
target_compile_definitions(f2c_runtime PRIVATE Skip_f2c_Undefs)
set_target_properties(f2c_runtime PROPERTIES OUTPUT_NAME "f2c")

if(ENABLE_SANITIZERS AND CMAKE_C_COMPILER_ID MATCHES "Clang|GNU")
  target_compile_options(f2c_runtime PRIVATE -fsanitize=address,undefined -fno-omit-frame-pointer)
  target_link_options(f2c_runtime PRIVATE -fsanitize=address,undefined)
endif()

# ---------------------------------------------------------------------------
# Optional: xsum generation (convenience check; not required for build)
# ---------------------------------------------------------------------------
set_source_files_properties("${F2C_SRC_DIR}/xsum.c" PROPERTIES GENERATED TRUE)
add_executable(xsum "${F2C_SRC_DIR}/xsum.c")
add_dependencies(xsum unpack)
add_custom_command(
  OUTPUT "${CMAKE_BINARY_DIR}/xsum.out"
  COMMAND ${CMAKE_COMMAND} -E chdir "${F2C_SRC_DIR}" $<TARGET_FILE:xsum> Notice README cds.c data.c defines.h defs.h equiv.c error.c exec.c expr.c f2c.1 f2c.1t f2c.h format.c format.h formatdata.c ftypes.h gram.c gram.dcl gram.exec gram.expr gram.head gram.io init.c intr.c io.c iob.h lex.c machdefs.h main.c makefile.u makefile.vc malloc.c mem.c memset.c misc.c names.c names.h niceprintf.c niceprintf.h output.c output.h p1defs.h p1output.c parse.h parse_args.c pccdefs.h pread.c proc.c put.c putpcc.c sysdep.c sysdep.h sysdeptest.c tokens usignal.h vax.c version.c xsum.c > "${CMAKE_BINARY_DIR}/xsum1.out"
  COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_BINARY_DIR}/xsum1.out" "${CMAKE_BINARY_DIR}/xsum.out"
  DEPENDS xsum
  COMMENT "Generating xsum.out (optional)"
  VERBATIM)
add_custom_target(check_xsum DEPENDS "${CMAKE_BINARY_DIR}/xsum.out")

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------
install(TARGETS f2c EXPORT f2cTargets RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(TARGETS f2c_runtime EXPORT f2cTargets ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(FILES "${GEN_DIR}/f2c.h" DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

# Export stubs for future packaging

install(EXPORT f2cTargets NAMESPACE f2c:: DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/f2c)

# ---------------------------------------------------------------------------
# Uninstall target
# ---------------------------------------------------------------------------
set(_UNINSTALL_IN "${CMAKE_SOURCE_DIR}/cmake_uninstall.cmake.in")
if(NOT EXISTS "${_UNINSTALL_IN}")
  set(_UNINSTALL_IN "${CMAKE_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in")
endif()
if(EXISTS "${_UNINSTALL_IN}")
  configure_file("${_UNINSTALL_IN}" "${CMAKE_BINARY_DIR}/cmake_uninstall.cmake" IMMEDIATE @ONLY)
  add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P "${CMAKE_BINARY_DIR}/cmake_uninstall.cmake"
    COMMENT "Uninstall previously installed files")
else()
  message(WARNING "cmake_uninstall.cmake.in not found; 'uninstall' target is disabled.")
endif()

# ---------------------------------------------------------------------------
# Cleaning policy
# - Default `clean` removes build artefacts only. It DOES NOT remove:
#   * local tarballs in ${TARBALL_DIR}
#   * downloaded tarballs in ${CMAKE_BINARY_DIR}/_dl (not declared as outputs)
# Provide an explicit "distclean" target for full reset (keeps _dl by default).
# ---------------------------------------------------------------------------
add_custom_target(distclean
  COMMAND ${CMAKE_COMMAND} -E rm -rf "${CMAKE_BINARY_DIR}/vendor" "${CMAKE_BINARY_DIR}/generated"
  COMMENT "Deep clean build products (keeps tarballs and downloaded cache)")

# Optional: purge even the download cache (use with care)
add_custom_target(purge
  COMMAND ${CMAKE_COMMAND} -E rm -rf "${CMAKE_BINARY_DIR}/vendor" "${CMAKE_BINARY_DIR}/generated" "${CMAKE_BINARY_DIR}/_dl"
  COMMENT "Remove build products and download cache (tarballs in ${TARBALL_DIR} are preserved)")

# ---------------------------------------------------------------------------
# Help target
# ---------------------------------------------------------------------------
add_custom_target(help_targets
  COMMAND ${CMAKE_COMMAND} -E echo ""
  COMMAND ${CMAKE_COMMAND} -E echo "Targets:"
  COMMAND ${CMAKE_COMMAND} -E echo "  help_targets- Show this help."
  COMMAND ${CMAKE_COMMAND} -E echo "  clean       - Remove build artifacts (keeps tar/zip and _dl cache)."
  COMMAND ${CMAKE_COMMAND} -E echo "  distclean   - Remove vendor/ and generated/ in build tree."
  COMMAND ${CMAKE_COMMAND} -E echo "  purge       - Remove vendor/, generated/, and _dl/ cache."
  COMMAND ${CMAKE_COMMAND} -E echo "  check_xsum  - Generate xsum.out for upstream consistency."
  COMMAND ${CMAKE_COMMAND} -E echo "  install     - Install built artifacts."
  COMMAND ${CMAKE_COMMAND} -E echo "  uninstall   - Uninstall previously installed files."
  COMMAND ${CMAKE_COMMAND} -E echo ""
  COMMAND ${CMAKE_COMMAND} -E echo "Options:"
  COMMAND ${CMAKE_COMMAND} -E echo "  -DNET_FETCH=ON|OFF       (current: ${NET_FETCH})"
  COMMAND ${CMAKE_COMMAND} -E echo "  -DTARBALL_DIR=/path      (current: ${TARBALL_DIR})"
  VERBATIM)

# --- Enable tests ---
include(CTest)
if(BUILD_TESTING)
  add_subdirectory(tests)
endif()