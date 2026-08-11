# Exhaustive boundary resume validation: preliminary v1

Date: 2026-07-21  
Branch: `issue138-cv-runtime`

## Clean staged repetition

The first clean staged repetition completed before the exhaustive boundary defect was discovered. It provides valid staged runtime evidence, but it is not yet paired gate evidence because the exhaustive implementation required the fix described below.

| Measurement | Observed value |
|---|---:|
| Wall time | 1,469.7 seconds |
| Executed fits | 70 |
| Successful fits | 70 |
| Peak process working set | 8.14 GiB |
| Peak VRAM | 1,610 MiB |
| Target-store size | 5.52 MB |
| GPU memory failure | No |

The staged rounds executed 40, 20, and 10 fits. Round one retained candidates 004, 006, 007, and 008; round two retained candidates 004 and 008. Both finalists had complete three-repeat evidence, and candidate 008 was selected. The unit and tier stores contained zero target errors.

The selected candidate's cached predictions assembled 9,840 unique OOF rows. Mean fold-macro metrics across repeats were 0.309 log loss, 0.656 AUC, and 0.0521 Tjur R2.

## Exhaustive provenance defect

The first exhaustive attempt completed all 120 fold/candidate fits, then failed in `data_sjsdm_tuning_execution_provenance`. Exhaustive orchestration has one restart boundary that executes all configured repeats. Its active schedule therefore contained one row, while the completed tuning table correctly contained three repeats. The provenance validator incorrectly required one schedule row per executed repeat, a contract that applies to staged rounds but not to the exhaustive boundary.

The validator now checks that every exhaustive repeat executed the configured initial candidate count. Staged execution retains the stricter one-to-one repeat/schedule validation. A regression test covers a one-row exhaustive schedule with three executed repeats and eight candidates per repeat.

## Cached resume evidence

The failed exhaustive store was resumed with `fresh_run = FALSE`. No tuning work-item branch reran. The repaired provenance target and downstream selection, cached OOF assembly, evaluation, and final-model targets completed in 190.3 seconds. This is direct restart evidence but is excluded from runtime gates.

The failed measured attempt is archived under ignored raw data as `repetition_1_failed_exhaustive_boundary_v1`. Its partial wall time and the subsequent resume time must not be combined or used as an exhaustive baseline.

## Validation

- The focused provenance tests passed with 18 assertions.
- The complete suite passed with 3,777 assertions, zero failures, zero warnings, and one expected integration skip.
- Fresh `run_cz_pipelines.R` completed in 1,939.1 seconds with exit code 0.
- Fresh target metadata contained 552 paleo-core, 692 paleo-resolution, and 2,490 modern-resolution rows, with zero errors in every store.
- `git diff --check` passed for the implementation and regression test.

Clean staged and exhaustive repetitions must start from the same committed implementation before entering the paired benchmark gate evaluator.
