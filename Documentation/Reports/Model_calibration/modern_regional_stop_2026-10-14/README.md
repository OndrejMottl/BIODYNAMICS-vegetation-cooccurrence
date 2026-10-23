# Stopped modern regional run: root-cause investigation

The user requested stopping regional and investigating the apparent cache/branch failures. The identified regional process tree and queued local continuation were stopped and verified exited; the process inventory and receipt are saved here. No production stores, completed targets, model budgets, or calibration evidence were deleted or reset. No modelling code was changed and nothing was restarted. The local queue status was updated to stopped rather than left as waiting.

## Findings

By the time of stopping, six units were logged as skipped. `classified_root_errors.csv` contains their registered preparation diagnoses and complete root messages.

| Units | Verified root problem |
| --- | --- |
| `eu_r003` | No family/genus taxa survive minimum-proportion filtering; no functional-type taxa survive minimum-sample filtering. |
| `am_r001` | All seven selected abiotic predictors have zero variance. |
| `am_r003`, `am_r006`, `am_r009`, `am_r012` | VegVault extraction fails with its opaque/empty condition. Independent read-only SQL confirmed that these windows have no vegetation-plot datasets, although they contain 189, 272, 71 and 145 climate-gridpoint datasets respectively. The spatial query used inclusive geographic bounds without an age restriction, so it does not exclude possible modern vegetation plots by narrowing the production age filter. |

The installed versions are `targets 1.12.0` and `qs2 0.2.0`; the legacy `qs` package is absent. Installed `targets` source shows that its `qs` reader first calls `qs2::qs_read()` and catches any error by attempting `qs::qread()`. Consequently an absent upstream object file can produce the misleading final message “there is no package called 'qs'”. The sampled failing dependencies had absent object files, not verified incompatible legacy bytes. Successful configuration and prepared-fold objects were readable through both `tar_read_raw()` and `qs2::qs_read()` without `qs` installed.

A small isolated pipeline reproduced the dependency-load/missing-`qs` cascade after an intentional taxa-filtering failure. Its successful-empty counterpart generated the existing sentinel design and finished without errors. This experiment confirms the fallback mechanism; it did not reproduce the exact warm-store empty-branch exception. The production logs separately show the empty-branch aborts at the tuning work-item input for `eu_r003`/`am_r001`, and at the taxa-classification input for the four extraction failures. Their upstream failures prevent creation of usable branch inputs; the CV sentinel cannot rescue a dependency that failed before the sentinel command runs.

## Proposed repair, not implemented

Stage 03 should use verified preparation diagnoses before dispatching impossible downstream tuning/model targets. Unchanged fully infeasible units should be recorded as expected exclusions with their actual root reasons, not repeatedly driven through dependency-load cascades. Resolution-specific infeasibility must not discard other eligible resolutions or units. Changed inputs must trigger fresh validation; unknown errors must remain blockers.

The error/reporting layer should distinguish a missing object after a failed ancestor from an existing unreadable serialization file. Do not install `qs`, reset stores, change data thresholds, or invalidate successful models merely because the fallback message mentions `qs`. Test cold and interrupted/warm stores, expected empty units, partial-resolution success, and genuine cache incompatibility before any resumed production run.

The prior status message overstated the missing-package diagnosis. These inspected failures have registered data roots, with misleading downstream software messages; this is not evidence of a general broken cache installation or memory exhaustion. Regional and the local continuation remain stopped pending approval of a handling/reporting fix.
