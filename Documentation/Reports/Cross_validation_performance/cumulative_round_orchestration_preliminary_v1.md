# Cumulative staged-round orchestration: preliminary validation v1

Date: 2026-07-20  
Branch: `issue138-cv-runtime`

## Implemented shared behavior

The common CV engine now separates the complete deterministic work-item
universe from the subset authorized to execute. Exhaustive profiles expose the
complete universe unchanged. Staged profiles expand the authorized subset only
after reading consecutive, context-compatible survivor decisions from the
isolated tier store.

The shared spatial and temporal orchestration sequence is:

1. execute round-one unit work items;
2. aggregate every unit in the tier and publish round-one survivors;
3. resume unit stores with round-two work items for the same survivors;
4. aggregate cumulative repeat-one and repeat-two evidence and publish
   finalists;
5. resume unit stores with round-three work items for both finalists; and
6. select the winner from complete three-repeat evidence and publish the
   existing tier artifact.

All paleo, modern, continental, regional, local, and Europe/America/Asia
temporal runners call the same orchestration helper. No project- or
continent-specific pruning thresholds were introduced.

Each unit invocation receives an explicit maximum authorized round. This
prevents stale later-round targets from a previous execution from skipping a
fresh earlier tier aggregation. Re-running the sequence starts at round one,
but completed granular fit branches remain reusable because their deterministic
work-item identities do not change.

## Fit budget

For the production grid of eight candidates, three repeats, and five folds:

| Strategy | Fit calculation | CV fits per unit |
|---|---:|---:|
| Exhaustive | `8 * 3 * 5` | 120 |
| Staged | `(8 * 5) + (4 * 5) + (2 * 5)` | 70 |

The staged graph therefore schedules 50 fewer CV fits per unit, a 41.7%
reduction. The selected candidate's OOF artifact is assembled from these cached
tuning predictions, so no additional 15-fold refit is added after selection.
This is a structural fit-count result, not yet a measured wall-time result.

## Test evidence

TDD coverage includes:

- cumulative work-item expansion and identity preservation;
- missing decisions as a normal round boundary;
- decision gaps, errored targets, malformed artifacts, and candidate drift;
- cumulative tier evidence through the current repeat;
- restart behavior when later evidence already exists;
- a candidate that leads initially but loses after later evidence;
- explicit spatial and temporal runner sequencing; and
- preservation of public tuning, OOF, diagnostics, evaluation, and tier target
  names.

The complete suite passed with 3,742 assertions, zero failures, zero warnings,
and one expected integration skip.

## Exhaustive CZ regression

`Rscript R/03_Supplementary_analyses/Testing/Smoke/run_cz_pipelines.R` completed with exit code 0 in
1,951.7 seconds (32 minutes 31.7 seconds). All active CZ profiles remained
explicitly exhaustive.

| Store | Metadata rows | Errors |
|---|---:|---:|
| CZ paleo core | 551 | 0 |
| CZ paleo resolution test | 691 | 0 |
| CZ modern spatial resolution test | 2,489 | 0 |
| Total | 3,731 | 0 |

The CZ paleo-core complete and authorized work-item tables were identical and
contained five work items, confirming that the explicit one-candidate profile
does not pretend to exercise production staged complexity.

## Remaining activation gates

Production remains exhaustive. The next checkpoint is a paired eight-candidate
CZ fixture using identical assignments and seeds under exhaustive and staged
strategies. It must verify the specified loss, AUC, Tjur R2, coverage, storage,
memory, fit-count, and wall-time gates before staged tuning becomes the
production default.
