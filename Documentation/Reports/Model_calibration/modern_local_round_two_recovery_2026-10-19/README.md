# Modern-local round-two subprocess recovery

## Scope and safe boundary

The user authorized monitoring the existing modern-local runner until round two ended, investigating and recovering `am_r004_l004`, and continuing toward round three. The existing run was `20261017_115924`, coordinator PID 41036 and canonical component PID 10584. No process was killed: the unit loop finished naturally and the existing unexplained-failure guard stopped tier selection. The monitor observed the coordinator gone at 12:56:55 UTC on 19 October 2026 (14:56:55 Prague). The log contains exactly one failed tuning unit, `am_r004_l004`; independent units were allowed to complete.

No production modelling code, candidate grid, CV budget, seed, final-model budget, scientific guard, target-store layout, or calibration evidence was changed. No stores were reset, no targets were manually invalidated, no disk repair or environment migration was attempted, and unrelated projects were not stopped. The existing dirty worktree was preserved; no staging, commit, or push was performed.

## Investigation

The failed unit's last successful round-two target was recorded at 07:51:14 UTC (09:51:14 Prague); the next unit first recorded a target at 07:51:50 UTC. Its progress retained the family result group and branch `list_sjsdm_tuning_work_item_result_family_0d18d1b00a2120d4` as dispatched. There was no saved target error explaining the abrupt callr subprocess loss. The original orchestration retained only a generic condition message, not the full native termination status.

All 30 cached prepared folds for genus and family were readable, finite, and row-aligned. Training folds contain 110–111 observations, four family responses, and six genus responses. Functional-type preparation has zero prepared tuning folds and the existing explicit `tuning_applicable = FALSE` sentinel; this is not a newly failed or discarded functional-type model. All 473 source/settings hashes recorded by the preceding launch still matched. Prepared-target hashes and timestamps across all 109 requested stores were snapshotted before any recovery fit.

The captured Windows System events contain 28 disk Event ID 7 bad-block records for `\Device\Harddisk0\DR0`, from 07:51:47.4980810 to 07:53:27.0984335 UTC. The first seven fall inside the inferred failed-unit interval. A fresh read-only volume query confirmed C: maps to physical disk 0 and D: maps to physical disk 1. The Application event query returned no warning/error in the bounded window; the only other System warning captured was an unrelated DistributedCOM event. The timing strongly supports an environmental/storage explanation, but does not prove the precise read, library, or termination mechanism. The C-drive defect remains unresolved.

## Operational correction and retry

The first recovery launcher (`20261019_145805`) stopped at 12:58:08 UTC before calling the pipeline or fitting any model. A doubled path separator in the operational wrapper made its literal store path fail equality against the manifest. A read-only probe reproduced zero literal matches versus three normalized matches. The wrapper was corrected to normalize paths and to validate the existing explicit non-applicable functional-type sentinel separately from applicable genus/family evidence. This was an operational correction, not a production modelling change or a relaxation of eligibility rules. The failed launch and receipt remain preserved.

The corrected launch is `20261019_150002`, detached coordinator PID 17776 and isolated retry worker PID 22680, started at 13:00:03 UTC (15:00:03 Prague). It requests the existing cumulative round-two tuning endpoints through `run_pipeline()` with the same profile, candidates, seeds, and budgets, `fresh_run = FALSE`, and interpolation prebuild disabled. It retains separate stdout/stderr logs, the subprocess exit status, and the full callr condition if the retry fails. Only one actual model-fitting retry is authorized by this sequence; a failed retry blocks automatic continuation.

Before continuation, the retry must validate the artifact envelopes, exact requested result coverage, convergence, complete round-two candidate evidence, and unchanged prepared-fold hashes and timestamps. The coordinator also checks all snapshotted prepared targets across the 109 stores. Only after these checks pass will it start the unchanged canonical `06_fit_modern_spatial_local.R` component. That component rechecks prerequisites and cached earlier rounds before publishing the round-two survivor decisions and proceeding to round three; its startup must not be described as proof that round three has already started.

## Validation and evidence

Operational scripts passed syntax and 80-column checks. Non-GPU subprocess probes verified that exit status 37 and full callr error serialization are preserved. No analytical implementation changed, so the scientific test suite and smoke pipelines were not rerun solely for these operational scripts. Recovery is additionally verified against the real isolated unit and the unchanged cached preparation.

- `source_and_settings_hash_check.csv`: all 473 preceding source/settings hashes matched.
- `prepared_targets_before_recovery.csv` and `.rds`: prepared-target snapshot for all requested stores.
- `cached_fold_input_audit.csv`: all 30 applicable cached-fold checks.
- `failed_unit_metadata_before_recovery.csv` and `failure_timeline.csv`: pre-retry target evidence and inferred failure interval.
- `System_events.xml`, `Application_events.xml`, and `crash_window_event_summary.csv`: original bounded Windows event captures and compact event inventory.
- `processes_after_round_boundary.csv`: R process inventory after natural shutdown.
- `launch_receipt.csv`: current recovery receipt; older receipts are archived beside it.
- Run logs: `Data/Temp/Main_analysis_execution/03_model_fitting_modern_local_small_fold_recovery/20261019_150002/`.

## Outcome

The corrected single fitting retry passed at 13:05:41 UTC on 19 October (15:05:41 Prague); its subprocess exited with status 0 at 13:05:42 UTC. Genus and family each contain all 60 cumulative candidate-fold results: the 40 existing round-one results plus 20 round-two results. All 60 per resolution converged, and each resolution has all four round-two candidates with complete evidence. The functional-type endpoint retains its explicit expected non-applicable sentinel. All three artifact envelopes and content hashes validate.

All 327 prepared-fold targets across the 109 requested stores retained exactly the same content hashes and timestamps. The previously completed genus/family candidate-fold results also retained their content hashes and completion times at the whole-second precision available in the pre-retry CSV; this check does not claim subsecond evidence that the CSV did not preserve. Detailed tables are `retry_coverage.csv`, `retry_status.csv`, `retry_subprocess_status.csv`, `retry_prepared_preservation.csv`, `all_units_prepared_preservation.csv`, and `prior_round_one_fit_preservation.csv`.

The unchanged canonical modern-local component restarted at 13:05:43 UTC (15:05:43 Prague), component PID 55416 under detached coordinator PID 17776. Independent verification at 13:09:37 UTC confirmed the live component had entered normal prerequisite rechecks; `canonical_restart_verified.csv` records that verification. These checks may print already classified expected-infeasible preparation messages. They are not a full preprocessing reset, and the runner must still verify cached earlier-round evidence and publish the round-two survivor decisions before round three can start. At this report update, round-three execution itself has not yet been asserted.

The formerly interrupted unit no longer blocks continuation. No deterministic modelling defect was reproduced or patched. The operational manifest-path bug was corrected, existing model and preparation caches were retained, and the C-drive bad-block risk remains unresolved. Recovery of this unit does not declare the complete modern-local analysis finished or all final models converged.
