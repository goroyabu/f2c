# Test Contracts

This directory verifies documented and deliberately selected behavior of the
`f2c` converter and translated programs. The suite is risk-based: it does not
claim complete Fortran 77 conformance or exhaustive coverage of every command-
line option.

Package-level downstream acceptance is covered separately by the example under
`examples/cmake`. This directory focuses on converter contracts and the
behavior of small translated programs.

## Suite Scope

This suite is a maintenance safety net for the upstream `f2c` version packaged
by this repository. Its coverage describes behavior that is continuously
verified here; an untested feature is not necessarily unsupported by upstream
`f2c`.

The suite selects small, portable contracts from five functional domains:

1. scalar types, expressions, assignment, conversion, and control flow;
2. arrays, indexing, initialization, and data layout;
3. program units, procedures, argument passing, and shared or saved state;
4. character and complex values and representative intrinsic functions; and
5. formatted and file I/O and the associated runtime behavior.

Source form, diagnostics, command-line options, generated-C interface
invariants, and portability are cross-cutting concerns rather than additional
language domains.

A case is a candidate for this suite when it covers a central documented
behavior, a translation or runtime boundary with meaningful regression risk, a
pattern common in existing Fortran code, or behavior that repository build and
packaging changes could break. The result must also have a stable oracle in the
supported CI environments.

Within each domain, prefer:

- one minimal normal case;
- one or two important boundary cases; and
- a small number of cases at high-risk intersections between domains.

Do not construct the Cartesian product of types, operators, control forms,
array forms, procedure forms, and I/O modes. Add a cross-domain case only when
the interaction has a distinct translation, ABI, or runtime risk.

The following are outside the suite's completeness claim:

- proof of full Fortran 77 conformance;
- exhaustive syntax, option, error, or feature-combination coverage;
- source-line coverage targets for upstream translator code;
- complete generated-C snapshots or incidental formatting details;
- processor-dependent numeric, storage, or I/O results without a portable
  oracle; and
- historical regressions or extensions whose current relevance has not been
  established.

Documented `f2c` extensions, uncommon language features, differential checks,
and historical regression candidates may be added selectively when they are
reproducible, relevant to the pinned upstream version, and maintainable across
supported environments.

Coverage is considered representative when every functional domain has useful
baseline coverage, important cross-domain boundaries are exercised, and every
known omission is recorded as partial, deferred, or intentionally out of
scope. It is not measured by a fixed test count or a claim of complete compiler
correctness.

## Repository Layout

Fixtures under `cases` are organized by verification layer and semantic domain:

```text
cases/
├── abi/
│   └── basic/
├── cli/
├── pipeline/
│   └── smoke/
└── semantics/
    ├── arrays/
    ├── procedures/
    ├── scalar_control/
    └── shared_state/
```

The `pipeline/smoke` directory contains minimal end-to-end sentinels that keep
the translation, C compilation, runtime linkage, and execution path covered.
The `semantics/<domain>` directories contain specification-based contracts for
the functional domains defined above. The `abi` directory contains independent
C callers that verify selected generated-C interface contracts. The `cli`
directory contains input and expected-output fixtures for black-box converter
command tests.

Create a new semantic domain directory only when at least one approved case is
ready to be added. Fixture paths describe organization, not test identity:
CTest names and labels remain stable when a case is moved between directories.

## Contract Sources

Tests use the following evidence, in descending order of authority:

1. The [Fortran 77 standard](https://wg5-fortran.org/ARCHIVE/Fortran77.html)
   for language semantics.
2. The upstream [`f2c` manual](https://www.netlib.org/f2c/f2c.1).
3. The upstream [`f2c` paper](https://www.netlib.org/f2c/f2c.pdf), especially
   its generated-C calling-convention description.
4. Upstream README files and interface headers.
5. The upstream source archive selected and verified by
   [`CMakeLists.txt`](../CMakeLists.txt).
6. Behavior reproduced with the currently pinned upstream source.
7. Historical change-log examples, only after their current relevance is
   established.

Observed behavior alone is not automatically a compatibility contract. When
the documentation and implementation differ, the discrepancy must be reviewed
before a test fixes either behavior as expected.

## Oracle Policy

Each case records independent expectations for the applicable observables:

- process exit status;
- standard output;
- standard error;
- files that must be created;
- files that must not be created;
- preservation of input files; and
- translated-program output.

Deterministic output is compared exactly. Normalization or partial matching is
limited to a contract that explicitly permits variation. Complete generated C
files are not used as golden snapshots because formatting, declarations, and
temporary names may change without changing the supported behavior.

Every case runs in an isolated build-tree directory. A failure should identify
the phase involved: preparation, translation, generated-file validation, C
compilation, linkage, execution, or result comparison.

## Initial Contract Matrix

The status column distinguishes the initial coverage implemented by issue #34
from areas deferred to later work. The implementation may combine compatible
assertions in one test, but each contract remains independently identifiable.

| Contract | Layer | Basis | Observable oracle | Status |
| --- | --- | --- | --- | --- |
| A simple main program translates, compiles, links with `libf2c`, and prints a string. | Pipeline sentinel | Existing `01_hello` case; upstream manual description of generated C and runtime linkage. | Translation, compilation, linkage, and execution succeed; exit status is zero; stdout is exactly ` HELLO\n`; stderr is empty during execution. | Covered by `pipeline.01_hello`. |
| Integer assignment survives translation and runtime output. | Pipeline sentinel | Existing `02_print_int` case. | All pipeline phases succeed; exit status is zero; stdout is exactly ` 42\n`; stderr is empty during execution. | Covered by `pipeline.02_print_int`. |
| A simple integer `DO` loop preserves its result. | Pipeline sentinel | Existing `03_sum` case. | All pipeline phases succeed; exit status is zero; stdout is exactly ` 15\n`; stderr is empty during execution. | Covered by `pipeline.03_sum`. |
| A named `.f` input produces a same-basename `.c` file in the converter working directory. | CLI, normal file path | Upstream manual, DESCRIPTION and FILES; current upstream behavior. | Exit status is zero; stdout is empty; the expected C file exists and is nonempty; no unexpected C file is created; the input file is unchanged. Translation diagnostics are captured separately. | Covered by `cli.file_input`. |
| With no named Fortran input, `f2c` reads standard input and writes generated C to standard output. | CLI, alternate input/output path | Upstream manual, DESCRIPTION; current upstream behavior. | Exit status is zero; stdout is nonempty generated C; the converter creates no separate `.c` file as a side effect; the source used to supply stdin is unchanged; diagnostics remain separate on stderr. Compile the captured stdout rather than comparing a full-file snapshot. | Covered by `cli.stdin_stdout`. |
| A positional input whose name does not end in `.f` or `.F` is rejected. | CLI, error path | Upstream manual input-name contract; validation in the pinned upstream `main.c`; current upstream behavior. | Exit status is one; stdout is empty; stderr reports the rejected filename; no C output is created; the input file, if present, is unchanged. | Covered by `cli.invalid_suffix`. |

For progress diagnostics emitted during successful translation, the harness
captures stderr independently but does not treat incidental spacing or complete
procedure-progress wording as a stable public interface. Error tests assert the
specific diagnostic meaning needed to identify the rejected input.

## Scalar and Control-Flow Contract Matrix

Issue #37 extends the semantic baseline with one primary language contract per
test case. A case may contain multiple inputs or expressions when they are
needed to demonstrate the same contract, but unrelated failure causes remain
separate.

| Contract | Basis | Observable oracle | Status |
| --- | --- | --- | --- |
| Multiplication binds more tightly than addition, while parentheses override the default precedence. | Fortran 77 Sections 6.1.2 and 6.6.3. | `2 + 3 * 4` produces 14 and `(2 + 3) * 4` produces 20. | Covered by `pipeline.04_expr_precedence`. |
| Division of two integer operands produces an integer result. | Fortran 77 Section 6.1.5. | `5 / 2` produces 2. | Covered by `pipeline.05_integer_division`. |
| Assigning a positive non-integral `REAL` value to an `INTEGER` truncates its fractional part. | Fortran 77 Section 10.1. | Assigning 2.5 produces 2. | Covered by `pipeline.06_real_assignment_conversion`. |
| Assigning a positive non-integral `DOUBLE PRECISION` value to an `INTEGER` truncates its fractional part. | Fortran 77 Section 10.1. | Assigning 4.5 produces 4. | Covered by `pipeline.07_double_assignment_conversion`. |
| Block `IF`, `ELSE IF`, and `ELSE` select the matching branch. | Fortran 77 Sections 11.6 through 11.9. | Negative, zero, and positive inputs select branch markers 1, 2, and 3 respectively. | Covered by `pipeline.08_block_if`. |
| A relational and logical expression can control a logical `IF`. | Fortran 77 Sections 6.3, 6.4, and 11.5. | A true expression using `.GT.`, `.AND.`, and `.NOT.` executes its guarded assignment, while a false expression does not. | Covered by `pipeline.09_logical_if`. |
| A `DO` loop accepts a negative increment and visits the descending sequence. | Fortran 77 Sections 11.10.3, 11.10.4, and 11.10.7. | Iterating from 5 to 1 by -2 produces a sum of 9. | Covered by `pipeline.10_do_negative_step`. |
| A `DO` loop whose initial bounds imply zero iterations does not execute its body. | Fortran 77 Sections 11.10.3 and 11.10.4; default `f2c` behavior without `-onetrip`. | Variable bounds from 3 to 1 with the default positive increment leave the count at zero. | Covered by `pipeline.11_do_zero_trip`. |

These cases deliberately use exact integer output. The `REAL` and `DOUBLE
PRECISION` inputs are exactly representable, so the contracts do not require a
floating-point tolerance or depend on formatted floating-point output.

This baseline does not enumerate every arithmetic, relational, or logical
operator or their Cartesian product with all scalar types. Mixed-type operands
within one expression, floating-point rounding boundaries, additional `DO`
increments, and less common control-flow forms remain candidates for later
tests when they address a distinct translation or regression risk.

## Array Contract Matrix

Issue #39 adds baseline coverage for array indexing, declared lower bounds,
element ordering, and static initialization. The two-dimensional ordering case
uses a `DATA` sequence because assigning and reading the same subscripts would
not expose an implementation that used a consistently incorrect layout. A
separate one-dimensional case keeps basic `DATA` initialization independently
diagnosable.

| Contract | Basis | Observable oracle | Status |
| --- | --- | --- | --- |
| Ordinary one-dimensional array elements can be assigned and referenced at each declared subscript. | Fortran 77 Sections 5.2, 5.3, and 5.4. | Assigning distinct values at subscripts 1, 2, and 3 produces exactly `11 22 33`. | Covered by `pipeline.12_array_1d_access`. |
| An explicit lower bound determines the valid subscript values and element mapping. | Fortran 77 Sections 5.2.1 and 5.4. | Assigning distinct values at subscripts -1, 0, and 1 produces exactly `41 42 43`. | Covered by `pipeline.13_array_lower_bound`. |
| Two-dimensional elements follow Fortran array element ordering, with the first subscript varying fastest. | Fortran 77 Sections 5.2.4, 5.2.5, and 9. | Initializing `A(2,2)` with `11, 21, 12, 22` and reading `A(1,1)`, `A(2,1)`, `A(1,2)`, and `A(2,2)` produces exactly `11 21 12 22`. | Covered by `pipeline.14_array_2d_order`. |
| A simple `DATA` value list establishes the initial values of an array in array element order. | Fortran 77 Sections 5.2.4 and 9. | A three-element array initialized with 4, 5, and 6 produces exactly `4 5 6` before any executable assignment. | Covered by `pipeline.15_array_data_init`. |

This baseline does not cover implied-DO initialization, array arguments,
adjustable or assumed-size arrays, ABI-level layout assertions, advanced
shared or overlaid storage beyond the dedicated shared-state matrix, character
arrays, or undefined out-of-range subscripts. These areas remain deferred to
later contract slices where they have a distinct semantic, ABI, or runtime
risk.

## Procedure Contract Matrix

Issue #43 adds baseline coverage for external subroutines, external integer
functions, and scalar and one-dimensional array argument association. Each
case contains one main program and one external procedure so that subroutine,
function, and array-association failures remain independently diagnosable.

| Contract | Basis | Observable oracle | Status |
| --- | --- | --- | --- |
| A scalar actual argument is associated with a scalar dummy argument, and a definition made by the subroutine is visible to the caller after return. | Fortran 77 Sections 15.6 and 15.9.3.2. | Starting with 7 and adding 5 through `ADD5(VALUE)` produces exactly `12`. | Covered by `pipeline.16_subroutine_scalar_argument`. |
| An external integer function receives an argument and supplies the function value used by the calling expression. | Fortran 77 Sections 15.2 and 15.5. | Evaluating `TWICE(7)` produces exactly `14`. | Covered by `pipeline.17_integer_function`. |
| A one-dimensional actual array is associated with a dummy array, and element definitions made by the subroutine are visible to the caller. | Fortran 77 Section 15.9.3.3. | Starting with 10, 20, and 30 and adding 1, 2, and 3 through `BUMP3(A)` produces exactly `11 22 33`. | Covered by `pipeline.18_array_argument`. |

These are Fortran-level observable contracts. They do not claim a stable C
calling convention, generated symbol spelling, or exact generated-C form.
Adjustable and assumed-size arrays, procedure arguments, statement functions,
`ENTRY`, alternate returns, recursion, character hidden-length arguments, and
complex function results remain deferred to later contract slices where they
have a distinct semantic, ABI, or maintenance risk.

## Shared and Saved State Contract Matrix

Issue #47 adds representative storage-association and persistence contracts.
Each fixture keeps all of its program units in one Fortran source file, so
these cases verify Fortran-visible behavior without deciding how independently
translated sources should coordinate ownership of common storage.

| Contract | Basis | Observable oracle | Status |
| --- | --- | --- | --- |
| A named common block associates its storage sequence across program units even when their local variable names differ. | Fortran 77 Section 8.3; upstream `f2c` paper. | Starting with 10 and 20, a subroutine viewing the same `/COUNTS/` block as `FIRST` and `SECOND` adds 1 and 2; the main program observes exactly `11 22`. | Covered by `pipeline.19_named_common`. |
| A local variable specified by `SAVE` retains its value across calls when ordinary locals are automatic. | Fortran 77 Section 8.9; upstream `f2c` manual description of `-a`. | Three calls, with explicit initialization on the first, produce exactly `1 2 3`; a narrow generated-C check confirms static storage for `COUNTER`. | Covered by `pipeline.20_saved_local`. |
| Same-type `EQUIVALENCE` associates an integer scalar with an integer array element. | Fortran 77 Section 8.2; upstream `f2c` paper. | Assigning 99 through a scalar associated with `VALUES(2)` changes the array output from `11 22 33` to exactly `11 99 33`. | Covered by `pipeline.21_equivalence_array_element`. |
| A `BLOCK DATA` program unit initializes a named common block before the main program observes it. | Fortran 77 Sections 8.3 and 16; upstream `f2c` paper. | Initializing `/LIMITS/ LOW, HIGH` through `BLOCK DATA` produces exactly `3 9`. | Covered by `pipeline.22_block_data_common_init`. |

The saved-local case passes `-a` only for that conversion. Its generated-C
assertion checks the single storage-duration invariant `static integer
counter;`; it is not a complete generated-C snapshot and does not make
formatting or unrelated declarations part of the contract.

The following shared-state areas remain deferred:

- blank common;
- common declarations that differ in type, size, or alignment;
- cross-type `EQUIVALENCE`, including character, complex, or other
  representation-dependent associations;
- common blocks extended through equivalence association;
- complicated interactions among `COMMON`, `EQUIVALENCE`, `DATA`, and
  Hollerith values;
- direct C access to generated common-block objects or assertions about exact
  generated structures, unions, macros, padding, and layout;
- the `-p` option;
- persistence and lifetime edge cases for named common blocks specified by
  `SAVE`; and
- independently translated source files sharing a common block, including
  common-definition ownership, which is tracked by Issue #48.

## Basic Generated-C ABI Contract Matrix

Issue #45 verifies a deliberately small set of generated-C interfaces from an
independent C caller. Each harness writes its declaration by hand using types
from `f2c.h`; it does not consume a prototype generated by the same converter.
This avoids using the implementation under test as its own interface oracle.

| Contract | Basis | Observable oracle | Status |
| --- | --- | --- | --- |
| An external Fortran subroutine is exposed as a lowercase symbol with a trailing underscore and receives a scalar integer argument by address. | Upstream `f2c` paper, Section 2; `f2c.h`. | Calling `incr_` through `extern int incr_(integer *)` changes 7 to 12. | Covered by `abi.scalar_subroutine`. |
| An external Fortran integer function returns `integer` directly and receives its argument by address. | Upstream `f2c` paper, Section 2; `f2c.h`. | Calling `twice_` through `extern integer twice_(integer *)` with 7 returns 14. | Covered by `abi.integer_function`. |
| With the default converter mode, an external Fortran `REAL` function uses the `E_f` return convention declared by `f2c.h`. | Upstream `f2c` paper, Section 2; `f2c.h`; default invocation without `-R`. | Calling `half_` through `extern E_f half_(real *)` with 6 returns 3. | Covered by `abi.default_real_function`. |
| A two-dimensional Fortran array passed to C uses contiguous column-major element order. | Fortran 77 Sections 5.2.4 and 15.9.3.3; upstream `f2c` paper, Section 2. | A Fortran assignment to `A(2,3)` changes C buffer offset 5 to 99 and leaves the other five elements unchanged. | Covered by `abi.matrix_argument`. |

The tests assert compilation, linkage, execution, and the values crossing the
interface. They deliberately do not compare complete generated C output,
because local identifiers, formatting, and other incidental text are not ABI
contracts.

Character hidden-length arguments, complex values, and shared state remain
separate roadmap areas. The `-R` return-mode option, names that already contain
underscores, alternate returns, and procedure arguments will be reconsidered
after this baseline according to their distinct compatibility risk.

## Initial Coverage Boundary

Issue #34 establishes the harness and representative coverage for a normal CLI
path, an alternate input/output path, and an error path. It also preserves the
intent of the three existing pipeline sentinels.

The following areas remain deferred to the parent test-strategy issue and must
not be inferred as covered by this initial matrix:

- multiple named inputs and output-directory selection;
- prototype generation and source-format options;
- broader warning, diagnostic, and malformed-Fortran behavior;
- generated-C ABI variants beyond the basic contracts listed above;
- broader numeric semantics, advanced array behavior, advanced procedure and
  shared-state behavior, character and complex values, and file-I/O semantics;
- differential checks against another Fortran compiler; and
- historical upstream regression candidates.

Coverage is evaluated by documented behavior category rather than by a target
source-line percentage. Future cases should extend this matrix and state
whether an area is covered, partially covered, deferred, or intentionally out
of scope.
