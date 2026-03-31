# f2c / libf2c – Build & Maintenance Guide

[日本語版 README](README.ja.md) も提供しています。

## 1. Overview

This repository modernizes the legacy Fortran-to-C converter **f2c** and its runtime **libf2c** with a reproducible CMake-based workflow. The goal is maintenance and portability—not new features.

- Prefer local archives when available, otherwise fetch upstream (`Mode B`).
- Keep the source tree clean; all generated files stay under `build/`.
- Target modern toolchains (Clang/GCC, Ninja/Make, etc.).

## 2. Directory Layout

```
.
├─ CMakeLists.txt
├─ cmake/                    # Shared CMake modules (FetchAndUnpack, ProjectConfig …)
├─ archives/                 # Optional local archives (src.tgz, libf2c.zip, …)
├─ tests/                    # Smoke / E2E tests
└─ build/                    # Generated artifacts (ignored by VCS)
   ├─ vendor/                # Extracted upstream sources
   ├─ generated/             # Generated headers (arith.h, f2c.h, …)
   └─ tests/                 # Test work directories
```

Additional cache: `.cache/downloads/` stores auto-fetched archives and can be wiped safely.

## 3. Prerequisites

- CMake 3.20+
- C compiler (GCC/Clang)
- Build tool (Ninja/Make)
- Optional: network tools (`curl`, etc.) when `NET_FETCH=ON`

Tested on macOS and Linux. Windows is not in scope.

## 4. Build & Install

```bash
# Configure (default: NET_FETCH=ON, enable tests)
cmake -S . -B build -DBUILD_TESTING=ON

# Build
cmake --build build --parallel

# Install (user-local)
cmake --install build --prefix "$HOME/.local"

# Uninstall
cmake --build build --target uninstall
```

To install under system paths, run with `sudo` or set an appropriate prefix (user-local is recommended).

## 5. Archive Workflow (Mode B)

1. Place upstream archives under `archives/`:
   - `src.tgz` (f2c sources)
   - `libf2c.zip` (runtime sources)
2. Network fetching is enabled by default (`NET_FETCH=ON`); downloaded files are cached in `.cache/downloads/`.
   Use `-DNET_FETCH=OFF` for strictly offline/reproducible local-archive workflows.

### Pinning SHA256 hashes

```bash
shasum -a 256 archives/src.tgz    | awk '{print $1}'
shasum -a 256 archives/libf2c.zip | awk '{print $1}'
```

Update the values in `CMakeLists.txt`:

```cmake
set(F2C_SRC_SHA256  "<SHA_FOR_src.tgz>")
set(LIBF2C_SHA256   "<SHA_FOR_libf2c.zip>")
```

To verify online fetching:

```bash
mkdir -p /tmp/f2c_archives_backup
mv archives/src.tgz    /tmp/f2c_archives_backup/
mv archives/libf2c.zip /tmp/f2c_archives_backup/

rm -rf build
cmake -S . -B build -DNET_FETCH=ON
cmake --build build
```

## 6. Targets & Cleanup

Primary targets:
- `f2c` – converter executable
- `f2c_runtime` – static runtime library
- `xsum` – optional upstream tool

Auxiliary targets:
- `unpack` – extracts archives via `add_unpack_target`
- `uninstall` – removes installed files
- `clean_downloads` – removes `build/vendor`, `build/generated`, and `.cache/downloads`

Examples:

```bash
cmake --build build --target clean
cmake --build build --target clean_downloads
cmake --build build --target uninstall
```

## 7. Tests

E2E smoke tests live under `tests/cases/<id>_name/`. Each case converts `.f`, links, runs, and checks stdout via regex.

```bash
# All smoke tests
ctest --test-dir build -L smoke --output-on-failure -j$(nproc 2>/dev/null || sysctl -n hw.ncpu)

# Single test
ctest --test-dir build -R '^01_hello$' --output-on-failure

# Re-run failed
ctest --test-dir build --rerun-failed --output-on-failure
```

Add a case by creating `tests/cases/NN_name/` with one fixed-form Fortran source and `expected.txt`, then append `add_f2c_case(...)` to `tests/CMakeLists.txt`. The source filename is arbitrary; `prog.f` is the recommended convention unless a more descriptive name is clearer.

## 8. Troubleshooting (selected)

- `I/O error on c_file`: check write permissions / directories.
- `Warning on line N: missing final end statement`: ensure fixed-form Fortran with trailing newline.
- `file INSTALL cannot copy ... Permission denied`: use `--prefix "$HOME/.local"` or `sudo`.
- `INSTALL(EXPORT) given unknown export`: align `install(TARGETS … EXPORT …)` names.

## 9. Maintenance

- Scope: bug fixes and toolchain support updates only.
- Upstream refresh flow:
  1. Download new archives → place under `archives/`
  2. Update SHA256 in `CMakeLists.txt`
  3. Rebuild/test with `-DNET_FETCH=ON`
  4. Tag/release with notes on hashes and upstream changes
- Target names (e.g., `f2c`, `f2c_runtime`) remain stable for downstream consumers.

## 10. Quick Reference

```bash
# Configure → Build → Install
cmake -S . -B build -DBUILD_TESTING=ON
cmake --build build --parallel
cmake --install build --prefix "$HOME/.local"

# Cleanup / Uninstall
cmake --build build --target clean
cmake --build build --target clean_downloads
cmake --build build --target uninstall

# Tests
ctest --test-dir build -L smoke --output-on-failure -j$(nproc 2>/dev/null || sysctl -n hw.ncpu)
```

---

See [README.ja.md](README.ja.md) for the Japanese version.
