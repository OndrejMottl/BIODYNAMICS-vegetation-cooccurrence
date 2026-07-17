# Paleo local CV scientific reference v1

**Recorded:** 2026-07-16
**Unit:** `eu_r005_l010`
**Taxonomic resolution:** genus
**Backend:** GPU
**CV design:** three repeats of five spatially stratified folds

## Decision

The larger European paleo local reference passes the versioned
`sjsdm_scientific_performance_v1` decision contract. Mean fold-macro Tjur R2 is
`0.168`, and all three repeat estimates exceed the operational threshold of
`0.1`. Mean AUC is `0.798`, and the model improves over the
fold-training-prevalence null for every primary metric in every repeat.

This changes the interpretation of the Czechia result. The low Czechia Tjur R2
does not show that the model class or CV implementation is generally unusable.
It shows that the small Czechia unit is a difficult, sparse engineering stress
test. `eu_r005_l010` is now the scientific local reference.

The scientific pass does not imply perfect probability calibration. Calibration
intercept and slope remain a documented caution and should be addressed before
probabilities are interpreted as fully calibrated occurrence risks.

## Execution contract

| Item | Recorded value |
|---|---|
| Aligned samples | 878 |
| Locations | 41 |
| Response taxa | 20 |
| Assignment rows | 123 |
| Repeats x folds | 3 x 5 |
| Successful fold fits | 15 / 15 |
| Fitting device | `gpu` |
| Iterations / posterior samples | 500 / 200 |
| Effective MEM axes | 3 in every fold |
| Retained taxa | 20 in 12 folds; 19 in 3 folds |
| Regularization source | `fixed_external_reference` |
| Alpha `(cov, coef, spatial)` | `(0.5, 0.5, 0.5)` |
| Lambda `(cov, coef, spatial)` | `(0.1, 0.1, 0.1)` |
| Pipeline completion | 30 targets, 0 errors |
| Latest deterministic GPU rebuild | approximately 1 minute 45 seconds |

Regularization was fixed before the benchmark. The run therefore did not tune
and evaluate hyperparameters on the same folds.

## Formal decision criteria

The versioned policy was formalized after the exploratory audit and is
prospective for future reference runs. It is not presented as preregistration
of this completed benchmark. All nine required criteria pass:

| Criterion | Observed | Required |
|---|---:|---:|
| Successful fold-fit contract | 1 | 1 |
| OOF prediction/status contract | 1 | 1 |
| All-taxa mean Tjur R2 | 0.168 | >= 0.1 |
| Eligible-taxa mean Tjur R2 | 0.208 | >= 0.1 |
| Minimum repeat AUC | 0.777 | > 0.5 |
| Minimum repeat log-loss improvement | 0.0826 | > 0 |
| Minimum repeat Brier improvement | 0.0336 | > 0 |
| Positive-taxon fraction | 0.947 | >= 0.8 |
| Minimum repeat Tjur evaluability | 0.840 | >= 0.8 |

The 498 `constant_in_training` prediction rows are accepted explicit
evaluability outcomes with undefined probabilities, not technical errors.
Full policy semantics are recorded in
`scientific_performance_decision_contract_v1.md`.

## All-taxa performance

Values are means across the three repeat-level fold-macro summaries. The
interval is the descriptive repeat interval emitted by the v2 summary contract;
with only three repeats it is not a formal population confidence interval.

| Metric | Mean | Repeat interval | Fold-taxon coverage |
|---|---:|---:|---:|
| Tjur R2 | 0.168 | 0.167-0.169 | 85.0% |
| AUC | 0.798 | 0.779-0.811 | 85.0% |
| Log loss | 0.285 | 0.281-0.288 | 99.0% |
| Brier score | 0.0837 | 0.0830-0.0844 | 99.0% |
| Calibration intercept | 0.265 | 0.249-0.291 | 85.0% |
| Calibration slope | 2.76 | 1.65-3.46 | 80.3% |

Tjur R2 is exceptionally stable across assignment repeats: `0.169`, `0.167`,
and `0.168`. AUC estimates are `0.777`, `0.812`, and `0.805`.

## Improvement over the prevalence null

Positive values favor the model. AUC and Tjur R2 use model minus null; log loss
and Brier score use null minus model.

| Metric | Mean improvement | Repeat interval | Positive repeats |
|---|---:|---:|---:|
| Tjur R2 | 0.168 | 0.167-0.169 | 3 / 3 |
| AUC | 0.298 | 0.279-0.311 | 3 / 3 |
| Log loss | 0.0844 | 0.0826-0.0868 | 3 / 3 |
| Brier score | 0.0342 | 0.0336-0.0349 | 3 / 3 |

The result is not a threshold-only pass: proper scoring rules improve in every
repeat as well as discrimination metrics.

## Prespecified eligible-taxon sensitivity

Eligibility requires prevalence in `[0.05, 0.95]` and at least 80% evaluable
folds. Fourteen of 20 taxa pass: Abies, Alnus, Betula, Corylus, Ericaceae,
Fagus, Fraxinus, Juniperus, Larix, Picea, Quercus, Salix, Tilia, and Ulmus.

| Metric | Eligible-taxon mean | Repeat interval | Fold-taxon coverage |
|---|---:|---:|---:|
| Tjur R2 | 0.208 | 0.205-0.209 | 98.1% |
| AUC | 0.824 | 0.818-0.831 | 98.1% |
| Log loss | 0.377 | 0.372-0.380 | 100% |
| Brier score | 0.114 | 0.113-0.115 | 100% |
| Calibration intercept | -0.0564 | -0.0798 to -0.0141 | 98.1% |
| Calibration slope | 2.01 | 1.79-2.21 | 92.4% |

Nineteen taxa have an estimable mean Tjur R2, 18 are positive, and nine reach
at least `0.1`. Pinus is present in 99.8% of observations and has no evaluable
discrimination fold. Five other taxa fail the prespecified eligibility rule
because of low prevalence and/or insufficient evaluable folds.

## Comparison with the Czechia engineering reference

| Metric | Czechia GPU | Larger local GPU | Interpretation |
|---|---:|---:|---|
| Tjur R2 | 0.0526 | 0.168 | Approximately 3.2 times larger |
| AUC | 0.6608 | 0.798 | Stronger discrimination |
| Evaluable Tjur/AUC fold-taxa | 66.2% | 85.0% | Less sparse evaluation |
| Eligible-taxon Tjur R2 | 0.0686 | 0.208 | Approximately 3.0 times larger |
| Log-loss improvement over null | 0.0200 | 0.0844 | Larger proper-score gain |
| Brier improvement over null | 0.00768 | 0.0342 | Larger probability-score gain |

The comparison supports the predeclared role split: Czechia remains useful for
testing sparse-class behavior, while the larger local unit is sufficiently
stable for scientific predictive-performance decisions.

## Calibration caveat

The all-taxa calibration intercept of `0.265` indicates average
calibration-in-the-large bias among evaluable fold-taxon groups. The slope of
`2.76` indicates probabilities are generally not separated enough on the logit
scale. Restricting to eligible taxa brings the intercept near zero but leaves a
slope of `2.01`.

Calibration therefore does not invalidate the discrimination and proper-score
pass, but the fitted probabilities should not yet be described as perfectly
calibrated. Future work should test calibration on more units and consider
cross-fitted recalibration only if absolute probability estimates are a primary
scientific output.

## Artifact provenance

Store:
`Data/targets/paleo_local_cv_scientific_reference_gpu/pipeline_paleo_local_cv_scientific_reference`

| Target | Data hash |
|---|---|
| `list_scientific_reference_fold_predictions` | `58dfb9ed9d89f853` |
| `data_scientific_reference_fold_metrics` | `ef138f699ca2979d` |
| `data_scientific_reference_taxon_eligibility` | `c7a377d94328b17b` |
| `list_scientific_reference_repeat_distributions` | `b8c466adc62bb503` |
| `list_scientific_reference_eligible_repeat_distributions` | `5605298663da9126` |
| `list_scientific_reference_performance_policy` | `c6829cc0c376ba58` |
| `data_scientific_reference_performance_criteria` | `ad00fab32fcdb3d0` |
| `data_scientific_reference_performance_decision` | `b85a1b2e4eb42af5` |

The fold-prediction artifact contains 52,680 taxon-observation rows. All 15 fit
diagnostics report `ok`, use three effective MEM axes, and record
`fixed_external_reference` regularization provenance.

## Status

- `technical_cv_status`: **pass**
- `scientific_prediction_status`: **pass under
  `sjsdm_scientific_performance_v1`**
- `calibration_status`: **caution; discrimination passes but probabilities are
  not perfectly calibrated**
- Czechia role: **engineering stress test**
- `eu_r005_l010` role: **scientific local CV reference**
