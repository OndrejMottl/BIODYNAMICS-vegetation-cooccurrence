# Issue 141 handoff: accepted shared CV execution design

Date: 2026-07-26  
Source issue: #138  
Consumer issue: #141  
Status: accepted handoff

## Decision

The accepted production design is the shared staged cross-validation engine
with granular candidate/fold work items, cached held-out predictions,
tier-wide survivor selection, isolated unit/tier stores, and restartable round
boundaries.

Production profiles use the staged `8 -> 4 -> 2` schedule across three repeats
and five folds. Explicit exhaustive reference profiles remain available.
Reduced one-candidate CZ profiles remain explicit and do not represent
production tuning complexity.

The implementation is shared by paleo, modern, spatial, temporal,
continental, regional, and local pipelines. No project-, continent-, or
unit-specific tuning rule or threshold is part of the accepted design.

## Accepted execution contract

Each repeat/fold/candidate fit has a deterministic work-item identity.
Fold-local response, abiotic, and MEM inputs are prepared once and reused
across candidates. Successful work items persist compact metrics,
diagnostics, and held-out predictions, but not fitted models.

The selected candidate's existing tuning predictions are assembled into the
public OOF artifact. Its 15 folds are not fitted again after selection.

Staged execution proceeds through isolated boundaries:

1. all eight candidates run on repeat 1;
2. the tier store pools complete equal-ID evidence and retains four candidates;
3. unit stores resume those four candidates on repeat 2;
4. the tier store retains two finalists;
5. unit stores resume both finalists on repeat 3; and
6. the winner is selected from complete three-repeat evidence.

Pruning is tier-wide. Partial evidence, candidate drift, malformed decisions,
missing required targets, and independently pruned unit candidates fail
closed.

Scientifically inapplicable units also fail closed without wasted
computation. When feasibility resolves to `cv_strategy = "none"`, the engine
executes zero fits, preserves typed public artifacts, records
`full_model_infeasible`, and does not invoke tier aggregation when all unit
summaries are empty.

## Public contract frozen for Issue 141

Issue 141 must preserve the public target-name, artifact-schema, status, seed,
provenance, and isolated-store contracts recorded in
[`contract_inventory_v1.md`](../Cross_validation_audit/contract_inventory_v1.md).

In particular:

- grouped locations and fold-local preprocessing remain mandatory;
- held-out MEM values are projected from training-fold bases;
- tuning uses deterministic fit and score seeds;
- tier aggregation retains equal-ID weighting;
- OOF predictions remain selected-candidate held-out probabilities;
- fold diagnostics retain explicit preparation, fit, prediction, and scoring
  statuses;
- model provenance retains the `sjsdm_fold_local_cv_v1` evaluation contract;
  and
- unit and tier stores remain isolated.

The paired CZ schema audit hash is
`2d727fd54623501e0ac384e0674c17f3`. The grouped-assignment audit hash is
`ec5dcdda6049a504cb0b69f845c64aa8`.

The granular work-item, tuning-round, and no-model targets added by Issue 138
are internal execution details. Issue 141 may simplify their ownership and
construction, but it must not change the established public targets or
artifacts without an explicitly approved migration and compatibility tests.

## Benchmark decision

Three clean paired CZ repetitions passed all 15 gates in policy
`issue138_staged_benchmark_v2`.

| Measurement | Accepted result |
|---|---:|
| Median paired wall-time reduction | 16.1% |
| Minimum paired wall-time reduction | 15.5% |
| CV-fit reduction | 41.7% |
| Worst target-store change | -9.0% |
| Worst peak process-RAM change | +1.8% |
| Worst peak VRAM change | +6.2% |
| GPU-memory failures | 0 |

Staged runs executed 70 candidate/fold fits versus 120 exhaustive fits. Both
strategies reused all 15 selected-candidate fold predictions. Assignments,
OOF values, fold metrics, public schemas, and selected `candidate_008` matched.
Both finalists had complete three-repeat evidence. No scientific review was
required.

The benchmark details and raw-result provenance are recorded in
[`paired_cz_benchmark_post_in_process_v2.md`](paired_cz_benchmark_post_in_process_v2.md).

## Allowable performance regression during Issue 141

Issue 141 must rerun the Issue 138 paired protocol after shared
infrastructure changes. Relative to the accepted reference:

- median staged wall-time reduction must remain at least 15%;
- every paired repetition must remain at least 10% faster;
- CV-fit reduction must remain at least 40%;
- target-store growth must not exceed 25%;
- paired peak RAM or VRAM growth must not exceed 10%;
- no GPU-memory failure is allowed;
- mean repeat log loss may worsen by at most `0.005`;
- AUC and Tjur R2 may each worsen by at most `0.01`;
- evaluable-taxon coverage may fall by at most two percentage points; and
- a changed selected candidate requires explicit scientific review.

Technical statuses, grouped assignments, leakage protections, deterministic
seeds, finalists' complete evidence, public target names, and artifact schemas
must continue to match.

## Representative validation

The shared implementation passed the representative paleo continental
Europe/genus run:

- 70/70 staged fits completed;
- candidate 001 was selected from complete evidence;
- cached predictions supplied all 15 OOF folds;
- peak process working set was 22.36 GB;
- peak VRAM was 2,736 MiB; and
- no target or GPU-memory failure occurred.

The scalable shared-MEM implementation then allowed the representative modern
continental Europe/genus unit to reach and complete the same shared CV path:

- 70/70 staged fits completed;
- candidate 001 was selected;
- all 308 genera were evaluable in every repeat;
- no selected-candidate fold was refitted;
- the useful pre-ANOVA path completed in approximately 138.6 minutes;
- peak process working set was 12.78 GB;
- peak VRAM was 5,195 MiB; and
- a completed-store resume repeated zero candidate fits.

The modern run establishes compatibility, resource safety, and restart
behavior. Its timing is not labeled a clean empty-store acceptance baseline
because the store was resumed after a shared configuration-propagation
correction. The formal wall-time acceptance decision remains the clean paired
CZ benchmark.

Temporal validation passed on comparable 6,500-year Europe and America
slices. Each completed 70 successful staged fits, reused the selected
candidate's 15 cached folds, produced the public evaluation and provenance
artifacts, and fitted the final full-data model once.

No Asia slice currently passes the existing scientific safeguards for a
three-repeat staged comparison. The 6,500-year slice adapts to single-repeat
leave-one-location-out CV. The 7,000-year slice is
`full_model_infeasible`; after the shared no-model correction it completes
with zero fits and compatible empty artifacts. Asia is therefore recorded as
not applicable, not forced through a continent-specific fallback.

## Rejected alternatives

The following alternatives are not part of the accepted production design:

- **Selected-candidate fold refitting:** rejected because cached tuning
  predictions provide the same OOF artifact while avoiding 15 fits.
- **Persisting fitted CV models:** rejected because compact predictions,
  metrics, and diagnostics are sufficient for restart and OOF assembly with a
  smaller storage burden.
- **Independent unit-level pruning:** rejected because survivor candidates
  must be selected only after complete tier-wide equal-ID aggregation.
- **Project- or continent-specific thresholds:** rejected because the common
  feasibility and tuning contracts must govern every pipeline.
- **Relaxing folds, repeats, or scientific safeguards for sparse units:**
  rejected; adaptive grouped CV, leave-one-location-out, tier-pooled
  regularization, and no-model outcomes remain the shared feasibility order.
- **Combining unit and tier graphs in one in-process session:** tested and
  rejected after the next graph failed package-library validation. Isolated
  callr sessions and target stores remain correctness boundaries.
- **Replacing exhaustive reference execution:** rejected; exhaustive remains
  available for reference tests and unusual configurations.

## Issue 141 boundary

Issue 141 may consolidate schema construction, shared/direct pipe-segment
duplication, runner sequencing, and internal target-building ownership.
It must not change candidate counts, repeat/fold counts, staged scheduling,
parallel fitting, scientific estimands, tuning weights, feasibility
thresholds, or the benchmark policy.

The long modern ANOVA and temporal final-model standard-error singularities
are separate downstream concerns. They did not invalidate CV tuning, cached
OOF prediction, predictive evaluation, provenance, or model selection and
must not broaden Issue 141 by convenience.
