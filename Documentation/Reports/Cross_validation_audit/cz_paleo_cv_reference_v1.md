# CZ paleo real cross-validation reference (v1)

**Recorded:** 2026-07-14 **Issue:** #139 **Reference base:** `05b1e4b74b9bdcd8b015bab8e08b7b6ba2d6ce7d`

## Purpose

This reference supplements the fast mandatory CZ smoke test with a real, reproducible regularization-selection run. It uses the small Czechia paleo genus model, a production-like candidate grid, repeated spatial assignments, actual sjSDM fitting, selected-candidate OOF refits, and an isolated target store. It is an end-to-end CV correctness and diagnostic reference, not a definitive ecological performance benchmark.

## Configuration

The `project_cz_paleo_cv_reference` profile inherits the CZ paleo data and model configuration while isolating output in `Data/targets/cz_paleo_cv_reference`. The dedicated runner is `R/03_Supplementary_analyses/Validation/Cross_validation/Reference_runs/run_cz_paleo_cv_reference.R`; the existing `run_cz_pipelines.R` smoke test is unchanged.

| Setting | Reference value |
|---|---|
| Pipeline | `R/Pipelines/pipeline_paleo_core.R` |
| Taxonomic resolution | Genus |
| Locations / samples / response taxa | 27 / 205 / 15 |
| CV strategy | `spatially_stratified_group_kfold` |
| Folds / assignment repeats | 5 / 3 |
| Selected grid-cell size | approximately 266 km |
| CV fitting device | CPU |
| Iterations / sampling | 500 / 200 |
| Effective MEV count | 3 in every selected fold |
| Alpha grid | `0.5` for covariance, coefficients, and spatial terms |
| Lambda grid | Cartesian product of `0` and `0.1` for covariance, coefficients, and spatial terms |
| Candidate count | 8; 120 candidate-fold fits |

## Execution record

- Fresh interpolation completed in 3m 0.6s with 55 targets completed and none skipped.
- Candidate tuning completed in 24m 37.3s. All 120 rows had `fit_status = "ok"`, finite scores, unique deterministic fit seeds, and unique deterministic score seeds. Log output recorded early stopping for 117 fits; three used the full iteration budget.
- The selected candidate was independently refitted across all 15 repeat/fold combinations in 2m 20.1s. All 15 fits had status `ok` and all 15 emitted early stopping.
- The first full-graph process was killed when its later full-data model subprocess started. No target error was recorded and all CV artifacts remained intact. A normal non-fresh resume verified the completed store, built 38 remaining targets, skipped 203 valid targets, and ended successfully in 1m 16.9s.
- Final store metadata contained 504 rows, zero errored targets, and 15 targets with retained warnings.
- The full-data selected model early-stopped after 179 epochs, with tail-loss slope `0` and median tail-loss difference `0`.
- The full regression suite before execution reported `FAIL 0 | WARN 0 | SKIP 1 | PASS 3249`; the skip was the documented opt-in VegVault integration test.
- The unchanged mandatory `run_cz_pipelines.R` gate was then rerun fresh. Paleo core completed 199 targets with 42 skipped, paleo resolution completed 302 with 42 skipped, and modern resolution completed 2,143 with none skipped. Store metadata reported zero errors in all three stores.

## Candidate selection

All candidates used alpha `0.5`. Candidates are ranked below by mean pooled held-out NLL per response across the three assignment repeats.

| Rank | Candidate | Lambda covariance | Lambda coefficients | Lambda spatial | Mean NLL/response | SD NLL/response | Mean fold-macro AUC |
|---:|---|---:|---:|---:|---:|---:|---:|
| 1 | `candidate_008` | 0.1 | 0.1 | 0.1 | 0.306641469176137 | 0.0103404521614122 | 0.656030399724223 |
| 2 | `candidate_007` | 0.1 | 0.1 | 0 | 0.318177889306055 | 0.00785852502426753 | 0.636868896242220 |
| 3 | `candidate_006` | 0.1 | 0 | 0.1 | 0.321336809108737 | 0.0144982278378476 | 0.667871513225882 |
| 4 | `candidate_004` | 0 | 0.1 | 0.1 | 0.322464469904830 | 0.0241163221553022 | 0.611287276704971 |
| 5 | `candidate_005` | 0.1 | 0 | 0 | 0.339606320291058 | 0.0152421065570900 | 0.666926689881572 |
| 6 | `candidate_003` | 0 | 0.1 | 0 | 0.344292452652342 | 0.0207376532693102 | 0.575738307447049 |
| 7 | `candidate_002` | 0 | 0 | 0.1 | 0.351735853277032 | 0.0320317311796971 | 0.645934666879926 |
| 8 | `candidate_001` | 0 | 0 | 0 | 0.384313689888821 | 0.0340474334268936 | 0.652067728225472 |

The selected fully regularized candidate reduced the selection loss by 20.2% relative to the unregularized candidate. Its repeat-specific NLL/response values were `0.298035773916492`, `0.303776230748575`, and `0.318112402863342`; its fold-macro AUC values were `0.660603298733578`, `0.676503281900089`, and `0.630984618539001`.

The winning candidate is on the upper boundary for all three lambda dimensions. This run proves that the single zero-lambda smoke configuration was inadequate, but it does not establish that `0.1` is the scientific optimum. A wider grid is required before production tuning.

## Selected-candidate OOF results

The selected refits produced 9,840 OOF rows: 3,154 `ok` rows and 126 `constant_in_training` rows in each repeat. All 9,462 `ok` probabilities were finite and ranged from `0.00392784597352147` to `0.998937368392944`. All 15 diagnostics had status `ok`; effective MEV count was three and retained taxa ranged from 14 to 16.

Positive delta means the model improved on the fold-training-prevalence null. For log loss, delta is null minus model; for Tjur R2 and AUC, it is model minus null.

| Repeat | Metric | Model | Prevalence null | Improvement delta |
|---:|---|---:|---:|---:|
| 1 | Tjur R2 | 0.0422186728234671 | -0.0142285803194663 | 0.0564472531429334 |
| 1 | AUC | 0.501925180021733 | 0.287297072508738 | 0.214628107512995 |
| 1 | Log loss | 0.355894928025124 | 0.383810853909818 | 0.0279159258846932 |
| 2 | Tjur R2 | 0.0285113478878042 | -0.0126816369752311 | 0.0411929848630354 |
| 2 | AUC | 0.485281973482963 | 0.294385412509649 | 0.190896560973314 |
| 2 | Log loss | 0.362310277000775 | 0.382019875274307 | 0.0197095982735325 |
| 3 | Tjur R2 | 0.0158291512500567 | -0.0249131482245810 | 0.0407422994746377 |
| 3 | AUC | 0.457934416715453 | 0.247104442786644 | 0.210829973928809 |
| 3 | Log loss | 0.383078227420152 | 0.401670497473052 | 0.0185922700529000 |

Across repeats, mean model Tjur R2 was `0.0288530573204427`, mean pooled AUC was `0.481713856740050`, and mean log loss was `0.367094477482017`. Mean log loss improved over the null by `0.0220725980703752`, or approximately 5.7%. The regularized model beat the null log loss in every repeat.

The pooled AUC is lower than the tuning table's fold-macro AUC because the final evaluator pools OOF rows across folds before calculating taxon metrics. Fold-specific training prevalence and probability calibration vary spatially, so pooling can reverse part of the within-fold ranking signal. The same fold-prevalence structure produces null AUC values far below 0.5. This is diagnostically important and should be considered when #138 evaluates the future CV estimand and partition strategy.

Tjur R2 remains small. Median taxon Tjur R2 was `0.0123`, `-0.00386`, and approximately `0.000005` across repeats, and only 8, 6, and 7 of 13 evaluable taxa had positive values. The real run therefore demonstrates functional regularization selection and reproducible OOF improvement in proper scoring loss; it does not demonstrate strong discrimination for this small local dataset.

## Fitted model and provenance

The final fitted model reported McFadden R2 `0.166485846168744` and Nagelkerke R2 `0.813612182748956`. Provenance recorded tier `cz_paleo_cv_reference`, candidate `candidate_008`, source `unit_cv`, three repeats, five effective folds, 15 successful fold fits, minimum 14 retained taxa, and constant effective MEV count three.

## Artifact hashes

| Target | `targets` data hash |
|---|---|
| `data_sjsdm_regularization_candidates` | `3bd53d51813810c7` |
| `data_sjsdm_tuning_candidates` | `56c5682a1fde3691` |
| `data_sjsdm_tuning_summary` | `8a243ab86845678d` |
| `data_sjsdm_selected_regularization_unit` | `1442fd113d5f7363` |
| `data_sjsdm_out_of_fold_predictions` | `9282cd94d08516ba` |
| `data_sjsdm_out_of_fold_diagnostics` | `77f808478da98dd1` |
| `data_sjsdm_model_provenance` | `075ff1f0efc15a97` |
| `model_evaluation_cross_validated` | `5f613abac99b41b9` |
| `model_evaluation_fitted` | `1e91d6cb2e78d8b1` |

All artifact schemas and column orders matched the v1 contract recorded in `correctness_reference_metadata_v1.md`. Future comparisons use the exact structural invariants and `1e-4` numeric tolerance defined there.

## Conclusion

The dedicated run confirms that the CV machinery performs real fold-local fitting, deterministic repeated scoring, loss-based candidate selection, independent selected-candidate refitting, OOF assembly, evaluation, and provenance publication. Regularization materially improves held-out NLL and OOF log loss beats the prevalence null in every repeat. The run also exposes three scientific limitations rather than concealing them: low Tjur discrimination, pooled-versus-fold AUC sensitivity, and a winning candidate at the lambda-grid boundary.
