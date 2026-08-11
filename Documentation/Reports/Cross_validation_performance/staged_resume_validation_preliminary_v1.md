# Staged round resume validation: preliminary v1

Date: 2026-07-20  
Branch: `issue138-cv-runtime`

## Runtime defect exposed by the real tier store

The first clean staged retry completed all 40 round-one fits and successfully published `data_sjsdm_tier_survivor_decisions_round_1`. Round two then failed closed before fitting because the cumulative work-item validator compared the decision round IDs with `identical()`.

The real collector returns a deliberately named list (`round_1`, `round_2`). `purrr::map_int()` retained that list name, so the numeric result was named `round_1 = 1L`; `identical()` rejected it against unnamed `1L` even though the round value and ordering were correct.

The validator now removes only vector names before checking exact integer round values. Missing rounds, gaps, malformed round IDs, and final-round decisions remain rejected. A regression test uses the named-list shape emitted by the actual collector.

## Diagnostic resume evidence

The failed run was resumed from its existing unit and tier stores with `fresh_run = FALSE`. This diagnostic run is not valid paired wall-time evidence, but it directly validates granular restart behavior:

| Boundary | Cumulative fits | Newly executed fits | Errors |
|---|---:|---:|---:|
| Completed round 1 | 40 | 0 on resume | 0 |
| Completed round 2 | 60 | 20 | 0 |
| Completed round 3 | 70 | 10 | 0 |

Both survivor targets and the final tier regularization artifact completed. The selected candidate was `candidate_008`, with all three lambda parameters equal to `0.1`. The two finalists were `candidate_004` and `candidate_008`.

The final unit store contained:

- 70 executed and 70 successful tuning fits;
- 15 selected-candidate refits avoided through cached predictions;
- 9,840 unique OOF rows with no duplicate repeat/row/taxon keys;
- 617 metadata rows with zero errors; and
- cached-prediction evaluation as the recorded prediction source.

The tier store contained 303 metadata rows with zero errors. Relative to the 120-fit exhaustive grid, the staged schedule executed 41.7% fewer CV fits. Relative to the former 135-fit path that also refit 15 selected folds, it avoided 48.1% of fits.

## Validation

- Named-list focused tests passed with 11 assertions.
- The complete suite passed with 3,773 assertions, zero failures, zero warnings, and one expected integration skip.
- The diagnostic staged resume completed in 867.8 seconds with exit code 0.
- A first fresh CZ attempt encountered a transient `callr` worker-start failure before CV and produced no target errors.
- The immediate fresh CZ retry completed in 1,945.4 seconds with exit code 0.
- Final CZ metadata contained 552 paleo-core, 692 paleo-resolution, and 2,490 modern-resolution rows, with zero errors in all stores.

The interrupted staged attempt is archived under ignored raw benchmark data and excluded from gate calculations. A new clean staged repetition is required after this fix is committed.
