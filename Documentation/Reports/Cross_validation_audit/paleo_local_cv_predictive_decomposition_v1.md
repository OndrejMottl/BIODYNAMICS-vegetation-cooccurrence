# Paleo local CV predictive decomposition v1

**Recorded:** 2026-07-17 **Unit:** `eu_r005_l010` **Backend:** GPU **CV design:** three repeats of five identical spatial folds

## Decision

The matched-fold predictive decomposition supports a clear hierarchy of transferable signal. The abiotic predictor block is the dominant contributor. Residual species associations add a smaller, repeatable improvement in proper probability scores and Tjur R2. The spatial block adds a small improvement in log loss, Brier score, and Tjur R2, but does not improve AUC.

These are predictive component-removal effects, not percentages of ecological variance explained. They are conditional on the fitted model, selected predictors, fixed regularization, spatial representation, and eligible-taxon rule. They do not identify causal environmental, spatial, or biotic processes.

## Execution contract

| Item | Recorded value |
|---|---|
| Source reference | `paleo_local_cv_scientific_reference_gpu` |
| Full model | Reused without refitting |
| Reduced variants | no abiotic, no spatial, no associations |
| Reduced fits | 45 / 45 successful |
| Assignment design | identical deterministic 3 x 5 spatial folds |
| Regularization | fixed external `(0.1, 0.1, 0.1)` lambdas |
| Fitting device | GPU |
| Pipeline targets | 28 |
| Pipeline errors | 0 |
| Fresh GPU runtime | approximately 4 minutes 58 seconds |

The no-associations model retains the complete abiotic and spatial structures but restricts the biotic covariance to its diagonal. It therefore removes residual cross-taxon associations without changing the other predictor blocks.

## Raw held-out component effects

Positive values favor the full model. Tjur R2 and AUC use full minus reduced; log loss and Brier score use reduced minus full. Intervals are descriptive 2.5th and 97.5th percentiles of three repeat-level fold-macro effects.

### All evaluable taxa

| Removed component | Log loss | Brier | Tjur R2 | AUC |
|---|---:|---:|---:|---:|
| Abiotic | 0.0759 (0.0746-0.0779) | 0.0304 (0.0299-0.0311) | 0.149 (0.148-0.152) | 0.225 (0.210-0.236) |
| Associations | 0.0261 (0.0245-0.0281) | 0.00432 (0.00430-0.00436) | 0.0131 (0.0124-0.0141) | 0.00112 (-0.00936 to 0.0107) |
| Spatial | 0.00372 (0.00269-0.00430) | 0.00139 (0.000871-0.00180) | 0.00779 (0.00560-0.00910) | -0.0111 (-0.0217 to -0.000353) |

### Prespecified eligible taxa

| Removed component | Log loss | Brier | Tjur R2 | AUC |
|---|---:|---:|---:|---:|
| Abiotic | 0.107 (0.106-0.110) | 0.0431 (0.0423-0.0440) | 0.184 (0.182-0.187) | 0.238 (0.226-0.254) |
| Associations | 0.0282 (0.0257-0.0314) | 0.00606 (0.00598-0.00617) | 0.0159 (0.0151-0.0170) | 0.00330 (-0.000863 to 0.00982) |
| Spatial | 0.00532 (0.00383-0.00624) | 0.00196 (0.00125-0.00254) | 0.00958 (0.00681-0.0115) | -0.00138 (-0.00749 to 0.00258) |

The abiotic result is stable for every metric in every repeat. Association and spatial removal also worsens both proper scoring rules and Tjur R2 in every repeat. Their AUC effects are weak or negative, showing that these blocks mainly refine probability separation and probability accuracy rather than taxon ranking.

## Secondary normalized log-loss shares

Shares normalize the positive repeat-level log-loss effects to 100 percent. They are provided only as a relative predictive summary. Leave-one-component- out effects can overlap, so these values are not additive causal fractions or ecological variance percentages.

| Scope | Abiotic | Associations | Spatial |
|---|---:|---:|---:|
| All taxa | 71.8% (69.8-73.1) | 24.7% (23.0-26.3) | 3.50% (2.59-4.01) |
| Eligible taxa | 76.2% (73.8-77.6) | 20.0% (18.2-21.9) | 3.77% (2.79-4.36) |

## Evaluability

All 45 reduced fits completed successfully. For each component, 255 of 300 taxon-fold pairs are evaluable for Tjur R2 and AUC, while 297 of 300 are evaluable for log loss and Brier score. The unavailable pairs originate from the full-model reference's documented one-class or degenerate taxon-fold groups; reduced-model failures did not remove additional matched pairs.

## Comparison with full-data sjSDM ANOVA

The existing full-data genus ANOVA for `eu_r005_l010` gives Nagelkerke R2 fractions of `0.933` for abiotic, `0.541` for associations, and `0.418` for spatial structure. Its shared abiotic-association and abiotic-spatial fractions are also large (`0.905` and `0.895`), while the three-way shared fraction is strongly negative (`-6.85`).

The qualitative unique-component ordering agrees with the held-out removal experiment: abiotic is largest, associations are second, and spatial structure is smallest. The magnitudes do not agree and should not be expected to. ANOVA uses fitted-data likelihood variation from the production full-data model, whereas the predictive experiment measures loss of performance at unseen locations under fixed CV regularization. The large shared and negative ANOVA fractions further demonstrate that those fitted fractions cannot be read as stable, additive percentages of ecological variance.

## Interpretation boundary

- Abiotic dominance supports the scientific usefulness of the measured environmental predictor block, but does not establish a causal climate effect.
- The association contribution supports predictive residual dependence among taxa, but does not prove direct biotic interactions.
- The small spatial proper-score contribution may represent dispersal, unmeasured spatially structured environment, history, or other spatial dependence.
- Agreement between predictive removal and ANOVA is limited to the qualitative component ordering; predictive effects remain the primary evidence.

## Artifact provenance

Store: `Data/targets/paleo_local_cv_decomposition_reference_gpu/pipeline_paleo_local_cv_decomposition_reference`

| Target | Data hash |
|---|---|
| `data_scientific_reference_decomposition_comparisons` | `2884959953b62957` |
| `data_scientific_reference_decomposition_summary` | `f810473271f34592` |
| `data_scientific_reference_decomposition_loss_share_summary` | `a56c9d8b31c65fbc` |
| `data_scientific_reference_full_data_anova_fractions` | `a1b9d82b5e0e06a7` |

## Status

- Predictive decomposition execution: **pass**
- Matched-fold and evaluability contract: **pass**
- Abiotic contribution: **large and repeatable**
- Association contribution: **smaller; repeatable for proper scores and Tjur R2**
- Spatial contribution: **small; positive for proper scores and Tjur R2, absent for AUC**
- Full-data ANOVA comparison: **complete; qualitative ordering agrees**
