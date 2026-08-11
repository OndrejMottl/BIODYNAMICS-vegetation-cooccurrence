# Scalable shared MEM continental validation (preliminary v1)

**Date:** 2026-07-25  
**Issue:** #143  
**Status:** Computational and resume gates passed; clean-run timing remains open

## Purpose

This validation asks whether the common spatial-MEM engine can reach and complete the production-like staged CV path for a representative modern continental unit. It uses the isolated Europe profile and stores:

- profile: `project_issue143_modern_spatial_continental_europe_shared_mem`;
- unit store: `Data/targets/issue143_validation/modern_continental_europe/europe/` `pipeline_modern_spatial_resolution`;
- eight regularization candidates, three repeats, and five grouped folds;
- the shared `auto` MEM strategy with no continent-specific threshold.

The run contains 19,634 aligned model locations and 308 retained genera.

## Validation history

The first attempt proved that the shared continental basis was no longer the bottleneck: the 19,864-location core selected `spmoran_nystrom`, completed in 0.969 seconds, and stored a 28.2 MB basis. The former exact path would require about 2.94 GiB for one dense matrix and had previously failed before CV.

That attempt then exposed a shared configuration propagation defect. The fold-local model configuration did not contain `spatial_mev`, so all candidate work items attempted the exact fallback. Both common model-configuration builders now propagate the same shared MEM block. Resuming the isolated store then prepared all 15 repeat-fold inputs successfully:

| Fold-preparation result | Value |
|---|---:|
| Successful folds | 15 / 15 |
| Requested strategy | `auto` |
| Selected strategy | `fast` |
| Strategy version | `spatial_mev_nystrom_v1` |
| Median preparation time | 1.060 s |
| Mean preparation time | 1.139 s |
| Maximum preparation time | 3.120 s |
| Prepared-fold cache size | 28,398,339 bytes |

Every fold constructed its basis from its 15,707 or 15,708 training locations and projected only afterward to its 3,927 or 3,926 held-out locations. No fold selected the exact engine.

## Staged-CV result

All 70 scheduled candidate-fold fits completed with status `ok`:

| Round / repeat | Candidates | Folds per candidate | Fits |
|---|---:|---:|---:|
| 1 | 8 | 5 | 40 |
| 2 | 4 | 5 | 20 |
| 3 | 2 | 5 | 10 |
| **Total** |  |  | **70** |

An exhaustive eight-candidate, three-repeat run would require 120 fits. Staging therefore removed 50 fits, or 41.7%, and passes the Issue 138 fit-count gate. Survivors were tier-wide and deterministic:

- repeat 1: candidates 001 through 008;
- repeat 2: candidates 001 through 004;
- repeat 3: candidates 001 and 003.

Candidate 001 was selected. The execution artifact retained 70 compact tuning rows and held-out predictions for all 15 selected-candidate folds. The public OOF diagnostics contain exactly those 15 repeat-fold records. The pipeline assembled OOF predictions from the cache and did not fit the winner's 15 folds a second time.

All 308 genera were evaluable in every repeat. Community-level predictive summaries were stable across repeats:

| Repeat | Mean log loss | Mean AUC | Mean Tjur R2 | Evaluable genera |
|---:|---:|---:|---:|---:|
| 1 | 0.160 | 0.788 | 0.0280 | 308 |
| 2 | 0.160 | 0.788 | 0.0279 | 308 |
| 3 | 0.160 | 0.788 | 0.0277 | 308 |

These are held-out results for the scalable path. The paired exact-versus-fast scientific comparison is reported separately in `scalable_shared_mem_native_paired_fixture_preliminary_v1.md`.

## Runtime and resources

The terminal harness elapsed time of 13.74 hours must not be interpreted as CV runtime. The requested target list originally included `model_anova_genus`. After CV, final fitting, standard errors, and evaluation had completed, that unrelated ANOVA remained active for roughly 11 hours until it was stopped. Completed target artifacts were preserved. The validation runner now ends at the final model, CV evaluation, and provenance targets; production pipeline targets are unchanged.

The useful timing breakdown before ANOVA was:

| Component | Time |
|---|---:|
| Staged tuning through the last work item | about 95.4 min |
| Sum of 70 candidate-fit target times | 91.9 min |
| Selected OOF cache assembly | 1.6 min |
| Final full-data model fit | 1.5 min |
| Final-model standard errors | 34.7 min |
| Cross-validated evaluation | 3.7 min |
| Harness start through pre-ANOVA completion | 138.6 min |

Pre-ANOVA resource samples recorded:

| Measure | Observed peak |
|---|---:|
| Process working set | 12.78 GB |
| System-used memory | 38.14 GB |
| VRAM | 5,195 MiB |
| GPU utilization | 100% peak; 83% median |
| GPU memory failure | none |

The 15.41 GB process, 41.62 GB system-memory, and 8,004 MiB VRAM peaks in the terminal interrupted-run summary include the long ANOVA and are not CV/MEM acceptance measurements.

The completed isolated target store is 1,128,010,436 bytes. This is an absolute measurement, not a valid storage-growth ratio: the earlier 104 MB store ended before successful tuning fits and is not a matched exhaustive baseline. Consequently, the 25% storage-growth gate remains unassessed for this continental run. The staged store contains only 70 candidate caches versus the 120 an exhaustive run would create.

## Resume result

A second harness invocation against the completed store finished successfully in 299.6 seconds with exit code zero:

- no candidate fit was repeated;
- the existing work-item branches were skipped;
- cached round results and the selected prediction cache were recombined;
- final targets remained complete;
- peak process working set was 4.93 GB;
- peak VRAM was 1,624 MiB;
- no GPU memory failure occurred.

This is restart/reuse evidence only. It is not a clean end-to-end runtime measurement.

## Decision and remaining caveat

The scalable shared MEM implementation passes the continental computational, leakage, staged-fit, cached-OOF, prediction-coverage, GPU-memory, and resume gates. It removes the deterministic dense-allocation failure without adding project- or continent-specific logic.

The evidence is not a formally clean Phase 4 repetition because the isolated store was resumed after correcting the shared configuration propagation bug. A new empty-store repetition would be required to label the 138.6-minute measurement a clean acceptance baseline. Repeating that computation is a benchmark-policy decision, not evidence of a remaining implementation defect.

The long ANOVA is a separate scalability concern and should be tracked outside Issue 143. It does not construct MEMs and did not prevent the CV, final model, or cross-validated evaluation artifacts from completing.

## Repository validation

After the continental evidence was assembled:

- all 34 changed R files parsed successfully;
- every changed R line remained within 80 characters;
- focused construction, projection, fold, benchmark, and pipeline-contract tests passed;
- the complete suite passed 3,920 assertions with zero failures and zero warnings, plus one expected opt-in VegVault integration skip;
- `renv` detected `spmoran` and its runtime dependency closure explicitly;
- `renv::status()` reported a consistent project library and lockfile.
