# Issue 138 shared cross-validation runtime implementation

**Branch:** `issue138-cv-runtime`  
**Base:** `a6b8f8630ec7f34ee51cccc7f8c1aa1f04bda05f`  
**Scope:** shared CV execution and orchestration only

## Objective

Reduce the number of sjSDM cross-validation fits for every model pipeline.
Czechia is the first controlled benchmark, not a project-specific optimization
target. Paleo, modern, spatial, temporal, continental, regional, and local
pipelines must consume the same implementation.

## Ordered implementation

1. Freeze the benchmark protocol, public targets, schemas, scientific gates,
   environment, seeds, and store boundaries.
2. Retain compact tuning-time held-out probabilities and fold metadata, without
   retaining fitted models.
3. Assemble the established selected-candidate OOF artifacts from that cache and
   preserve their public target names and schemas.
4. Add deterministic staged schedules and fail-closed tier-wide survivor
   selection with configured repeat order and survivor counts.
5. Split staged orchestration into explicit unit round and isolated tier
   selection boundaries. Resume only unfinished fold/candidate work items.
6. Compare exhaustive and staged results on identical assignments and tuning
   seeds. Keep production exhaustive until all scientific and technical gates
   pass.
7. Run three repeated CZ paleo/modern benchmarks, the eight-candidate reference,
   and representative continental and temporal validations.
8. Freeze the selected design, rejected alternatives, benchmark evidence,
   public contract, and allowable regression for issue 141.

## Current implementation boundary

Steps 1--6 are complete. Exact prediction reuse, deterministic work items,
tier-wide survivor selection, isolated round orchestration, and restartable
execution are integrated into the shared engine. Three clean paired CZ
repetitions passed the approved version-two computational and scientific
gates. Representative paleo and modern continental validations also completed
without CV or GPU-memory failure after the shared spatial-MEM scalability fix.

The production default is switched to `staged` on
`issue138-production-staged`; reduced CZ and explicit exhaustive reference
profiles remain `exhaustive`. The remaining step-7 gate is representative
Europe, America, and Asia temporal-slice validation.

A clean Europe 16,000-year diagnostic exposed a single-repeat
leave-one-location-out fallback that is incompatible with the three-round
staged schedule. Its apparent zero exit was also false because target errors
were retained under `{targets}` error mode `null`. The shared runner now
checks staged repeat coverage before fitting, propagates new target errors,
locks target stores, and retains restart-safe shared interpolation inputs.
The comparable 6,500-year slice supplies three grouped five-fold repeats in
Europe and is configured for all three temporal validation regions.
Representative runners end at final-model, cross-validated evaluation, and
provenance targets so the separate ANOVA workload cannot obscure CV
acceptance timing. Diagnostic evidence is recorded in
`Documentation/Reports/Cross_validation_performance/`
`temporal_validation_preliminary_v1.md`.

## Mandatory safeguards

- Prepare response, abiotic, and MEM inputs within each training fold.
- Keep grouped locations and held-out MEM interpolation unchanged.
- Select staged survivors only after complete equal-ID tier aggregation.
- Require both finalists to have evidence from all configured repeats.
- Preserve unit/tier store isolation and fail closed on missing tier evidence.
- Do not introduce continent-specific thresholds or execution branches.
- Do not report fitted pseudo-R2 as cross-validated performance.

## Validation gates

The exact commands, workloads, measurements, and numerical thresholds are
frozen in
`Documentation/Reports/Cross_validation_performance/benchmark_protocol_v1.md`.
No production switch to `staged` is permitted from a single timing run or from
unit tests alone.
