# Sensitivity checkpoints and likelihood progress

## Scope and evidence

The stopped modern common-regularization sensitivity run spent most of its time in sjSDM 1.0.7 conditional likelihood calculations, not model fitting. Its single results target published nothing until all nine representatives finished. Production model, tuning, and prepared-fold targets remain unchanged; the post-stop audit confirmed all 1,964 monitored hashes and timestamps matched the baseline.

## Implementation

1. Add atomic, content-addressed sensitivity checkpoints separately for each representative's successful fit, standard-error calculation, and decomposition. Errors are not cached. Checkpoint identities include prepared inputs, formula, scientific regularization fields, budgets, seed, dependency version, and backend code, but exclude artifact creation time. Keep existing public results and artifact fields unchanged.
2. Add timestamped messages before and after each leave-one-taxon likelihood calculation, including elapsed time and completed/total counts. Execute the installed sjSDM algorithm in a private function environment containing an instrumented iteration adapter; never modify its namespace, package files, prediction calculations, Monte Carlo draws, or iteration order. Version and structural guards fail closed if the installed algorithm changes.
3. Wire these changes only into common-regularization sensitivity. The shared production ANOVA producer remains untouched. The pipeline supplies a checkpoint directory inside its own sensitivity store; no production store is reset or invalidated.
4. Test phase reuse after failure, stale-content invalidation, numerical and RNG equivalence of iteration, progress messages, failure propagation, and preservation of existing result contracts. Run architecture generators/checker, full tests, and canonical CZ smoke validation.
5. Run a bounded likelihood pilot using the cached modern Europe-genus model, retaining existing Monte Carlo sampling and batch size. Record timing and a finite work limit; no fitting is performed. Restart sensitivity only after validation and measurable pilot progress. Do not restart preprocessing, tuning, or final fitting. Stage 04/05 remain pending sensitivity success.

## Limits and recovery

Phase checkpoints survive interruption after a completed fit or standard-error calculation. They do not resume midway through a conditional likelihood pass. A single taxon call may still be quiet while its GPU batches execute; start/end timestamps distinguish that from an undispatched phase. This change improves observability and recovery, not the scientific algorithm or guaranteed runtime. No ETA is accepted before measurement.

## Naming and invalidation

New capability-owned functions are `run_sjsdm_sensitivity_checkpoint`, `run_sjsdm_likelihood_sequence`, and `compute_jsdm_variance_partition_with_progress`, with matching files and mirrored tests. These names describe material checkpoint I/O, ordered diagnostic execution, and the unchanged decomposition calculation respectively. Existing target names and public outputs remain unchanged. Only sensitivity descendants depend on the new helpers. Content hashes deliberately ignore volatile publication timestamps but include scientific regularization parameters and both fitting budgets. Atomic writes use a temporary sibling followed by rename; existing valid checkpoints are never overwritten.
