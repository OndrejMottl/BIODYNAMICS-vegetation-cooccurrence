# CZ paleo selection guardrail diagnostic v1

## Purpose

This Phase 5 diagnostic tests whether the structured-regularization winner can pass explicit stability and scientific-performance requirements. It also tests whether a declared sparse-taxon eligibility rule materially changes the CZ paleo conclusion. No models were refitted for this analysis; all comparisons use the completed GPU tuning and independent-refit artifacts.

The diagnostics are published by `pipeline_cz_paleo_cv_regularization_reference.R`. They do not alter the production `select_sjsdm_regularization()` behavior or replace the accepted reference candidate.

## Declared rules

### Candidate selection guardrails

A candidate is eligible only when all of the following hold:

1. held-out NLL per response is lower than the reference in every tuning repeat;
2. tuning AUC does not decrease by more than `0.01` in any repeat;
3. the independent refit is non-inferior in every repeat: AUC and Tjur R2 may not decrease by more than `0.01`, while log loss and Brier score may not increase;
4. the candidate's mean independent-refit fold-macro Tjur R2 is at least `0.1`.

The independent-refit check is deliberately separate from the models used to select the candidate. This prevents a shallow tuning optimum from being called an improvement when it does not reproduce.

### Taxon eligibility sensitivity

A taxon is eligible when:

- observation-weighted prevalence is between `0.05` and `0.95`, inclusive;
- model Tjur R2 is evaluable in at least 80% of the 15 repeat-fold groups.

The rule was declared before recomputing the eligible-subset metrics. It is a sensitivity analysis rather than a license to hide the complete-community result, so both scopes are retained below.

## Taxon eligibility result

Nine of 16 taxa are eligible: Abies, Carpinus, Corylus, Fagus, Fraxinus, Salix, Tilia, Ulmus, and Vaccinium.

Seven taxa are excluded:

- Alnus, Betula, Picea, and Pinus exceed the maximum prevalence and have insufficient evaluable-fold coverage;
- Juniperus is below the minimum prevalence and has insufficient coverage;
- Calluna and Quercus have insufficient coverage.

Excluding poorly covered taxa raises the original reference's mean fold-macro Tjur R2 from `0.052599` to `0.068596`, but this remains below `0.1`. Sparse and nearly constant taxa therefore explain part of the low community score, not the full scientific-performance failure.

## Guardrail result

The structured-search winner, `candidate_003`, is rejected under both the complete-community and eligible-taxa scopes.

| Scope | Candidate AUC | Reference AUC | Candidate Tjur R2 | Reference Tjur R2 | Candidate log loss | Reference log loss | Candidate Brier | Reference Brier |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| All taxa | 0.642915 | 0.660795 | 0.040832 | 0.052599 | 0.323643 | 0.308218 | 0.091349 | 0.089108 |
| Eligible taxa | 0.700331 | 0.704085 | 0.053210 | 0.068596 | 0.421424 | 0.402869 | 0.126558 | 0.122629 |

The larger eligible-subset losses are not directly comparable with the complete-community losses because the outcome prevalence and taxon mix differ. Within each scope, the candidate is worse than its matching reference.

The candidate passes only the tuning-AUC non-inferiority guardrail. It fails the other three requirements:

- tuning NLL improves in only two of three repeats;
- the independent refit deteriorates in every repeat;
- mean Tjur R2 remains below `0.1` for both all taxa (`0.040832`) and eligible taxa (`0.053210`).

## Decision

The original `(0.1, 0.1, 0.1)` regularization reference remains accepted. `candidate_003` must not replace it. A declared sparse-taxon rule improves the interpretability and AUC of the evaluated subset but does not rescue predictive separation or the regularization candidate.

This closes the CZ regularization and sparse-taxon improvement experiments. Further parameter tuning on CZ is unlikely to be scientifically useful. CZ should remain the engineering stress test, while a somewhat larger local model should be considered for the scientific CV reference.

## Reproducibility

- Eligibility target hash: `2280589a7f2d130e`
- Complete-community guardrail hash: `e3259ecebeeed539`
- Eligible-taxa guardrail hash: `40eedd186724eb0c`
- Incremental pipeline result: 20 completed, 12 skipped, exit code 0
- Final diagnostic refresh: 13 completed, 19 skipped, exit code 0
- New model fits: none

The two function tests and pipeline contract passed 37 focused assertions. The full suite passed 3,482 assertions with no failures or warnings and one expected opt-in integration skip. The mandatory fresh CZ gate completed with exit code 0 in 43 minutes 32 seconds. Direct metadata checks found zero errors in all three fresh CZ stores and the isolated regularization-diagnostic store.
