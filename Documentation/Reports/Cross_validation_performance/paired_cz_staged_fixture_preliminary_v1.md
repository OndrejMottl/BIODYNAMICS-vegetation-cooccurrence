# Paired CZ staged-search fixture: preliminary validation v1

Date: 2026-07-20  
Branch: `issue138-cv-runtime`

## Purpose

This fixture enables the production-like paired gate for the shared staged search. It does not activate staged tuning in production and it does not add CZ-specific tuning logic.

The exhaustive profile remains `project_cz_paleo_cv_reference_gpu`. The paired staged profile is `project_cz_paleo_cv_staged_reference_gpu`. Both inherit the same eight-candidate regularization grid, three assignment repeats, assignment seed, fit seed, GPU device, model settings, and tier identity. They use different isolated target stores, and the staged profile changes only the tuning strategy and restores the production schedule of three repeats with survivor counts `c(4, 2)`.

## Shared orchestration

`run_cz_paleo_cv_staged_reference_gpu.R` uses the same `run_sjsdm_tuning_sequence()` helper as every spatial and temporal production runner. The shared tier pipeline now recognizes `paleo_core` as one direct unit with genus resolution. This is a normal non-nested tier context, equivalent in shape to the existing temporal direct-store context.

A fresh staged run clears each isolated unit store and the isolated tier store only before round one. Rounds two and three resume the same stores, retaining completed deterministic fold/candidate work items. The final core-pipeline call then consumes the published tier artifact and completes the existing public targets.

## Preliminary validation

- The focused TDD contracts passed with 33 assertions.
- The complete test suite passed with 3,758 assertions, zero failures, zero warnings, and one expected integration skip.
- The staged core manifest contains 123 targets and no duplicate names.
- The staged tier manifest contains 18 targets and no duplicate names.
- Both survivor-decision targets and the final tier artifact are present.
- All changed R files parse and have no lines longer than 80 characters.

## Benchmark status

This checkpoint establishes the executable fixture only. No paired GPU timing or scientific-equivalence result is claimed yet. Production remains `exhaustive` until the repeated runs satisfy the frozen gates in `benchmark_protocol_v1.md`.
