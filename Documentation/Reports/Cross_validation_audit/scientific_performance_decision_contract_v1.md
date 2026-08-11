# sjSDM scientific-performance decision contract v1

**Recorded:** 2026-07-17 **Policy version:** `sjsdm_scientific_performance_v1` **Reference unit:** `eu_r005_l010`

## Purpose

This contract separates three questions that must not be collapsed into one model-quality label:

1. Did the cross-validation workflow execute correctly?
2. Does the model show repeatable predictive skill at unseen locations?
3. Are its probabilities sufficiently calibrated for interpretation as occurrence risks?

Tjur R2 is a probability-discrimination measure in this contract. A value of `0.1` is not interpreted as 10% of ecological variance explained. It is an operational screening threshold adopted for future reference comparisons.

The threshold was formalized after the exploratory CZ and `eu_r005_l010` audits. It is therefore a versioned prospective rule for future runs, not a claim that the completed reference analysis was preregistered.

## Required scientific criteria

| Criterion | Rule | Rationale |
|---|---|---|
| All-taxa discrimination | Mean fold-macro Tjur R2 >= 0.1 | Prevents a pass based only on a filtered subset. |
| Eligible-taxa sensitivity | Mean fold-macro Tjur R2 >= 0.1 | Confirms the conclusion after the prespecified prevalence/evaluability filter. |
| Repeat AUC | Every repeat AUC > 0.5 | Requires discrimination above chance in every assignment repeat. |
| Log-loss skill | Model improves on the fold-training prevalence null in every repeat | Requires repeatable improvement under a proper scoring rule. |
| Brier skill | Model improves on the fold-training prevalence null in every repeat | Confirms probability-score improvement on a second proper score. |
| Taxon consistency | At least 80% of taxa with estimable mean Tjur R2 are positive | Prevents a community mean from hiding widespread negative discrimination. |
| Evaluable coverage | Every repeat has at least 80% evaluable Tjur fold-taxon groups | Requires enough evidence to support the community summary. |

The technical decision separately requires unique repeat/fold diagnostics with successful fits and a unique OOF prediction key for every emitted row. `constant_in_training` is an accepted explicit non-predictive status with an undefined probability; it reduces evaluability but is not a technical error. Preparation, fitting, alignment, or prediction failures do fail the technical contract.

## Status vocabulary

| Field | Values |
|---|---|
| `technical_cv_status` | `pass`, `fail` |
| `scientific_prediction_status` | `pass`, `fail_null_skill`, `fail_discrimination`, `insufficient_evidence` |
| `calibration_status` | `acceptable`, `caution`, `not_evaluable` |

A technical failure forces `scientific_prediction_status` to `insufficient_evidence`. Calibration remains diagnostic: it is reported independently and cannot silently convert demonstrated held-out skill into a failure or conceal poor calibration behind a scientific pass.

Calibration is marked `caution` when the observed repeat range for the fold-macro calibration intercept does not contain zero or the corresponding slope range does not contain one. These repeat ranges are descriptive, not formal confidence intervals.

## Reference decision

All nine required criteria pass for `eu_r005_l010`:

| Criterion | Observed | Threshold |
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

The executable result is:

- `technical_cv_status = pass`
- `scientific_prediction_status = pass`
- `calibration_status = caution`

## Implementation and provenance

The policy is declared under `project_paleo_local_cv_scientific_reference_gpu.scientific_performance` in `config.yml`. `assess_sjsdm_scientific_performance()` emits criterion-level and one-row decision artifacts in the isolated scientific-reference pipeline.

| Target | Data hash |
|---|---|
| `list_scientific_reference_performance_policy` | `c6829cc0c376ba58` |
| `list_scientific_reference_performance_assessment` | `6d70ba767d55d5c0` |
| `data_scientific_reference_performance_criteria` | `ad00fab32fcdb3d0` |
| `data_scientific_reference_performance_decision` | `b85a1b2e4eb42af5` |

The policy integration run completed with zero target errors. The prediction artifact retained hash `58dfb9ed9d89f853`, confirming that the deterministic GPU reference evidence reproduced exactly.
