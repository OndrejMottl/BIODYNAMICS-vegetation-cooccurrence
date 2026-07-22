# Paired CZ benchmark after orchestration optimization: v1

Date: 2026-07-21  
Branch: `issue138-cv-runtime`  
Benchmark commit: `6acfc059`

## Decision

The three-pair `issue138_staged_benchmark_v1` assessment returned `fail`.
Staged tuning remains unsuitable as the production default until the failed
runtime gates are resolved or the frozen policy is scientifically reviewed.
Production therefore remains `exhaustive`.

Scientific and technical equivalence passed. Staged tuning selected the same
`candidate_008`, produced identical assignments and public artifact schemas,
and reproduced the exhaustive OOF predictions and fold metrics exactly.

## Clean paired measurements

All six valid runs started from fresh isolated target stores at commit
`6acfc059`. Each run used the same runner family, configuration, VegVault hash,
assignments, and deterministic seeds.

| Repetition | Exhaustive wall time | Staged wall time | Wall reduction |
|---:|---:|---:|---:|
| 1 | 1,184.0 s | 1,036.7 s | 12.4% |
| 2 | 1,166.3 s | 1,039.3 s | 10.9% |
| 3 | 1,215.7 s | 1,062.5 s | 12.6% |

The median paired wall-time reduction was 12.4%, below the required 20%.
The minimum paired reduction was 10.9%, below the evaluator's 15% minimum.

| Measurement | Exhaustive | Staged | Gate result |
|---|---:|---:|---:|
| Executed fits per run | 120 | 70 | Pass: 41.7% fewer |
| Target-store size | 6.07 MB | 5.52 MB | Pass: about 9.0% smaller |
| Maximum paired RAM growth | - | 0.14% | Pass: at most 10% |
| Maximum paired VRAM growth | - | 14.4% | Fail: at most 10% |
| GPU-memory failures | 0 | 0 | Pass |

The peak-VRAM failure came from repetition 1, where staged reached 1,910 MiB
and exhaustive reached 1,670 MiB. The other paired VRAM changes were -5.5%
and 4.8%. No run failed because of GPU memory.

## Technical and scientific equivalence

The final paired stores had:

- zero target errors;
- identical assignments, with audit hash
  `8d000c75acb45333be4732abb39ee9d5`;
- identical schemas for the public OOF, fold-metric, evaluation, and model
  provenance artifacts, with audit hash
  `f6e6bb638e4d85ffd82583999f16582a`;
- identical 9,840-row OOF artifacts with 9,840 unique rows;
- identical fold-local metrics;
- complete three-repeat evidence for both staged finalists; and
- the same selected `candidate_008` under both strategies.

Mean repeat-level fold-macro values were 0.30854 log loss, 0.65618 AUC, and
0.05208 Tjur R2. Mean evaluable fold-taxon coverage for AUC and Tjur R2 was
0.6625. All staged-minus-exhaustive scientific regressions were zero, and no
scientific review was required for candidate selection.

## Invalid infrastructure attempt

The first attempt at staged repetition 3 failed before any CV fit. All 24
workers missed the 125-second cluster connection timeout while starting the
first unit graph. The wrapper failed closed with exit code 1.

The raw attempt is retained as
`Data/Temp/issue138/staged/repetition_3_failed_cluster_startup_v1` and is not
included in the paired assessment. A clean restart succeeded at the same
boundary. This is infrastructure evidence, not a model or GPU-memory failure.

## Interpretation and next step

The shared staged engine reliably removes 50 of 120 CV fits and preserves the
scientific result, but fixed preparation, worker startup, isolated-store, and
final-evaluation costs limit the end-to-end speedup to about 11-13% on this CZ
reference. The remaining work should target shared orchestration and startup
costs rather than project-specific model logic.

Continental and temporal promotion should remain blocked by the CZ wall-time
gate. The next optimization must be benchmarked against these archived clean
runs, retain isolated unit/tier stores and fail-closed evidence collection,
and preserve the passing fit-count, storage, technical, and scientific gates.

The next shared orchestration optimization and its preliminary validation are
recorded in
[`tier_in_process_orchestration_preliminary_v1.md`](tier_in_process_orchestration_preliminary_v1.md).

The subsequent committed three-pair benchmark passed the revised version-two
policy and is recorded in
[`paired_cz_benchmark_post_in_process_v2.md`](paired_cz_benchmark_post_in_process_v2.md).
