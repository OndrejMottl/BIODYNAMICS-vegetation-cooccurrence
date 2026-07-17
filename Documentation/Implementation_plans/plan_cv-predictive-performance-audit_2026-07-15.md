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
- [x] Require AUC uncertainty to support performance above `0.5` and require most
  evaluable taxa to have positive discrimination.
- [x] Compare prevalence, intercept-only, abiotic-only, spatial-only, and full
  model baselines using identical folds.
- [x] Diagnose taxa with sparse classes, constant training responses, unstable
  calibration, or consistently negative discrimination.
- [x] Classify the result independently as `technical_cv_status` and
  `scientific_prediction_status`.

**Validation:**

- Use paired fold/repeat comparisons against every baseline.
- Record uncertainty, evaluable-taxon counts, and the decision rule with the
  result.
- Do not declare scientific success from a community mean alone.

**Phase checkpoint:** The no-refit GPU taxon audit passes the technical CV and
AUC/majority-positive guardrails, but fails the provisional scientific Tjur
gate. Fold-macro AUC is approximately `0.661` with all three repeat estimates
above `0.5`; 116 of 159 evaluable fold-taxon Tjur estimates are positive.
Nevertheless, mean Tjur remains approximately `0.053`, only Carpinus and Fagus
exceed `0.1` on average, and Pinus, Alnus, and Picea have no evaluable model
discrimination estimates. Details are recorded in
`cz_paleo_taxon_eligibility_diagnostic_v1.md`. The component-baseline comparison
is the next unresolved diagnostic.

**Component checkpoint:** The isolated GPU comparison completed all 45 reduced
model fits successfully on the reference folds. Intercept-only, spatial-only,
abiotic-only, and full-model fold-macro Tjur R2 values are `0`, `0.0251`,
`0.0308`, and `0.0526`, respectively. The full model improves AUC, Tjur R2, log
loss, and Brier score over both reduced predictor models in every repeat. Both
predictor blocks therefore contain complementary signal, but their combination
still fails the working `0.1` Tjur gate. Details are recorded in
`cz_paleo_predictor_component_diagnostic_v1.md`.

### Phase 5 - Targeted improvement experiments

**Goal:** Improve predictive performance only if the corrected evaluation fails
the scientific gate.

**Tasks:**

- [x] Define a first-pass coordinate search with one reference plus separate
  covariance, abiotic-coefficient, and spatial-coefficient axes.
- [x] Test a wider lambda range such as `0`, `0.01`, `0.03`, `0.1`, `0.3`, and
  `1` using a sequential or structured search rather than all 216 combinations.
- [x] Diagnose covariance, coefficient, and spatial regularization separately.
- [x] Retain negative log likelihood as the primary proper scoring rule while
  enforcing minimum discrimination and calibration guardrails.
- [x] Test whether sparse taxa should be excluded by a prespecified prevalence
  or fold-evaluability rule.
- [x] If CZ remains too unstable, choose a somewhat larger local model as the
  scientific reference while retaining CZ as an engineering stress test.

**Validation:**

- Run all candidates on identical deterministic folds and GPU backend.
- Require improvement across repeats and taxa, not only the selected mean.
- Confirm the winner is not on the search boundary before calling it optimal.
- Run focused tests, the full suite, fresh affected pipelines, and review.

**Search-design checkpoint:** The deterministic first pass contains 16
candidates: the current `(0.1, 0.1, 0.1)` reference and five alternatives along
each lambda axis. It records the varied axis and explicit lower/upper boundary
flags while preserving the seven-column production candidate schema. This
reduces the first GPU experiment from 216 to 16 candidates; combined axis values
will be tested only after the first-pass response surface is observed. The
generator passed 14 focused assertions, the full suite passed 3,445 assertions
with the single opt-in integration skip, and the mandatory fresh CZ gate ended
with exit code 0 and zero target errors in all three stores.

**First-pass result:** The isolated GPU search completed all 240 candidate fits
and 15 independent selected-candidate refits. Covariance lambda `0.01` minimized
mean tuning NLL, but improved it by only `0.001214` per response relative to the
`0.1` reference and was worse in one of three repeats. Its independent refit was
worse than the original reference on AUC, Tjur R2, log loss, and Brier score;
mean Tjur R2 fell from `0.0526` to `0.0408`. The selected value is not a search
boundary, but it fails the repeat-stability and scientific guardrails and must
not replace the reference. Details are recorded in
`cz_paleo_structured_regularization_diagnostic_v1.md`. The implementation
passed 15 focused assertions and the full suite with 3,460 passes and one
expected integration skip. The mandatory fresh CZ gate completed with exit
code 0; direct metadata checks found zero target errors in all three rebuilt
stores and the isolated structured-search store.

**Guardrail checkpoint:** Candidate acceptance now requires NLL improvement in
every tuning repeat, AUC non-inferiority, independent-refit non-inferiority, and
mean Tjur R2 of at least `0.1`. The declared taxon sensitivity retains nine of
16 taxa using prevalence `[0.05, 0.95]` and at least 80% evaluable folds. The
reference Tjur R2 rises from `0.0526` to only `0.0686` in that subset, while the
regularization winner reaches `0.0532` and remains worse than the reference.
The candidate is rejected under both scopes. Details are recorded in
`cz_paleo_selection_guardrail_diagnostic_v1.md`. The implementation passed 37
focused assertions and the full suite with 3,482 passes and one expected
integration skip. The mandatory fresh CZ gate completed with exit code 0;
direct metadata checks found zero errors in every rebuilt and diagnostic store.

**Scientific-reference selection checkpoint:** `eu_r005_l010` is selected as
the larger paleo local scientific reference. It contains 878 aligned samples,
41 locations, and 20 genus responses. Under fresh deterministic 3 x 5 spatial
folds, 85% of taxon-fold combinations are evaluable and 16 of 20 taxa are
evaluable in at least 80% of folds. This passes the pre-fit threshold while
remaining substantially cheaper than `eu_r005_l006` (1,840 samples and 28
taxa). CZ remains the small-sample engineering stress test. An isolated GPU
pipeline now fixes regularization at `(0.1, 0.1, 0.1)` before fitting so the
benchmark does not select and assess hyperparameters on the same folds.
The harness passed 11 focused assertions and the full suite with 3,493 passes
and one expected integration skip. A pre-fit build produced all 123 assignment
rows for 41 locations across three repeats and five folds. The mandatory fresh
Czechia gates finished with zero target errors in both paleo stores and the
modern store; the clean modern rebuild completed 2,152 targets.

**Scientific-reference result:** The fresh `eu_r005_l010` GPU benchmark
completed all 15 fixed-candidate fold fits successfully. Mean fold-macro Tjur
R2 is `0.168` (repeat estimates `0.169`, `0.167`, and `0.168`) and mean AUC is
`0.798`. All repeats improve on the prevalence null for Tjur R2, AUC, log loss,
and Brier score. Fourteen prespecified eligible taxa produce mean Tjur R2
`0.208` and AUC `0.824`; 18 of 19 evaluable taxa have positive mean Tjur R2.
The larger reference therefore passes the provisional `0.1` discrimination
gate and supports a scientific-performance pass, while CZ remains a valid
engineering stress test rather than the scientific benchmark. Calibration
remains a caution: the all-taxa mean intercept is `0.265` and slope is `2.76`.
The execution and artifact hashes are recorded in
`paleo_local_cv_scientific_reference_v1.md`.
The final harness passed 13 focused assertions and the full suite with 3,495
passes and one expected integration skip. The mandatory fresh Czechia gate
completed with exit code 0, and direct metadata checks found zero errors in all
three rebuilt stores.

### Phase 6 - Cross-validated predictive decomposition

**Goal:** Test whether abiotic, spatial, and residual species-association
components make repeatable contributions to prediction at unseen locations in
the `eu_r005_l010` scientific reference.

**Tasks:**

- [ ] Reuse the scientific reference's identical deterministic three-repeat,
  five-fold spatial assignments and fixed external regularization.
- [ ] Fit full, no-abiotic, no-spatial, and no-associations variants with
  fold-local preprocessing and held-out MEM interpolation preserved.
- [ ] Report raw held-out changes in log loss and Brier score as the primary
  component evidence, with Tjur R2 and AUC changes as discrimination
  diagnostics.
- [ ] Summarize uncertainty and evaluability across repeats, folds, taxa, and
  the prespecified eligible-taxon subset.
- [ ] Report normalized positive-loss shares only as a secondary predictive
  summary and never as percentages of ecological variance explained.
- [ ] Compare the predictive removal results with the full-data sjSDM ANOVA
  fractions, explicitly documenting agreement, disagreement, shared signal,
  and non-causal interpretation.
- [ ] Record a versioned report and artifact provenance for the scientific
  reference decomposition.

**Validation:**

- Require every model variant to use the same training and test rows within a
  fold and preserve deterministic seeds and GPU provenance.
- Confirm that the full-model metrics reproduce the scientific reference
  within declared numerical tolerance.
- Preserve negative component deltas before any secondary clamping and report
  undefined shares rather than forcing a decomposition.
- Run focused decomposition-contract tests, the full suite, the isolated GPU
  reference pipeline, and the mandatory change-review workflow.

**Phase status:** In progress. The first implementation slice adds an explicit
no-associations fitting contract and an isolated 18-target GPU pipeline that
reuses the scientific reference's assignments, fixed candidate, eligibility
table, and full-model fold metrics. The three reduced variants and final
predictive summaries have not yet been executed; raw component-effect
summaries remain the next implementation slice.

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
