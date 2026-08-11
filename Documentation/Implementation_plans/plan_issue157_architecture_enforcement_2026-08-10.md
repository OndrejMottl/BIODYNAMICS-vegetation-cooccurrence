# Plan: Issue 157 architecture enforcement

**Date:** 2026-08-10 **Status:** Approved **Parent issue:** #149 **Implementation issue:** #157 **Related deferred issue:** #141

## Goal

Replace the migration-era report-only architecture audit with maintained, blocking repository contracts; publish the final R architecture and dependency map; and bring workflow READMEs, generated function documentation, and coverage artifacts into sync with the completed repository-wide refactor.

## Boundaries

- Preserve scientific behaviour, public and frozen CV contracts, target names, artifact schemas, configuration values, profile IDs, stores, seeds, and scheduling policy.
- Keep Issue #141 responsible for CV architecture simplification.
- Represent its 32 naming and seven nested-helper findings as exact, issue-bounded exceptions that expire when #141 closes.
- Preserve historical reports as provenance rather than rewriting old paths.
- Do not add CI services or external R dependencies.

## Implementation

### 1. Resolve the final migration findings

- Refresh the script and function inventories.
- Correct the two obsolete configuration-test paths.
- Limit generic naming and nested-helper checks to active inventory rows.
- Inline the trait group-selection error callback and preserve its behaviour in focused tests.
- Record the 39 exact Issue #141 exceptions with owner, rationale, and expiry issue.

Validation: inventory regeneration is idempotent, focused tests pass, and the repository has exactly 39 excepted findings with no unresolved finding.

### 2. Install maintained blocking architecture contracts

- Extract pure diagnosis, exception matching, validation, and map-building functions from the procedural architecture checker.
- Make duplicate symbols/basenames, file/function mismatch, one function per file, inventory drift, placement, naming, nested-helper disposition, stale active references, documentation completeness, and workflow README completeness blocking.
- Keep the command-line checker as a thin report-writing entry point.
- Add fixture-based unit tests and a live repository contract test to the full suite.

Validation: every contract fails under an isolated violating fixture; valid exceptions pass; malformed, duplicate, orphaned, and unmatched exceptions fail.

### 3. Publish the final architecture

- Preserve `architecture_findings_v1.csv` as historical migration evidence.
- Generate `architecture_findings_current.csv`, `r_architecture_exceptions.csv`, and `r_architecture_dependency_map.md` deterministically.
- Document R-root ownership, runner/profile/pipeline/store relationships, pipe/function capabilities, validation flows, generated artifacts, and the temporary #141 boundary.
- Normalize every inventory-defined non-main workflow README and update root, canonical `.ai`, and adapter guidance to the final paths and contracts.

Validation: two generations are byte-identical, all workflow roots satisfy the README contract, and active guidance contains no retired paths.

### 4. Refresh generated documentation and coverage

- Make function documentation generation fail closed instead of swallowing errors.
- Generate HTML, TXT, PDF, QMD, and published HTML for every active non-legacy function and remove only provably stale generated pages.
- Regenerate coverage reports without lowering the 96.31 percent baseline.
- Render and inspect the website outputs.

Validation: active function basenames exactly match every required artifact set; all R and Quarto sources parse; the full suite, 26-profile manifest inventory, Czech smoke workflows, and trait-reference workflow pass; frozen #141 contracts remain unchanged; `git diff --check` and the mandatory read-only change review pass.

## Maintained interfaces

The current findings report contains:

`finding_id`, `finding_type`, `current_path`, `symbol`, `owner_issue`, `message`, `resolution_status`, `exception_id`.

`resolution_status` is limited to `blocking` and `excepted`.

The exception ledger contains:

`exception_id`, `finding_type`, `current_path`, `symbol`, `owner_issue`, `rationale`, `expiry_issue`.

An exception is valid only when it matches exactly one current finding. Issue #141 exceptions must be removed or replaced by approved canonical decisions when #141 closes.
