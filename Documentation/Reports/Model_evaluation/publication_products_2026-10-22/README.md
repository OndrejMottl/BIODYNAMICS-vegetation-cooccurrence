# Stage 04 and Stage 05 publication run, 22 October 2026

## Execution result

The approved Stage 04 synthesis and Stage 05 visualisation masters completed successfully, sequentially, between 15:35:57 and 15:44:00 Europe/Prague on 22 October 2026 (13:35:57–13:44:00 UTC). All four synthesis components and seven visualisation components returned exit status zero. Calibration, production fitting, and regularization sensitivity were not restarted.

```powershell
Rscript R/02_Main_analyses/04_Synthesis/01_run_synthesis.R
Rscript R/02_Main_analyses/05_Visualisation/01_run_visualisation.R
```

The run used commit `6483905b0ca1174318743d8189b08ef9181da789` with the existing dirty worktree, not a clean checkout. The recorded configuration xxhash64 is `4355c93dde04dfc9`. See `publication_run_provenance.csv` and `publication_component_status.csv` for the actual execution record.

## Verified output coverage

- Eight canonical figures were exported, each as PDF, TIFF, and PNG: 24 nonempty files, all modified during this run. File paths, timestamps, sizes, and SHA-256 hashes are recorded in `publication_figure_inventory.csv`.
- PNG files are 2000 × 1600 pixels; TIFF files are 4000 × 3200 pixels. See `publication_raster_dimensions.csv`.
- Spatial synthesis contains 229 distinct paleo and 275 distinct modern unit–resolution models. All three spatial tiers and resolutions are represented in each dataset. These counts describe available fitted models, not every requested or theoretically possible model.
- Every fitted modern model in the previous completion audit is represented: `missing_fitted_modern_models.csv` has zero data rows.
- Matched comparison validation retained 163 biotic comparison rows and checked modern-minus-paleo arithmetic. Counts by tier and resolution are saved in `matched_unit_counts.csv`.
- The existing preservation check compared 1,964 monitored production targets across 294 modern stores against the pre-publication baseline. Hashes and timestamps were all identical. Evidence is in `../modern_spatial_completion_2026-10-20/main_target_preservation_check.csv`; this is not a claim that every target in every paleo/temporal store was independently compared.

## Scientific and visual caveats

Successful execution does not constitute complete scientific or manuscript-layout acceptance.

The cached paleo temporal results include 28 time slices classified as `unexpected_error`: America 2, Europe 6, and Asia 20. There are 95 slices classified as available. The complete error rows, root targets, and saved error messages are in `temporal_cached_error_rows.csv`; counts are in `temporal_slice_status_counts.csv`. Examples include `data_sample_ids must be a data frame` and a saved `ZeroDivisionError`. These were surfaced from existing stores, not newly caused by this publication run. They have not been reclassified as expected data limitations or refitted. Spatial completion must not be interpreted as temporal completion.

All eight review PNGs were visually inspected. The matched-comparison figure has overlapping or clipped count/exclusion annotations and an overlapping panel-B label. The functional-type figure clips its panel-A tag. The temporal figure's sampling-density strip is not visibly rendered, and its density-legend tick labels are crowded. The paleo atlas remains dense at local scale. These outputs are reproducible but are not all manuscript-ready; see `visual_review.csv`. No plotting implementation was changed during this execution-only request.

## Logs and recovery

The outer queue log is `Data/Temp/Main_analysis_execution/publication_products_20261022/queue.stdout.log`; its component logs and status file are under `Data/Temp/Main_analysis_execution/publication_products_20261022/20261022_153557/`. Inner synthesis logs are under `Data/Temp/Main_analysis_execution/04_synthesis/20261022_153804/`, and inner figure logs are under `Data/Temp/Main_analysis_execution/05_visualisation/20261022_154209/`.

No runner restart is needed for this completed job. The next distinct tasks are a figure-layout repair and a separately scoped investigation of the cached temporal failures. Neither requires automatically rerunning spatial calibration or fitting.
