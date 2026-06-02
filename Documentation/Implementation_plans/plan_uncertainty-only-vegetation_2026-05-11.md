# Plan: Apply age uncertainty only to vegetation interpolation

**Date:** 2026-05-11  
**Author:** plan-large-changes agent  
**Status:** Draft

---

## Goal

Ensure age uncertainty is used only where it is scientifically valid: paleo vegetation interpolation. Abiotic interpolation must never use uncertainty iterations, and modern vegetation should remain non-interpolated in this project design. The result should be a clean, explicit separation of interpolation behavior by data type across all active pipelines, with regression-safe validation gates.

---

## Background

Related GitHub Issues reviewed:

- #79 (open): Add contemporary vegetation data analysis + large pipeline refactor
- #73 (closed): Age uncertainty interpolation via uncertainty matrix (historical implementation)

Current overlap assessment:

- No open issue appears to directly track the specific correction "abiotic must not use uncertainty" as a standalone bug/refactor item.
- #79 is adjacent and architectural, but broader in scope.
- Decision: track this as a new standalone issue.

---

## Scope

### In scope

- Make interpolation intent explicit by data type:
  - Paleo vegetation: uncertainty-aware interpolation.
  - Abiotic: deterministic interpolation only (no uncertainty path).
  - Modern vegetation: no interpolation step.
- Add a strict guard (explicit abort) if uncertainty inputs are accidentally routed into abiotic steps.
- Refactor pipe-segment wiring and helper interfaces as needed to prevent accidental cross-use.
- Add/adjust tests that enforce this boundary.
- Validate across all pipelines affected by shared segments.

### Out of scope

- Changing model formulas or model-fitting hyperparameters.
- Changing taxonomic classification behavior.
- Introducing modern vegetation interpolation.
- Broad redesign of targets architecture unrelated to interpolation behavior.

### Affected files / components

- R/02_Main_analyses/_pipes/pipe_segment_community_prepare_paleo.R
- R/02_Main_analyses/_pipes/pipe_segment_community_prepare_modern.R
- R/02_Main_analyses/_pipes/pipe_segment_abiotic_extract.R
- R/02_Main_analyses/_pipes/pipe_segment_sample_alignment.R
- R/Functions/Time/interpolate_community_data_with_uncertainty.R
- R/Functions/Time/interpolate_community_data.R
- R/Functions/Time/interpolate_data.R
- R/03_Supplementary_analyses/Testing/testthat/test-interpolate_community_data_with_uncertainty.R
- R/03_Supplementary_analyses/Testing/testthat/test-interpolate_data.R
- Any additional pipeline script references if target names/signatures are adjusted:
  - R/02_Main_analyses/pipeline_paleo_core.R
  - R/02_Main_analyses/pipeline_paleo_spatial_resolution.R
  - R/02_Main_analyses/pipeline_paleo_temporal.R
  - R/02_Main_analyses/pipeline_paleo_resolution_test.R
  - R/02_Main_analyses/pipeline_modern_spatial_resolution.R

---

## Refactoring Strategy

Primary target outcome selected: cleaner separation of concerns with one interpolation path per data type.

Design approach:

- Keep uncertainty logic encapsulated in vegetation-only pathways, anchored at paleo preprocessing.
- Keep abiotic preprocessing strictly deterministic by calling only interpolate_data() with abiotic inputs.
- Add explicit abiotic guard checks that abort early if uncertainty-iteration artifacts are detected in abiotic input contracts.
- Make data-contract expectations explicit in helper docs/tests so future edits fail fast if uncertainty data is passed to abiotic paths.
- Prefer minimal signature changes; if signatures change, update all call sites in one phase to avoid temporary broken pipelines.
- Sequence changes so tar_manifest can pass after each phase.

Proposed interface boundaries:

- interpolate_community_data_with_uncertainty(): vegetation-only function, requires taxon/value structure and uncertainty table.
- interpolate_community_data(): vegetation deterministic helper (for gridpoints fallback inside uncertainty wrapper).
- interpolate_data(): generic deterministic interpolation utility (including abiotic).

---

## Implementation Phases

### Phase 1 — Lock down interpolation contracts and guards

**Goal:** Make intended usage boundaries explicit and introduce fail-fast protection for abiotic routes.

**Tasks:**

- [ ] Update function-level documentation/spec language to clearly state allowable contexts per interpolation function.
- [ ] Add strict guard logic that aborts if uncertainty-routed inputs are accidentally passed into abiotic interpolation steps.
- [ ] Add/adjust tests to assert:
  - uncertainty-aware function is used for vegetation workflows only.
  - abiotic interpolation remains deterministic and guarded.
- [ ] Confirm existing modern workflow has no interpolation target introduced.

**Validation:**

- This phase is not complete until its validation passes.
- Run targeted tests:
  - testthat::test_file(here::here("R/03_Supplementary_analyses/Testing/testthat/test-interpolate_community_data_with_uncertainty.R"))
  - testthat::test_file(here::here("R/03_Supplementary_analyses/Testing/testthat/test-interpolate_data.R"))
- Run tar_manifest() for all affected pipelines:
  - targets::tar_manifest(script = here::here("R/02_Main_analyses/pipeline_paleo_core.R"))
  - targets::tar_manifest(script = here::here("R/02_Main_analyses/pipeline_paleo_spatial_resolution.R"))
  - targets::tar_manifest(script = here::here("R/02_Main_analyses/pipeline_paleo_temporal.R"))
  - targets::tar_manifest(script = here::here("R/02_Main_analyses/pipeline_paleo_resolution_test.R"))
  - targets::tar_manifest(script = here::here("R/02_Main_analyses/pipeline_modern_spatial_resolution.R"))
- For any larger code change, run the mandatory change-review workflow from `.github/copilot-instructions.md` before finalising this phase.

---

### Phase 2 — Enforce pipe-segment separation

**Goal:** Ensure each pipe segment uses only its allowed interpolation path.

**Tasks:**

- [ ] Confirm and harden paleo vegetation interpolation in pipe_segment_community_prepare_paleo.R.
- [ ] Confirm and harden deterministic abiotic interpolation in pipe_segment_abiotic_extract.R, including strict guard behavior.
- [ ] Ensure downstream alignment expectations in pipe_segment_sample_alignment.R remain consistent after separation.
- [ ] Ensure modern segment remains non-interpolated.

**Validation:**

- This phase is not complete until its validation passes.
- Re-run targeted interpolation tests from Phase 1.
- Run smallest executable pipeline checks:
  - one quick paleo config tar_make slice or selected target build
  - one quick modern config tar_make slice or selected target build
- Re-run tar_manifest() for all five pipelines listed in Phase 1.
- For any larger code change, run the mandatory change-review workflow from `.github/copilot-instructions.md` before finalising this phase.

---

### Phase 3 — Regression hardening and baseline smoke validation

**Goal:** Prevent future leakage and confirm end-to-end behavior on the selected baseline configuration.

**Tasks:**

- [ ] Add edge-case tests for mixed dataset types and missing uncertainty rows.
- [ ] Add test that abiotic interpolation path aborts on uncertainty-routed input and remains deterministic on valid input.
- [ ] Verify no hidden dependencies rely on uncertainty columns outside paleo community path.
- [ ] Run baseline paleo smoke validation on `project_paleo_core_cz`.

**Validation:**

- This phase is not complete until its validation passes.
- Run focused testthat files for newly added/changed tests.
- Run full test suite:
  - Rscript R/03_Supplementary_analyses/Testing/Run_tests.R
- Run baseline smoke validation with:
  - Sys.setenv(R_CONFIG_ACTIVE = "project_paleo_core_cz")
  - targets::tar_manifest(script = here::here("R/02_Main_analyses/pipeline_paleo_core.R"))
  - smallest feasible `tar_make()` smoke slice for `pipeline_paleo_core.R`
- For any larger code change, run the mandatory change-review workflow from `.github/copilot-instructions.md` before finalising this phase.

---

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|-----------|
| Silent scientific regression by applying uncertainty to non-vegetation data | Medium | Add explicit tests, strict abiotic guard aborts, and function-level contracts for allowed data types |
| Pipeline target dependency breakage after refactor | Medium | Keep target names stable where possible; validate each phase with tar_manifest() |
| Hidden assumptions in downstream alignment/model prep | Medium | Add focused alignment checks and a small execution smoke test per data mode |
| Overlap with broader open issue leads to duplicate effort | Low | Track as standalone issue and cross-link #79 for context |

---

## Decisions Locked

- Tracking mode: new standalone issue (not a subtask under #79).
- Guard behavior: strict explicit abort if uncertainty-routed inputs enter abiotic steps.
- Primary paleo smoke-test baseline: `project_paleo_core_cz`.

---

## GitHub Issue Scaffold

> This issue is self-contained and can be created directly.

### Single Issue

**Title:** Restrict age uncertainty interpolation to paleo vegetation only (with strict abiotic guard)

**Body:**

## Background

The current interpolation workflow needs a strict scientific boundary: age uncertainty applies to paleo vegetation interpolation, not abiotic predictors. Shared pipeline architecture increases the risk that uncertainty behavior leaks into wrong data paths unless contracts are explicit, guarded, and tested.

Related context: #79 (broader modern/pipeline refactor), #73 (historical uncertainty implementation).

## Goal

After this change, only paleo vegetation interpolation uses age uncertainty. Abiotic interpolation remains deterministic and aborts explicitly if uncertainty-routed input is detected. Modern vegetation remains non-interpolated.

## Scope

- Clarify and enforce interpolation contracts by data type
- Add strict abiotic guard with explicit abort behavior
- Refactor pipe-segment usage where needed to enforce separation
- Add regression tests for non-leakage of uncertainty behavior
- Validate all affected pipelines via tar_manifest and test suite

## Planned phases

1. Lock down interpolation contracts and guards
2. Enforce pipe-segment separation
3. Regression hardening and baseline smoke validation (`project_paleo_core_cz`)

## Validation expectations

- Each phase has a validation gate and is incomplete until gate passes.
- Validation/review remains attached to each phase; no standalone final validation-only phase.
- Affected pipeline manifests must pass.
- Full test suite must pass at final phase gate.
- Any larger code change requires the mandatory change-review workflow from `.github/copilot-instructions.md`.

## Acceptance Criteria

- [ ] Paleo vegetation interpolation uses uncertainty-aware path as intended
- [ ] Abiotic interpolation uses deterministic path only
- [ ] Abiotic path explicitly aborts on uncertainty-routed input
- [ ] Modern vegetation preprocessing remains non-interpolated
- [ ] Regression tests cover uncertainty/non-uncertainty boundaries and guard behavior
- [ ] tar_manifest passes for affected pipelines
- [ ] Full test suite passes
