# Issue 139 closure review v1

**Recorded:** 2026-07-17
**Issue:** #139, Audit and stabilize cross-validation contracts
**Comparison:** `origin/main...OndrejMottl/issue139`
**Reviewed head before closure edits:** `e49f2add`

## Decision

Issue 139 is ready for pull-request review. The branch contains the complete
PR #137 audit, correctness fixes, regression contracts, versioned reference
evidence, matched-fold predictive decomposition, and formal scientific
performance decision. No high- or medium-severity finding remains unresolved.

The pull request should use `Closes #139`. Issue closure should occur on merge,
after repository CI and review confirm the recorded local evidence.

## Final review boundary

The reviewed comparison at `e49f2add` contains 591 changed paths. This closure
slice adds this report plus checklist and convention-only corrections:

| Category | Paths |
|---|---:|
| Generated pipeline progress | 234 |
| Generated or website documentation | 18 |
| Cross-validation audit reports | 20 |
| R source, pipeline, runner, and test files | 86 |
| Implementation plans | 2 |
| Configuration, coverage, other generated files, and supporting material | 231 |
| **Total** | **591** |

Four deleted paths are explicitly classified in
`pr137_file_inventory_v1.md`. Every inventory row is marked `Reviewed`; source,
tests, configuration, generated documentation, progress artifacts, and deleted
paths are therefore included rather than silently omitted.

## Findings disposition

- The final inventory scan found zero rows without `Reviewed` status.
- The findings-register scan found zero unresolved high/medium findings.
- Findings CV-001 through CV-014, CV-017, CV-018, and CV-021 are resolved with
  tests, convention corrections, and reference evidence.
- Remaining low-severity maintainability findings CV-015, CV-016, CV-019, and
  CV-020 are explicitly accepted for Issue #141 after Issue #138 fixes the
  measured execution design.
- The predictive decomposition uses identical fixed spatial folds and retains
  raw negative effects. It is explicitly predictive and non-causal, not an
  additive partition of ecological variance.

## Final structural review

- All 86 changed, non-deleted R files parse successfully.
- The R line-length scan identified three long generated-path comments in the
  paleo continental, regional, and local runners; they were wrapped during this
  closure slice.
- The non-progress `git diff --check` scan identified four Markdown hard-break
  whitespace lines in two audit reports; they were removed.
- Generated self-contained progress HTML embeds third-party JavaScript with
  upstream whitespace. Those assets are preserved exactly as generated and are
  isolated under `Documentation/Progress/`.
- The complete PR #137 inventory, architecture/store map, contract inventory,
  findings register, and correctness metadata were cross-checked and are
  mutually consistent.

## Validation evidence

| Gate | Result |
|---|---|
| Latest full test suite | 3,569 passed, 0 failed, 1 expected opt-in skip |
| Required production pipeline manifests | Parsed with no duplicate targets |
| Scientific-reference manifest | 30 targets |
| Fresh CZ paleo and modern workflows | Completed with zero target errors |
| Scientific-reference GPU folds | 15 / 15 successful |
| Predictive-decomposition reduced GPU folds | 45 / 45 successful |
| Scientific-performance decision | Technical pass; prediction pass; calibration caution |
| Quarto/generated documentation | Rebuilt, parsed/rendered, and visually checked where changed |
| Final inventory review | Every PR #137 path reviewed |
| Final findings gate | No unresolved high/medium finding |

Detailed values, hashes, schemas, and environment metadata remain in
`correctness_reference_metadata_v1.md` and the versioned diagnostic reports.

## Residual non-blocking notes

- The repository reports that the project is out of sync with `renv`, while the
  installed library is synchronized with the lockfile.
- The full test runner emits a post-suite database-disconnection reminder after
  reporting zero test warnings and failures.
- Calibration remains a scientific caution for absolute occurrence
  probabilities, but does not negate the held-out discrimination and
  proper-score pass.
- Generated progress dashboards add substantial vendor assets to version
  control; their inclusion is intentional for the Issue 139 validation record.

None of these notes is an unresolved correctness or contract blocker.
