# Cross-validation performance benchmark protocol v1

**Issue:** #138  
**Protocol frozen:** 2026-07-20  
**Implementation branch:** `issue138-cv-runtime`  
**Correctness base:** `a6b8f8630ec7f34ee51cccc7f8c1aa1f04bda05f`

## Purpose

Measure and reduce the cost of the shared cross-validation engine. Czechia is
the initial controlled benchmark, not an optimization target. Every accepted
change must operate through the common direct and shared CV pipe segments and
must remain applicable to paleo, modern, spatial, temporal, and future model
configurations.

## Frozen environment record

| Item | Reference value |
|---|---|
| Operating system | Windows 11 Pro, build 26200 |
| CPU | Intel Core i9-13900KF, 24 physical / 32 logical cores |
| Memory | 63.8 GiB visible memory |
| GPU | NVIDIA GeForce RTX 3050, 8 GiB |
| NVIDIA driver | 596.49 |
| R | 4.5.1 UCRT |
| `{targets}` | 1.12.0 |
| `{sjSDM}` | 1.0.7 |
| Assignment seed | 900723 |
| Fit seed | 900723 |

Each benchmark result must additionally record the Git commit, `renv.lock`
hash, VegVault file size/modification time/hash, `config.yml` hash, active
configuration, Python executable, CUDA visibility, worker counts, free memory,
and GPU driver/runtime state immediately before execution.

## Workloads and order

1. Run three fresh repetitions of `project_cz_paleo` through
   `pipeline_paleo_core.R` and `pipeline_paleo_resolution_test.R`.
2. Run three fresh repetitions of `project_cz_modern` through
   `pipeline_modern_spatial_resolution_test.R` for `eu_r005_l014`.
3. Run three fresh repetitions of the eight-candidate, three-repeat
   `project_cz_paleo_cv_reference_gpu` workload.
4. After the CZ gate passes, run the selected design for the Europe genus
   branch of paleo and modern continental pipelines, followed by one eligible
   temporal slice in each of Europe, America, and Asia.
5. Before closure, run the complete affected continental and temporal runner
   set required by issue #138.

The first repetition uses a clean isolated benchmark store. The second and
third repetitions recreate the same clean state. Warm-cache measurement is a
separate no-op invocation after each successful fresh run. Restart measurement
stops after the tuning-summary boundary and resumes from the same store.

## Measurements

- Wall time for complete CV, final fitting, and ANOVA targets.
- Fold preparation, fitting, prediction, and scoring time from
  `data_sjsdm_tuning_stage_timings*`.
- Executed, successful, historical, and reused fit counts from
  `data_sjsdm_tuning_execution_provenance*`.
- MEM construction/interpolation and response/abiotic preparation shares from
  an `Rprof()` trace of the fold-preparation stage.
- Process peak working set and system memory sampled every second.
- GPU utilization, memory, temperature, and power sampled every second with
  `nvidia-smi`.
- Store size before and after each stage, including prediction-cache size.
- Target metadata, warnings, errors, cache state, and restart behavior.

Raw samples belong in ignored benchmark stores under `Data/Temp/issue138/`.
Versioned result tables contain summaries and hashes, not fitted models or raw
large prediction caches.

## Predefined acceptance gates

- Median paired CV wall time improves by at least 20 percent.
- Every paired repetition improves by at least 15 percent.
- The eight-candidate, three-repeat design executes at least 40 percent fewer
  CV fits before it may replace exhaustive tuning.
- Target-store growth is no more than 25 percent.
- Peak RAM and VRAM increase by no more than 10 percent and no run exhausts GPU
  memory.
- Exact-semantics paths preserve target schemas, keys, statuses, seeds,
  missingness, candidate selection, and numeric values within `1e-4`.
- Staged tuning preserves technical decisions and null-skill decisions; mean
  repeat log loss may worsen by at most `0.005`, AUC and Tjur R2 by at most
  `0.01`, and evaluable-taxon coverage by at most two percentage points.
- A changed selected candidate requires an explicit scientific disposition.

## Execution designs

The exhaustive reference evaluates every candidate on every repeat and fold.
The first semantics-preserving optimization retains compact tuning-time
probabilities and assembles selected OOF output without 15 unconditional
refits. The staged experiment evaluates eight candidates on repeat one, four
survivors on repeat two, and two finalists on repeat three. Finalists must have
complete three-repeat evidence before selection.

Staged survivor decisions must be common to all source IDs in a tier and use
the existing equal-ID aggregation. Until this tier-wide orchestration passes
the gates above, `config.yml` keeps `tuning_strategy: exhaustive`; the staged
schedule and deterministic survivor contracts are present only for controlled
experiments.

## Restart and equivalence procedure

For restart testing, retain completed fold/candidate targets, interrupt at a
documented tuning boundary, resume, and verify that completed fit identities
are not executed again. Compare selected OOF artifacts after sorting by repeat,
fold, row, and taxon. Categorical fields and missing positions must match
exactly before numeric tolerance is applied.

Every result report records accepted and rejected designs, fit arithmetic,
wall-time variance, storage trade-offs, scientific comparison, and the maximum
allowable performance regression handed to issue #141.
