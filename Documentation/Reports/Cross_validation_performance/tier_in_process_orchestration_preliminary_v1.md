# In-process tier orchestration: preliminary validation v1

Date: 2026-07-21  
Branch: `issue138-cv-runtime`

## Motivation

The first three clean post-optimization pairs reduced median wall time by
12.4%, below the required 20%, despite reducing CV fits by 41.7%. Timing
decomposition showed that staged tuning saved about 315 seconds of pipeline
work but paid about 168 seconds more process-boundary overhead than exhaustive
tuning.

The staged strategy starts three small tier graphs, compared with one for
exhaustive tuning. Each tier graph performs seconds of aggregation but
previously launched a new callr process and reloaded the full project.

## Shared change

`run_pipeline()` now accepts the `callr_function` passed to
`targets::tar_make()`. Its default remains `callr::r`, so unit pipelines,
interpolation prebuilds, public pipelines, and every existing caller retain
process isolation.

`run_sjsdm_tuning_sequence()` supplies `callr_function = NULL` only for the
small tier-tuning graph. Unit graphs remain in isolated callr sessions, and
unit and tier target stores remain separate. This avoids mixing successive
unit graphs in one R process, which previously failed package-library
validation for `collinear`.

The optimization is shared by all spatial and temporal runners. It contains no
CZ-, continent-, project-, or unit-specific branch.

## Validation

Failing-first tests covered explicit callr-backend forwarding and required the
staged sequence to retain isolated unit calls while using in-process tier
calls. The focused files then passed with 33 assertions each.

A non-destructive resume against the completed staged CZ store:

- completed in 173.4 seconds, compared with 331.3 seconds for the previous
  isolated-tier resume;
- dispatched no candidate-fit branch;
- completed all three tier graphs in-process;
- retained 70 cached successful fits; and
- left both unit and tier stores with zero target errors.

The complete suite passed with 3,791 assertions, zero failures, zero warnings,
and one expected VegVault integration skip.

Fresh `Run_CZ_test.R` completed in 1,911.7 seconds with exit code 0. Fresh
target metadata contained 552 paleo-core, 692 paleo-resolution, and 2,490
modern-resolution rows, with zero errors in every public store. The staged CZ
reference stores also retained zero unit and tier errors after resume.

## Benchmark status

The earlier three-pair `fail` decision remains the valid result for commit
`6acfc059`. The 173.4-second resume demonstrates that the new boundary removes
the intended startup overhead, but it is not a clean paired benchmark.

After this change is committed, staged and exhaustive CZ runs must be repeated
from fresh stores. Production remains `exhaustive` until the versioned gate
evaluator passes clean committed evidence.

Before those new measurements, the runtime acceptance threshold was revised
and frozen in
[`benchmark_policy_revision_v2.md`](benchmark_policy_revision_v2.md).

The three clean post-commit pairs passed that policy. Measurements and the
formal decision are recorded in
[`paired_cz_benchmark_post_in_process_v2.md`](paired_cz_benchmark_post_in_process_v2.md).
