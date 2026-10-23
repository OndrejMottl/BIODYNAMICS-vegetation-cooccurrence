# Content-verified prepared-fold cache preservation

## Approved scope

Preserve completed tuning when a normal preparation rebuild produces exactly the same analytical fold contents. Then resume the modern continental, regional and local fitting components sequentially, without starting the paleo sequence or publishing new calibration budgets.

## Implementation

Extend `prepare_sjsdm_tuning_folds()` with an optional cached-record reader. Always construct folds from current inputs first. Compare the complete current and cached records using the existing version-five analytical-content normalizer, which removes only preparation runtime and spatial runtime/memory measurements. If all current folds prepared successfully and the normalized records are identical, return the original cached object, including its historical measurements. Missing, unreadable, malformed, failed or analytically different records are not reused. Empty infeasible fold lists may remain empty.

The shared pipeline target resolves its own local object path using public `targets` APIs and reads it with the project's qs2 reader. Reading metadata with `tar_read_raw()` inside the same running pipeline is unsupported, so the cache reader deliberately does not do that. Target names, stores, scientific settings and fitting executors stay unchanged. There is no private metadata editing, cue suppression or cache approval based only on sample counts or work-item identifiers. Genuine changes to observations, predictors, folds, identifiers, scaling, spatial strategy and other analytical fields follow normal invalidation; independent CV-budget dependencies still invalidate fitting normally.

## Evidence and validation

Write failing tests before implementation. Cover operational-only differences, analytical differences, failures, unreadable caches and real target dependency behavior in an isolated store. Regenerate function documentation and architecture/configuration inventories; run focused and full tests and both CZ smoke pipelines. Before production, verify active processes and store availability, and retain logs and provenance. Completed production folds may be refreshed only through ordinary target execution; compare cached fitting records before and after where feasible.

## Restart

Run only Stage 03 components `04_fit_modern_spatial_continental.R`, `05_fit_modern_spatial_regional.R` and `06_fit_modern_spatial_local.R`, using the existing sequential stage orchestrator in a detached process with timestamped logs. Stop at the first unexplained failure. Existing production calibration guards remain mandatory. Do not reset stores, refit paleo, change calibration/final budgets, commit or push.
