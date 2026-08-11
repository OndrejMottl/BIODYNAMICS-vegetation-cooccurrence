# Scalable shared MEM native paired fixture (preliminary v1)

**Date:** 2026-07-24 **Issue:** #143 **Status:** Downstream gate passed; branch `auto` candidate is under validation

## Purpose

This fixture tests whether the shared Nyström MEM path preserves downstream held-out sjSDM behavior, rather than relying only on basis similarity. Exact and fast runs used identical:

- 2,500 synthetic projected locations;
- six binary taxa generated from spatial and abiotic gradients;
- three distinct five-fold spatial assignments;
- 2,000 training and 500 held-out locations per fold;
- fold-local response filtering and predictor scaling;
- regularization candidate, sjSDM settings, and fit seeds;
- shared prediction and fold-local evaluation functions.

The fixture executed 30 native sjSDM fits: 15 exact and 15 fast. Five public MEM columns were retained from each basis. The fast construction requested 30 Nyström eigenpairs, and every fast fold reported the real package fast path.

## Predictive results

Metrics are fold-macro summaries from the existing shared CV evaluation stack. No predictions from separately fitted folds were pooled before scoring.

| Repeat | Strategy | Log loss | AUC | Tjur R2 | Coverage |
|---:|---|---:|---:|---:|---:|
| 1 | Exact | 0.6202524 | 0.7339728 | 0.1108094 | 1.00 |
| 1 | Fast | 0.6195793 | 0.7326447 | 0.1177241 | 1.00 |
| 2 | Exact | 0.6214467 | 0.7324472 | 0.1091222 | 1.00 |
| 2 | Fast | 0.6209201 | 0.7307707 | 0.1153868 | 1.00 |
| 3 | Exact | 0.6210357 | 0.7327019 | 0.1109726 | 1.00 |
| 3 | Fast | 0.6202050 | 0.7331490 | 0.1186732 | 1.00 |

The gate evaluates the worst paired regression across repetitions:

| Gate | Observed worst regression | Allowed | Result |
|---|---:|---:|---|
| Mean log loss | -0.0005265 | 0.005 | Pass |
| AUC | 0.0016765 | 0.010 | Pass |
| Tjur R2 | -0.0062645 | 0.010 | Pass |
| Evaluable-taxon coverage | 0.0000000 | 0.020 | Pass |

Negative regression means that the fast path performed better. Log loss and Tjur R2 improved in every repeat. The small AUC reduction remained well inside the approved Issue 138 allowance.

## Technical results

- All 30 fold fits completed with status `ok`.
- Exact and fast runs used the same assignment hash.
- Prediction artifact schemas had the same hash.
- All 18,000 held-out taxon probabilities were finite and evaluable.
- Every fold used a training-only basis and the matching held-out projection.
- The instrumented full paired run completed in 180.91 seconds on CPU.
- No GPU was used, so the result did not compete for GPU memory with another R session.

## Runtime and basis evidence

The runner records preparation, MEM construction, fitting, and prediction separately for each fold. Times below are sums across 15 folds per strategy. MEM time is a measured component of preparation time and is not added again in the combined stage total.

| Measure | Exact | Fast |
|---|---:|---:|
| Preparation | 66.97 s | 1.04 s |
| MEM construction | 65.31 s | 0.18 s |
| sjSDM fitting | 54.41 s | 52.39 s |
| Held-out prediction | 0.11 s | 0.07 s |
| Preparation + fitting + prediction | 121.49 s | 53.50 s |
| Median retained basis object | 225,600 bytes | 913,568 bytes |
| Estimated dense matrix per fold | 32,000,000 bytes | avoided |

Fast MEM reduced measured fold preparation by 98.45% and the combined measured stages by 55.96%. Model fitting time was similar, which is expected because the same responses, candidate, retained five-column spatial input, and fitting budget were used. The larger retained fast basis is explicit projection state; it remained below one megabyte with 30 Nyström eigenpairs.

These figures isolate the bottleneck more clearly than whole-run wall time: almost all exact preparation time was MEM construction, while fitting became the dominant cost after the fast basis was enabled.

The focused benchmark runner, summarizer, and assessor tests pass with 17 assertions and no warnings or skips.

## Interpretation and limits

This is direct downstream evidence that the low-rank basis can replace the dense basis without a meaningful predictive regression under controlled paired assignments. It is stronger than the earlier structural comparison, but it is still a synthetic fixture with six taxa, one candidate, five retained MEM columns, and a reduced iteration budget.

It authorizes enabling `auto` on the Issue 143 branch to perform the final acceptance run; it does not yet authorize merging that setting into production. The remaining step is a clean representative modern continental run using the same shared implementation, with per-stage runtime, RAM/VRAM, storage, leakage, staged-fit, and cached-OOF evidence. No continent-specific method or threshold should be introduced for that run.

## Decision

The Phase 3 downstream predictive gate passes. The common `auto` rule is now enabled on the Issue 143 branch for isolated continental repetition 143. Do not merge the production switch until that validation is clean. After it passes, return to the remaining Issue 138 staged-CV benchmark work.

## Method reference

The candidate basis and held-out projection use the package-backed [`spmoran` 0.3.3 APIs](https://cran.r-project.org/web/packages/spmoran/spmoran.pdf).
