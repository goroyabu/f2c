# f2c CMake Build

This repository provides a CMake-based build, test, install, and package
workflow for the upstream **f2c** Fortran-to-C converter and its **libf2c**
runtime library.

It does not replace or extend the upstream Fortran translator. The project
focuses on maintainability, portability, reproducible source acquisition, and
downstream CMake integration.

## What This Repository Provides

- The `f2c` command-line converter
- The static `libf2c` runtime library
- The public `f2c.h` header
- An installed CMake package with the `f2c::f2c_runtime` target
- End-to-end converter/runtime smoke tests
- Linux and macOS CI with GCC, Clang, AppleClang, and sanitizer coverage
- Online source acquisition by default, with an optional offline workflow

Upstream source archives are downloaded from
[Netlib](https://www.netlib.org/f2c/) during configuration unless archives with
the expected filenames are available locally.

## Quick Start

### Prerequisites

- CMake 3.20 or later
- A C compiler such as GCC, Clang, or AppleClang
- A build tool such as Ninja or Make
- Network access during the first configuration, unless local archives are
  provided

Run the following commands from the repository root:

```bash
cmake -S . -B build -DBUILD_TESTING=ON
cmake --build build --parallel
ctest --test-dir build --output-on-failure
```

Network fetching is enabled by default with `NET_FETCH=ON`. Downloaded
archives are cached under `.cache/downloads/`.

Every selected upstream archive is checked against its pinned SHA256 value,
whether it is supplied under `archives/`, reused from the download cache, or
downloaded during configuration. A mismatch stops configuration by default.

For deliberate local experiments with changed upstream contents, the mismatch
can be acknowledged explicitly:

```bash
cmake -S . -B build \
  -DF2C_ALLOW_UNVERIFIED_ARCHIVES=ON
```

This option still calculates and reports the expected and actual hashes, but
continues after the mismatch. It is unsafe for normal builds, CI, or releases.
The setting is stored in the build directory's CMake cache; return to strict
verification explicitly when the experiment is complete:

```bash
cmake -S . -B build \
  -DF2C_ALLOW_UNVERIFIED_ARCHIVES=OFF
```

The option does not allow missing files or download failures to be ignored.

### Install

Install to a user-local prefix:

```bash
cmake --install build --prefix "$HOME/.local"
```

This installs the following primary artifacts on conventional Unix systems:

```text
$HOME/.local/bin/f2c
$HOME/.local/include/f2c.h
$HOME/.local/lib/libf2c.a
$HOME/.local/lib/cmake/f2c/
```

If `$HOME/.local/bin` is not already on `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Confirm that the installed converter is available:

```bash
command -v f2c
```

### Translate and Run a Small Program

Create a fixed-form Fortran source file named `hello.f`:

```fortran
      PROGRAM HELLO
      PRINT *, 'HELLO'
      END
```

Translate it to C:

```bash
f2c hello.f
```

The command writes `hello.c` in the current directory. Compile the generated C
source and link it with `libf2c` and the platform math library:

```bash
cc hello.c \
  -I"$HOME/.local/include" \
  -L"$HOME/.local/lib" \
  -lf2c -lm \
  -o hello
./hello
```

Expected output:

```text
 HELLO
```

For the complete f2c command-line reference, see the
[upstream f2c manual](https://www.netlib.org/f2c/f2c.1).

## Using the Installed CMake Package

Downstream CMake projects can consume the installed runtime through its
exported target:

```cmake
cmake_minimum_required(VERSION 3.15)
project(example LANGUAGES C)

find_package(f2c CONFIG REQUIRED)

add_executable(example generated.c)
target_link_libraries(example PRIVATE f2c::f2c_runtime)
```

In this example, `generated.c` is a C source file that has already been
translated by f2c. The installed CMake package does not currently automate the
Fortran-to-C translation step.

When f2c is installed under a non-system prefix, pass that prefix while
configuring the consumer:

```bash
cmake -S . -B build \
  -DCMAKE_PREFIX_PATH="$HOME/.local"
cmake --build build --parallel
```

The imported target supplies the installed `f2c.h` include directory and the
runtime library location. The current package provides a static runtime
library.

## Offline Build

Offline building is supported as a secondary workflow. Place these files under
`archives/`:

```text
archives/src.tgz
archives/libf2c.zip
```

Then explicitly disable network fetching:

```bash
cmake -S . -B build \
  -DNET_FETCH=OFF \
  -DBUILD_TESTING=ON
cmake --build build --parallel
ctest --test-dir build --output-on-failure
```

The archives are not stored in this Git repository.

## Supported Environments

The continuous-integration matrix currently covers:

- Ubuntu 24.04 with GCC
- Ubuntu 24.04 with Clang and AddressSanitizer/UndefinedBehaviorSanitizer
- Ubuntu 22.04 with GCC
- macOS 15 with AppleClang
- macOS 14 with AppleClang

Ninja and Make-style CMake generators are intended to work. CI is the source of
truth for the specific operating-system and compiler combinations verified by
the project.

## Known Limitations

- Windows is currently out of scope.
- The installed runtime is currently a static library; a shared library is not
  provided.
- The primary use case is legacy Fortran 77 input. This project is not a
  replacement for a modern Fortran compiler and does not add newer Fortran
  language features to upstream f2c.
- Cross-compilation is not currently verified because the build runs the
  generated `arithchk` host tool while creating platform-specific headers.

## License

Repository-maintained files are available under the [MIT License](LICENSE).
Downloaded upstream f2c and libf2c sources, and artifacts derived from them,
remain subject to the [upstream notice](THIRD_PARTY_NOTICES.md). The repository
MIT License does not relicense those upstream sources or derived artifacts.
