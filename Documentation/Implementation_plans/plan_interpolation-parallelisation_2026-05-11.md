# Plan: Parallelise interpolation using furrr

**Date:** 2026-05-11
**Author:** plan-large-changes agent
**Status:** Draft

---

## Goal

The interpolation step — primarily `interpolate_data()` and the per-iteration
path in `interpolate_community_data_with_uncertainty()` — currently runs on a
single core, making it the dominant wall-clock bottleneck. This change adds
multi-core support via `furrr` (drop-in `purrr` replacement backed by `future`),
with a clean unified interface: a single `n_cores` argument that seamlessly falls
back to sequential mode when set to `1`. After this change the same functions
work correctly on one core or many, and the pipe segments pass the number of
cores from project configuration. The user is responsible for installing `furrr`
and `future` and updating `renv` manually.

---

## Scope

### In scope
- Profile the exact bottleneck before implementation (reproducible `Data/Temp/` script)
- Add `n_cores` argument to `interpolate_data()`; switch inner `purrr::map()` to
  `furrr::future_map()` when `n_cores > 1`, with `purrr::map()` as sequential fallback
- Thread `n_cores` through `interpolate_community_data()` and
  `interpolate_community_data_with_uncertainty()`
- Update `pipe_segment_abiotic_extract.R` and
  `pipe_segment_community_prepare_paleo.R` to pass `n_cores` from config
- Update roxygen2 docs for all changed functions
- Add/extend tests: correctness (parallel output == sequential output), error on
  invalid `n_cores`

### Out of scope
- Updating `renv.lock` — the user manages `renv` manually
- `interpolate_mev_to_grid()` and `interpolate_st_mev_to_grid()` (spatial
  interpolation utilities, not the bottleneck being targeted)
- Changing interpolation contracts or guards (those belong to Issue #94 phases)
- Adding a new `config.yml` key for `n_cores_interpolation`

### Affected files / components

| File | Change |
|------|--------|
| `R/Functions/Time/interpolate_data.R` | Add `n_cores` argument; `furrr`/`purrr` unified map |
| `R/Functions/Time/interpolate_community_data.R` | Thread `n_cores` through |
| `R/Functions/Time/interpolate_community_data_with_uncertainty.R` | Thread `n_cores` through both call sites |
| `R/02_Main_analyses/_pipes/pipe_segment_abiotic_extract.R` | Pass `n_cores` from config |
| `R/02_Main_analyses/_pipes/pipe_segment_community_prepare_paleo.R` | Pass `n_cores` from config |
| `R/03_Supplementary_analyses/Testing/testthat/test-interpolate_data.R` | Extend tests |
| `R/03_Supplementary_analyses/Testing/testthat/test-interpolate_community_data.R` | Extend tests |
| `R/03_Supplementary_analyses/Testing/testthat/test-interpolate_community_data_with_uncertainty.R` | Extend tests |

---

## Refactoring Strategy

The chosen style is **unified interface**: one function, one `n_cores` argument,
no separate "parallel" variant functions.

- `interpolate_data()` gains `n_cores = max(1L, parallel::detectCores() - 1L)`.
- Internally: when `n_cores == 1` use `purrr::map()`; when `n_cores > 1` capture
  the current `future` plan, set `future::plan(future::multisession, workers = n_cores)`,
  restore the previous plan in `on.exit(..., add = TRUE)`, then call
  `furrr::future_map()` with `furrr::furrr_options(seed = TRUE)`.
- `interpolate_community_data()` and `interpolate_community_data_with_uncertainty()`
  gain the same `n_cores` default and forward it **explicitly** (not solely via `...`)
  to every `interpolate_data()` call site to avoid ambiguity where two call sites exist.
- Pipeline call sites pass `n_cores = get_active_config("model_fitting")$n_cores`
  so the value is centralised in `config.yml`.

---

## Implementation Phases

### Phase 1 — Profile and confirm bottleneck

**Goal:** Produce a reproducible, minimal profiling script that confirms which
function and loop is the wall-clock bottleneck before touching any source file.

**Tasks:**
- [ ] Write `Data/Temp/profile_interpolation_2026-05-11.R` that:
  - Sources `R/___setup_project___.R`
  - Reads a small fixture (e.g. `targets::tar_read(data_community_proportions)`
    for `project_paleo_core_cz`)
  - Runs `profvis::profvis()` over `interpolate_community_data_with_uncertainty()`
    and `interpolate_data()` separately
  - Saves the profvis HTML report to `Data/Temp/`
  - Logs baseline `system.time()` for both functions via `message()`
- [ ] Inspect the report and note the dominant hotspot (expected: the `purrr::map()`
  inside `interpolate_data()` when `by` includes `"iteration"`)

**Validation:**
- The profiling script runs end-to-end without error.
- Baseline timings are logged.
- No source files are modified — no change-review needed for this phase.

---

### Phase 2 — Add `n_cores` to `interpolate_data()`

**Goal:** Replace the sequential `purrr::map()` in `interpolate_data()` with a
unified parallel/sequential dispatcher; confirm numerical equivalence and correct
`furrr` package integration.

**Tasks:**
- [ ] Update roxygen2 doc for `interpolate_data()`:
  - Add `@param n_cores` (single positive integer; `1` = sequential;
    default `max(1L, parallel::detectCores() - 1L)`)
  - Add `@seealso [furrr::future_map()]`
- [ ] Implement the `n_cores` argument in `interpolate_data()`:
  - Validate with `assertthat` (single positive integer)
  - `n_cores == 1`: use `purrr::map()` unchanged
  - `n_cores > 1`: capture previous plan with `prev_plan <- future::plan()`;
    `on.exit(future::plan(prev_plan), add = TRUE)`;
    `future::plan(future::multisession, workers = n_cores)`;
    call `furrr::future_map(.options = furrr::furrr_options(seed = TRUE), ...)`
- [ ] Update `test-interpolate_data.R`:
  - Add test: `n_cores = 1` and `n_cores = 2` produce numerically identical output
    on a small fixture
  - Add test: `n_cores = 0` or `n_cores = -1` throws an informative error
- [ ] Run targeted tests:
  ```r
  testthat::test_file(
    here::here("R/03_Supplementary_analyses/Testing/testthat/test-interpolate_data.R")
  )
  ```

**Validation:**
- All tests in `test-interpolate_data.R` pass.
- `interpolate_data()` with `n_cores = 2` produces output numerically identical
  to `n_cores = 1` on the profiling fixture.
- Run the mandatory change-review workflow from `.github/copilot-instructions.md`
  before proceeding to Phase 3.

---

### Phase 3 — Thread `n_cores` through caller functions

**Goal:** `interpolate_community_data()` and
`interpolate_community_data_with_uncertainty()` expose and forward `n_cores` so
callers can control parallelism at a single point.

**Tasks:**
- [ ] Update roxygen2 docs for both functions (add `@param n_cores`)
- [ ] Add `n_cores = max(1L, parallel::detectCores() - 1L)` argument to
  `interpolate_community_data()`; pass it explicitly to `interpolate_data()`
- [ ] Add same argument to `interpolate_community_data_with_uncertainty()`; pass it
  explicitly to both `interpolate_community_data()` and the direct
  `interpolate_data()` call inside the fossil-core branch
- [ ] Update `test-interpolate_community_data.R`: add correctness test for
  `n_cores = 2`
- [ ] Update `test-interpolate_community_data_with_uncertainty.R`: add correctness
  test for `n_cores = 2` (fixture must contain at least one fossil core dataset
  and one gridpoint)
- [ ] Run targeted tests:
  ```r
  testthat::test_file(
    here::here("R/03_Supplementary_analyses/Testing/testthat/test-interpolate_community_data.R")
  )
  testthat::test_file(
    here::here("R/03_Supplementary_analyses/Testing/testthat/test-interpolate_community_data_with_uncertainty.R")
  )
  ```
- [ ] Run full test suite:
  ```powershell
  Rscript R/03_Supplementary_analyses/Testing/Run_tests.R
  ```

**Validation:**
- All targeted tests pass.
- Full test suite passes.
- Run the mandatory change-review workflow from `.github/copilot-instructions.md`
  for this phase.

---

### Phase 4 — Update pipe segments and validate pipelines

**Goal:** Both affected pipe segments pass the configured `n_cores` value so
pipeline runs are automatically parallelised without per-run code changes.

**Tasks:**
- [ ] In `pipe_segment_abiotic_extract.R`: add
  `n_cores = get_active_config("model_fitting")$n_cores` to the `interpolate_data()`
  call inside the relevant `tar_target()`
- [ ] In `pipe_segment_community_prepare_paleo.R`: add the same argument to the
  `interpolate_community_data_with_uncertainty()` call
- [ ] Run `tar_manifest()` for both configurations:
  ```r
  Sys.setenv(R_CONFIG_ACTIVE = "project_paleo_core_cz")
  targets::tar_manifest(
    script = here::here("R/02_Main_analyses/pipeline_paleo_core.R")
  )

  Sys.setenv(R_CONFIG_ACTIVE = "project_paleo_temporal_europe")
  targets::tar_manifest(
    script = here::here("R/02_Main_analyses/pipeline_paleo_temporal_europe.R")
  )
  ```
- [ ] Smoke-check: run `data_community_interpolated` and `data_abiotic_interpolated`
  targets for `project_paleo_core_cz` and record elapsed time vs Phase 1 baseline:
  ```r
  targets::tar_make(
    names = c("data_community_interpolated", "data_abiotic_interpolated")
  )
  ```
- [ ] Run full test suite:
  ```powershell
  Rscript R/03_Supplementary_analyses/Testing/Run_tests.R
  ```
- [ ] Run the mandatory change-review workflow from `.github/copilot-instructions.md`.

**Validation:**
- `tar_manifest()` succeeds for both configurations with no errors.
- Smoke-check run completes successfully.
- Full test suite passes.
- Mandatory change-review passes with no confirmed violations.

---

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|-----------|
| `furrr`/`future` not yet installed in the project renv library | Medium | User installs manually; implementer checks with `requireNamespace("furrr")` before proceeding |
| Multi-session workers don't inherit functions from `R/Functions/` (not on search path) | Medium | Use fully-qualified `pkg::fn()` calls inside the mapped closure; confirm all internal helpers are namespace-qualified |
| Numerical non-equivalence between parallel and sequential runs | Low | `stats::approx()` is deterministic per group; groups are independent so ordering doesn't affect results |
| Nested parallelism: `future::multisession` inside a `targets` worker | Medium | Capture and restore the pre-existing `future` plan with `prev_plan <- future::plan(); on.exit(future::plan(prev_plan), add = TRUE)` so the outer plan is never broken |
| `future::plan()` restoration disturbs outer plans set by `targets` | Low | Using the capture-and-restore pattern (not hard-coding `future::sequential`) avoids this |

---

## Open Questions

1. **Future plan ownership**: should `future::plan()` set/restore live inside
   `interpolate_data()` (self-contained, but called twice in the uncertainty
   wrapper), or should callers own the plan and `interpolate_data()` simply call
   `furrr::future_map()` unconditionally? The current plan keeps it inside the
   function for self-containedness.

2. **`n_cores` config key**: reuse `model_fitting.n_cores` (already in
   `config.yml`) or add a dedicated `data_processing.n_cores_interpolation` key
   to separate concerns?

---

## GitHub Issue Scaffold (sub-issue of #94)

**Title:** [Performance] Parallelise interpolation via furrr to use multiple cores

**Body:**
```
## Background

`interpolate_data()` is the core utility that powers all temporal interpolation
in the pipeline. It currently uses a sequential `purrr::map()` loop over groups
(dataset × taxon, or dataset × taxon × iteration). With hundreds of groups and
hundreds of age-uncertainty iterations, this single-core loop is the dominant
wall-clock cost of the pipeline run.

This is a sub-issue of #94 (interpolation contract refactor). It is
independently implementable but should not conflict with those contracts.

## Goal

After this change, `interpolate_data()`, `interpolate_community_data()`, and
`interpolate_community_data_with_uncertainty()` all accept an `n_cores` argument.
When `n_cores > 1`, the internal map loop uses `furrr::future_map()` backed by
`future::multisession`; when `n_cores == 1` it falls back to `purrr::map()`.
Pipe segments pass the value from `config.yml` so no per-run code changes are
needed.

## Scope

- `interpolate_data()` — unified parallel/sequential dispatcher
- `interpolate_community_data()` — thread `n_cores` through
- `interpolate_community_data_with_uncertainty()` — thread `n_cores` through
  both internal call sites
- `pipe_segment_abiotic_extract.R` and `pipe_segment_community_prepare_paleo.R`
  — pass `n_cores` from config
- Extend tests for correctness (parallel == sequential) and error-handling

Note: `renv` updates are managed manually by the user.

## Planned phases

1. Profile and confirm bottleneck (reproducible script in `Data/Temp/`)
2. Add `n_cores` + `furrr` dispatch to `interpolate_data()`, extend its tests
3. Thread `n_cores` through `interpolate_community_data()` and
   `interpolate_community_data_with_uncertainty()`, extend their tests, run full suite
4. Update pipe segments; validate `tar_manifest()` for `project_paleo_core_cz`
   and `project_paleo_temporal_europe`; smoke-check elapsed time

## Validation expectations

- Each phase has its own validation gate and is not complete until that gate passes.
- Targeted test files run after each phase.
- `tar_manifest()` for both configurations runs after Phase 4.
- Full test suite runs at phases 3 and 4.
- Any larger code change includes the mandatory change-review workflow from
  `.github/copilot-instructions.md`.

## Acceptance Criteria

- [ ] `interpolate_data()` accepts `n_cores`; output for `n_cores = 2` is
      numerically identical to `n_cores = 1`
- [ ] `interpolate_community_data()` and
      `interpolate_community_data_with_uncertainty()` expose and forward `n_cores`
- [ ] Pipe segments pass `n_cores` from `config.yml`
- [ ] `tar_manifest()` passes for `project_paleo_core_cz` and
      `project_paleo_temporal_europe`
- [ ] Full test suite passes
- [ ] Wall-clock time for `data_community_interpolated` and
      `data_abiotic_interpolated` targets is measurably reduced vs baseline
```
