# Test Contracts

This directory verifies documented and deliberately selected behavior of the
`f2c` converter and translated programs. The suite is risk-based: it does not
claim complete Fortran 77 conformance or exhaustive coverage of every command-
line option.

Package-level downstream acceptance is covered separately by the example under
`examples/cmake`. This directory focuses on converter contracts and the
behavior of small translated programs.

## Contract Sources

Tests use the following evidence, in descending order of authority:

1. The upstream [`f2c` manual](https://www.netlib.org/f2c/f2c.1).
2. Upstream README files and interface headers.
3. The upstream source archive selected and verified by
   [`CMakeLists.txt`](../CMakeLists.txt).
4. Behavior reproduced with the currently pinned upstream source.
5. Historical change-log examples, only after their current relevance is
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

The status column distinguishes existing coverage from cases planned by
issue #34. The implementation may combine compatible assertions in one test,
but each contract remains independently identifiable.

| Contract | Layer | Basis | Observable oracle | Status |
| --- | --- | --- | --- | --- |
| A simple main program translates, compiles, links with `libf2c`, and prints a string. | Pipeline sentinel | Existing `01_hello` case; upstream manual description of generated C and runtime linkage. | Translation, compilation, linkage, and execution succeed; exit status is zero; stdout is exactly ` HELLO\n`; stderr is empty during execution. | Existing; migrate to the contract harness. |
| Integer assignment survives translation and runtime output. | Pipeline sentinel | Existing `02_print_int` case. | All pipeline phases succeed; exit status is zero; stdout is exactly ` 42\n`; stderr is empty during execution. | Existing; migrate to the contract harness. |
| A simple integer `DO` loop preserves its result. | Pipeline sentinel | Existing `03_sum` case. | All pipeline phases succeed; exit status is zero; stdout is exactly ` 15\n`; stderr is empty during execution. | Existing; migrate to the contract harness. |
| A named `.f` input produces a same-basename `.c` file in the converter working directory. | CLI, normal file path | Upstream manual, DESCRIPTION and FILES; current upstream behavior. | Exit status is zero; stdout is empty; the expected C file exists and is nonempty; no unexpected C file is created; the input file is unchanged. Translation diagnostics are captured separately. | Planned in issue #34. |
| With no named Fortran input, `f2c` reads standard input and writes generated C to standard output. | CLI, alternate input/output path | Upstream manual, DESCRIPTION; current upstream behavior. | Exit status is zero; stdout is nonempty generated C; the converter creates no separate `.c` file as a side effect; the source used to supply stdin is unchanged; diagnostics remain separate on stderr. Compile the captured stdout rather than comparing a full-file snapshot. | Planned in issue #34. |
| A positional input whose name does not end in `.f` or `.F` is rejected. | CLI, error path | Upstream manual input-name contract; validation in the pinned upstream `main.c`; current upstream behavior. | Exit status is one; stdout is empty; stderr reports the rejected filename; no C output is created; the input file, if present, is unchanged. | Planned in issue #34. |

For progress diagnostics emitted during successful translation, the harness
captures stderr independently but does not treat incidental spacing or complete
procedure-progress wording as a stable public interface. Error tests assert the
specific diagnostic meaning needed to identify the rejected input.

## Initial Coverage Boundary

Issue #34 establishes the harness and representative coverage for a normal CLI
path, an alternate input/output path, and an error path. It also preserves the
intent of the three existing pipeline sentinels.

The following areas remain deferred to the parent test-strategy issue and must
not be inferred as covered by this initial matrix:

- multiple named inputs and output-directory selection;
- prototype generation and source-format options;
- broader warning, diagnostic, and malformed-Fortran behavior;
- stable generated-C ABI and calling-convention invariants;
- systematic numeric, array, procedure, character, complex, shared-state, and
  file-I/O semantics;
- differential checks against another Fortran compiler; and
- historical upstream regression candidates.

Coverage is evaluated by documented behavior category rather than by a target
source-line percentage. Future cases should extend this matrix and state
whether an area is covered, partially covered, deferred, or intentionally out
of scope.
