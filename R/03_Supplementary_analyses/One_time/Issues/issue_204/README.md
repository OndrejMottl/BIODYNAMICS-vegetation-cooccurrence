# Issue 204 projection diagnostics

## Purpose and backstory

Spatial predictors (Moran eigenvector maps, MEMs) were built from coordinates projected with EPSG:3035, a European projection, for every continent. Distances in North America and northern Asia were therefore distorted. The projection is now chosen per continent (`spatial_crs_by_continent`). These scripts record how the projection was chosen and which fitted models change materially.

## Status and entry point

Status: one-time diagnostics for issue #204.

Run from the repository root:

```powershell
rig run -r 4.5.1 R/03_Supplementary_analyses/One_time/Issues/issue_204/diagnose_projection_distortion.R
rig run -r 4.5.1 R/03_Supplementary_analyses/One_time/Issues/issue_204/diagnose_mem_projection_change.R
rig run -r 4.5.1 R/03_Supplementary_analyses/One_time/Issues/issue_204/estimate_refit_cost.R
```

## Prerequisites and configuration

Both scripts only read production stores. `diagnose_projection_distortion.R` follows the 9 November 2026 method: up to 300 random cores per continental store (seed 900723), pairs more than 50 km apart, and the ratio of projected to great-circle distance. Great-circle distances use `{s2}` on a spherical Earth because `{lwgeom}` is not installed; this shifts every ratio by less than 0.5 % and does not change the ranking. Candidates per continent are EPSG:3035, the regional Albers equal-area projection (ESRI:102008 for America, ESRI:102025 for Asia), and the Lambert azimuthal equal-area and azimuthal equidistant projections centred on the continental grid box. The narrowest 5-95 % ratio range (ties: median closest to 1) selects the projection; Europe keeps EPSG:3035 by decision.

`diagnose_mem_projection_change.R` reads the projections from `spatial_crs_by_continent` in `config.yml`. The refit threshold (`threshold_r2 = 0.99`) was fixed in the script before the run.

## Outputs and interpretation

In `Documentation/Reports/Model_evaluation/stage_a_model_input_corrections_2026-11/`:

- `projection_distortion.csv`: ratio median, `lwr_90` and `upr_90` (5th and 95th percentiles), minimum, maximum, and range per data source, continent, and candidate; `flag_selected` marks the chosen projection.
- `mem_projection_r2_by_unit.csv`: for every American and Asian unit and resolution, the smallest R^2 of a new MEM regressed on the stored MEMs, the MEM counts, whether the model is published, and `flag_refit` (R^2 below the threshold or a changed MEM count).
- `fossil_projection_refit_list.csv`: published fossil-pollen models that need refitting, including units for which the new projection supports no positive MEM (they become expected infeasible when refitted).
- `refit_cost_by_unit.csv` (`estimate_refit_cost.R`, run after the MEM diagnostic): for every published fossil and modern unit on every continent, one row per resolution plus one `shared` row for targets common to all resolutions, with the recorded compute hours of the targets downstream of `data_coords_projected`, split into cross-validation, final fit, variance partition and other targets, and `flag_refit_projection` from the MEM diagnostic. Hours are the `seconds` that `{targets}` recorded at the last build of each target (stems and patterns; branch time is included in its pattern). Builds ran one target at a time, so the hours approximate wall-clock time on the same GPU.

Units whose pipeline stopped before `data_coords_analysis` (VegVault extraction failure, constant predictors or too few cores) have no stored coordinates and are reported as `not_built`; none of them holds a published model. Reading such a target directly fails with the misleading "there is no package called 'qs'", because `{targets}` falls back to the legacy `qs` reader whenever the `qs2` read fails, including for a missing object file.

## Regeneration and retirement

Rerun only if the candidate projections or the stores change. Archive this folder when issue #204 closes.
