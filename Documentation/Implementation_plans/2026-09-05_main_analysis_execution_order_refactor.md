# Refactor main analyses into an executable numbered workflow

## Summary

Replace the analysis-first layout and hidden preparation mode with five genuinely sequential stages: preparation, model calibration, model fitting, synthesis, and visualisation. Each stage exposes one master runner, while `_components/` retains granular recovery entry points.

## Execution contract

1. `R/02_Main_analyses/01_Preparation/01_run_preparation.R`
2. `R/02_Main_analyses/02_Model_calibration/01_run_model_calibration.R`
3. `R/02_Main_analyses/03_Model_fitting/01_run_model_fitting.R`
4. `R/02_Main_analyses/04_Synthesis/01_run_synthesis.R`
5. `R/02_Main_analyses/05_Visualisation/01_run_visualisation.R`

Preparation and fitting use separate scripts. The preparation master caches current folds for paleo spatial, modern spatial, and paleo temporal analyses. Calibration inventories those folds, benchmarks every selected representative sequentially, publishes accepted budgets, and regenerates configuration. Fitting then resumes the same target stores without forcing preprocessing. Synthesis and visualisation run only after their required upstream artifacts exist.

The continental legacy audit and targeted invalidation remain available only as a documented one-time migration under `R/03_Supplementary_analyses/One_time/Cross_validation/Fit_budget_migration/`.

## Operational behavior

- Master runners execute components sequentially in isolated R subprocesses.
- Console output is mirrored to timestamped logs under `Data/Temp/Main_analysis_execution/`.
- Expected insufficient-data outcomes remain eligible skips; unexplained failures block downstream stages.
- Rerunning a stage reuses target stores and accepted calibration results.
- Every failure identifies the required numbered stage, failed component, log, and recovery command.

## Compatibility and validation

Keep target stores, target names, tuning grids, worker settings, and scientific outputs unchanged. Update supported-runner metadata, active documentation, error messages, tests, generated configuration, and architecture inventories for the new paths. Confirm that path-only metadata changes do not invalidate completed prepared-fold targets. Run focused orchestration and CV tests, configuration and architecture generators, the full test suite, and CZ smoke pipelines.

## Implementation record

Implemented on 2026-09-05 without resetting or discarding the existing CV-budget worktree. The five numbered stages, master runners, recovery components, artifact-based prerequisite guards, timestamped execution records, automatic calibration enumeration, and one-time migration workflow are in place. Obsolete production runner paths and the preparation-mode environment switch were removed.

Configuration generation and semantic-reference validation passed for all 26 profiles, with analytical profile content unchanged by runner-path authorization metadata. Architecture inventories and the persisted-contract manifest were regenerated; the blocking architecture validator completed with zero findings across zero types. All 138 changed R files parsed successfully and satisfied the 80-column R-source contract.

The full repository test suite completed with exit status 0. The combined paleo and modern CZ smoke runner completed with exit status 0; its durable logs are under `Data/Temp/Main_analysis_execution/validation/`. A bounded ordinary update of the preserved paleo continental Europe store completed in 10.2 seconds with 28 lightweight configuration and fingerprint targets refreshed and 1,447 analytical targets skipped. That check did not exercise `prebuild_interpolation = TRUE`. The first live stage-01 master run exposed unconditional shared-input invalidation in the interpolation prebuild helper, which would rebuild cached dynamic branches. The helper now invalidates only errored interpolation targets; a regression fixture confirms that a second prebuild leaves successful interpolation at one execution while retaining targeted error recovery.
