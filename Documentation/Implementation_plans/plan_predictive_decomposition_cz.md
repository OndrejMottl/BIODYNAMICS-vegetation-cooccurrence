# CZ Pilot Plan: Stable Predictive Decomposition

## 1. Objective

Build and test a stable decomposition workflow for the CZ paleo project using block ablation and out-of-sample predictive performance, then compare it against the current ANOVA-based decomposition.

Primary goal:

- Produce sensible, finite, uncertainty-aware shares for Abiotic, Spatial, and Associations.

Pilot scope:

- CZ project only.
- Start with genus resolution in the existing CZ resolution test store.
- Expand to family and functional type only after genus pilot passes quality checks.

---

## 2. Why this pilot is needed

Current ANOVA decomposition can produce extreme negative raw fractions, which are then clamped and normalized. This can create visually stable but potentially misleading percentages.

Pilot hypothesis:

- Out-of-sample block ablation on predictive metrics will yield more robust decomposition than current internal ANOVA partitioning.

---

## 3. Decomposition definition for the pilot

For each fitted full model, define three reduced variants:

- no_abiotic
- no_spatial
- no_associations

Evaluate all variants on held-out folds using the same metric.

Suggested primary metric:

- log loss or deviance-like loss

Secondary metric:

- AUC

Contribution deltas (higher means more contribution):

- delta_abiotic = loss_no_abiotic - loss_full
- delta_spatial = loss_no_spatial - loss_full
- delta_associations = loss_no_associations - loss_full

Convert to shares:

- clamp negative deltas to 0
- share_k = delta_k / sum(delta_all) * 100
- if sum(delta_all) = 0, mark decomposition as undefined for that fold

Aggregate across folds/repeats:

- median share
- lwr_95 and upr_95

---

## 4. Pilot data and execution scope

Base data and store:

- Use CZ paleo resolution test pipeline outputs in Data/targets/cz_paleo/pipeline_paleo_resolution_test.

Pilot sequence:

1. Genus only
2. If genus passes acceptance criteria, repeat for family
3. If family passes, repeat for functional type

---

## 5. Implementation phases

## Phase A: Analysis specification and helper functions

Deliverables:

- New helper functions for:
  - building reduced model variants from the same input data
  - running repeated fold evaluation
  - computing block deltas and normalized shares
  - summarizing decomposition across repeats

Proposed function responsibilities:

- fit_predictive_ablation_models(): fit full and three reduced models
- evaluate_predictive_ablation(): evaluate performance on held-out folds
- compute_predictive_decomposition_shares(): convert deltas to shares
- summarise_predictive_decomposition(): median and interval summary

Quality checks in functions:

- all required model variants exist
- no NA metric values in fold summaries
- fold-level decomposition sum close to 100 when defined
- explicit undefined flag when all deltas are non-positive

## Phase B: CZ pilot script

Deliverables:

- One standalone pilot script in the age-scaling diagnostic folder that:
  - reads CZ genus model input
  - runs repeated fold ablation decomposition
  - writes fold-level and summary CSV outputs
  - compares new summary vs existing ANOVA summary side-by-side

Outputs:

- Documentation/Reports/Diagnostics/age_scalling/cz_predictive_pilot/cz_predictive_decomposition_genus_folds.csv
- Documentation/Reports/Diagnostics/age_scalling/cz_predictive_pilot/cz_predictive_decomposition_genus_summary.csv
- Documentation/Reports/Diagnostics/age_scalling/cz_predictive_pilot/cz_predictive_decomposition_vs_anova_genus.csv

## Phase C: Visualization check for interpretability

Deliverables:

- One quick figure from summary output:
  - component shares with uncertainty intervals
  - optional side-by-side panel with ANOVA-based shares

Output:

- Documentation/Reports/Diagnostics/age_scalling/cz_predictive_pilot/cz_predictive_decomposition_genus.png

## Phase D: Scale-up readiness decision

Decision gate after genus pilot:

- If acceptance criteria pass, run same pilot for family and functional type.
- If criteria fail, diagnose and revise (fold design, metric choice, variant definitions).

---

## 6. Fold design for CZ pilot

Recommended default:

- repeated K-fold, K = 5
- repeats = 5
- fixed seed per repeat for reproducibility

Alternative if temporal leakage is a concern:

- block folds by age bins

Pilot should start with repeated random folds for speed, then test one blocked-fold variant as sensitivity analysis.

---

## 7. Acceptance criteria for the CZ pilot

Minimum criteria:

1. No extreme numeric explosions in decomposition outputs.
2. At least 90 percent of fold-level runs return defined shares.
3. Median shares are stable across repeats (no pathological flip in dominant driver each repeat).
4. Uncertainty intervals are finite and interpretable.
5. Results can be reproduced by rerunning with same seeds.

Stretch criteria:

- Similar qualitative conclusions under both primary and secondary metric.

---

## 8. Risk register and mitigations

Risk: Reduced variants fail to converge in some folds.

- Mitigation: keep fold-level status and include failure counts; retry with simplified training budget for failed folds.

Risk: Fold-level deltas are often negative.

- Mitigation: check metric direction and variant definitions; use deviance/log loss as primary metric.

Risk: Large compute cost.

- Mitigation: CZ genus first, low iteration budget for pilot, then increase only if needed.

Risk: Not directly comparable to old ANOVA shares.

- Mitigation: provide explicit side-by-side comparison table and narrative of estimand change.

---

## 9. Proposed file-level implementation map

Likely touch points:

- R/Functions/Modelling for new ablation and decomposition helpers
- R/03_Supplementary_analyses/Testing/testthat for unit tests
- Documentation/Reports/Diagnostics/age_scalling/cz_predictive_pilot
  for pilot outputs

Possible later integration path:

- Add optional predictive decomposition target segment for CZ and then paleo spatial pipelines once validated.

---

## 10. Test plan for pilot code

Unit tests:

- delta and share calculations with controlled synthetic inputs
- undefined-share handling when all deltas <= 0
- summary quantile calculations

Integration test:

- one short CZ run that produces non-empty fold and summary files
- verify expected columns and finite values

Validation checks against current workflow:

- compare rank ordering of dominant component against ANOVA outputs
- report agreement/disagreement explicitly

---

## 11. Practical execution order

1. Implement helper functions
2. Add unit tests
3. Run CZ genus pilot script
4. Inspect fold diagnostics and summary
5. Generate comparison table and quick figure
6. Decide go or no-go for family and functional type

---

## 12. Decision output from this pilot

At the end of the CZ pilot, produce a short decision note with:

- whether predictive decomposition is numerically stable
- whether component ranking is interpretable
- whether method is ready for full spatial scale comparison
- exact changes needed before broader rollout
