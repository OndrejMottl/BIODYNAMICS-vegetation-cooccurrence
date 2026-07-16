# Plan: Audit and improve CV predictive performance

**Date:** 2026-07-15
**Author:** Codex
**Status:** In progress
**Related issues:** #139 correctness audit; #138 CV strategy and performance

---

## Goal

Determine whether the very small Czechia paleo out-of-fold Tjur R2 reflects a
genuinely weak model, an inappropriate cross-fold aggregation estimand, or both.
The work will first correct and expand evaluation using existing OOF artifacts,
then establish an explicit scientific performance gate, and only then spend GPU
time on retuning or model changes.

## Current evidence

- The dedicated reference has 27 locations, 205 samples, and 15 response taxa.
- Mean pooled OOF Tjur R2 is approximately `0.029`; median taxon values are near
  zero and only 6-8 of 13 evaluable taxa are positive per repeat.
- Pooled OOF AUC is approximately `0.482`, but tuning fold-macro AUC is
  approximately `0.656`.
- The fold-training-prevalence null has negative pooled Tjur R2 and AUC between
  approximately `0.25` and `0.29`. Within an evaluable fold, a constant null must
  instead have Tjur R2 `0` and AUC `0.5`.
- The selected candidate improves OOF log loss over the null by approximately
  5.7%, but wins at the upper boundary of all three lambda grids.
- Future CV and final-model fits now use the GPU backend.

## Decision principles

1. Do not use fitted McFadden or Nagelkerke R2 as evidence of held-out
   predictive validity.
2. Preserve pooled v1 evaluation for historical compatibility, but do not treat
   it as the sole scientific estimand.
3. Evaluate fold-local predictions before combining results from separately
   fitted fold models.
4. Use proper scoring rules for primary selection, with discrimination and
   calibration guardrails.
5. Do not retune until the evaluation estimand and acceptance criteria are
   explicit.

## Scope

### In scope

- Fold-local model and prevalence-null metrics by repeat, fold, and taxon.
- Fold-macro and observation-weighted summaries with uncertainty.
- Tjur R2, AUC, log loss, Brier score, calibration intercept, and calibration
  slope where estimable.
- Taxon/fold prevalence and evaluability diagnostics.
- Simple predictive baselines and component-ablation models.
- A wider, efficient regularization search if the corrected evaluation remains
  weak.
- A documented predictive-performance decision for the CZ reference.

### Out of scope

- Treating the small CZ dataset as proof of continental model performance.
- Selecting a model from fitted-data R2.
- Silently replacing historical v1 reference values.
- Running a full Cartesian hyperparameter grid before a targeted search design
  is approved.
- Broad CV architectural simplification before the estimand decision owned by
  #138 is resolved.

## Implementation phases

### Phase 1 - Fold-local evaluation contract

**Goal:** Measure model and null performance within each independently fitted
fold without changing the existing pooled evaluator.

**Tasks:**

- [x] Add a separate fold-local evaluator returning one row per repeat, fold,
  taxon, prediction source, and metric.
- [x] Evaluate model and fold-training-prevalence-null predictions independently
  so an unavailable model prediction does not suppress a valid null diagnostic.
- [x] Preserve explicit statuses for incomplete predictions and one-class folds.
- [x] Prove that an evaluable constant null produces fold-local Tjur R2 `0` and
  AUC `0.5`.
- [x] Apply the evaluator to the existing CZ reference OOF artifact and record
  the first pooled-versus-fold-local comparison.

**Validation:**

- Run the focused fold-local evaluator tests through a red-green TDD cycle.
- Run the existing pooled-evaluator tests unchanged.
- Verify unique repeat/fold/row/taxon keys and valid probability bounds.
- Run the full test suite because the new evaluator shares core metric helpers.
- Run the mandatory CZ gate if shared pipeline behavior is changed; a standalone
  helper with no pipeline integration requires the focused and full suites only.

**Phase status:** Complete on 2026-07-15. Focused fold-local and pooled-evaluator
tests pass, the existing OOF artifact was evaluated without refitting, and the
full regression suite reports zero failures.

### Phase 2 - Aggregation, calibration, and uncertainty

**Goal:** Produce scientifically interpretable community summaries and quantify
their stability.

**Tasks:**

- [x] Add fold-macro and observation-weighted aggregation without pooling raw
  probabilities across fold models.
- [x] Add Brier score and calibration intercept/slope with explicit undefined
  statuses for one-class or degenerate groups.
- [x] Add repeat-level distributions and intervals rather than reporting only
  point means.
- [x] Report taxon coverage, fold coverage, prevalence, and class counts beside
  every community metric.
- [x] Define paired model-minus-null deltas for discrimination and
  null-minus-model deltas for loss metrics.

**Validation:**

- Use hand-checkable synthetic folds with unequal sizes and prevalence.
- Test macro versus observation-weighted summaries separately.
- Test degenerate calibration and one-class status contracts.
- Run focused tests and the full suite.

**Phase status:** Complete on 2026-07-15. Fold-macro and
observation-weighted summaries, paired improvements, coverage, calibration,
and descriptive repeat intervals are implemented and applied to the CZ
reference. The corrected evaluation consistently beats the prevalence null,
but observed repeat Tjur R2 remains below the provisional `0.1` gate.

### Phase 3 - Pipeline integration and versioned evidence

**Goal:** Publish fold-local evaluation as a new artifact without silently
changing the v1 pooled contract.

**Tasks:**

- [x] Add a separately named target for fold-local evaluation to direct and
  shared CV pipe segments.
- [x] Record the evaluation estimand, aggregation method, source, device, and
  schema in provenance.
- [x] Update the correctness contract and create a versioned diagnostic report.
- [x] Re-run the isolated CZ paleo reference on GPU and compare CPU/GPU results
  without overwriting the historical execution record.

**Validation:**

- Check affected target manifests and public target names.
- Run focused pipeline-contract tests, the full suite, and a fresh isolated CZ
  reference run.
- Confirm all fold fits, OOF keys, artifacts, hashes, and target errors.
- Run the mandatory change-review workflow before staging.

### Phase 4 - Scientific performance decision

**Goal:** Decide whether the current CZ model passes a predeclared predictive
standard and locate the source of any failure.

**Tasks:**

- [ ] Agree on a prospective Tjur R2 threshold; treat `0.1` as the provisional
  user-specified minimum until formally confirmed.
- [ ] Require AUC uncertainty to support performance above `0.5` and require most
  evaluable taxa to have positive discrimination.
- [ ] Compare prevalence, intercept-only, abiotic-only, spatial-only, and full
  model baselines using identical folds.
- [ ] Diagnose taxa with sparse classes, constant training responses, unstable
  calibration, or consistently negative discrimination.
- [ ] Classify the result independently as `technical_cv_status` and
  `scientific_prediction_status`.

**Validation:**

- Use paired fold/repeat comparisons against every baseline.
- Record uncertainty, evaluable-taxon counts, and the decision rule with the
  result.
- Do not declare scientific success from a community mean alone.

### Phase 5 - Targeted improvement experiments

**Goal:** Improve predictive performance only if the corrected evaluation fails
the scientific gate.

**Tasks:**

- [ ] Test a wider lambda range such as `0`, `0.01`, `0.03`, `0.1`, `0.3`, and
  `1` using a sequential or structured search rather than all 216 combinations.
- [ ] Diagnose covariance, coefficient, and spatial regularization separately.
- [ ] Retain negative log likelihood as the primary proper scoring rule while
  enforcing minimum discrimination and calibration guardrails.
- [ ] Test whether sparse taxa should be excluded by a prespecified prevalence
  or fold-evaluability rule.
- [ ] If CZ remains too unstable, choose a somewhat larger local model as the
  scientific reference while retaining CZ as an engineering stress test.

**Validation:**

- Run all candidates on identical deterministic folds and GPU backend.
- Require improvement across repeats and taxa, not only the selected mean.
- Confirm the winner is not on the search boundary before calling it optimal.
- Run focused tests, the full suite, fresh affected pipelines, and review.

## Risks and mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Fold-level groups contain one response class | High | Preserve explicit undefined statuses and report evaluability rather than imputing metrics. |
| Macro summaries are dominated by tiny folds | Medium | Report macro and observation-weighted estimates together with counts. |
| A post-hoc threshold overstates certainty | Medium | Declare the gate before new fitting and show continuous estimates with uncertainty. |
| Wider tuning overfits the small reference | High | Use nested or clearly separated selection/evaluation logic and deterministic repeats. |
| GPU rerun is mistaken for a remedy | Medium | Complete the no-refit OOF audit first; treat device parity separately from model quality. |
| New artifacts break the v1 contract | Medium | Add separately named versioned outputs and retain the pooled evaluator unchanged. |

## Immediate execution checkpoint

Phase 1 begins with a standalone fold-local evaluator and synthetic contract tests.
The first checkpoint is complete when the existing CZ OOF predictions demonstrate
whether fold-local null metrics return their theoretical baselines and how much the
model's fold-local Tjur R2 differs from the pooled `0.029` value.

**Checkpoint result:** Completed on 2026-07-15. The fold-local null returns Tjur
R2 `0` and AUC `0.5`. Model fold-local AUC is approximately `0.646`, while Tjur
R2 is approximately `0.053`. Pooling materially distorted both null and model
metrics, but corrected Tjur R2 remains below the provisional `0.1` gate. Details
are recorded in `cz_paleo_fold_local_diagnostic_v1.md`.
