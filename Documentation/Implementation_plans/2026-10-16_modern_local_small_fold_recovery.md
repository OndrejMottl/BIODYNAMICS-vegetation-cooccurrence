# Modern-local small-fold fitting recovery

## Scope and authorization

On 16 October 2026 the user authorized stopping the current modern-local run, investigating its failures and large tuning batch, fixing implementation defects, and continuing. Do not change scientific feasibility thresholds, fold policy, tuning grids, calibration budgets, or unrelated computations.

## Confirmed evidence before implementation

- Coordinator PID 9124 and its verified descendants were stopped. A subsequent process enumeration confirmed the coordinator and component PID 42992 were absent. Other projects were not stopped.
- The current run is `20261015_104316`, canonical component `06_fit_modern_spatial_local.R`.
- Cached branch errors identify `am_r007_l001` (80 failed branches), `am_r008_l002` (40), and `am_r008_l014` (40) with the secondary diagnostic-recording failure.
- An isolated fit on the first cached `am_r007_l001` family fold reproduced `ZeroDivisionError` at `model_sjSDM.py:411`. sjSDM 1.0.7 computes its default batch size as `floor(nrow(env$X) * 0.1)`; eight training rows yield zero.
- `fit_sjsdm_cross_validation_candidate()` returns no scalar epochs, slope, median difference, or early-stopping fields on its `fit_error` path. `run_sjsdm_prepared_tuning_candidate()` forwards these missing fields to the result builder, which then fails with `epochs_run must be size 1, not 0`, obscuring the Python error. The subsequent missing-`qs` messages are dependency cascades, not evidence requiring a package installation.
- The 11,912 functional-type branches for `am_r010_l001` are 1,489 leave-one-location-out folds times eight candidates. Cached fold-search evidence confirms that 5, 10, 20, and 50 grouped folds each failed the existing minimum-taxa requirement in at least one training partition. Leave-one-location-out passed. This is a genuine configured fallback, not a duplicate-dispatch defect; retain it without weakening scientific guardrails.

## Minimal changes and tests

1. Specify and test a complete scalar diagnostic contract for failed CV fits. Preserve original errors and their attempt tables, with typed missing values for unavailable convergence diagnostics. Ordinary fit errors still do not escalate.
2. Specify and test a safe automatic batch size for fewer than ten training observations in the shared model adapter. Preserve explicit batch sizes and the unchanged default path for ten or more observations. Record the resolved batch size in the fitted sjSDM object's existing settings.
3. Test boundaries, explicit overrides, original error propagation, and successful fitting of a previously failed cached fold. Do not mark an unexplained runtime error as expected data infeasibility.
4. Run focused tests, architecture/documentation generators and blocking validation, the full test suite, and the canonical paleo/modern CZ smoke pipelines before production resumes.

## Cache and restart contract

Preserve every production store and prepared-fold object. Do not edit private targets metadata, reset stores, or install `qs` to conceal upstream errors. Source changes may legitimately invalidate fitting targets; let targets track these changes normally and report any resulting refitting rather than claiming all successful GPU work can necessarily be reused. Calibration evidence is retained only after the existing compatibility guard accepts it.

Restart only the canonical modern-local component in a detached sequential process after validation. Retain the interrupted log, publish a new timestamped log and launch receipt, record source hashes and recovery events, verify the subprocess is alive, and inspect its first genuine fit/error outcome. Synthesis and visualization are outside this restart's scope.
