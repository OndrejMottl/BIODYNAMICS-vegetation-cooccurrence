# Paired CZ benchmark and orchestration optimization: preliminary v1

Date: 2026-07-21  
Branch: `issue138-cv-runtime`  
Benchmark commit: `6f7b6a03`

## First valid paired repetition

The first staged and exhaustive runs used the same committed implementation, configuration, runner family, VegVault hash, assignments, and seeds. Both completed with zero target errors and no GPU-memory failure.

| Measurement | Exhaustive | Staged | Staged change |
|---|---:|---:|---:|
| Wall time | 1,194.6 s | 1,352.0 s | 13.2% slower |
| Executed CV fits | 120 | 70 | 41.7% fewer |
| Target-store size | 6.07 MB | 5.52 MB | 9.0% smaller |
| Peak process working set | 8.18 GiB | 8.30 GiB | 1.5% larger |
| Peak VRAM | 1,682 MiB | 1,625 MiB | 3.4% smaller |

Staged therefore passed the fit-count, storage, and GPU-memory criteria but failed the wall-time criterion in this repetition. This is preliminary pair evidence only; the formal decision requires three repetitions.

## Technical and scientific equivalence

Both strategies:

- selected `candidate_008`;
- completed all 15 selected-candidate folds;
- used grouped spatial five-fold CV with three repeats;
- produced identical assignments, with canonical hash `5ae7e1e05b4d7c4bd2a0c397c728bf42`;
- produced identical public OOF, diagnostic, evaluation, and provenance schemas, with canonical hash `e537531ff29da3be1bfba6dd01fdcf27`;
- produced 9,840 unique cached OOF rows; and
- matched mean fold-macro log loss, AUC, Tjur R2, and evaluable coverage.

The scientific regression values are therefore zero for this pair.

## Runtime diagnosis

The staged run performed fewer fits but crossed the unit/tier boundary several times. Each `targets::tar_make()` launched a new callr process and reloaded the project. Every intermediate unit and tier call also rendered a progress report. Interpolation prebuild was requested before every unit round and once again before final completion, despite the completed interpolation store already being reusable.

Pipeline-reported work accounted for about 14.7 minutes of the 22.5-minute staged wall time. Repeated setup, visualization, and boundary overhead accounted for the remaining approximately 7.8 minutes. Exhaustive incurred about 1.6 minutes of comparable wrapper overhead.

## Shared optimization implemented after the pair

The shared orchestration now:

- prebuilds interpolation only in the first unit round;
- suppresses intermediate progress rendering and retains the final tier report; and
- skips redundant interpolation prebuild during post-selection completion in every spatial and temporal runner.

Unit and tier stores retain their existing isolated callr sessions. An in-process alternative was tested and rejected: the first unit graph completed, but the next graph failed package-library validation for `collinear` before any CV fit executed. Preserving callr isolation is therefore a correctness requirement in the current project environment.

## Validation

- Focused pipeline-runner tests passed with 32 assertions.
- Focused shared-sequence and runner-contract tests passed with 32 assertions.
- The complete suite passed with 3,789 assertions, zero failures, zero warnings, and one expected integration skip.
- Fresh `run_cz_pipelines.R` completed in 1,900.0 seconds with exit code 0.
- Fresh target metadata contained 552 paleo-core, 692 paleo-resolution, and 2,490 modern-resolution rows, with zero errors in every store.
- A safe isolated staged resume completed in 331.3 seconds without dispatching candidate-fit branches and restored 70 successful fits with zero unit or tier errors after the rejected in-process diagnostic.

The first pair must be archived as pre-optimization evidence. Clean paired repetitions must restart from the committed optimized implementation before formal gate evaluation.

The completed three-pair post-optimization decision is recorded in [`paired_cz_benchmark_post_optimization_v1.md`](paired_cz_benchmark_post_optimization_v1.md).
