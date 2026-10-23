# Modern fitting infeasibility handling

## Scope and outcome

This fix follows the stop/investigation recorded in `../modern_regional_stop_2026-10-14/`. Modern regional and local components now classify preparation separately by resolution before requesting tuning or final fitting. Production and the queued local continuation remain stopped. No target stores were deleted/reset, no packages installed, and no fitting budgets, scientific thresholds, or configuration fragments changed.

Registered failed preparation roots are reattempted once per unit, with the existing lightweight worker setup and no interpolation prebuild. Only those roots are requested: normal targets dependency checks inspect current commands, configuration, and input hashes. Current expected root evidence permits exclusion; a root that now succeeds requires refreshed stage 01/02 evidence. Successful cached folds are read without executing their preparation. The isolated warm-store regression verifies unchanged healthy final-model metadata and rejection of an old exclusion after its input changes.

Wholly infeasible units have no tuning/fitting request. Partial units retain targets for every viable resolution. Tier pooling reads the same explicit eligible store-target pairs from `sjsdm_tier_unit_requests.csv` under the configured tier store root, outside internal targets object/metadata directories. Unexplained tuning failures and incomplete eligible artifacts block tier selection after independent units are attempted.

Missing serialized objects are distinguished from existing unreadable objects before assigning cache-recovery status. A missing-qs fallback alone remains unexplained. It is a dependency cascade only alongside a registered current data root; a thrown empty-branch error may retain that root's expected status, but an unrelated subprocess error is not reclassified.

## Validation evidence

The final focused tests, complete test suite, warm canonical paleo/modern CZ smoke checks, and blocking architecture validation are preserved beside this report with their receipt. The two new helpers were tested against empty stubs before implementation. Additional tests cover absent serialization objects, shared and partial infeasibility, stale exclusions, malformed tier requests, strict unexpected errors, and actual cold/warm isolated targets stores. All selected changed R sources parse and satisfy the 80-column limit; whitespace checks pass.

The full suite may emit existing package-build and DBI cleanup warnings; the logs distinguish these from test failures. The architecture generators recorded 19,782 profile-target rows across 26 profiles, and the final standalone validator reported zero findings. Function documentation was regenerated and its published pages rendered. No production fitting or calibration was used as a validation shortcut.

## Restart boundary

Resume the canonical modern regional component only after explicit restart approval: `R/02_Main_analyses/03_Model_fitting/_components/05_fit_modern_spatial_regional.R`. Successful targets remain cached. Modern local still requires the two previously identified America-local representative calibrations and scoped CV-budget publication before its fitting guard will pass. The stopped queued continuation points to the old regional run/PID and must not be relaunched unchanged against a new regional run.

Cached objects are preserved rather than forcibly reset. If corrected eligibility changes tier evidence or selected regularization, ordinary targets invalidation may correctly rebuild the dependent tuning/model products; this fix does not bypass those scientific dependencies.
