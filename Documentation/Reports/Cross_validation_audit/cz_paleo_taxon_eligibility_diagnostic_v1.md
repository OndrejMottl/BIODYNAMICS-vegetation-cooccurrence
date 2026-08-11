# CZ paleo taxon eligibility diagnostic (v1)

**Recorded:** 2026-07-16 **Source store:** `Data/targets/cz_paleo_cv_reference_gpu/pipeline_paleo_core` **Evaluation artifact:** `data_sjsdm_fold_local_metrics`

## Purpose

This Phase 4 checkpoint asks whether the low community Tjur R2 is caused by a broken cross-validation implementation, sparse or nearly constant taxa, or weak probability separation among otherwise evaluable taxa. It uses the fresh GPU reference without refitting. Each taxon has at most 15 fold evaluations: five folds in each of three assignment repeats.

The provisional scientific gate remains mean fold-local Tjur R2 of at least `0.1`. This is a prospective user-specified working threshold, not a universal ecological-model standard. The three-repeat intervals below are descriptive repeat ranges and should not be interpreted as population confidence intervals.

## Community-level guardrails

The GPU fold-macro AUC is `0.66079`, with a descriptive repeat interval of `0.643` to `0.680`. The corresponding prevalence-null AUC is exactly `0.5`. Thus every repeat supports discrimination above chance under the corrected fold-local estimand.

Of 159 evaluable fold-taxon Tjur estimates, 116 are positive (`73.0%`) and 30 are at least `0.1` (`18.9%`). The median is only `0.0165`; the first and third quartiles are approximately `-0.00007` and `0.0693`. At the taxon-within-repeat level, 9, 9, and 11 of the 13 taxa with any evaluable folds have positive mean Tjur R2. The requirement that most evaluable taxa show positive discrimination therefore passes, but the magnitude requirement does not.

## Taxon-level results

Prevalence is observation-weighted across folds and repeats. `Evaluable folds` counts model Tjur estimates with two held-out classes and complete model predictions. Mean Tjur uses only those folds.

| Taxon | Prevalence | Evaluable folds / 15 | Mean Tjur R2 | Positive folds | Mean AUC |
|---|---:|---:|---:|---:|---:|
| Juniperus | 0.029 | 8 | -0.0002 | 4 | 0.535 |
| Vaccinium | 0.054 | 12 | -0.0013 | 5 | 0.398 |
| Calluna | 0.088 | 10 | -0.0032 | 4 | 0.340 |
| Fraxinus | 0.127 | 14 | 0.0140 | 9 | 0.677 |
| Salix | 0.137 | 14 | 0.0503 | 11 | 0.728 |
| Tilia | 0.195 | 15 | 0.0776 | 15 | 0.756 |
| Ulmus | 0.259 | 15 | 0.0426 | 10 | 0.656 |
| Carpinus | 0.444 | 15 | 0.191 | 15 | 0.833 |
| Quercus | 0.859 | 11 | -0.0113 | 4 | 0.503 |
| Corylus | 0.868 | 13 | 0.0344 | 11 | 0.669 |
| Fagus | 0.873 | 12 | 0.189 | 11 | 0.879 |
| Abies | 0.893 | 14 | 0.0158 | 12 | 0.709 |
| Betula | 0.985 | 6 | 0.00004 | 5 | 0.763 |
| Pinus | 0.990 | 0 | Not evaluable | 0 | Not evaluable |
| Alnus | 0.995 | 0 | Not evaluable | 0 | Not evaluable |
| Picea | 0.995 | 0 | Not evaluable | 0 | Not evaluable |

Carpinus and Fagus are the only taxa whose across-fold mean exceeds `0.1`. Both are positive in every repeat, with repeat means of `0.170` to `0.223` for Carpinus and `0.174` to `0.216` for Fagus. Salix is also repeat-stable but only near `0.05`. Calluna is negative in every repeat, while Quercus is negative in two repeats and only slightly positive in the third. Vaccinium is near zero and negative in two repeats.

Pinus, Alnus, and Picea have no evaluable model Tjur or AUC estimates. Although each has three held-out folds containing both classes, the corresponding model predictions are unavailable because the taxon is constant in the training response. Betula is technically evaluable in only six folds and its apparently strong AUC is paired with essentially zero Tjur separation. This illustrates why AUC alone is insufficient for this reference.

### Calibration stability

Calibration slopes are estimable in 155 fold-taxon groups, while three groups have separation and one has a fit warning. The estimable slopes are too unstable to rescue or reject individual taxa: Betula has a median slope of `28.6` across only six folds, Calluna has median `-15.0` and range `-55.3` to `30.4`, and Juniperus has median `-11.0` and range `-41.9` to `187`. Vaccinium ranges from `-104` to `13.9`. Even better-performing taxa vary materially; Carpinus ranges from `0.709` to `6.83`, and Fagus from `-0.385` to `3.52`. These values confirm the earlier community-level conclusion that calibration slope is not a stable selection guardrail for this small reference. Log loss and Brier score remain the reliable calibration-sensitive summaries.

## What drives the low community Tjur R2

Taxon prevalence alone is not a sufficient explanation. Across the 13 taxa with an evaluable Tjur estimate, the descriptive Spearman association between prevalence and mean Tjur is only `0.308`. Both rare taxa and nearly ubiquitous taxa can perform poorly, while Fagus performs well despite high prevalence.

Fold evaluability is more informative. The descriptive Spearman association between the number of two-class folds and mean Tjur is `0.709`. This estimate is based on only 13 taxa and is not causal, but it shows that the small CZ data set creates an important coverage limitation. Even after excluding unavailable folds, however, the median evaluable Tjur remains `0.0165`. Sparse classes therefore explain part of the instability and missing coverage, but not the weak separation among the remaining taxa.

## Decision

The two status dimensions are deliberately separated:

- `technical_cv_status = pass`: folds, GPU fits, OOF keys, null baselines, scoring, aggregation, and repeat behavior satisfy the implemented contracts.
- `scientific_prediction_status = fail_provisional_tjur_gate`: fold-macro Tjur R2 is approximately `0.053`, below `0.1`; only two taxa exceed `0.1` on average, and only 18.9% of evaluable fold-taxon estimates reach that value.

The result does not support treating the current CZ model as a strong scientific prediction reference. It does support retaining CZ as an engineering reference: the model beats the prevalence null, discrimination is above chance, and the pipeline exposes the weak and unavailable taxa instead of hiding them.

## Next experiment

The next Phase 4 checkpoint should compare intercept/prevalence, abiotic-only, spatial-only, and full models on the identical folds. That experiment will show whether the weak Tjur magnitude arises primarily from limited predictors, the spatial component, or the intrinsic sample/class structure. Sparse-taxon exclusion should not be chosen from these outcomes post hoc; any eligibility rule should be declared before the comparison is used for selection.
