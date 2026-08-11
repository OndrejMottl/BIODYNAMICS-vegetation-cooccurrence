# CZ paleo fold aggregation diagnostic (v1)

**Recorded:** 2026-07-15 **Source artifact:** `data_sjsdm_out_of_fold_predictions` **Source store:** `Data/targets/cz_paleo_cv_reference/pipeline_paleo_core` **Model-fitting device for source artifact:** CPU

## Purpose

This checkpoint formalizes repeat-level aggregation of fold-local metrics. It uses the existing OOF prediction artifact and does not refit the model or pool predictions from independently fitted folds.

Two aggregation estimands are retained:

- `fold_macro`: every evaluable fold-taxon group receives equal weight.
- `observation_weighted`: fold-taxon metrics are weighted by held-out sample count.

The output records evaluable and total fold-taxon groups, folds, taxa, observations, presences, absences, and prevalence beside every estimate.

## Paired improvement contract

Model and prevalence-null metrics are paired by repeat, fold, taxon, and metric. Only pairs with two `ok` statuses contribute to the estimate. Positive values always favor the model:

- Tjur R2 and AUC use model minus prevalence null.
- Log loss and Brier score use prevalence null minus model.
- Calibration coefficients are summarized by source but are not transformed into directional improvements because their ideal values are zero and one, not simply larger or smaller.

## CZ paired results

| Repeat | Metric | Fold macro | Observation weighted | Evaluable / total fold-taxa |
|---:|---|---:|---:|---:|
| 1 | AUC improvement | 0.157 | 0.156 | 52 / 80 |
| 2 | AUC improvement | 0.134 | 0.135 | 56 / 80 |
| 3 | AUC improvement | 0.149 | 0.145 | 51 / 80 |
| 1 | Tjur R2 improvement | 0.0700 | 0.0696 | 52 / 80 |
| 2 | Tjur R2 improvement | 0.0453 | 0.0458 | 56 / 80 |
| 3 | Tjur R2 improvement | 0.0428 | 0.0422 | 51 / 80 |
| 1 | Log-loss improvement | 0.0248 | 0.0245 | 77 / 80 |
| 2 | Log-loss improvement | 0.0177 | 0.0175 | 77 / 80 |
| 3 | Log-loss improvement | 0.0172 | 0.0166 | 77 / 80 |
| 1 | Brier improvement | 0.00961 | 0.00947 | 77 / 80 |
| 2 | Brier improvement | 0.00644 | 0.00643 | 77 / 80 |
| 3 | Brier improvement | 0.00680 | 0.00665 | 77 / 80 |

Every paired improvement is positive under both aggregation estimands. The conclusion that the model beats the prevalence null is therefore not driven by unequal held-out fold sizes.

## Coverage

Tjur R2 and AUC coverage is `65.0%`, `70.0%`, and `63.75%` across the three repeats. All five folds contribute, but only 13 of 16 taxa contribute at least one evaluable fold in each repeat. The evaluable class counts are:

| Repeat | Observations | Presences | Absences | Observation-weighted prevalence |
|---:|---:|---:|---:|---:|
| 1 | 2,139 | 871 | 1,268 | 0.407 |
| 2 | 2,298 | 1,029 | 1,269 | 0.448 |
| 3 | 2,091 | 897 | 1,194 | 0.429 |

Log loss and Brier score coverage is `96.25%` in every repeat: 77 of 80 fold-taxon groups, all five folds, and all 16 taxa. Each repeat contributes 3,154 fold-taxon observations, including 1,680 presences and 1,474 absences.

## Interpretation

The aggregation audit strengthens the technical conclusion: the selected model consistently improves ranking and proper scoring loss over the prevalence null, and macro versus observation-weighted estimates agree closely.

It does not resolve the scientific concern. Tjur R2 improvement remains between approximately `0.042` and `0.070`, below the provisional `0.1` threshold in every repeat and under both estimands. In addition, discrimination coverage is only about two thirds of fold-taxon groups. The remaining Phase 2 task is to add repeat distributions and uncertainty intervals before declaring the scientific performance decision.
