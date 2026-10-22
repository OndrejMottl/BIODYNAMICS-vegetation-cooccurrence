# Finish modern sensitivity, audit results, and rebuild publication outputs

## Approved scope

The user approved all four follow-up steps on 20 October 2026: correct resolution-aware eligibility in common-regularization sensitivity; rerun sensitivity only; audit modern convergence and evaluation completeness; then rebuild Stage 04 synthesis and Stage 05 figures. Preserve the dirty worktree, completed preprocessing, tuning, and main fitted models. No staging, commit, push, store reset, parameter retuning, or unrequested production-model rerun is authorized by this workflow.

## Confirmed starting state

Run `20261019_150002` finished the modern-local unit fitting/evaluation pass with 109 successful units, 153 expected-infeasible units, and zero unexpected unit failures. All 311 requested unit-resolution evaluation endpoints were current. The component subsequently failed while collecting common-sensitivity tuning summaries because its Cartesian unit-resolution lookup requested the absent family artifact for `as_r001_l001`; the production eligibility manifest requests only that unit's functional-type artifact. The shared summary loader already supports explicit eligible store-target pairs, but the sensitivity pipeline does not supply the manifest.

## Execution and validation

1. Add a failing isolated regression for sensitivity's mixed-resolution collection, retain strict failure on genuinely missing eligible evidence, and connect the existing per-tier request manifest without changing scientific selection or fitting settings.
2. Run focused regressions, regenerate architecture inventories, run the blocking validator, full test suite, and canonical paleo/modern CZ smoke pipelines. Record failures rather than weakening guards or accepting false completion.
3. Execute only `pipeline_sjsdm_common_regularization_sensitivity.R` under the modern-local profile in a logged isolated R process. Verify errors, artifact payloads, fit-attempt convergence, and provenance. Preserve before/after production model and prepared-fold metadata snapshots to demonstrate no main-model recomputation.
4. Run the existing modern convergence diagnostic in its default read-only mode, save its tabular diagnostics, and separately distinguish missing, expected-infeasible, full-model-infeasible, errored, fitted, and non-converged results. Do not treat non-null endpoints or runner success as proof of model convergence.
5. After the audit, run the Stage 04 master and then the Stage 05 master sequentially. Their existing prerequisite checks remain authoritative. Do not rebuild temporal models or other analyses to bypass missing prerequisites; report a blocker while completing independent authorized products when safe.
6. Validate dated tables and canonical figure outputs against current sources, inspect exported figures, record explicit exclusions and remaining scientific limitations, and hand off the execution logs and audit report. Any newly discovered modelling issue requiring a scientific fitting-budget change or substantial new fitting is a decision gate, not implicit permission to retune.

## Provenance and remaining risks

Execution logs and subprocess statuses belong under `Data/Temp/Main_analysis_execution/`. Durable audit and recovery evidence belongs under `Documentation/Reports/Model_evaluation/` and `Documentation/Reports/Model_calibration/`. The machine's known C-drive bad-block problem remains unresolved; this task does not authorize disk repairs, environment migration, or stopping unrelated projects. No whole-repository Quarto rendering should be invoked because archived temporary material is outside the publication scope.
