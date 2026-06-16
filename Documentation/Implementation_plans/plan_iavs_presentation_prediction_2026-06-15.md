# Plan: Slide 12 Paleo Prediction Animations

## Summary
Replace the placeholder slide 12 prediction animation with two real LGM-to-present GIFs built from the existing Europe continental genus model in `pipeline_paleo_spatial_resolution`.

Use the existing store:
`Data/targets/paleo_spatial_continental/europe/pipeline_paleo_spatial_resolution`

Use these targets:
`model_jsdm_selected_genus`, `data_model_input_genus`, `data_coords_projected`, `data_spatial_mev_core`, `data_spatial_mev_samples_genus`, `data_spatial_scaled_list_genus`, `model_evaluation_genus`.

`Fagus` is the selected genus for the taxon animation. Diversity will be labelled as expected genus richness, calculated as the row-wise sum of predicted genus probabilities.

## Key Changes
- Refactor `R/03_Supplementary_analyses/Prediction/Predict_on_full_grid.R` into a thin orchestration script using new tested helpers in `R/Functions`.
- Reuse existing project helpers where applicable: `build_spatial_model_store_index()`, `get_spatial_window()`, `check_target_succeeded()`, and existing MEV/CHELSA helpers.
- Add only missing modular helpers for:
  - reading suffixed spatial-resolution prediction inputs,
  - building a land-masked prediction grid from `get_spatial_window("europe")`,
  - extracting/scaling CHELSA predictors by age,
  - aligning/interpolating spatial predictors,
  - predicting with `sjSDM:::predict.sjSDM(..., type = "link")`,
  - asserting predictions are finite probabilities in `[0, 1]`,
  - summarising expected genus richness.
- Replace `future_predictions_animation.R` placeholder logic with real frame generation:
  - `slide_12_future_predictions_fagus.gif`
  - `slide_12_future_predictions_expected_genus_richness.gif`
  - frames under `Documentation/Presentations/IAVS_2026/figures/results/frames/...`
- Do not use nonexistent placeholder helpers such as `get_result_frame_dir()` or `save_result_placeholder()`.

## Quarto Slide Updates
- Update `Documentation/Presentations/IAVS_2026/index.qmd` slide 12 to source the real script with `eval: true`.
- Display both GIFs side by side.
- Rename slide chunk labels so they are unique:
  - future prediction chunks become `result-slide12-*`
  - current take-home/synthesis chunks become `result-slide13-*`
- Update slide text away from “future predictions” unless explicitly framed as past-to-present model predictions that motivate future use.

## Validation
- Follow TDD for every new `R/Functions` helper:
  - roxygen stub,
  - unit tests,
  - fail against stub,
  - implement,
  - pass targeted tests.
- Run metadata preflight on the Europe store and fail early if required genus targets are missing or errored.
- Run a smoke prediction on one age and a coarse grid before full animation generation.
- Preflight CHELSA cache/network access and assert `magick` is available; final GIF generation must require `used_magick == TRUE`.
- Run:
  - targeted helper tests,
  - `Rscript R/03_Supplementary_analyses/Testing/Run_tests.R`,
  - `Rscript R/02_Main_analyses/Run_CZ_test.R` because new helpers in `R/Functions` are auto-sourced by main setup.
- Run the read-only changes-reviewer workflow after each implementation phase for instruction compliance; treat this separately from tests and rendering.

## Assumptions
- Use `project_paleo_spatial_continental`, `scale_id = "europe"`, `resolution_id = "genus"`.
- Use ages from the spatial config age range, `0` to `20000`, stepped by configured `data_processing$time_step`.
- Use `sel_grid_resolution = 0.5` degrees unless runtime is too slow, in which case only smoke checks use a coarser grid.
- Prediction probability scale is `type = "link"` for the installed `sjSDM`; helpers must assert bounded probability output before downstream diversity calculation.
