# Grouped CV fold-ladder implementation and migration audit

## Dated audit and subsequent completion

This report preserves the 2026-10-06 implementation and migration audit. Its pending-recovery statements describe that date, not current blockers. The [2026-10-07 recovery report](2026-10-07_calibration_evidence_recovery.md) records the completed modern-local fold refresh, verified legacy reuse, ten recalibrations and successful budget publication/configuration validation. Production fitting was separately started on 2026-10-08; that execution is not completion of all models or downstream products.

## Implemented policy

The direct and shared CV routes now preserve feasible initial assignments, otherwise try 10, 20, and 50 grouped folds before retaining exhaustive leave-one-location-out (LOO). The authored ladder includes the initial five-fold setting. All configured repeats and existing training-taxon, sample, location, MEM, grid-balance, and coverage checks remain mandatory. No fitting budget, candidate grid, worker count, taxon filter, or final-model setting was changed.

Attempt and partition diagnostics are persisted as separate target objects. Existing v2 analytical artifact schemas remain unchanged. The ladder is isolated from shared initial-assignment and final-fitting configuration values, so a policy change does not itself change heavy preparation inputs.

## Cached-design audit

The spatial audit examined 638 cached unit-resolution feasibility records across the six production store roots. Fourteen existing LOO designs change: thirteen modern-local records and one paleo-local record. No cached continental or regional design changes. Three of the four temporal LOO designs change; other already-feasible grouped designs retain their original assignments.

| Analysis | Unit or time slice | Resolution | Old LOO folds | New grouped folds | Old candidate-fold tasks | New staged candidate-fold tasks |
|---|---|---|---:|---:|---:|---:|
| Modern local | am_r007_l007 | Functional type | 1235 | 10 | 9880 | 140 |
| Modern local | as_r002_l011 | Functional type | 125 | 10 | 1000 | 140 |
| Modern local | as_r005_l008 | Functional type | 125 | 10 | 1000 | 140 |
| Modern local | eu_r004_l003 | Functional type | 182 | 20 | 1456 | 280 |
| Modern local | eu_r004_l004 | Functional type | 174 | 10 | 1392 | 140 |
| Modern local | eu_r005_l001 | Functional type | 170 | 50 | 1360 | 700 |
| Modern local | eu_r005_l007 | Functional type | 710 | 10 | 5680 | 140 |
| Modern local | eu_r007_l001 | Functional type | 354 | 10 | 2832 | 140 |
| Modern local | eu_r008_l001 | Functional type | 704 | 50 | 5632 | 700 |
| Modern local | eu_r008_l003 | Functional type | 162 | 10 | 1296 | 140 |
| Modern local | eu_r008_l004 | Functional type | 156 | 50 | 1248 | 700 |
| Modern local | eu_r009_l003 | Genus | 13 | 10 | 104 | 140 |
| Modern local | eu_r009_l003 | Family | 13 | 10 | 104 | 140 |
| Paleo local | am_r002_l006 | Family | 14 | 10 | 112 | 140 |
| Paleo temporal | Europe, 14500 BP | Genus | 71 | 10 | 568 | 140 |
| Paleo temporal | America, 17500 BP | Genus | 29 | 20 | 232 | 280 |
| Paleo temporal | America, 0 BP | Genus | 22 | 20 | 176 | 280 |

Counts use the existing eight-candidate exhaustive LOO policy versus the existing 8/4/2 staged grouped policy across three repeats. They exclude convergence escalation, selected-fold refits, and subsequent evaluations. Grouped CV can cost more for small units because it retains three repeats; the policy prioritizes feasible grouped evidence rather than minimizing task count unconditionally.

The interrupted modern-local unit `eu_r005_l015` still requires 588 LOO folds and 4,704 candidate-fold tasks: none of the grouped alternatives passes its existing data checks. The high-fold case `am_r010_l001` also remains unchanged. This change cannot eliminate every expensive LOO case without changing the scientific guardrails.

The spatial inventory audit did not select any new calibration representative. A separate comparison against existing calibration result hashes found mismatches for ten of the twenty registered representatives. Those stores and result files were not modified by the fold-ladder audit, so these are pre-existing compatibility findings, not evidence that the new ladder changed their prepared inputs. Every incompatible representative's prepared-fold cache was rebuilt after its calibration finished; none of the ten compatible representatives has that timestamp pattern. Current, prior-policy, and legacy input hashes were checked. Changing the hashing locale did not resolve the mismatches.

The incompatible representatives are modern continental Europe (all three resolutions), modern regional `eu_r005` (all three), modern local `eu_r005_l010` functional type, and paleo local `eu_r005_l006` (all three). The original calibration input payload is not retained in the result, so timestamps alone cannot establish whether the newer cache is scientifically identical. Do not rewrite their hashes or silently schedule ten new GPU calibrations. Resolve this existing evidence mismatch before production resumes; it does not, by itself, establish that new GPU calibration is necessary.

## Cache and execution safeguards

The modern completion batch was stopped before the modelling-contract change. No production store was deleted or archived, no cached hashes were forcibly rewritten, and no unrelated R sessions were stopped. Metadata snapshots and detailed audit tables are retained under `Data/Temp/Main_analysis_execution/cv_fold_ladder_20261006/`.

A diagnostic ASCII-versus-UTF-8 locale mismatch initially changed serialized file hashes for identical values in the stopped unit. Rebuilding those diagnostic targets under the original UTF-8 locale naturally restored their original hashes. A subsequent normal check finished in 11.8 seconds with 22 configuration targets completed and 1,101 targets skipped, including heavy preparation and the unchanged final assignments.

The final run must retain the original UTF-8 locale. Scientific configuration is not controlled through any new environment-variable interface.

## Validation and remaining gates

Focused CV, deterministic-search, scheduling, configuration-generation, and direct/shared pipeline-contract tests pass. Configuration generation and semantic-reference validation pass for all 26 profiles. All 1,010 R sources parse; changed R sources satisfy the 80-column contract. The full test suite passes. Initial validation exposed external taxonomy access restrictions and a pre-existing Windows line-ending assertion; the taxonomy tests passed with network access and the assertion was made newline-portable without weakening its contract.

Function documentation and its website reference were generated. Architecture generators record 19,782 profile-target rows across all 26 profiles, and the blocking architecture validator passes with zero findings. A sandboxed manifest subprocess crashed; the complete generation and validation succeeded on retry outside the sandbox. Generated HTML retains renderer-supplied whitespace; authored R/configuration files pass `git diff --check`.

Both paleo CZ pipelines and the modern CZ pipeline completed successfully with no recorded target errors. The first fresh CZ interpolation pass completed successfully; optional progress screenshots stalled, so the analytical validation was resumed with the existing `plot_progress = FALSE` option and completed interpolation reused. The resolution test and modern test retain their canonical fresh-run settings. The final modern evaluation artifacts were written at 22:07:55 CEST on 6 October 2026. No production model runner has been restarted.

Validation logs are `Data/Temp/cv_ladder_full_tests_completed.log`, `Data/Temp/cv_ladder_architecture_completed.log`, and `Data/Temp/cv_ladder_smoke_resume.log`. Metadata verification is saved in `Data/Temp/cv_ladder_smoke_metadata.log`.

The bounded GPU check passed using one candidate and one fold from the newly selected ten-fold `eu_r009_l003` genus design, with 500 iterations and sampling 200. Preparation, GPU fitting, prediction, and scoring took 19.3 seconds in total; the fit was converged, returned status `ok`, and produced finite normalized held-out loss (0.295). It used eleven training locations, two held-out locations, and three retained taxa. This tiny check is not a representative production timing benchmark. Its evidence is diagnostic, not accepted calibration or production tuning evidence, and is written only under the audit directory. The log is `Data/Temp/cv_ladder_bounded_gpu.log`.

The code and validation gates are complete, but production migration and resumption are not. Before resumption, resolve the pre-existing calibration hash mismatches, refresh affected modern-local prepared folds, and verify that required representative evidence remains compatible. Let `targets` invalidate CV selections, models, tier summaries, synthesis, and figures naturally where their real inputs change. The affected paleo-local and temporal results are reported for a separate scoped rerun; they have not been silently rerun. No changes have been staged or committed.
