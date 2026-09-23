# Calibration near-tie and restart-safety implementation plan

## Objective

Prevent CV-budget calibration from escalating iterations merely because two practically equivalent regularization candidates exchange rank across CV repeats, and prevent a machine interruption from discarding all completed candidate-fold fits in an unfinished calibration rung.

## Behavioural changes

1. Retain the existing convergence, adjacent-rung winner, rank-correlation, and loss-change checks.
2. Confirm repeat 2 when the repeat-1 provisional winner either remains the exact winner or has repeat-2 normalized loss within 2% of the repeat-2 minimum. The threshold was increased from 1% after the paleo regional functional-type benchmark produced nine fully converged confirmations with consistent 1.18–1.67% near ties that did not improve with larger fitting budgets.
3. Record the exact-winner flag, relative repeat-2 loss gap, tolerance, and practical-equivalence decision in accepted-budget provenance.
4. Keep calibration separate from production regularization selection; production tuning continues to select regularization from three repeats.
5. Persist each completed calibration candidate-fold result in a content-matched rung checkpoint and reuse it after interruption.
6. Print concise progress with stage, budget, completed count, total count, repeat, fold, and candidate.
7. Re-evaluate compatible version-2 calibration results and checkpoints under the revised policy without refitting their saved evidence.
8. Publish only version-3 results after validating the migrated evidence and input hashes.

## Validation

- Add failing tests for a different but practically equivalent repeat-2 winner, a materially worse repeat-1 winner, per-fit checkpoint resumption, progress suppression, and compatible version-2 evidence migration.
- Preserve tests for incomplete folds, non-convergence, unstable adjacent rungs, and incompatible inputs.
- Run focused calibration tests, parse and 80-column checks, the full test suite, architecture generators and validator, and the paleo/modern CZ smoke pipelines.
- Re-evaluate the existing calibration evidence before restarting production. Do not delete prepared folds or accepted fit evidence.
