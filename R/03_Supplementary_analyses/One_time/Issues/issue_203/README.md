# Issue 203 variance-partition penalty pilot

## Purpose and backstory

`sjSDM:::anova.sjSDM()` (sjSDM 1.0.7) refits each variance-partition sub-model with a default `bioticStruct()`, so sub-models that contain the association component lose the association penalty of the full model (`lambda_cov`), and they use the default sjSDM seed instead of the model seed. `compute_jsdm_variance_partition()` now runs the same method through `build_jsdm_variance_partition_method()`, which carries the full model's penalty settings and seed into every sub-model. This folder records the pilot that compares published partitions with corrected ones before the selective rerun.

## Status and entry point

Status: one-time pilot for issue #203.

Run from the repository root:

```powershell
rig run -r 4.5.1 R/03_Supplementary_analyses/One_time/Issues/issue_203/run_variance_partition_penalty_pilot.R
```

## Prerequisites and configuration

The script copies the pilot stores to `Data/Temp/pilot_203/` with the `<target_store>/<scale_id>/<pipeline_name>` layout, then rebuilds only `list_jsdm_variance_partition_<resolution>` on the copies with `shortcut = TRUE`. Production stores are only read. A GPU is used for the sub-model fits.

## Outputs and interpretation

`Documentation/Reports/Model_evaluation/stage_a_model_input_corrections_2026-11/variance_partition_penalty_pilot.csv` has one row per unit, resolution, and component, with the full model's `lambda_cov`, the published and corrected Shapley share percentages and their difference, the published and corrected raw three-way fraction (Abiotic & Associations & Spatial), and the partition runtime. Units with `lambda_cov = 0` differ only by the change of sub-model seed.

## Regeneration and retirement

The pilot is evidence for the issue #203 decision and the Stage B rerun. Archive this folder when issue #203 closes.
