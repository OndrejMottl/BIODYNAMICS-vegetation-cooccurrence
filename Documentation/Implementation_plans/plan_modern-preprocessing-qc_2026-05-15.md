# Plan: Modern vegetation data quality-control and preprocessing

**Date:** 2026-05-15
**Author:** plan-large-changes agent
**Status:** Draft

---

## Goal

The modern spatial pipeline (`pipeline_modern_spatial_resolution.R`) currently applies
only two preprocessing steps — non-Plantae filtering and taxonomic classification
(`pipe_segment_community_prepare_modern.R`). Before analyses can be trusted, the raw
modern community data extracted from VegVault must be subjected to data-quality
checks (most immediately: detection and removal of duplicate sites/communities) as
well as any further issues uncovered by a systematic diagnostic pass. This plan
delivers: (1) a diagnostic exploration script that maps all data-quality problems in
the modern dataset, (2) dedicated QC functions in `R/Functions/`, (3) a new
`pipe_segment_community_qc_modern.R` pipe segment that wires every QC step into the
pipeline as independent, inspectable targets, and (4) corresponding updates to
`pipe_segment_community_prepare_modern.R` so it consumes QC-validated data.

---

## Scope

### In scope

- Diagnostic/exploration script for the `project_modern_spatial_continental` config
- `deduplicate_modern_sites()` function (keep one representative record per
  location)
- Additional QC functions to be confirmed after Phase 1 exploration
- New `pipe_segment_community_qc_modern.R` pipe segment (sits between
  `pipe_segment_community_extract.R` and `pipe_segment_community_prepare_modern.R`)
- Refactoring of `pipe_segment_community_prepare_modern.R` to accept QC-validated
  data
- Updates to `pipeline_modern_spatial_resolution.R` to source the new segment
- Unit tests for every new function
- `tar_manifest()` validation after every pipeline file change

### Out of scope

- Changes to any paleo pipeline or paleo preprocessing
- New abiotic or model-fitting targets
- Visualisation of modern co-occurrence patterns (Issue #79 Phase H)

### Affected files / components

| File | Change |
|------|--------|
| `R/02_Main_analyses/01_Spatial/01_Contemporary/Explore_modern_data_quality_2026-05-15.R` | **New** — diagnostic script |
| `R/Functions/Community/deduplicate_modern_sites.R` | **New** |
| `R/Functions/Community/<further_qc_functions>.R` | **New** — to be confirmed after Phase 1 |
| `R/Pipelines/_pipes/pipe_segment_community_qc_modern.R` | **New** |
| `R/Pipelines/_pipes/pipe_segment_community_prepare_modern.R` | **Edit** — accept QC-validated input |
| `R/Pipelines/pipeline_modern_spatial_resolution.R` | **Edit** — source new segment |
| `config.yml` | **Edit** — add any new QC parameters (e.g. spatial proximity threshold) |
| `R/03_Supplementary_analyses/Testing/testthat/` | **New tests** for every new function |

---

## Git Worktree Setup

Follow the worktree workflow from `.github/instructions/git-workflow.instructions.md`.
Create the worktree after the GitHub issue is created so the branch name reflects
the issue number.

1. Verify `main` is current:
   ```powershell
   git checkout main
   git pull origin main
   ```
2. Create worktree (replace `<issue-number>` with the actual number):
   ```powershell
   git worktree add -b "<issue-number>-modern-data-qc-preprocessing" `
     "..\BIODYNAMICS_modern_data_qc"
   ```
3. Verify: `git worktree list`
4. Open in new VS Code window:
   ```powershell
   code -n "..\BIODYNAMICS_modern_data_qc"
   ```
5. Symlink VegVault (elevated cmd):
   ```cmd
   mklink "D:\GITHUB\BIODYNAMICS_modern_data_qc\Data\Input\VegVault.sqlite" ^
          "D:\GITHUB\BIODYNAMICS_vegetation_cooccurrence\Data\Input\VegVault.sqlite"
   ```
6. Restore renv in the new worktree's R session:
   ```r
   renv::restore()
   ```

---

## Refactoring Strategy

The refactor scope is **Large** — the goal is clear, decomposed interfaces with no
hidden dependencies between the QC layer and the subsequent preprocessing layer.

### Decomposition principles

1. **One function per QC concern.** Each data-quality problem discovered in Phase 1
   gets its own function in `R/Functions/Community/`. Functions must be independently
   testable against a synthetic data frame; they must not require a live VegVault
   connection.

2. **One target per QC step.** `pipe_segment_community_qc_modern.R` chains QC
   function calls so each intermediate output (`data_community_no_spatial_dups`,
   `data_community_no_community_dups`, etc.) is a named, inspectable pipeline target.
   This makes it trivial to disable or swap individual steps.

3. **Explicit data flow.** `pipe_segment_community_prepare_modern.R` must receive its
   input from the final QC target (e.g. `data_community_qc_validated`), not from
   `data_community_long_ages` directly. This removes hidden coupling between the
   extraction and preparation segments.

4. **Config-driven thresholds.** Any threshold that may need tuning (e.g. a spatial
   proximity radius for near-duplicate detection) goes into `config.yml` under
   `data_processing` for the relevant modern configurations. Accessed with
   `get_active_config("data_processing")$<param>` inside functions.

### Target state after refactor

```
pipe_segment_community_extract.R      →  data_community_long_ages
pipe_segment_community_qc_modern.R    →  data_community_qc_validated  (new, ≥ 2 targets)
pipe_segment_community_prepare_modern.R  →  data_community_classified  (updated input)
```

---

## Implementation Phases

### Phase 1 — Diagnostic exploration script

**Goal:** Produce a reproducible console report that lists every data-quality issue
present in the modern community data so that Phase 2 knows exactly which functions to
build.

**Tasks:**

- [ ] Create
  `R/02_Main_analyses/01_Spatial/01_Contemporary/Explore_modern_data_quality_2026-05-15.R`
- [ ] Source `R/___setup_project___.R` at the top
- [ ] Set `R_CONFIG_ACTIVE = "project_modern_spatial_continental"` (use a small
  spatial window if needed to keep execution fast)
- [ ] Connect to VegVault and extract a representative modern community dataset using
  existing `build_vegvault_plan()` + `extract_data_from_vegvault()` +
  `get_community_data()` + `make_community_data_long()` + `add_age_to_samples()`
- [ ] Check 1 — **Exact spatial duplicates**: datasets sharing identical
  `(coord_long, coord_lat)` — report count and examples
- [ ] Check 2 — **Near-spatial duplicates**: datasets within a configurable distance
  threshold (e.g. ≤ 100 m, ≤ 1 km) — report histogram of pairwise distances
- [ ] Check 3 — **Identical community composition**: datasets with the same set of
  taxon names and abundances/cover values — report count and examples
- [ ] Check 4 — **Empty / degenerate samples**: sites with zero taxa or zero total
  cover — report count
- [ ] Check 5 — **Implausible cover values**: values outside expected range (e.g. <0
  or if percentage cover > 100 for individual records) — report count
- [ ] Check 6 — **Coordinate precision anomalies**: e.g. many decimal places all
  zero, values snapped to grid — report summary
- [ ] Check 7 — **Dataset-type composition**: confirm all extracted datasets are the
  expected modern types (not accidentally including fossil pollen records)
- [ ] Each check prints a labelled `cli::cli_h1()` header followed by a
  `cli::cli_inform()` summary. No files are saved.
- [ ] Annotate the script with a clear `# FINDINGS:` comment block at the end
  listing confirmed issues to be addressed in Phase 2

**Validation:**

- This phase is not complete until its validation passes.
- Script runs to completion without error against a representative spatial window.
- Every check produces a non-empty console output.
- The `# FINDINGS:` block is filled in and reviewed with the user before Phase 2
  starts.
- No pipeline files are changed in this phase; `tar_manifest()` is not required.

---

### Phase 2 — QC functions

**Goal:** One well-tested function for each confirmed data-quality issue identified
in Phase 1. Deduplication is confirmed; further functions depend on Phase 1 findings.

**Tasks (confirmed):**

- [ ] Write roxygen2 stub for `deduplicate_modern_sites()`:
  - Input: long community data frame with `dataset_name`, `coord_long`, `coord_lat`
  - Behaviour: groups by `(coord_long, coord_lat)`, keeps one representative dataset
    per unique location (e.g. first by `dataset_name` alphabetically or by maximum
    taxon count — to be confirmed from Phase 1 findings)
  - Return: filtered data frame with duplicates removed
- [ ] Write tests for `deduplicate_modern_sites()` before implementation (TDD)
- [ ] Implement `deduplicate_modern_sites()`
- [ ] Run targeted tests: pass before proceeding
- [ ] *(Repeat the roxygen2 stub → test → implement cycle for each additional QC
  function confirmed in Phase 1 — e.g. `remove_empty_modern_samples()`,
  `filter_implausible_cover_values()`, etc.)*

**Validation:**

- This phase is not complete until its validation passes.
- Run targeted tests for every new function:
  ```r
  testthat::test_file(
    here::here("R/03_Supplementary_analyses/Testing/testthat/test-deduplicate_modern_sites.R")
  )
  ```
  (Repeat for each additional QC function.)
- Run the full suite:
  ```r
  Rscript R/03_Supplementary_analyses/Testing/Run_tests.R
  ```
- No pipeline files have changed in this phase; `tar_manifest()` is not required.
- Run the mandatory change-review workflow from `.github/copilot-instructions.md`
  before finalising this phase. If the runtime requires explicit user permission for
  the review subagent, ask for it before finalising.

---

### Phase 3 — New QC pipe segment and pipeline integration

**Goal:** All confirmed QC steps are wired into the modern pipeline as independent,
inspectable `{targets}` targets; `pipe_segment_community_prepare_modern.R` consumes
only QC-validated data.

**Tasks:**

- [ ] Create `R/Pipelines/_pipes/pipe_segment_community_qc_modern.R`:
  - Define `pipe_segment_community_qc_modern` as a list
  - Add one `tar_target()` per QC function, chained sequentially:
    - `data_community_no_spatial_dups` ← `deduplicate_modern_sites(data_community_long_ages)`
    - *(additional targets for each confirmed QC step)*
    - `data_community_qc_validated` ← final output target after all QC steps
  - Thresholds read from `get_active_config("data_processing")$<param>` where
    applicable
- [ ] Update `pipe_segment_community_prepare_modern.R`:
  - Replace `data_community_long_ages` input reference with
    `data_community_qc_validated`
- [ ] Update `pipeline_modern_spatial_resolution.R`:
  - Add `"pipe_segment_community_qc_modern.R"` to the sourced pipe segment list,
    between `"pipe_segment_community_extract.R"` and
    `"pipe_segment_community_prepare_modern.R"`
- [ ] Add any new QC threshold parameters to `config.yml` under
  `project_modern_spatial_continental` (and `project_modern_spatial_regional`,
  `project_modern_spatial_local` if they exist)
- [ ] Run `tar_manifest()` after every pipeline file edit:
  ```r
  Sys.setenv(R_CONFIG_ACTIVE = "project_modern_spatial_continental")
  targets::tar_manifest(
    script = here::here("R/Pipelines/pipeline_modern_spatial_resolution.R")
  )
  ```

**Validation:**

- This phase is not complete until its validation passes.
- `tar_manifest()` passes without errors for `project_modern_spatial_continental`.
- Run the full test suite:
  ```r
  Rscript R/03_Supplementary_analyses/Testing/Run_tests.R
  ```
- Optionally run a small-window pipeline slice to confirm targets execute correctly:
  ```r
  Sys.setenv(R_CONFIG_ACTIVE = "project_modern_spatial_continental")
  targets::tar_make(
    names = tidyselect::starts_with("data_community_qc")
  )
  ```
- Run the mandatory change-review workflow from `.github/copilot-instructions.md`
  before finalising this phase. If the runtime requires explicit user permission for
  the review subagent, ask for it before finalising.

---

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|-----------|
| Phase 1 reveals many more issues than expected, expanding scope significantly | Medium | Triage findings into must-fix (Phase 2) vs. future issues; cap Phase 2 at issues that directly affect model validity |
| `deduplicate_modern_sites()` strategy (keep first vs. keep most complete) is non-obvious from the data | Medium | Let Phase 1 diagnostics inform the choice; make the `tie_breaking` rule an explicit function argument with a clear default |
| Renaming the upstream input from `data_community_long_ages` to `data_community_qc_validated` in `pipe_segment_community_prepare_modern.R` invalidates existing cached targets | Low | This is expected; `tar_outdated()` will flag affected targets; re-run is normal |
| New near-duplicate detection threshold added to `config.yml` may not suit all spatial scales (continental vs regional) | Low | Add as an optional parameter with a sensible default; each scale config overrides if needed |
| VegVault connection in diagnostic script is slow over large windows | Low | Use a small test bounding box for initial exploration; document in script header |

---

## Open Questions

- After Phase 1: which additional QC steps (beyond spatial deduplication) are needed?
  The `# FINDINGS:` block in the diagnostic script drives Phase 2 scope.
- What tie-breaking rule should `deduplicate_modern_sites()` use when multiple
  datasets share the same location? (Options: most taxa, alphabetically first,
  highest total cover.) — confirm from Phase 1.
- Should identical-community-composition duplicates be removed separately from
  spatial duplicates, or is spatial deduplication sufficient?
- Are `project_modern_spatial_regional` and `project_modern_spatial_local` configs
  already in `config.yml`? If not, Phase 3 only targets `continental`.

---

## GitHub Issue Scaffold

> This issue is self-contained. Anyone reading it without access to this plan file
> should have all the context they need to understand and act on it.

### Single Issue

**Title:** Add data quality-control preprocessing for modern vegetation data

**Body:**
```
## Background

The modern spatial pipeline (`pipeline_modern_spatial_resolution.R`) extracts
vegetation community data from VegVault and applies only two preprocessing steps:
non-Plantae filtering and taxonomic classification. During active pipeline runs it
became apparent that the raw modern data contains duplicate sites (multiple datasets
at identical or near-identical coordinates), and potentially further quality issues
that have not yet been systematically characterised. Without a QC pass, these
duplicates enter the modelling stack and inflate spatial autocorrelation or
artificially inflate co-occurrence signals.

This issue is related to the parent modern-data tracking issue #79 (Phases G/H
still open).

## Goal

Introduce a systematic modern-data QC layer between VegVault extraction and
community preprocessing, so that the modelling pipeline receives clean, deduplicated
data. The QC steps are grounded in an explicit diagnostic script that maps all
confirmed problems first.

## Scope

- Diagnostic script (`Explore_modern_data_quality_2026-05-15.R`) that identifies
  all data-quality issues in the modern community data
- QC functions in `R/Functions/Community/` (one per issue found)
- New `pipe_segment_community_qc_modern.R` pipe segment
- Updated `pipe_segment_community_prepare_modern.R` (consumes QC-validated data)
- Updated `pipeline_modern_spatial_resolution.R` (sources new segment)
- `config.yml` extended with any new QC threshold parameters

## Planned phases

1. **Phase 1 — Diagnostic script**: run against modern VegVault data and produce a
   labelled console report of all data-quality issues; fill in `# FINDINGS:` block
   before Phase 2 starts.
2. **Phase 2 — QC functions**: one function per confirmed issue, full TDD cycle
   (roxygen2 stub → failing tests → implementation → targeted test pass → full
   suite pass).
3. **Phase 3 — Pipeline integration**: new `pipe_segment_community_qc_modern.R`,
   updated prepare segment and pipeline file, `tar_manifest()` validation.

## Validation expectations

- Each phase has its own validation gate and is not complete until that gate passes.
- Final implementation must keep all existing tests and pipeline manifests passing.
- Any larger code change must include the mandatory change-review workflow from
  `.github/copilot-instructions.md`.

## Acceptance Criteria

- [ ] Diagnostic script runs to completion and documents all confirmed data issues
- [ ] Every confirmed data-quality issue has a corresponding QC function with passing
      tests
- [ ] `pipe_segment_community_qc_modern.R` contains one target per QC step; each
      target is independently inspectable
- [ ] `pipe_segment_community_prepare_modern.R` receives `data_community_qc_validated`
      not `data_community_long_ages`
- [ ] `tar_manifest()` passes for `project_modern_spatial_continental`
- [ ] Full test suite passes
- [ ] Mandatory change-review workflow completed
```
