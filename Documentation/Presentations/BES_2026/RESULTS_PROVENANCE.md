# BES 2026 results provenance

The BES 2026 deck is a copy of the CSPE 2026 deck. The spatial results come from the newer cross-validated fits, and a new section shows how the association share depends on the number of taxa in a model. All results are preliminary. Every model will be refitted once the corrected VegVault release is available (Stage B of `Documentation/Implementation_plans/2026-11-16_model_input_corrections_and_rebuild_plan.md`).

## Source of each slide

| Slides | Results | Source |
| --- | --- | --- |
| 03 to 07 (data and methods) | Schematics, data coverage, climate screening, example decomposition | Copied from CSPE 2026 (`figures/results/`), unchanged |
| 08 and 09 (spatial axis) | October 2026 cross-validated fossil-pollen spatial fits | `R/Visualisation/spatial_association_tiles_figure.R` and `spatial_taxonomic_matrix_figure.R`, reading `Outputs/Tables/paleo_patterns_unit_2026-10-22.csv` |
| 08 map animation | Spatial units, local to regional to continental | `R/Visualisation/spatial_units_map_figure.R` (frame order reversed for BES; reads VegVault) |
| 10 and 11 (temporal axis) | June 2026 temporal fits, without cross-validation | Copied from CSPE 2026 (IAVS 2026 assets), unless the section below records the November rerun |
| 11b (matrix scale, main talk) and extra slides 11c to 11e | October 2026 fits and the 6 November 2026 per-taxon partition diagnostics | `R/Visualisation/model_size_figures.R`, reading `Outputs/Tables/Visualisation/paleo_variance_partitioning_unit_2026-10-23.csv` and `Outputs/Tables/Diagnostics/Taxon_variance_partition/{model_share_definitions,nested_extent_contrasts}_2026-11-06.csv`; values quoted in the notes are in `figures/results/model_size_summary.csv` |
| Extra slide 11f (taxa through time) | June 2026 temporal fits | `R/Visualisation/temporal_taxa_share_figure.R table` |
| 12 (paleo predictions) | IAVS 2026 prediction animations | Copied from CSPE 2026 |
| 13 (take-home counts) | Counts recomputed on 23 November 2026 | `results_snapshot.json`; see below |
| Extra slides | IAVS 2026 assets | Copied from CSPE 2026, not updated |

The plot code of the matrix-scale slides is ported from the Round 0 report (`Documentation/Reports/Third_report/_Project_status_and_direction.qmd`, chunks `model-matrix-size`, `compare-tier-gradient`, `fit-climate-balance`, `fit-nested-extent` and `plot-taxa-through-time`) and reproduces its values.

## Summary counts on the take-home slide

The counts in `results_snapshot.json` were recomputed on 23 November 2026 with the logic of the IAVS 2026 chunk `slide-13-data-overview`, using current sources:

- cores, spatio-temporal communities and taxa: distinct `dataset_name`, `dataset_name` and `age` pairs, and `taxon` in `data_community_analysis` of the continental fossil-pollen spatial stores (October 2026) and the three temporal stores (June 2026 fits, read from `Data/targets/_archive/2026-11-23_june_temporal_fits/` for Europe and North America);
- trait values: rows of `data_traits_classified_corrected` in `Data/targets/traits_reference/pipeline_traits_reference` (lower than the IAVS value after the trait corrections);
- functional types: distinct functional-type labels across the continental functional-type model matrices (IAVS summed the matrix widths of the three continents);
- models: 229 fossil-pollen spatial models (`paleo_variance_partitioning_unit_2026-10-23.csv`) plus 95 temporal slice models (June 2026 fits).

The snapshot keeps the mode name `frozen_iavs_artifacts` because `load_results_snapshot()` requires it.

## Caveats kept for the speaker notes and the methods meeting

- All fits use VegVault 1.0.0, whose age-0 `bio4` values are zero south of 65.7 degrees N and whose trait units need correction (VegVault#76, VegVault#78).
- The variance partitions of penalised models overstate the association share (by 1.2 to 20.6 percentage points in the Stage A pilot). The matrix-size relation is not produced by this bias: among the 140 fossil-pollen spatial models without a penalty on the association term, log taxon number explains R² = 0.73 of the association share, against 0.68 for all 229 models (`model_size_summary.csv`).
- The equal-taxon values on slide 11d come from a linear model with taxon number, resolution, extent and continent; they are an adjustment, not a refit.
- Slide 11e is the exploratory nested-extent diagnostic, marked in the Round 0 report as not to be quoted.

## Temporal rerun of November 2026

On 23 November 2026 the Europe and North America temporal stores were refitted with the calibrated cross-validated workflow (0 ka excluded because of the `bio4` zeros; Asia not rerun, because almost all of its slices are too small for that workflow). The June fits are archived in `Data/targets/_archive/2026-11-23_june_temporal_fits/`. Status on 23 November 2026: Stage 01 preparation (cross-validation folds) completed for both continents, but both fit runners stopped at the calibration check before any model was fitted. North America reported that the Stage 02 fit-budget calibration is incompatible with the current preparation (the Stage A configuration changes and the new exclusions), and Europe checked the North America store before its folds were prepared. No temporal model was refitted, so slides 10 and 11 and extra slide 11f show the June 2026 fits. Rerunning Stage 02 calibration is an open decision of the rebuild plan.
