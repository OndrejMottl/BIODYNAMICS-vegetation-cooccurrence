# Plan: Future Diversity Prediction Main Analyses

**Date:** 2026-06-24
**Author:** plan-large-changes agent
**Status:** Draft

---

## Goal

Add a new main-analysis workflow that predicts future diversity for the Europe continental spatial unit by reusing the existing continental paleo and continental modern spatial models, driving them with CMIP6 future climate scenarios, and producing scenario-comparison outputs for 2050 and 2100. The implementation should promote the current supplementary prediction machinery into a reproducible, scenario-aware analysis surface that fits the repository's main-analysis and targets conventions.

---

## Background

The repository already contains reusable prediction infrastructure in the supplementary layer:

- `R/03_Supplementary_analyses/Prediction/Predict_on_full_grid.R`
- `R/Functions/Prediction/Inputs/read_spatial_resolution_prediction_inputs.R`
- `R/Functions/Prediction/Grids/build_land_prediction_grid.R`
- `R/Functions/Prediction/Inference/predict_spatial_resolution_grid_age.R`
- `R/Functions/Prediction/Climate/extract_prediction_climate.R`
- `R/Functions/Abiotic/Ingest/get_chelsa_raster.R`

That stack currently supports age-based hindcasting using CHELSA-TraCE21k. It does not yet support future scenario metadata, future-climate raster acquisition, or a main-analysis orchestration layer.

A presentation prototype also exists in `Documentation/Presentations/IAVS_2026/R/Visualisation/future_predictions_animation.R`, which confirms that the prediction helpers are already usable outside the supplementary script layer.

GitHub issue search was not completed while drafting this plan because the current runtime session does not expose the deferred GitHub search tool needed by this planner.

---

## Scope

### In scope

- Add a new main-analysis workflow for future diversity prediction.
- Start with the Europe continental spatial unit only.
- Reuse both existing continental paleo and continental modern model stores.
- Use CMIP6 future climate scenarios for 2050 and 2100.
- Produce future prediction data objects, map-ready outputs, and scenario-comparison summaries.
- Refactor current prediction helpers so climate access is backend-aware instead of hard-wired to paleo age slices.
- Keep existing paleo and modern modelling pipelines runnable without behaviour changes.
- Keep output naming and store conventions aligned with the current repository structure.

### Out of scope

- Regional or local future-prediction workflows.
- Full multi-continent production rollout.
- Multi-GCM ensemble uncertainty in the first implementation pass.
- Family and functional-type future diversity outputs unless they fall out naturally after the genus workflow is stable.
- Quarto or website documentation work.
- Manuscript writing.

### Affected files / components

- `config.yml`
- `R/02_Main_analyses/01_Spatial/02_Contemporary/05_Compare_paleo_modern.R`
- `R/03_Supplementary_analyses/Prediction/Predict_on_full_grid.R`
- `R/Functions/Abiotic/Ingest/get_chelsa_raster.R`
- `R/Functions/Prediction/Climate/extract_prediction_climate.R`
- `R/Functions/Prediction/Inference/predict_spatial_resolution_grid_age.R`
- `R/Functions/Prediction/Inputs/read_spatial_resolution_prediction_inputs.R`
- `R/Functions/Prediction/Scaling/scale_prediction_abiotic.R`
- `R/Pipelines/pipeline_paleo_spatial_resolution.R`
- `R/Pipelines/pipeline_modern_spatial_resolution.R`
- `R/Pipelines/_pipes/pipe_segment_abiotic_extract.R`
- New future-climate ingest helpers under `R/Functions/Abiotic/` or `R/Functions/Prediction/Climate/`
- New future-prediction orchestration helpers under `R/Functions/Prediction/`
- New targeted tests in `R/03_Supplementary_analyses/Testing/testthat/`
- New main-analysis runner(s) under `R/02_Main_analyses/01_Spatial/03_Future/`
- Likely new targets pipeline under `R/Pipelines/` for future prediction outputs
- Outputs under `Outputs/Data/`, `Outputs/Figures/`, and `Outputs/Tables/`

---

## Refactoring Strategy

Promote the current supplementary prediction stack into a generic prediction subsystem that separates three concerns:

- model-store resolution and prediction input loading,
- climate-backend acquisition and preprocessing,
- prediction summarisation and output generation.

Refactor direction (backward compatibility not required—clean modularity prioritized):

- Fully replace `get_chelsa_raster()` with a backend-aware climate-raster acquisition system that supports both historical CHELSA-TraCE21k and future CMIP6 rasters.
- Consolidate climate extraction logic so a single generic helper replaces the current age-only `extract_prediction_climate()`.
- Replace `predict_spatial_resolution_grid_age()` with a new generic prediction helper that accepts a `prediction_context` parameter bundle.
- Represent prediction context explicitly as metadata: model source, scale id, resolution id, climate backend, scenario id, horizon year, and optional age.
- Keep store reading and model interpolation code shared across paleo and modern future projections.
- Prefer a thin runner script plus a dedicated targets pipeline for repeated scenario execution, rather than a monolithic imperative script.

Target interface design:

- **Climate backend abstraction**: Generic function `get_climate_raster(prediction_context, cache_dir)` that dispatches to historical or future climate sources based on `prediction_context$climate_backend`. Supported backends: `"chelsa_trace21k"` (historical) and `"chelsa_cmip6"` (future).
- **Climate extraction**: `extract_climate_for_prediction(data_grid, prediction_context, cache_dir)` returns a tibble with grid coordinates and extracted bioclim variables.
- **Prediction context**: A required named list containing `list(model_source = "paleo"|"modern", scale_id = "europe", resolution_id = "genus", climate_backend = "chelsa_trace21k"|"chelsa_cmip6", scenario_id = "historical"|"ssp245"|..., horizon_year = 0|2050|2100, age = <optional>)`.
- **Generic prediction helper**: `predict_from_model_context(prediction_inputs, data_grid, data_grid_coords_projected, prediction_context, cache_dir, climate_fn, spatial_interpolate_fn, ...)` returns long-format taxon probabilities.
- **Output summariser**: Returns prediction-level data plus expected richness summaries in a stable, long-format schema.

Recommended climate data/tool choice:

- Use CHELSA CMIP6 future bioclim rasters so the predictor family stays aligned with the existing CHELSA-based hindcast workflow.
- Reuse the current `terra` plus cache-directory download pattern, ideally through a new backend-specific raster helper.
- Add a package dependency only if CHELSA CMIP6 access proves unstable through direct URLs.

---

## Implementation Phases

### Phase 1 - Generalise climate and prediction infrastructure

**Goal:** Convert the current age-only prediction helpers into a backend-aware prediction subsystem that can support both historical and future climate inputs without breaking existing hindcast workflows.

**Tasks:**
- [ ] Audit the current supplementary prediction stack and identify shared responsibilities split across `Predict_on_full_grid.R`, `extract_prediction_climate()`, `predict_spatial_resolution_grid_age()`, and `get_chelsa_raster()`.
- [ ] Design and implement a backend-aware climate-raster acquisition system that replaces `get_chelsa_raster()` with support for both historical CHELSA-TraCE21k and future CMIP6 scenarios.
- [ ] Refactor `extract_prediction_climate()` into a generic climate extraction helper that accepts a climate-raster backend and `prediction_context` metadata.
- [ ] Replace `predict_spatial_resolution_grid_age()` with a new generic prediction helper `predict_from_model_context()` that accepts `prediction_context` and delegates to climate and spatial-interpolation backends.
- [ ] Add explicit validation for unsupported climate backends, missing rasters, extrapolation-prone predictors, and naming mismatches between climate rasters and model abiotic variables.
- [ ] Update or rewrite supplementary and presentation scripts to use the new helper interfaces; these are not backward-compatibility requirements, but informative for understanding refactor scope.

**Validation:**
- This phase is not complete until its validation passes.
- Write comprehensive unit tests for the new generic prediction helper, climate-backend abstraction, and context-building helpers.
- Run the smallest executable smoke checks: one with historical climate (CHELSA-TraCE21k age slice), one with future climate (mocked CMIP6 scenario).
- Verify that model-store reading and spatial-interpolation logic remain unchanged and produce numerically identical predictions for hindcast scenarios as before.
- Run the mandatory change-review workflow before closing the phase because this phase replaces core prediction infrastructure.

---

### Phase 2 - Build a dedicated future-prediction pipeline for Europe

**Goal:** Create a reproducible future-prediction pipeline that consumes existing continental model stores and materialises scenario-by-horizon diversity predictions for Europe.

**Tasks:**
- [ ] Add future-prediction configuration entries to `config.yml`, including target store, scale id, climate backend, scenario ids, horizon years, selected abiotic variables, cache paths, and prediction output controls.
- [ ] Create a new targets pipeline, likely `R/Pipelines/pipeline_future_spatial_prediction.R`, that branches over model source (`paleo`, `modern`), scenario, and horizon.
- [ ] Add a new main-analysis runner under `R/02_Main_analyses/01_Spatial/03_Future/` that sets the active configuration and runs the future-prediction pipeline for Europe.
- [ ] Reuse `build_spatial_model_store_index()` and `read_spatial_resolution_prediction_inputs()` so the new pipeline reads the already fitted continental stores rather than refitting models.
- [ ] Build stable target objects for prediction grids, future climate slices, predicted probabilities, and expected genus richness summaries.
- [ ] Write outputs to repository-standard locations in `Outputs/Data/`, `Outputs/Figures/`, and `Outputs/Tables/`.
- [ ] Keep genus richness as the first required diversity metric for v1, because that path already has tested summarisation support.

**Validation:**
- This phase is not complete until its validation passes.
- Run `targets::tar_manifest(script = here::here("R/Pipelines/pipeline_future_spatial_prediction.R"))`.
- Run a smoke `tar_make()` on one combination only: one model source, one SSP, one horizon, Europe only.
- Confirm that the pipeline reads model stores without modifying or rebuilding the original paleo/modern fit stores.
- Confirm that outputs are created with stable names and the expected columns for `grid_id`, coordinates, scenario, horizon, model source, and predicted diversity values.
- Run the smallest additional executable check needed to confirm reproducibility from a clean cache directory.
- Run the mandatory change-review workflow before closing the phase because a new pipeline and config surface are being introduced.

---

### Phase 3 - Extract and quantify prediction uncertainty

**Goal:** Build uncertainty quantification infrastructure that captures model-parameter and prediction-grid uncertainty in future diversity predictions, producing credible intervals and uncertainty maps for all predictions.

**Tasks:**
- [ ] Assess what uncertainty information is already available in the fitted sjSDM model stores (posterior samples, credible intervals, variability in fit diagnostics).
- [ ] Design a context-aware uncertainty extraction helper that accepts `prediction_context` and materialises prediction credible intervals (e.g. 95% CI from posterior ensemble or bootstrapped prediction intervals).
- [ ] Implement spatial-error quantification: for each prediction grid cell, compute the per-cell prediction standard error or credible interval width as a function of predictor extrapolation distance and local spatial variation.
- [ ] Add optional uncertainty propagation to the Phase 2 pipeline so that each prediction target can be optionally computed with full uncertainty surfaces (mean + lower/upper bounds).
- [ ] Generate uncertainty maps (95% credible intervals, standard error) for a representative subset of predictions on the Europe test matrix (one model source, one SSP, one horizon).
- [ ] Document the sources and limitations of uncertainty estimates in code comments and output metadata, especially where paleo and modern model uncertainty may differ due to different training data or fit quality.

**Validation:**
- This phase is not complete until its validation passes.
- Write unit tests for the new uncertainty extraction helper that confirm credible intervals are finite, monotonic (lower < mean < upper), and consistent with model store contents.
- Run one full uncertainty-bearing prediction on the Europe test matrix to confirm that uncertainty maps are spatial smooth and interpretable (no NaNs, no infinite ranges).
- Confirm that uncertainty estimates reflect model-structure differences between paleo and modern fits (document if they are roughly similar or substantially different).
- Visually inspect one uncertainty map to confirm credible intervals are widest in regions of poor extrapolation or sparse training data.
- Run the mandatory change-review workflow before closing the phase because this phase adds new statistical inference outputs.

---

### Phase 4 - Add comparison summaries and publication-ready main-analysis outputs

**Goal:** Produce interpretable future-diversity deliverables that compare paleo-driven and modern-driven projections across scenarios and horizons.

**Tasks:**
- [ ] Add summary helpers that compare paleo and modern future predictions on a shared grid and emit tidy comparison tables, with uncertainty ranges propagated from Phase 3 estimates.
- [ ] Add map-generation scripts or helpers under the new future-analysis folder for scenario maps, delta maps, paleo-vs-modern difference surfaces, and uncertainty maps.
- [ ] Extend the current comparison logic conceptually used in `05_Compare_paleo_modern.R` so future outputs can be summarised in the same repository style, including uncertainty in paleo-vs-modern comparison deltas.
- [ ] Generate scenario-comparison summaries for 2050 and 2100, with uncertainty ranges for mean differences.
- [ ] Save figure and table outputs with date-stamped or config-stamped names consistent with the existing output structure; ensure uncertainty ranges are included in all tables.
- [ ] Document the interpretation guardrails directly in code comments or helper names where necessary, especially that paleo-driven future projections are methodological extrapolations rather than the same inferential object as modern projections, and that uncertainty estimates come from model-parameter and spatial error sources.

**Validation:**
- This phase is not complete until its validation passes.
- Run targeted tests for the new summarisation and comparison helpers, confirming they correctly propagate uncertainty ranges from Phase 3.
- Run the future-prediction pipeline on the full Europe v1 matrix of required scenarios and horizons, with uncertainty surfaces included.
- Run one executable check that verifies shared-grid joins do not silently drop cells between paleo and modern outputs and that uncertainty ranges are finite and aligned.
- Validate that all expected tables and figures are created; that comparison deltas are finite and interpretable; and that uncertainty ranges on deltas reflect the combined paleo-model and modern-model uncertainties.
- Run the mandatory change-review workflow before closing the phase because this phase adds end-user analysis outputs with uncertainty quantification.

---

### Phase 5 - Scale from Europe to all continents

**Goal:** Extend the future-prediction pipeline and comparison outputs from Europe to all available continental spatial units (likely Asia, America, and Australia/Oceania in addition to Europe).

**Tasks:**
- [ ] Update configuration entries in `config.yml` to support all continental scale_ids that exist in the paleo and modern spatial stores (verify via `build_spatial_model_store_index()`).
- [ ] Verify that the generic prediction helpers built in Phase 1 and pipeline structure in Phase 2 do not require continent-specific customisation; if they do, refactor to genericise.
- [ ] Test the future-prediction pipeline on one additional continent (e.g. Asia) to confirm reproducibility and output schema consistency across geographic regions.
- [ ] Generate future-prediction outputs for all continents using the same scenario, horizon, and climate-backend configuration.
- [ ] Extend comparison summaries in Phase 4 to aggregate across continents, producing global-scale comparison tables and continent-wise summary tables.
- [ ] Verify that output naming, file organisation, and result sizes remain manageable across all continents; adjust caching or output partitioning if necessary.

**Validation:**
- This phase is not complete until its validation passes.
- Run the future-prediction pipeline on one full test continent (not Europe) to catch any undiscovered regional dependencies.
- Confirm that outputs for all continents have matching column names, value ranges, and metadata; document any expected differences (e.g. differences in richness distributions by geography).
- Run one executable check that confirms no silent data loss or cell misalignment when joining continental results into global summaries.
- Validate that the entire continental workflow completes within a reasonable runtime estimate (document the estimate and actual runtime for future extensions).
- Run the mandatory change-review workflow before closing the phase because this phase scales the production data surface.

---

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|-----------|
| CHELSA CMIP6 file layout or URL scheme differs from CHELSA-TraCE21k assumptions | Medium | Isolate access in a backend-specific raster helper and test it independently before wiring it into the pipeline. |
| Predictor distributions in 2050/2100 exceed the training range of paleo or modern models | High | Add extrapolation diagnostics and report out-of-range predictor frequencies alongside predictions. |
| Paleo and modern models are not directly comparable under future forcing because their fitted structures differ | High | Keep both projection streams separate first, then compare only after joining on a shared grid with explicit labels and interpretation caveats. |
| Scenario x horizon x model-source branching creates excessive runtime or cache growth | Medium | Start with Europe, genus richness, one representative GCM, and a limited SSP set; expand only after timings and storage are measured. |
| Future climate data source does not align cleanly with variables used in fitted stores | Medium | Lock the future backend to the exact `sel_abiotic_var_name` set and fail early on any unavailable variable. |

---

## Open Questions

- Which exact SSP set should define v1: only a minimal pair such as SSP2-4.5 and SSP5-8.5, or a broader panel?
- Which representative GCM should be used first for Europe before any multi-GCM extension?
- Should v1 remain genus-only, or should family and functional-type predictions be added once the future pipeline works for genus?
- Should extrapolation diagnostics be treated as mandatory outputs in the first release, or as a follow-up phase?

---

## End-of-plan checklist

- [ ] Confirm the exact SSP list and first-pass GCM.
- [ ] Decide the final config and store names for the future-prediction pipeline.
- [ ] Implement Phase 1 before creating any broad scenario matrix.
- [ ] Keep Europe as the only production scope during Phases 1–3 until runtime, cache size, and interpretability are verified.
- [ ] Verify that uncertainty information (posterior samples or credible intervals) is accessible in the existing sjSDM model stores before Phase 3 begins.
- [ ] Identify all continental scale_ids in the current spatial grids before Phase 5 begins.
- [ ] Plan continental-scale resource allocation (compute time, storage) before Phase 5 production runs.
