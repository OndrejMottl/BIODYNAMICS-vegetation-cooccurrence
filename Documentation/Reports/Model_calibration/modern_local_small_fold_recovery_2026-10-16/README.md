# Modern-local small-fold recovery, 16 October 2026

## Interrupted run

The user authorized stopping, investigating, fixing, and continuing modern-local fitting. The verified coordinator for run `20261015_104316` (PID 9124) and its descendants, including canonical component PID 42992, were stopped. Both R PIDs were subsequently absent. No unrelated project was stopped, no target store was reset, and no package was installed.

Original log: `Data/Temp/Main_analysis_execution/03_model_fitting_modern_local_recovery/20261015_104316/06_fit_modern_spatial_local.log`.

## Root causes and fixes

1. **Actual small-fold fit failure.** The first family training fold for `am_r007_l001` has eight observations. Installed sjSDM 1.0.7 derives its default batch size as `floor(nrow(env$X) * 0.1)`, producing zero. The isolated Python traceback identifies `model_sjSDM.py:411`, division by `batch_size`. The shared project fitting adapter now uses batch size one only for fewer than ten observations with no explicit batch setting; explicit values and larger-data defaults are unchanged. The model's existing `settings$step_size` records the resolved value.
2. **Secondary diagnostic-recording failure.** The CV escalation adapter omitted four scalar convergence fields from its `fit_error` return. The result builder then failed on an empty `epochs_run`, concealing the original error. Failed returns now include typed missing values for epochs, slope, median difference, and early-stopping outcome. Original errors and attempt provenance are retained, and ordinary fitting errors are still not escalated. Missing-`qs` dependency messages followed these upstream failures; they were not fixed by installing packages or masking errors.

Cached metadata identified 160 affected branch errors across `am_r007_l001` (80), `am_r008_l002` (40), and `am_r008_l014` (40). Additional downstream errors are cascades, not additional independent scientific failures.

## Large functional-type batch is not a duplicate-dispatch bug

For `am_r010_l001`, the cached search tried 5, 10, 20, and 50 grouped folds. Respectively 7, 3, 2, and 2 training partitions failed the minimum-taxa requirement; other count and MEM thresholds passed. The 1,489-fold leave-one-location-out fallback passed all checks. Thus round 1 requests `1489 * 8 = 11912` candidate-fold tasks. This search policy and its feasibility thresholds are unchanged. It would be scientifically misleading to replace this with 40 fits or drop hard folds merely to improve runtime without a separate approved design change.

## Validation and preservation

- Regression tests reproduced both defects before implementation (three batch-size boundary failures; four missing diagnostic-field failures plus the original result-builder error).
- After implementation, the focused fitting, escalation, and prepared-candidate tests passed 96 assertions with no test failures, warnings, or skips. Session startup separately emits existing package/Python-selection notices.
- A real GPU fit of the previously failing cached family fold completed with 500 epochs, 200 sampling, batch size one, tail slope zero, and median difference approximately 0.01; its status was `ok` and convergence passed.
- Architecture generators and the blocking validator completed with zero findings and 19,782 configured profile-target rows.
- `preparation_hash_summary_before_resume.csv` preserves per-store preparation content fingerprints. The complete metadata snapshot is retained under the ignored execution directory identified by `preparation_snapshot_location.csv`, with its SHA-256 and row count. `calibration_compatibility.csv`, when present, records the live production calibration guard result. These are evidence, not markers that override prerequisite validation.
- The first full-suite attempt encountered two missing published documentation pages while those exact pages were being regenerated. It was not accepted as passing. The standalone function references were generated successfully; their published HTML was then rendered in an isolated Quarto project to avoid traversing unrelated website resources. The full suite is rerun only after both pages exist.
- The subsequent complete test-suite run exited successfully and emitted `PALEO RECOVERY FULL TEST SUITE PASSED`; its log is `Data/Temp/local_fitting_full_tests_verified_20261016.log`. Existing package-build-version notices and a database-connection cleanup warning are retained in the log, not silently removed.
- The live modern-local production calibration guard passed at `2026-10-16 12:14:05 UTC` against all three required representatives (America family/genus `am_r007_l008` and Europe functional types `eu_r005_l010`). Calibration fitting and budget publication were not rerun.
- `representative_batch_compatibility.csv` additionally proves that all 45 prepared representative folds are outside the corrected small-batch case: America family/genus have at least 1,808 training rows and Europe functional types at least 2,196. Their fitting behavior is unchanged by this fix.
- `preparation_preservation_before_restart.csv` compares the production preparation content fingerprints before and after implementation and validation: all 109 eligible unit stores are unchanged. This comparison includes prepared folds, community data, assignments, abiotic/spatial preparation, and functional-type file targets; the CZ smoke stores are separate.
- Full-suite, smoke, documentation, and restart results are recorded in the recovery execution logs and launch receipt; absence of a completed status is not success.

No completed cache is declared reusable merely because a branch name matches. Normal targets invalidation is retained: the fitting source changes can invalidate fitting targets even though their inputs remain scientifically identical, while upstream preprocessing and prepared folds are preserved. No private target metadata is edited and no analytical hashes are spoofed to suppress legitimate invalidation.

## Scope of continuation

Resume only `R/02_Main_analyses/03_Model_fitting/_components/06_fit_modern_spatial_local.R` after required validation passes. Accepted calibration results and published budgets are not recalculated. The canonical component rechecks prerequisites, resumes staged tuning, then final fitting, evaluation, and modern cross-tier sensitivity. Synthesis and visualization do not start automatically.

## Restart and final validation outcome

All three warm canonical CZ smoke pipelines completed successfully, each with zero errored targets in its final progress records. The full-suite log, smoke log, and regenerated-reference log are copied into the recovery execution directory and their SHA-256 values are recorded in `validation_status.csv` there. Existing runtime notices remain visible in their logs.

The detached canonical modern-local run restarted at `2026-10-16 12:32:17 UTC` (14:32 Prague), run ID `20261016_143217`. Coordinator PID 38312 and canonical component PID 52344 were verified alive after launch. `launch_receipt.csv` records the baseline commit `6483905b0ca1174318743d8189b08ef9181da789`; the actual dirty source/configuration tree is fingerprinted in the execution directory's `source_and_settings_hashes.csv`. No commit, push, package installation, store reset, recalibration, or budget republication was performed.

Live component log: `Data/Temp/Main_analysis_execution/03_model_fitting_modern_local_small_fold_recovery/20261016_143217/06_fit_modern_spatial_local.log`.

Initial activity is the canonical preparation/eligibility preflight, not immediate new tuning. It rechecks known failed roots and skips cached preparation. The log may therefore contain explicit insufficient-taxa errors such as `No taxa remain after filtering`; these remain registered expected-infeasible outcomes and are distinct from the corrected `epochs_run`/zero-batch implementation failures. Do not interpret every red targets line as an unexpected whole-component failure, or claim fitting has started before its tuning targets are actually dispatched.

A subsequent live check confirmed continued progress after these outcomes: `eu_r002_l002` was explicitly classified `expected_infeasible (no_abiotic_variation)` for all three resolutions, and the process continued. Available system RAM at that check was approximately 16.2 GiB. This is a startup observation, not a guarantee against later resource pressure or a final convergence audit.
