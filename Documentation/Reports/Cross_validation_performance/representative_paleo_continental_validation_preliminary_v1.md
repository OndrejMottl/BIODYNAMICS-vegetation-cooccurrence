# Representative paleo continental validation: preliminary v1

Date: 2026-07-23  
Branch: `issue138-cv-runtime`  
Commit: `43124b6b`

## Scope

This validation exercises the shared staged cross-validation engine on the Europe/genus unit of the paleo continental spatial pipeline. It does not add continent-specific tuning logic or thresholds.

The validation profile used:

- the production eight-candidate regularization grid;
- three repeats and five grouped folds;
- the shared staged survivor schedule `8 -> 4 -> 2`;
- fold-local preprocessing and held-out MEM interpolation; and
- four interpolation workers to keep representative validation within host memory.

The raw accepted run is repetition `112` under ignored benchmark data.

## Accepted clean run

The run completed successfully in 14,397.5 seconds (3 h 59 min 57 s), with:

- 1,828 unit-store metadata rows and zero target errors;
- 313 isolated tier-store metadata rows and zero target errors;
- 10,499 resource samples and no sampling warnings;
- a maximum sampling interval of 2.74 seconds;
- 22.36 GB peak process working set;
- 45.02 GB peak system-used memory;
- 2,736 MiB peak VRAM;
- no GPU-memory failure; and
- a 522.8 MB target store.

Median GPU utilization was 7%, and mean GPU utilization was 34.3%. Median process working set was 3.87 GiB.

## Runtime breakdown

| Shared execution boundary | Wall time | Share |
|---|---:|---:|
| Interpolation prebuild | 2 h 02 min 52 s | 51.2% |
| Staged round 1 | 52 min 28 s | 21.9% |
| Staged round 2 | 27 min 53 s | 11.6% |
| Staged round 3 | 12 min 34 s | 5.2% |
| Final unit fitting and artifacts | 19 min 51 s | 8.3% |
| Tier aggregation and orchestration overhead | 4 min 20 s | 1.8% |

The interpolation pattern contained 708 branches with 28,390.9 summed branch seconds. Four-worker execution reduced this to 2 h 02 min 52 s of wall time.

The 70 tuning fits used 5,393.0 summed fit seconds. Their median individual fit time was 73.5 seconds.

## Staged tuning evidence

All scheduled work items completed successfully:

| Repeat | Candidates | Fits | Successful |
|---:|---:|---:|---:|
| 1 | 8 | 40 | 40 |
| 2 | 4 | 20 | 20 |
| 3 | 2 | 10 | 10 |

The staged engine therefore executed 70 fits instead of 120 exhaustive fits, a 41.7% reduction. Relative to the former path that also refitted 15 selected folds, it avoided 48.1% of fits.

Round one retained `candidate_001`, `candidate_002`, `candidate_005`, and `candidate_006`. Round two retained `candidate_001` and `candidate_002`. `candidate_001` was selected using complete three-repeat evidence.

The selected candidate had 15 successful fold fits. Its 15 cached held-out prediction entries were reused to assemble evaluation artifacts; no selected fold was refitted. Provenance records `out_of_fold` as the prediction source, `repeat_fold_taxon` as the estimand, and `sjsdm_fold_local_cv_v1` as the evaluation schema.

## Invalid attempts

Repetition `101` is excluded. Sixteen-worker interpolation exhausted host memory, and a transient Windows process query killed the benchmark root while leaving worker processes orphaned. This attempt motivated the committed four-worker validation cap, transient sampler tolerance, and process-tree cleanup.

Repetition `111` is also excluded. The modelling process remained healthy, but the external one-hour tool allowance killed its benchmark harness and ended telemetry before the pipeline completed. Its exact process tree was stopped, and repetition `112` restarted from a fresh target store with an eight-hour observer allowance.

Neither invalid attempt contributes to benchmark or acceptance calculations.

## Interpretation

The representative paleo continental unit validates the common staged engine, tier-wide pruning, cached selected predictions, bounded preprocessing, and clean completion without GPU-memory failure.

The fit-count gate is met exactly: 41.7% fewer CV fits exceeds the required 40% reduction. This run is not an exhaustive-versus-staged wall-time pair, so it does not independently establish the 15% wall-time or 25% store-growth gates.

Interpolation, not CV fitting, is now the largest wall-time component. Staged tuning still accounts for 38.7% of wall time, while the selected final fit and artifact tail account for 8.3%. Representative modern and temporal validation should reuse this implementation and report the same shared phase boundaries.
