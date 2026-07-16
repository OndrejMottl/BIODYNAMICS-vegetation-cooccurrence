# CZ paleo predictor-component diagnostic (v1)

**Recorded:** 2026-07-16
**Component store:**
`Data/targets/cz_paleo_cv_component_reference_gpu/`
`pipeline_cz_paleo_cv_component_reference`
**Full-model source store:**
`Data/targets/cz_paleo_cv_reference_gpu/pipeline_paleo_core`

## Purpose

This Phase 4 checkpoint tests which predictor components contribute to the low
but positive Czechia paleo cross-validated signal. It compares the prevalence
null, an sjSDM intercept-only model, abiotic-only predictors, spatial-only MEM
predictors, and the full abiotic-spatial model.

All fitted variants use the same three repeats, 15 folds, response filtering,
fit seeds, GPU backend, and fully regularized `candidate_008` selected by the
full reference. Fixing regularization isolates predictor inclusion. It does not
claim that the reduced structures are individually tuned optima. The full model
and prevalence null are read unchanged from the validated GPU reference store.

The intercept-only model retains sjSDM's biotic covariance but has no predictor
that varies among samples. It is distinct from the fold-training-prevalence
null, although both must have fold-local AUC `0.5` and Tjur R2 `0`.

## Execution evidence

The isolated pipeline completed 24 targets in 5 minutes 38 seconds. All 45 new
GPU fits succeeded: 15 intercept-only, 15 abiotic-only, and 15 spatial-only.
Every structure preserved 9,840 OOF rows, comprising 9,462 `ok` rows and 378
`constant_in_training` rows. Fit seeds were identical across structures. The
intercept-only and abiotic-only fits used zero MEMs; every spatial-only fold used
three fold-local MEMs. The target store contains zero errors.

## Fold-local performance

Values are means across the three repeat-level fold-macro estimates. Parenthetic
ranges are descriptive 2.5th to 97.5th percentiles across only three repeats,
not population confidence intervals.

| Structure | AUC | Tjur R2 | Log loss | Brier score |
|---|---:|---:|---:|---:|
| Prevalence null | 0.500 | 0.0000 | 0.328 | 0.0968 |
| Intercept-only | 0.500 | 0.0000 | 0.331 | 0.0969 |
| Spatial-only | 0.608 (0.595–0.628) | 0.0251 (0.0162–0.0379) | 0.321 | 0.0922 |
| Abiotic-only | 0.627 (0.616–0.636) | 0.0308 (0.0257–0.0340) | 0.318 | 0.0934 |
| Abiotic + spatial | 0.661 (0.643–0.680) | 0.0526 (0.0427–0.0691) | 0.308 | 0.0891 |

The intercept-only model cannot rank samples and slightly underperforms the
fold-prevalence null on proper scoring rules. Both substantive predictor blocks
beat the null independently. Abiotic-only has stronger discrimination than
spatial-only, while their proper-score ordering is mixed: abiotic-only has lower
log loss, whereas spatial-only has lower Brier score.

## Paired incremental contributions

The table reports full-model improvement over each reduced comparator. For AUC
and Tjur R2 this is full minus reduced; for log loss and Brier score it is
reduced minus full, so every positive value favors the full model. Every delta
is positive in all three repeats.

| Removed information | Comparator | AUC | Tjur R2 | Log loss | Brier score |
|---|---|---:|---:|---:|---:|
| All varying predictors | Intercept-only | 0.161 | 0.0526 | 0.0227 | 0.00775 |
| Spatial predictors | Abiotic-only | 0.0338 | 0.0218 | 0.0101 | 0.00430 |
| Abiotic predictors | Spatial-only | 0.0525 | 0.0275 | 0.0123 | 0.00311 |

The full-versus-abiotic-only Tjur improvement ranges from `0.0122` to `0.0353`
across repeats. The full-versus-spatial-only improvement ranges from `0.0225`
to `0.0314`. Abiotic predictors add slightly more discrimination and log-loss
improvement conditional on the spatial component, while spatial predictors add
slightly more Brier improvement conditional on the abiotic component. The two
blocks are complementary rather than interchangeable.

## Decision

The comparison rejects two simple explanations for the low full-model Tjur R2:

1. The abiotic block is not non-functional; it independently improves AUC, Tjur
   R2, and proper scores over the null.
2. The spatial block is not merely noise; it also improves every primary metric
   over the null and adds value to the abiotic-only model in every repeat.

The full structure is the best of the tested structures, but its Tjur R2 remains
approximately `0.053`, below the `0.1` working gate. Removing either component
would make prediction worse. The current failure is therefore a limitation of
signal magnitude, predictor adequacy, sample/class support, and possibly the
regularization boundary—not evidence that CV or one predictor path is broken.

This preserves `technical_cv_status = pass` and
`scientific_prediction_status = fail_provisional_tjur_gate`.

## Artifact hashes

| Artifact | Hash |
|---|---|
| Intercept-only fold predictions | `59a312c2f2a130df` |
| Abiotic-only fold predictions | `baae1e71bdc554d4` |
| Spatial-only fold predictions | `072627343cf16af4` |
| Intercept-only fold metrics | `a8c6b2f1a30ec016` |
| Abiotic-only fold metrics | `fb566cf5652f1757` |
| Spatial-only fold metrics | `08fd88dea7a2d61d` |

## Validation

The structure adapter, selected-fold runner, and isolated-pipeline contracts
pass 49 focused assertions. The full regression suite reports
`FAIL 0 | WARN 0 | SKIP 1 | PASS 3430`; the skip is the documented opt-in
VegVault integration test. The mandatory fresh CZ validation completed with
exit code 0 in 43 minutes 5 seconds. Direct metadata checks found zero target
errors across 514 paleo-core, 624 paleo-resolution, and 2,422 modern-resolution
metadata rows.

## Next experiment

Phase 5 should retain the full abiotic-spatial structure and test the wider
regularization range. Because `candidate_008` lies on the current upper lambda
boundary, the next search should diagnose covariance, abiotic-coefficient, and
spatial-coefficient regularization separately rather than dropping a predictor
block. Predictor enrichment or a larger local reference should follow if
regularization cannot materially improve repeat-stable Tjur R2.
