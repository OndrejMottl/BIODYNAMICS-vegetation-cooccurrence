# Modern restart preflight

The October 13 request authorizes resuming models. Checks were performed before launching a production runner, to avoid duplicate processes and accidental loss of completed tuning. No active fitting master/component was found. No target was executed, invalidated, deleted, or rewritten by these checks.

Modern calibration is not blocked by the nine outstanding paleo representative mismatches: the production guard selects representatives for its own analysis and tier. The recent compatibility audit accepts all nine modern representatives, including the verified migrated modern Europe functional-type result. This does not make the full nine-component Stage 03 master suitable for restart, because that master starts with paleo; the intended modern-only continuation is components 04, 05, and 06 in that order.

## Cache preservation blocker

Direct, isolated round-one `targets::tar_outdated(shortcut = TRUE)` checks in the Europe continental store report:

| Resolution | Prepared-fold target directly outdated | Tuning-result pattern directly outdated |
|---|---|---|
| Family | Yes | No |
| Functional type | Yes | No |
| Genus | Yes | No |

The store is `Data/targets/modern_spatial_continental/europe/pipeline_modern_spatial_resolution`. The exact endpoints are `list_sjsdm_prepared_tuning_folds_{family,ft_modern,genus}` and `list_sjsdm_tuning_work_item_result_{family,ft_modern,genus}`. The direct findings are saved in `modern_restart_direct_cache.csv`.

A normal runner rebuilds outdated prepared folds before tuning. Those records contain `preparation_seconds` and spatial runtime provenance, and each tuning branch depends on the whole prepared-fold target. `run_sjsdm_tuning_work_item()` has no separate content-verified fit checkpoint to recover a result once that dependency changes. Consequently, rebuilding analytically identical folds with new operational timing can invalidate completed GPU tuning, despite the tuning executor itself being unchanged. The version-five calibration signature and read-only freshness guard do not prevent this ordinary targets invalidation.

Do not interpret the broad whole-pipeline outdated list as a list of genuine data changes: unchanged always-cued configuration propagates through a dry run. Likewise, 210 cached tuning branches per continent include historical state and do not prove that every branch is current. The six direct endpoint checks above are the relevant restart warning.

## Recommended next action

Implement content-verified prepared-fold cache preservation before resuming production. If freshly constructed folds match the cached complete analytical payload exactly, return the original cached record, preserving its measured operational provenance and downstream content hash. If any analytical field, assignment, response, predictor, scaling, status, or required configuration changes, retain ordinary invalidation and block incompatible calibration. This must use normal target execution and exact content checks, not manually rewrite target hashes or set broad never-run cues.

The proposed fix requires focused cache-preservation/invalidation tests and normal validation before restarting modern continental, regional, and local components sequentially. It does not require another model-tuning reset, new scientific budgets, or automatic paleo recalibration. No model has been restarted pending this decision.

## Inspection issues

Whole-pipeline inspection in the current process encountered a variadic-evaluation error. Isolated subprocess inspection succeeded. Literal target selectors were injected into the subprocess to avoid losing caller-local selector variables. These were read-only diagnostic errors, not model failures. Raw audit outputs remain under `Data/Temp/Main_analysis_execution/modern_restart_20261013/`.
