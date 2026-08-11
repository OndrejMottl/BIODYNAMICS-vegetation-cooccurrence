# CZ paleo fold-local calibration diagnostic (v1)

**Recorded:** 2026-07-15 **Source artifact:** `data_sjsdm_out_of_fold_predictions` **Source store:** `Data/targets/cz_paleo_cv_reference/pipeline_paleo_core` **Model-fitting device for source artifact:** CPU

## Purpose

This checkpoint extends the fold-local evaluation contract with Brier score, calibration-in-the-large, and calibration slope. It uses the existing 9,840 OOF prediction rows and does not refit the model.

Calibration intercept is estimated by logistic regression with the predicted logit as an offset. Calibration slope is estimated by logistic regression with a free intercept. Probabilities are clipped to `[1e-6, 1 - 1e-6]` before the logit transformation.

## Metric contract

The fold-local evaluator now returns six metrics for each repeat, fold, taxon, and prediction source:

- Tjur R2 and AUC for discrimination.
- Log loss and Brier score as proper scoring rules.
- Calibration intercept and slope where estimable.

Brier score remains defined for a one-class held-out group. Calibration coefficients require both classes. Calibration slope also receives an explicit undefined status for constant predictions, complete separation, numerical fit warnings, and fit failures. The evaluator therefore does not report extreme coefficients from a warning-producing fit as valid estimates.

## Overall results

| Prediction source | Metric | Fold-taxon macro | Observation weighted | Evaluable fold-taxa |
|---|---|---:|---:|---:|
| Model | Brier score | 0.0892 | 0.0899 | 231 |
| Prevalence null | Brier score | 0.0968 | 0.0975 | 231 |
| Model | Calibration intercept | -0.0494 | -0.0447 | 159 |
| Prevalence null | Calibration intercept | -0.0459 | -0.0425 | 159 |
| Model | Calibration slope | -2.17 | -2.18 | 150 |

The model improves macro Brier score by approximately 7.9% relative to the prevalence null. It has the lower Brier score in 158 of 231 paired fold-taxon groups; the null is better in 73. This supports the earlier log-loss result that the model adds probabilistic information on average, but the improvement is not uniform.

Mean calibration intercept is close to zero for both sources, suggesting little average calibration-in-the-large bias among evaluable fold-taxon groups. However, this should not be interpreted as complete calibration because slope behavior is highly heterogeneous.

## Calibration-slope stability

Of the 240 model fold-taxon groups:

- 150 have an estimable slope.
- 55 have no held-out absences and 17 have no held-out presences.
- Nine have incomplete model predictions.
- Five have complete separation.
- Four produce numerical fit warnings and are retained with an explicit undefined status.

Among the 150 estimable slopes, the median is `1.50`, the interquartile range is `-0.370` to `3.65`, 107 are positive, and 43 are negative. The range is extreme (`-215` to `107`), so the arithmetic mean of `-2.17` is dominated by unstable small-group estimates and is not a defensible standalone community summary.

Repeat-level mean slopes also vary strongly: `-3.60`, `-3.46`, and `0.815` for repeats 1, 2, and 3 respectively. Formal aggregation and uncertainty are needed before applying a calibration gate.

## Interpretation

The Brier result reinforces the conclusion that the model is better than the prevalence null on average. It does not resolve the concern about weak Tjur R2: probability separation remains modest and performance differs substantially among taxa and folds.

The calibration analysis reveals an additional limitation of the small CZ reference. Calibration-in-the-large is broadly centered near zero, but fold-taxon calibration slopes are too variable for a simple mean to be trusted. The next implementation chunk must define robust aggregation, paired deltas, coverage reporting, and uncertainty rather than interpreting these raw slope coefficients in isolation.
