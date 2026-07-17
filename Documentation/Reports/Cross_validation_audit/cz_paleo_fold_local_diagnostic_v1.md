# CZ paleo fold-local predictive diagnostic (v1)

**Recorded:** 2026-07-15
**Source artifact:** `data_sjsdm_out_of_fold_predictions`
**Source store:** `Data/targets/cz_paleo_cv_reference/pipeline_paleo_core`
**Model-fitting device for source artifact:** CPU

## Purpose

This checkpoint tests whether the weak predictive metrics in
`cz_paleo_cv_reference_v1.md` were caused by pooling predictions from separately
fitted cross-validation folds. It re-evaluates the existing 9,840 OOF rows within
each repeat, fold, and taxon. No model was refitted.

The standalone evaluator preserves the historical pooled v1 output and compares
model predictions with the fold-training-prevalence null on the scale where each
prediction was generated.

## Fold-local contract

The evaluator produced 1,440 rows from 240 repeat-fold-taxon groups, two
prediction sources, and three metrics:

- Prediction sources: `model`, `prevalence_null`.
- Metrics: Tjur R2, AUC, and binary log loss.
- Tjur R2 and AUC were evaluable for 159 of 240 model groups.
- Fifty-five groups had no held-out absences and 17 had no held-out presences.
- Nine model groups had incomplete predictions.
- Binary log loss was evaluable for 231 of 240 model groups.

Model and null predictions were evaluated independently. An unavailable model
prediction therefore did not automatically suppress an otherwise valid null
diagnostic.

## Overall comparison

| Prediction source | Metric | Fold-taxon macro | Observation weighted | Evaluable fold-taxa |
|---|---|---:|---:|---:|
| Model | Tjur R2 | 0.0526 | 0.0524 | 159 |
| Prevalence null | Tjur R2 | 0 | 0 | 159 |
| Model | AUC | 0.646 | 0.645 | 159 |
| Prevalence null | AUC | 0.5 | 0.5 | 159 |
| Model | Log loss | 0.308 | 0.311 | 231 |
| Prevalence null | Log loss | 0.328 | 0.330 | 231 |

The fold-local null returns its theoretical Tjur R2 and AUC baselines exactly.
This confirms that the previously negative null Tjur R2 and null AUC values near
`0.25-0.29` were cross-fold pooling artifacts.

Fold-local model AUC is approximately `0.646`, close to the tuning fold-macro AUC
of approximately `0.656` and materially different from the pooled OOF AUC of
approximately `0.482`. The model therefore has useful within-fold ranking signal.

Fold-local model Tjur R2 increases from the pooled value of approximately `0.029`
to approximately `0.053`. Pooling depressed the discrimination estimate, but the
corrected value remains below the provisional scientific threshold of `0.1`.

## Repeat-level comparison

| Repeat | Source | Tjur R2 | AUC | Log loss |
|---:|---|---:|---:|---:|
| 1 | Model | 0.0700 | 0.657 | 0.300 |
| 1 | Prevalence null | 0 | 0.5 | 0.325 |
| 2 | Model | 0.0453 | 0.634 | 0.303 |
| 2 | Prevalence null | 0 | 0.5 | 0.321 |
| 3 | Model | 0.0428 | 0.649 | 0.322 |
| 3 | Prevalence null | 0 | 0.5 | 0.339 |

The model improves discrimination and log loss over the null in every repeat.
However, no repeat reaches Tjur R2 `0.1`.

## Taxon-level Tjur R2

| Taxon | Mean fold Tjur R2 | Median fold Tjur R2 | Evaluable folds |
|---|---:|---:|---:|
| Quercus | -0.0111 | -0.0131 | 11 |
| Calluna | -0.00350 | -0.00150 | 10 |
| Vaccinium | -0.00136 | -0.000326 | 12 |
| Betula | 0.0000674 | 0.0000641 | 6 |
| Juniperus | 0.000538 | 0.000195 | 8 |
| Abies | 0.0150 | 0.0223 | 14 |
| Fraxinus | 0.0153 | 0.0176 | 14 |
| Corylus | 0.0359 | 0.0365 | 13 |
| Ulmus | 0.0418 | 0.0218 | 15 |
| Salix | 0.0533 | 0.0502 | 14 |
| Tilia | 0.0785 | 0.0365 | 15 |
| Carpinus | 0.188 | 0.195 | 15 |
| Fagus | 0.189 | 0.203 | 12 |

Only Carpinus and Fagus exceed mean fold Tjur R2 `0.1`; three taxa have negative
mean discrimination. Community-level improvement is therefore not representative
of uniformly reliable taxon prediction.

## Interpretation

The original conclusion needs refinement:

- The model is not worse than random at ranking held-out observations within
  folds; pooled AUC obscured a stable AUC near `0.65`.
- The model's probability separation remains weak. Correct fold-local Tjur R2 is
  approximately `0.053`, not `0.029`, but still falls short of `0.1`.
- Only 66.25% of fold-taxon groups are evaluable for Tjur R2 and AUC because many
  held-out groups contain one response class or have incomplete predictions.
- The small CZ dataset remains useful as a technical stress test but has not yet
  passed the provisional scientific prediction gate.

## Next checkpoint

Add formal fold-macro and observation-weighted aggregation, uncertainty across
repeats/folds, Brier score, calibration intercept/slope, and paired model-null
deltas. The performance decision must then be declared before any wider GPU
regularization search or model-component experiment.
