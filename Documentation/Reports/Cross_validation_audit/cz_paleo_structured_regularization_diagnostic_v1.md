# CZ paleo structured regularization diagnostic v1

## Purpose

This report tests whether the weak corrected CZ paleo cross-validation
performance can be improved by changing sjSDM regularization. It is a Phase 5
diagnostic in the predictive-performance audit. The experiment reuses the
validated three-repeat, five-fold assignments and full abiotic-spatial predictor
structure from the isolated GPU reference.

The search is deliberately structured rather than factorial. It compares the
current `(lambda_cov, lambda_coef, lambda_spatial) = (0.1, 0.1, 0.1)` reference
with five alternatives on each lambda axis: `0`, `0.01`, `0.03`, `0.3`, and
`1`. This gives 16 candidates instead of 216 combinations. All alpha values
remain `0.5`.

## Execution result

The fresh isolated GPU pipeline completed in 48 minutes 1.8 seconds. All 240
tuning fits (16 candidates x 3 repeats x 5 folds) and all 15 independent
selected-candidate refits completed with status `ok`. The selected refit
produced 9,462 `ok` prediction rows and 378 `constant_in_training` rows. The
target store contains no target errors.

The primary selection metric was pooled held-out negative log likelihood per
response. AUC was retained as a discrimination diagnostic and was not used to
select the candidate.

The pipeline contract passed 15 focused assertions. The full test suite passed
3,460 assertions with no failures or warnings and one expected opt-in
integration skip. The mandatory fresh CZ validation completed with exit code 0
in 56 minutes 37 seconds. Direct metadata checks found zero errors in the paleo
core, paleo resolution, modern resolution, and structured-regularization
stores.

## Tuning response surface

The table is ordered by mean negative log likelihood across repeats. Only one
lambda changes from the reference in each non-reference row.

| Candidate | Axis | Axis value | Lambda covariance | Lambda coefficient | Lambda spatial | Mean NLL/response | NLL SD | Mean AUC |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| `candidate_003` | covariance | 0.01 | 0.01 | 0.10 | 0.10 | 0.305712 | 0.013419 | 0.659372 |
| `candidate_004` | covariance | 0.03 | 0.03 | 0.10 | 0.10 | 0.305763 | 0.011131 | 0.656472 |
| `candidate_001` | reference | - | 0.10 | 0.10 | 0.10 | 0.306926 | 0.010568 | 0.655752 |
| `candidate_005` | covariance | 0.30 | 0.30 | 0.10 | 0.10 | 0.307085 | 0.010844 | 0.644481 |
| `candidate_014` | spatial | 0.03 | 0.10 | 0.10 | 0.03 | 0.307209 | 0.008539 | 0.659989 |
| `candidate_006` | covariance | 1.00 | 1.00 | 0.10 | 0.10 | 0.307460 | 0.010553 | 0.670206 |
| `candidate_013` | spatial | 0.01 | 0.10 | 0.10 | 0.01 | 0.309886 | 0.007052 | 0.648470 |
| `candidate_009` | coefficient | 0.03 | 0.10 | 0.03 | 0.10 | 0.309913 | 0.011002 | 0.668161 |
| `candidate_015` | spatial | 0.30 | 0.10 | 0.10 | 0.30 | 0.311414 | 0.010085 | 0.644246 |
| `candidate_016` | spatial | 1.00 | 0.10 | 0.10 | 1.00 | 0.314662 | 0.010644 | 0.635230 |
| `candidate_010` | coefficient | 0.30 | 0.10 | 0.30 | 0.10 | 0.314991 | 0.010272 | 0.655723 |
| `candidate_008` | coefficient | 0.01 | 0.10 | 0.01 | 0.10 | 0.315166 | 0.011820 | 0.670577 |
| `candidate_012` | spatial | 0.00 | 0.10 | 0.10 | 0.00 | 0.317993 | 0.008032 | 0.634229 |
| `candidate_011` | coefficient | 1.00 | 0.10 | 1.00 | 0.10 | 0.318559 | 0.009172 | 0.584325 |
| `candidate_007` | coefficient | 0.00 | 0.10 | 0.00 | 0.10 | 0.321419 | 0.014213 | 0.668379 |
| `candidate_002` | covariance | 0.00 | 0.00 | 0.10 | 0.10 | 0.322831 | 0.023536 | 0.628429 |

The selected covariance value, `0.01`, is an interior search value. The
coefficient reference value `0.1` was better on NLL than every tested
coefficient alternative. The spatial reference value `0.1` was also better
than every tested spatial alternative, although `0.03` was close.

## Repeat stability

The selected candidate's average tuning NLL improved by only `0.001214` per
response. The direction was favourable in two repeats and unfavourable in the
third.

| Repeat | Reference NLL | Selected NLL | NLL improvement | Reference AUC | Selected AUC | AUC change |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | 0.298070 | 0.295866 | 0.002204 | 0.677158 | 0.673754 | -0.003404 |
| 2 | 0.304083 | 0.300273 | 0.003811 | 0.647221 | 0.648318 | 0.001097 |
| 3 | 0.318624 | 0.320997 | -0.002372 | 0.642878 | 0.656045 | 0.013167 |

This does not satisfy the planned requirement for improvement across repeats.
The small mean difference is also much smaller than the between-repeat NLL
variation.

## Independent selected-candidate refit

The independently refitted selected candidate did not reproduce a predictive
improvement over the original GPU reference.

| Fold-macro model metric | Selected candidate | Original reference | Direction |
|---|---:|---:|---|
| AUC | 0.643 | 0.661 | worse |
| Tjur R2 | 0.0408 | 0.0526 | worse |
| Log loss | 0.324 | 0.308 | worse |
| Brier score | 0.0913 | 0.0891 | worse |

The selected candidate still improves on the prevalence null for mean log loss
(`0.324` versus `0.328`) and Brier score (`0.0913` versus `0.0968`), but its
Tjur R2 remains far below the provisional `0.1` scientific gate. GPU fitting is
not bitwise deterministic, so the independent refit is intentionally treated
as a stability check rather than as the same fitted models used during tuning.

## Decision

The structured search is an engineering success and a scientific non-success.
It establishes that:

1. zero covariance regularization is clearly harmful;
2. the tuning NLL surface is shallow around covariance lambda `0.01` to `0.3`;
3. extreme coefficient and spatial settings do not solve weak prediction;
4. the nominal NLL winner is not stable across repeats or an independent refit;
5. regularization alone does not raise corrected CZ Tjur R2 to an acceptable
   level.

`candidate_003` must therefore not replace the existing reference or be called
an optimized production setting. The next experiment should add explicit
selection guardrails and test prespecified taxon eligibility. If those do not
produce stable, scientifically adequate performance, a somewhat larger local
model should become the scientific reference while CZ remains an engineering
stress test.

That follow-up is complete and recorded in
[`cz_paleo_selection_guardrail_diagnostic_v1.md`](cz_paleo_selection_guardrail_diagnostic_v1.md).
The candidate is rejected under both the complete-community and declared
eligible-taxa scopes; taxon filtering does not change the scientific decision.

## Reproducibility

- Profile: `project_cz_paleo_cv_regularization_reference_gpu`
- Pipeline: `pipeline_cz_paleo_cv_regularization_reference.R`
- Store: `Data/targets/cz_paleo_cv_regularization_reference_gpu/pipeline_cz_paleo_cv_regularization_reference`
- Tuning candidates hash: `9f3a8711289fbafb`
- Response surface hash: `467acf3074c7be30`
- Selection diagnostic hash: `7a9d8159511472f3`
- Selected fold predictions hash: `2808f28d38fa5405`
- Selected repeat distributions hash: `674e9ad8ffcb4445`
