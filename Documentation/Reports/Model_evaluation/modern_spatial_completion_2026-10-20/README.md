# Modern spatial completion audit and publication recovery

## Audit on 20 October 2026

This is a read-only audit of current modern continental, regional, and local target stores, followed by the user-approved sensitivity-only recovery and Stage 04/05 rebuild. It does not authorize a production tuning reset or main-model refitting. Run logs and component-status records are under `Data/Temp/Main_analysis_execution/`; the tables here are the durable audit evidence.

| Tier | Fitted and converged | Fitted, convergence criterion failed | Expected full-model infeasibility | Expected preparation infeasibility | Requested CV evaluation endpoints |
| --- | ---: | ---: | ---: | ---: | ---: |
| Continental | 9 | 0 | 0 | 0 | 9 |
| Regional | 47 | 0 | 13 | 27 | 60 |
| Local | 218 | 1 | 92 | 475 | 311 |
| Total | 274 | 1 | 105 | 502 | 380 |

Counts refer to unit-resolution combinations, not spatial units. All 380 requested CV evaluation envelopes validate and have pooled evaluation evidence. Expected full-model infeasibility can coexist with usable held-out CV evidence; those 105 endpoints are not 105 fitted full-data models. The complete three-tier grid contains 882 unit-resolution slots.

Preparation evidence independently corroborates every one of the 502 unrequested resolutions as `expected_infeasible`; absence from a request manifest was not accepted as sufficient evidence on its own. The CV provenance records 6,472 fold fits and 6,472 successful fits. Metrics marked incomplete occur in 52 unit-resolution artifacts because some taxa are constant in a training fold: the affected prediction artifacts contain only `ok` or `constant_in_training` rows and successful fold-fit statuses, not fit, preparation, alignment, or prediction errors. These are explicit taxon-level evaluation exclusions, not complete prediction coverage for every taxon, and must not be replaced with zero-valued metrics.

One fitted model, modern local `am_r005_l003` / family, fails the strict comparison against its stored rounded diagnostic: reported tail slope `0.01` (required `< 0.01`), median difference `0.06` (required `< 1`), 149 epochs, early stopping triggered. A subsequent read-only precision check recomputed the identical tail statistics from the cached convergence plot's loss-history data: actual slope is approximately `0.00595`, and actual median difference is approximately `0.0620`. Both pass the unchanged thresholds. The apparent failure is therefore a diagnostic-rounding artifact, not evidence that this model needs refitting. `borderline_convergence_precision_check.csv` and `am_r005_l003_family_loss_history.png` retain the evidence. The original stored-rule classification is preserved in the audit tables rather than rewritten as if the persisted diagnostic had changed. All 275 fitted models pass either the stored diagnostics or this documented full-precision check; no fitting budget, threshold, or model was changed.

The maintained modern diagnostic script previously looked for the obsolete `convergence` list key. Current evaluation objects use `list_convergence_diagnostics`. Its reader and missing-diagnostic filter were corrected with a failing-then-passing regression test before these counts were accepted. Continental stores predate the explicit production-request manifest; their documented three-resolution scope was reconstructed in memory and labelled in `audited_production_requests.csv`, without altering a production store or fabricating a manifest.

## Sensitivity repair

The sensitivity pipeline attempted a Cartesian product of eligible units and all resolutions. Partially eligible units, including `as_r001_l001`, do not have all three artifacts. The pipeline now passes the existing per-tier production-request manifests to the shared strict summary loader. Genuine missing requested artifacts still fail. Completed tuning, prepared folds, final fits, and evaluation targets are not rerun by this repair.

The sensitivity-only operation refits the nine configured cross-tier representatives with common regularization. It must validate the final artifact, check target errors, and require successful converged provenance for every representative; a successful runner exit alone is insufficient. Publication proceeds through the existing Stage 04 and Stage 05 masters, in that order, only after this operation succeeds.

## Evidence and verification

- `modern_model_completion_status.csv` records all 882 unit-resolution classifications; `modern_model_completion_summary.csv` contains the summary above.
- `modern_audit_findings.csv` identifies the one stored-rule convergence flag. `modern_non_converged_models.csv` and `modern_convergence_diagnostics.csv` preserve its diagnostics and all fitted-model checks. The separate full-precision check resolves that flag without mutating the source evaluation object.
- `modern_cv_evaluation_evidence.csv` records validated requested CV envelopes and pooled evidence. `audited_production_requests.csv` distinguishes explicit request manifests from the continental legacy scope.
- `modern_preparation_scope_corroboration.csv` joins the audit to classified preparation evidence. `modern_cv_evaluation_completeness.csv` records successful fold-fit counts and incomplete-metric counts; `modern_cv_metric_status_counts.csv` and `modern_incomplete_metric_prediction_evidence.csv` trace those exclusions to their cached evidence.
- `main_targets_before_publication.rds` preserves exact hashes and timestamps for 1,964 main-model, prepared-fold, and tuning target metadata rows across 294 modern stores. The corresponding after-snapshot and preservation check will be written after publication; they are required before claiming that completed analytical targets were preserved.
- `sensitivity_model_provenance.csv`, `sensitivity_fit_attempts.csv`, and `sensitivity_target_errors.csv` will be written by the sensitivity-only validation. Their absence means that operation has not yet been verified complete.

The machine's known C-drive faults remain outside this repair. No disk repair, environment migration, Git staging, commit, or push is performed.

## Execution monitoring

The approved sequence is managed by a hidden detached R process, with its PID and logs recorded in `publication_launch_receipt.csv`. Its queue status and coordinator logs are under `Data/Temp/Main_analysis_execution/modern_sensitivity_and_publication_queue_20261020/`. The queue waits for all five components of validation run `modern_publication_validation_20261020/20261020_123857` to succeed; a failed validation component blocks sensitivity and publication. The full test suite and architecture validator passed before the queue was launched; canonical CZ smoke pipelines were still running at launch. Those smoke pipelines use their isolated test stores, not modern or paleo production stores.

After validation succeeds, the queue runs the sensitivity-only worker, the unchanged Stage 04 master, the unchanged Stage 05 master, and explicit cache/output verification in order. Each component runs in a fresh R subprocess, and failure blocks later components. Their combined logs and status CSV are under `Data/Temp/Main_analysis_execution/modern_sensitivity_and_publication_20261020/<run_id>/`. `publication_run_provenance.csv` records the source commit, configuration and preparation-inventory hashes, times, and completion status; `publication_component_status.csv` is copied here at completion or failure. Absence of a successful final status is not completion.

## User-authorized stop on 21 October 2026

At 12:15:40 Prague time (10:15:40 UTC), the user-approved stop terminated only the verified recovery queue, PID 14852, its sensitivity worker PID 23960, the pipeline R process PID 50816, and their two console-host descendants. All five PIDs were verified absent afterward. No unrelated analysis process was targeted. GPU utilization subsequently fell to 0%, with about 800 MiB still used by the desktop and other applications.

The stop interrupted the Europe genus common-regularization sensitivity decomposition, the third configured representative. The latest log output remained the saturated-model early stop from 09:57:58 Prague time. The process had continued consuming CPU/GPU resources, but no verifiable representative completion had been recorded. All nine representatives share one target, so partial in-memory sensitivity work was not independently checkpointed and may need repeating. The sensitivity artifact was not completed; Stage 04 synthesis and Stage 05 figures did not start. No automatic restart is scheduled.

After cancellation, `main_target_preservation_check.csv` verified that all 1,964 main-model, prepared-fold, and tuning metadata rows across 294 modern stores retained identical hashes and timestamps. The after-snapshot in this directory is therefore a post-cancellation preservation check, not evidence of successful publication. No target store, preprocessing data, fitted production model, tuning artifact, or existing output was deleted or reset. Queue status and run provenance explicitly record `stopped_by_user`; the abrupt termination did not produce the normal component-completion CSV.
