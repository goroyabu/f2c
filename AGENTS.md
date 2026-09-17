# Repository Agent Guidance

## Scope

This repository maintains a reproducible CMake-based build, install, package,
and test workflow for upstream Netlib `f2c` and `libf2c`. Focus changes on
maintenance, portability, packaging, documentation, and verification. Do not
add new Fortran language features to the upstream translator.

## Canonical Guidance

- Read `README.md` for supported user workflows and current limitations.
- Follow `CONTRIBUTING.md` for development, verification, pull request,
  versioning, and release policy.
- Follow `tests/README.md` when adding or changing test cases.
- Follow `SECURITY.md` for vulnerability-reporting scope and procedure.
- Use repository templates for Issues and pull requests.

Do not duplicate detailed procedures from those files here. If behavior or
policy changes, update its canonical document.

## Repository Boundaries

- Keep tracked shared documentation, code comments, commits, Issues, and pull
  requests in English.
- Treat extracted sources under `build/vendor`, generated files under
  `build/generated`, downloaded archives, build trees, and staging prefixes as
  untracked artifacts unless a reviewed change explicitly says otherwise.
- Make upstream compatibility changes reproducible in repository-owned build
  logic rather than by editing generated or extracted copies.
- Preserve public package interfaces where practical, especially `f2c`,
  `f2c_runtime`, `f2c::f2c`, and `f2c::f2c_runtime`.
- Keep long-lived documentation self-contained; use Issues and pull requests
  for discussion and history, not as substitutes for the current contract.

## Change and Verification Discipline

- Keep changes narrow and do not revert unrelated user work.
- Run checks proportional to the affected behavior and report what was
  actually verified, including relevant limitations.
- When user-facing workflows, installed interfaces, source acquisition, or
  repository layout change, update the corresponding documentation and
  executable verification path together.
- Do not describe an unverified platform or workflow as supported.
