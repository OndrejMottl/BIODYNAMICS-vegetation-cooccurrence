# Prepared-fold cache preservation and modern restart

## Change

The shared preparation endpoint now resolves its prior local object path through public `targets` APIs and reads it with the project's qs2 reader. It never reads target metadata during execution. It always prepares folds from current inputs and preserves the original cached record only when complete normalized analytical content is exactly identical and preparation succeeded. The existing version-five normalizer excludes only preparation runtime and spatial runtime/memory measurements. Unknown analytical fields remain significant. Failed, missing, unreadable or malformed caches are not certified.

No production target names, store paths, model settings, grids, CV budgets or final-model budgets changed. No target metadata was patched or dependency cue disabled. Genuine analytical changes still invalidate downstream fitting.

## Evidence

The red test run failed on the missing reuse and argument-validation behavior before implementation. A stronger end-to-end test deliberately changes operational measurements and exposed that `tar_read_raw()` is unsupported within its own running pipeline. That initial adapter was replaced before any production restart. Focused tests cover responses, predictors, sample identities, scaling, unknown analytical fields, fold contexts, spatial strategy, preparation failures, recovery, empty input and malformed runtimes. A real isolated `targets` pipeline demonstrates that a semantically equivalent preparation command change does not rerun a cached downstream fit; changing the response does rerun it. The focused standalone test emits only the installed-package R-version warning.

The direct CZ core check passed with the revised reader: a preparation-only rebuild after an equivalent-function change returned the exact cached fold object and left fitting metadata unchanged. Its initial direct `tar_make()` probe lacked the required interpolation registry and failed in the test store only; recovery used the canonical `run_pipeline()` wrapper. The core pipeline then completed a normal warm-cache run. A subsequent modern CZ preparation-only rebuild preserved all three raw fold records and all cached fitting metadata exactly. No production store was modified by these diagnostics. Exact evidence is in `prepared_fold_live_cache_proof.csv` and `modern_prepared_fold_cache_proof.csv`.

The read-only restart audit found all nine required modern calibration representatives compatible: eight exact legacy matches and the migrated modern continental functional-type result accepted under the current contract. It saved the relevant production metadata before restarting. This compatibility audit is distinct from the live preparation-freshness guard, which each production component still runs before fitting.

Architecture generation and blocking validation passed with zero findings. Configuration generation and semantic-reference validation passed. Function references were regenerated and rendered, and `git diff --check` passed. The full test suite passed with no failures or errors; package-build-version and the existing database-disconnection warnings were retained in its log. CZ smoke results and the launch receipt will be recorded below once completed.

## Execution scope and provenance

Base commit: `6483905b0ca1174318743d8189b08ef9181da789`, with existing uncommitted work preserved. The approved restart uses the canonical Stage 03 components `04_fit_modern_spatial_continental.R`, `05_fit_modern_spatial_regional.R` and `06_fit_modern_spatial_local.R`, in that order, through the existing sequential stage orchestrator. The detached operational harness does not introduce another analysis workflow. The first unexplained failure stops subsequent components.

Audit and metadata snapshot: `Data/Temp/Main_analysis_execution/modern_cache_restart_20261013/`. Validation logs: `Data/Temp/prepared_fold_cache_{focused,validation,docs,full_tests,smoke,audit}_20261013.log`. Production log and PID are recorded in `launch_receipt.csv` when the restart is launched. Paleo fitting, calibration publication, production store resets and Git commits are outside this operation.

## Current state

Final focused tests passed 42 assertions across the preparation and cache-reader contracts. The full test suite passed with no failures or errors after the fixture was made explicitly RDS. Documentation, architecture, configuration, the nine-representative calibration/cache-reader audit, CZ smoke pipelines and the warm modern cache proof passed. `git diff --check` passed, and generated configuration and the lockfile remained unchanged.

The detached modern sequence started at 2026-10-13 13:37:41 UTC (15:37:41 Prague time), PID `39828`. The canonical continental component is active as PID `47476`; regional and local are queued behind it. GPU/Python setup completed successfully. At the initial live verification, the runner was performing prerequisite/cache checks, not yet reporting a production fitting branch. The master log is `Data/Temp/Main_analysis_execution/03_model_fitting_modern/20261013_153741/modern_sequence_master.log`; the continental log is beside it as `04_fit_modern_spatial_continental.log`. The receipt is also preserved as `modern_restart_launch_receipt.csv` in this report directory. No production model was launched before completion of the required checks.
