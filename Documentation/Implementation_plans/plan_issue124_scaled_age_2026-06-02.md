# Plan: Implement Issue #124 With Default Paleo Tuning Reset

**Date:** 2026-06-02
**Issue:** https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/124

## Summary

Keep the production predictor column named `age`, but scale it to mean 0 and
standard deviation 1 before sjSDM fitting. Preserve sjSDM ANOVA as the
production decomposition method. Reset all paleo spatial tuning CSVs to
model-fitting defaults first, because the corrected scaled-age models are new
specifications and old tuning values are not reliable priors.

## Key Changes

- Update `scale_abiotic_for_fit()` to accept
  `age_scale_mode = c("z_score", "center")`, defaulting to `"z_score"`.
- Keep the column name `age`; do not introduce `age_z`.
- Update `scale_abiotic_for_fit()` docs and tests so default `age` scaling has
  mean 0 and standard deviation 1 when age varies.
- Add `model_fitting.age_scale_mode: "z_score"` to `config.yml`.
- Include `age_scale_mode` in shared and resolution-specific
  `config_model_fitting` targets.
- Pass `config_model_fitting$age_scale_mode` into `scale_abiotic_for_fit()`
  from `pipe_segment_model_prepare_response.R`.
- Keep `make_env_formula()` unchanged: production age-dependent formulas remain
  `~ (bio...) * age - age`, with `age` now z-scored before fitting.
- Update prediction-time abiotic scaling in `Predict_on_full_grid.R` so `age`
  uses both `scaled:center` and `scaled:scale`.
- Preserve diagnostic route behavior by explicitly using center mode where
  legacy diagnostics require it.

## Tuning Reset

- Reset these paleo tuning files to defaults for every existing `scale_id` row:
  - `Data/Input/Model_tuning/model_tuning_paleo_spatial_genus.csv`
  - `Data/Input/Model_tuning/model_tuning_paleo_spatial_family.csv`
  - `Data/Input/Model_tuning/model_tuning_paleo_spatial_ft.csv`
- Use the `default:model_fitting` values in `config.yml`:
  - `n_iter = 500`
  - `n_step_size = NA`
  - `n_sampling = 200`
  - `n_samples_anova = 1000`
  - `n_early_stopping = NA`
- Treat focused CZ and Asia runs as behavior-discovery preflights, not
  validation of old tuning.
- Retune only after observing convergence and runtime behavior under the
  default reset.

## Test Plan

- Update `test-scale_abiotic_for_fit.R` for default z-scored age, legacy center
  mode, and recorded `scale_attributes$age`.
- Update `test-prepare_decomposition_fold_input.R` so diagnostic center and
  z-score route semantics remain stable.
- Run targeted tests for scaling, diagnostic fold preparation, formula
  construction, and tuning helpers if touched.
- Run affected manifests for paleo core, paleo spatial resolution, paleo
  temporal, and CZ test pipelines.
- Run:
  - `Rscript R/03_Supplementary_analyses/Testing/Run_tests.R`
  - `Rscript R/02_Main_analyses/Run_CZ_test.R`
- Run the read-only `changes-reviewer` workflow on all changed files.

## Assumptions

- Old paleo tuning values should be overwritten, not archived in production
  CSVs.
- sjSDM ANOVA remains the production decomposition route.
- Predictive decomposition remains a diagnostic/sensitivity route.
- No git commit, push, branch mutation, or PR action should be done without an
  explicit request.
