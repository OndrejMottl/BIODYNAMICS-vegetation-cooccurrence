# CZ paleo repeat uncertainty diagnostic (v1)

**Recorded:** 2026-07-15
**Source artifact:** `data_sjsdm_out_of_fold_predictions`
**Source store:** `Data/targets/cz_paleo_cv_reference/pipeline_paleo_core`
**Model-fitting device for source artifact:** CPU

## Purpose

This checkpoint completes Phase 2 of the predictive-performance audit by
summarizing variation across the three repeated cross-validation splits. It
uses existing OOF predictions and does not refit the model.

For each source, metric, and aggregation method, the summary records the mean,
median, standard deviation, and empirical 2.5th and 97.5th percentiles of the
repeat estimates. It also records evaluable repeat counts and the mean and range
of fold-taxon coverage.

These bounds describe stability across the three supplied repeated splits. With
only three repeats on the same dataset, they are not population-level confidence
intervals and should not be interpreted as such.

## Model performance across repeats

| Metric | Aggregation | Mean | Empirical 95% repeat interval | Mean fold-taxon coverage |
|---|---|---:|---:|---:|
| AUC | Fold macro | 0.647 | 0.635 to 0.657 | 66.2% |
| AUC | Observation weighted | 0.645 | 0.635 to 0.656 | 66.2% |
| Tjur R2 | Fold macro | 0.0527 | 0.0429 to 0.0688 | 66.2% |
| Tjur R2 | Observation weighted | 0.0525 | 0.0424 to 0.0684 | 66.2% |
| Log loss | Fold macro | 0.308 | 0.300 to 0.321 | 96.2% |
| Log loss | Observation weighted | 0.311 | 0.301 to 0.323 | 96.2% |
| Brier score | Fold macro | 0.0892 | 0.0870 to 0.0918 | 96.2% |
| Brier score | Observation weighted | 0.0899 | 0.0873 to 0.0926 | 96.2% |

Model AUC remains above `0.5` in every observed repeat and under both
aggregation methods. Conversely, Tjur R2 remains below `0.1` in every observed
repeat. The low Tjur result is therefore not caused by a single unfavorable
repeat or by unequal held-out fold sizes.

## Paired model improvement

Positive values favor the model. Discrimination uses model minus prevalence
null; loss metrics use prevalence null minus model.

| Metric | Aggregation | Mean improvement | Empirical 95% repeat interval | Positive repeats |
|---|---|---:|---:|---:|
| AUC | Fold macro | 0.147 | 0.135 to 0.157 | 3 / 3 |
| AUC | Observation weighted | 0.145 | 0.135 to 0.156 | 3 / 3 |
| Tjur R2 | Fold macro | 0.0527 | 0.0429 to 0.0688 | 3 / 3 |
| Tjur R2 | Observation weighted | 0.0525 | 0.0424 to 0.0684 | 3 / 3 |
| Log loss | Fold macro | 0.0199 | 0.0173 to 0.0245 | 3 / 3 |
| Log loss | Observation weighted | 0.0195 | 0.0166 to 0.0241 | 3 / 3 |
| Brier score | Fold macro | 0.00762 | 0.00645 to 0.00947 | 3 / 3 |
| Brier score | Observation weighted | 0.00752 | 0.00644 to 0.00933 | 3 / 3 |

All paired improvements are positive in all three repeats. The model therefore
has repeat-stable predictive value relative to the prevalence null, even though
its absolute probability separation is weak.

## Calibration stability

Mean model calibration intercept is near zero (`-0.052` fold macro), but its
repeat interval spans approximately `-0.131` to `0.028`. This does not indicate
a stable directional calibration-in-the-large bias.

Calibration slope remains unsuitable for a simple community-level decision.
The fold-macro repeat estimates have a mean of approximately `-2.08`, a median
of `-3.46`, and an empirical interval of approximately `-3.59` to `0.60`.
Fold-taxon slope coverage averages only `62.5%`, and the underlying coefficients
are highly variable. Calibration should therefore remain a diagnostic guardrail
rather than a selection statistic for this small reference.

## Phase 2 conclusion

The corrected evaluation supports two simultaneous conclusions:

1. The CV machinery is producing coherent, repeat-stable signal. AUC and both
   proper scoring rules improve over the prevalence null in every repeat.
2. The current CZ model does not meet the provisional scientific discrimination
   gate. Tjur R2 remains between approximately `0.042` and `0.069`, below `0.1`,
   with only about two thirds of fold-taxon groups evaluable.

Phase 3 should publish these fold-local outputs as versioned pipeline artifacts
and verify GPU parity without replacing the historical CPU reference. The
scientific decision and baseline/component experiments remain Phase 4 work.
