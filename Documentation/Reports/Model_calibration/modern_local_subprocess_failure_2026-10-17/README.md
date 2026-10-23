# Modern-local subprocess failure investigation

## Scope

Investigated `eu_r005_l006` on 17 October 2026 without stopping the active modern-local runner, launching another fit, invoking CUDA from the diagnostic R sessions, invalidating targets, resetting stores, changing production source/configuration, or repairing disks. The active run is `20261016_152015`, coordinator PID 33588 and canonical component PID 16232. The investigation concerns the isolated unit child, not another complete PC crash.

## Confirmed findings

- The canonical component log records the family tuning group declaring 40 branches, the GPU parallel-setting message, then `callr subprocess failed: could not start R, exited with non-zero status, has crashed or was killed`. It continued to the next unit. The exact source is `Data/Temp/Main_analysis_execution/03_model_fitting_modern_local_small_fold_recovery/20261016_152015/06_fit_modern_spatial_local.log`, lines 13523–13528 at investigation time.
- This unit's last new successful target was recorded at 18:20:49 UTC on 16 October (20:20:49 Prague). The next unit, `eu_r005_l007`, recorded its first new target at 18:21:24 UTC (20:21:24 Prague). Thus the failed fit attempt occurred after 18:20:49 UTC and before the next unit's first recorded target; the exact process-death time was not persisted.
- Target progress retains the family group and branch `list_sjsdm_tuning_work_item_result_family_3c1a970e22e96ab6` as dispatched. The unit has no recorded target error. No new candidate result was saved; its tuning-result metadata still dates from 5 October. Those old objects are not evidence that the failed current run succeeded.
- All 45 cached prepared folds were readable and had preparation status `ok`. Training response, environmental, and spatial matrices were finite and had aligned row counts. Family and genus training folds have 1,494–1,495 rows, respectively 21 and 30 taxa; functional-type folds have 1,540 rows and five taxa. These checks do not prove that a model will converge, but they find no empty/small-fold or non-finite-input explanation.
- The first requested family work item is round 1, repeat 1, fold 1, `candidate_001`, work item `sjsdm_cv_b5cc268607fb24bf`, seed 900723. Its training data contain 1,494 rows, 21 taxa, four environmental predictors, and three spatial predictors. The current CV budget is 500 initial iterations, 2,000 maximum iterations, and sampling 200. The default ten-percent batch is 149 rows, so the earlier batch-size-zero bug is not applicable.
- Windows System log has seven `disk` Event ID 7 records, IDs 548965–548971, at approximately 18:21:53.53–18:21:53.55 UTC (20:21:53 Prague). Windows renders the description as `The device, \Device\Harddisk0\DR0, has a bad block.` Read-only volume disk-extents queries map C: to physical disk 0 and D: to physical disk 1.
- No Application warning/error or Windows Error Reporting event was returned within the 18:19–18:24 UTC window. No System resource-exhaustion or display-reset event was returned in that window. A separate query found no Rterm/Rscript Application Error event since the run began. Absence of those records does not rule out transient memory pressure, a native-library failure, or external termination.
- The active runner remained alive and continued GPU work during the investigation. A read-only GPU sample showed approximately 1.3 GiB of 8 GiB allocated, 29 percent utilization, and 55 C. These are current observations, not measurements from the failed child.

## Interpretation and limits

This is an abrupt subprocess loss, not a classified insufficient-data outcome and not a reported convergence failure. C: disk errors are a concrete environmental problem and a plausible explanation because R, Python, libraries, and temporary files use C:, even though the target stores are on D:. However, the seven retained events occurred approximately 29 seconds after the next unit's first recorded target. They are near the failure, not proof that a particular disk read killed this R child.

The orchestration retains only `conditionMessage()` and a coarse error classification for a failed tuning unit. The detailed callr condition, including any available subprocess status and stdout/stderr diagnostics, was not persisted. The actual exit status, offending module, and process-death mechanism therefore cannot be reconstructed from the durable analysis log. Broad Windows Error Reporting queries also returned delayed submissions of old watchdog dumps; these were not treated as current GPU failures.

No GPU fit was reproduced during this investigation because the user required the current runner to remain uninterrupted and an additional fit would compete with it. Consequently no deterministic code-level cause or fix is claimed.

## Recovery recommendation

Let independent units continue as requested. Do not lower scientific thresholds, change CV budgets, discard prepared folds, or classify this unit as expected infeasible. The current round's unexplained-error guard will prevent tier selection once its unit loop finishes. Repairing the store externally would not erase the coordinator's in-memory failed-unit status, so a clean continuation still needs a new orchestration pass after the current pass ends.

At that safe boundary, retry this unit through the canonical fitting path with the same budgets and seed while preserving the full callr condition and subprocess status/output. A bounded isolated retry can distinguish a transient environmental failure from a reproducible data/runtime failure. If it succeeds, rerun the canonical modern-local component normally to reuse current targets and progress beyond the guard. Do not reset the stores. Persist richer subprocess diagnostics and consider bounded crash-only retries as a separately authorized hardening change; ordinary model/scoring errors must not be silently retried or suppressed.

C: storage reliability requires separate attention. Do not run repair operations, disk stress tests, environment migrations, driver changes, or restart the machine while this authorized computation continues without an explicit user decision. The diagnostics here do not establish that D: or existing outputs are corrupt, nor do they constitute a full disk-health audit or backup verification.

## Evidence

- `cached_fold_input_audit.csv`: 45 cached-fold structure/finite-value checks, generated without fitting.
- `disk_events_20261016_1819_1824_utc.xml`: original seven Windows System event records from the narrow investigation window.
- Read-only operational probes: `Data/Temp/inspect_eu_r005_l006_crash_20261017.R`, `inspect_failed_unit_inputs_20261017.R`, `inspect_failed_unit_timeline_20261017.R`, and `inspect_volume_disk_mapping_20261017.py`.

## Approved recovery execution

The user subsequently approved stopping the modern-local runner, retrying this unit with unchanged settings and detailed subprocess logging, and restarting the canonical modern-local component only if the retry passes. This supersedes the earlier request to leave the runner untouched. No disk repair, environment migration, production-code change, tuning-budget change, store reset, commit, or push was authorized or performed as part of this recovery.

Operational scripts wait for an identified owned callr unit child to exit, then stop only the identity-checked coordinator tree. The retry requests the three existing round-1 tuning endpoints through `run_pipeline()` with `fresh_run = FALSE` and interpolation prebuild disabled. It preserves any full callr error condition, records separate stdout/stderr logs and the retry R process exit status, validates the artifact envelopes and candidate coverage, and checks that the three prepared-fold content hashes remain unchanged. A failed single retry blocks automatic continuation.

The recovery launcher compares all recorded source/settings hashes with the previous tested launch before executing any retry. The operational scripts passed parse/80-column checks. Small non-GPU subprocess probes verified preservation of exit status 37 and round-trip serialization of the detailed callr error condition. These are operational checks, not another model benchmark or full scientific test run; production implementation and scientific settings are unchanged.

The owned current unit subprocess (PID 18516, `am_r002_l003`) completed before the stop. Read-only verification found all 40 family and 40 genus branches completed, plus its not-applicable functional-type sentinel. The old coordinator tree was terminated at 09:59:17 UTC (11:59 Prague), including a newly spawned next-unit child during startup. No stores were reset. The identity-checked process tree is recorded in `owned_processes_before_boundary_stop.csv` and the stop in `boundary_stop_receipt.csv`.

Recovery run `20261017_115924` launched at 09:59:24 UTC (11:59 Prague), detached coordinator PID 41036 and retry worker PID 57028. The launcher confirmed the previous source/settings hashes remained unchanged and that no duplicate runner remained. Its run directory is `Data/Temp/Main_analysis_execution/03_model_fitting_modern_local_small_fold_recovery/20261017_115924/`. The originally interrupted first family candidate-fold subsequently saved status `ok`, `converged = TRUE`, and `actual_n_iter = 500`. This supports a non-deterministic/environmental explanation but does not identify the original termination mechanism. The coordinator permits canonical continuation only after the whole single-unit retry and its validation succeed; it does not treat this first successful fit as unit completion.

### Verified outcome

The single targeted retry passed at 10:17:29 UTC on 17 October (12:17 Prague); the worker exited with status 0 at 10:17:32 UTC. Genus, family, and functional types each produced all 40 requested candidate-fold results, all 40 converged, and all eight candidates had complete converged fold coverage. Each resolution required 40 fit attempts for its 40 results. All three artifact envelopes and content hashes validated. The three prepared-fold target content hashes remained unchanged, and no store reset occurred.

The canonical modern-local fitting component restarted at 10:17:32 UTC (12:17 Prague), with component PID 10584 under detached coordinator PID 41036. Its sjSDM/CUDA startup passed, and it entered the normal preparation-eligibility checks. Startup was verified at 10:18:15 UTC, with another live process check confirming both the coordinator and canonical component running. Expected data-limit errors can still be printed during this preflight; these are distinct from the recovered abrupt subprocess failure. The local analysis as a whole is not declared complete or fully converged by this unit recovery.

Durable outcome evidence is stored beside this report in `retry_coverage.csv`, `retry_status.csv`, `retry_subprocess_status.csv`, `retry_prepared_preservation.csv`, and `canonical_restart_verified.csv`. The active component log is `Data/Temp/Main_analysis_execution/03_model_fitting_modern_local_small_fold_recovery/20261017_115924/06_fit_modern_spatial_local.log`. The isolated retry's output and error streams remain separately preserved as `retry_stdout.log` and `retry_stderr.log` in that run directory. No modelling code, scientific fitting settings, calibration budgets, or target metadata were manually changed to obtain success. The C: storage risk remains unresolved.
