# Contributing

Thank you for considering a contribution to this project. This repository
maintains a reproducible CMake-based build, install, package, and test workflow
for the upstream Netlib `f2c` converter and `libf2c` runtime.

## Project Scope

Appropriate contributions include:

- build-system and installation improvements;
- portability and compiler compatibility fixes;
- packaging and downstream-consumer integration;
- source-acquisition and integrity improvements;
- CI and test coverage;
- documentation corrections and maintenance; and
- updates needed to incorporate a reviewed upstream f2c release.

This repository does not develop new Fortran language features or replace the
upstream f2c translator. Changes to upstream translation behavior should first
be discussed with or contributed to the upstream project unless a local change
is necessary to maintain this repository's build or packaging workflow.

Windows, shared-library builds, and cross-compilation are not currently part of
the verified support contract. Proposals concerning an unsupported environment
should define a maintainable verification strategy rather than assuming that
the environment is already supported.

## Before Making a Change

Search the open Issues before starting substantial work. Use an existing Issue
when it already covers the change, or open a focused proposal when the change
requires a new public interface, support commitment, or design decision.

Use a short imperative title in the form `<area>: <summary>` for Issues and
pull requests. Stable areas include `build`, `docs`, `tests`, `ci`, `release`,
and `meta`.

A separate Issue is not required for every small correction. Straightforward
documentation fixes and similarly narrow maintenance changes may proceed
directly to a pull request.

Keep each pull request focused on one coherent maintenance outcome. Avoid
combining unrelated cleanup or refactoring with the intended change.

## Development Workflow

1. Start from an up-to-date `main` branch.
2. Create a topic branch for the change.
3. Make the smallest complete change that addresses the stated problem.
4. Run the checks relevant to the affected behavior.
5. Open a pull request against `main`.
6. Confirm that the required GitHub checks pass before merging.
7. Merge with a merge commit and delete the topic branch when it is no longer
   needed.

Do not commit normal development changes directly to `main`.

This repository preserves the pull request boundary and its individual commits
in history. Do not squash or rebase a pull request into `main`. Keep commits in
the pull request understandable enough to remain useful after the merge.

Use English for tracked shared documentation, code comments, commit messages,
Issue titles and descriptions, and pull request titles and descriptions.

## Build and Test

The baseline local workflow is:

```bash
cmake -S . -B build -DBUILD_TESTING=ON
cmake --build build --parallel
ctest --test-dir build --output-on-failure
```

Network fetching is enabled by default. To verify the strict offline workflow,
provide the expected archives under `archives/` and configure explicitly with:

```bash
cmake -S . -B build-offline \
  -DNET_FETCH=OFF \
  -DBUILD_TESTING=ON
cmake --build build-offline --parallel
ctest --test-dir build-offline --output-on-failure
```

Run additional checks according to the change:

- installation or exported-target changes should verify a staged installation
  and the downstream project under `examples/cmake`;
- source-acquisition changes should verify both online and strict offline
  configurations;
- generated-code or runtime changes should run the relevant semantic and ABI
  tests; and
- sanitizer, CI, or platform-specific changes should run the closest available
  local equivalent and rely on the GitHub matrix for remaining environments.

If a relevant check cannot be run locally, state that limitation in the pull
request rather than implying that it passed.

Sanitizer builds are diagnostic configurations, not supported installation or
distribution artifacts. Do not use a sanitizer-enabled build as the sole
package-consumer verification unless the supported packaging contract changes.

## Upstream Sources and Generated Files

Do not commit downloaded upstream archives, extracted vendor sources, build
directories, installed staging directories, or generated C files unless a
separate reviewed change explicitly establishes them as tracked artifacts.

Upstream archives are identified by their URL and pinned SHA256 value in the
build configuration. Do not change a pinned hash merely to make an unexpected
archive pass verification. An upstream refresh must review the source change,
version information, notices, and resulting build and test behavior together.

The upstream translator version is parsed from `src/version.c` in the selected,
verified `src.tgz` and exported to CMake consumers as `F2C_UPSTREAM_VERSION`.
When refreshing that archive, verify the focused `upstream_version.*` tests and
the staged `examples/cmake` package test so that the archive metadata, installed
package configuration, and `f2c --version` output remain consistent.

`F2C_ALLOW_UNVERIFIED_ARCHIVES=ON` is limited to deliberate local experiments.
Do not use it as verification for a pull request, CI run, or release. Return the
build directory to strict verification after the experiment.

Generate temporary and translated files in a build directory so that normal
development does not modify the source tree.

## Public Package Compatibility

Treat installed executables, imported targets, headers, and their usage
requirements as user-facing interfaces. Keep the target names `f2c`,
`f2c_runtime`, `f2c::f2c`, and `f2c::f2c_runtime` stable where practical.

When installation, exports, target properties, include paths, link
dependencies, package versions, or relocation behavior change, install to a
clean staging prefix and verify the downstream project under `examples/cmake`.

## Documentation

Update the README when a change affects user-facing build, installation,
package-consumer, or supported-usage instructions. Keep these documented paths
consistent:

- extracted upstream sources are under `build/vendor`;
- generated headers are under `build/generated`;
- `NET_FETCH` is enabled by default; and
- offline-only examples explicitly pass `-DNET_FETCH=OFF`.

Avoid copying complete upstream manuals or maintaining repository-local forks
of upstream documentation when a link or installed upstream document is more
appropriate.

Keep long-lived documentation self-contained. Issues and pull requests record
discussion, decisions, and progress, but a tracked document should state its
current contract or limitation without requiring a specific Issue or pull
request URL for essential context.

Test contributions must follow the scope, case-selection, isolation, and
oracle guidance in [`tests/README.md`](tests/README.md). Keep that detailed
policy in its canonical file rather than duplicating it here.

## CI and Dependency Maintenance

Pin third-party GitHub Actions to reviewed full commit SHAs and retain a human-
readable version comment. Review dependency updates manually. This repository
uses Dependabot alerts for visibility but does not use automated Dependabot
version-update or security-update pull requests.

Preserve least-privilege workflow permissions, bounded job timeouts, pull
request concurrency cancellation, and failure-aware external downloads unless
a focused change documents and verifies a different policy.

Required status checks are identified by workflow job name. When a workflow or
job name changes, update and verify the default-branch ruleset. When labels or
release-note categories change, keep `.github/release.yml` aligned with the
labels actually used on pull requests.

## Commits and Pull Requests

Use a short imperative commit subject in this form:

```text
<area>: <summary>
```

Stable areas include `build`, `docs`, `tests`, `ci`, `release`, and `meta`.
Choose the area that best represents the main result of the commit. When a body
is useful, explain why the change matters and wrap it at a readable width.

Pull requests should describe:

- the problem and resulting behavior;
- the related Issue when one exists;
- the verification actually performed;
- user-facing, installation, or packaging impact; and
- documentation changes or why none are needed.

Keep pull request titles useful for the generated release notes. Apply labels
that describe the primary change, and review release-note categorization when a
workflow or label name changes.

## Versioning and Releases

Use full semantic repository versions such as `0.4.0` and tags in the form
`vX.Y.Z`. Keep the root `project(VERSION ...)`, generated package-version
metadata, and release tag aligned.

Use patch releases for narrow maintenance, documentation, packaging, and
compatibility fixes. Use minor releases for meaningful user-facing workflow,
CI, installation, export, or larger maintenance milestones. Prepare a release
through a focused pull request, confirm the release commit on `main` passes the
required checks, then create the matching tag and GitHub Release.

Use GitHub-generated release notes by default and keep their categories aligned
with pull request labels. Do not duplicate generated release notes in the
README. Mention version bumps explicitly in the release commit message.

## Review Expectations

Review will consider correctness, project scope, portability, reproducibility,
maintainability, and whether the verification is proportional to the risk.
Feedback may request a smaller scope, clearer documentation, or additional
tests before a change is merged.
