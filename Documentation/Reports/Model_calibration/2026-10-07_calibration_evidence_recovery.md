# Calibration evidence recovery and modern-local prepared folds

## Outcome

Calibration recovery is complete. Following user approval, the additional regional preparation blockers were resolved, the ten incompatible calibration directories were reversibly archived and recalibrated, and ten compatible accepted results were reused. The canonical Stage 02 master completed successfully at **2026-10-07 23:20:37 CEST**: all 24 components returned `ok`, including content-matched budget publication, configuration regeneration and configuration validation. There are no pending calibration hash blockers from this recovery. Production fitting was separately authorized and started on 2026-10-08 at 08:19:47 CEST; its completion is outside this recovery's acceptance. No commit or push was made during the recovery execution. The initial audit sections below are historical; the completion record supersedes their pending decisions and original-path status.

This report describes work on top of commit `5bbc8a449f6a6b45b68d150dc95b8ff1e3534cb9`, retaining the existing uncommitted grouped-fold-ladder implementation and unrelated changes. The associated plan is [2026-10-07_calibration_evidence_recovery.md](../../Implementation_plans/2026-10-07_calibration_evidence_recovery.md).

## Requested fold refresh

Normal `targets` execution refreshed only `list_sjsdm_prepared_tuning_folds_*` and their genuinely outdated dependencies in twelve modern-local stores. No fresh-store reset, target-hash override, interpolation rebuild, or production model fitting was used. The successful refresh ran from 2026-10-07 08:51:16 to 09:11:04 CEST.

| Unit | Resolution | Grouped folds per repeat | Prepared records |
|---|---|---:|---:|
| am_r007_l007 | Functional type | 10 | 30 |
| as_r002_l011 | Functional type | 10 | 30 |
| as_r005_l008 | Functional type | 10 | 30 |
| eu_r004_l003 | Functional type | 20 | 60 |
| eu_r004_l004 | Functional type | 10 | 30 |
| eu_r005_l001 | Functional type | 50 | 150 |
| eu_r005_l007 | Functional type | 10 | 30 |
| eu_r007_l001 | Functional type | 10 | 30 |
| eu_r008_l001 | Functional type | 50 | 150 |
| eu_r008_l003 | Functional type | 10 | 30 |
| eu_r008_l004 | Functional type | 50 | 150 |
| eu_r009_l003 | Genus | 10 | 30 |
| eu_r009_l003 | Family | 10 | 30 |

All 780 prepared records have status `ok`; all thirteen combinations have the expected fold count and three repeats. Every affected store has zero target errors. The 28 checked heavy preprocessing targets in each of the twelve stores retain their original data hashes and timestamps, including interpolation, abiotic tables, community matrices and projected coordinates. Consequently, completed interpolation/community preprocessing was reused. Selected fold assignments genuinely changed; their tuning/model descendants must be rebuilt normally when production resumes.

The fold ladder does not change the required representative identifiers: selection from the current prepared inventory still returns exactly the same twenty representatives, with no additions or removals. The separate paleo-local and temporal fold changes identified in the previous audit were not refreshed by this modern-local-only task.

## Hash defect and repair

The previous signature serialized the complete fold records, including `preparation_seconds` and the spatial provenance table's measured `elapsed_seconds`. A minimal reproduction changed only preparation time and produced a different digest. This proves that timing alone could invalidate evidence; it does not prove that any historical mismatch was timing-only.

Result and benchmark-checkpoint contracts now use version 4; candidate-fit work checkpoints use version 2. Their scientific signatures exclude only those two operational timing fields. Assignments, sample/taxon identifiers, observations, predictors, spatial strategy/projection provenance, seeds, candidate grid, fitting controls and confirmation policy remain hashed. An actual predictor named `elapsed_seconds` remains hashed. Original timings remain in the fitting inputs and provenance; only the hash copy is normalized.

New and migrated results retain per-fold scientific fingerprints plus candidate, formula and fitting fingerprints, both in the result and `calibration_input_fingerprints.qs`. Legacy evidence is migrated only when its original supported raw hash exactly matches the current raw inputs. The migration retains the old version, input hash and full original run provenance. Matching counts or file dates never authorize reuse.

Publication now reconstructs the hashes from each representative's actual cached inputs. A saved `accepted` status alone is insufficient. The canonical publication component was exercised: it rejected exactly the ten mismatched representatives before changing any spatial budget CSV, temporal profile or generated configuration.

## Representative evidence at the initial audit

Ten results were migrated through the canonical single-representative calibration component without any GPU fit. Their accepted budgets and scientific benchmark evidence remain unchanged:

- Paleo continental Europe: genus, family and functional type.
- Paleo regional `eu_r005`: genus, family and functional type.
- Modern local `am_r007_l008`: genus and family.
- Paleo temporal America and Europe: genus.

The other ten were initially classified `incompatible_inputs` and subsequently recalibrated:

| Profile | Unit | Resolutions requiring recalibration |
|---|---|---|
| Modern spatial continental | europe | Genus, family, functional type |
| Modern spatial regional | eu_r005 | Genus, family, functional type |
| Modern spatial local | eu_r005_l010 | Functional type |
| Paleo spatial local | eu_r005_l006 | Genus, family, functional type |

Their fold caches were rebuilt after the original calibration runs, and no original prepared-input payload or scientific fingerprint snapshot was found. Available partition counts do not establish analytical identity; some older benchmark counts are missing. These results were not relabelled or given replacement hashes. Their previous recorded calibration runtimes total 12.5863 hours; this is historical evidence, not a guaranteed duration for fresh calibration. A compute decision was requested before launching the GPU recalibrations, and the approved execution is recorded below.

All original result/checkpoint files were copied before migration to `Data/Temp/Main_analysis_execution/calibration_recovery_20261007/original_evidence/`. Incompatible originals were subsequently archived as recorded below; the original production paths now contain fresh accepted evidence. No incompatible checkpoint signature was forced current.

## Additional pre-existing preparation blocker at the initial audit

The canonical inventory rebuild exposed thirty blocked resolution rows in ten paleo-regional stores: `eu_r003`, `am_r001`, `am_r009`, `am_r012`, `as_r001`, `as_r002`, `as_r003`, `as_r004`, `as_r005` and `as_r007`. Their existing root errors concern `list_spatial_mev_core_basis`: insufficient projected-coordinate rows, or `argument of length 0` in the two Asia stores `as_r001`/`as_r002`. These are not new modern-local refresh errors.

The inventory initially refused to publish a globally complete preparation state. Independent selection from its valid prepared rows confirmed that the required twenty representatives were unchanged, but the Stage 02 master was blocked by these regional errors. At that initial audit, no paleo-regional stores had been modified. The exact failures were subsequently investigated and recovered as recorded below; unclassified errors were not broadly suppressed.

## Validation and execution provenance

- Focused tests cover runtime-independent signatures, preservation of analytical fields, strict raw legacy proof, incomplete/changed-input rejection, final-budget independence, and checkpoint restart behavior.
- Configuration regeneration preserves all twenty-six profile semantic references and matches independently generated artifacts.
- All 1,016 R sources parse, and changed R sources pass the 80-column check.
- Architecture inventories and profile-target manifests were regenerated; the final blocking validator reports zero findings.
- The final full test suite passed with zero test failures and one intentionally skipped optional VegVault integration test (`Data/Temp/calibration_hash_full_tests_verified.log`). After the live inventory rebuild, an intermediate run exposed a production-inventory-dependent common-sensitivity test. That test now supplies an isolated prepared/expected-infeasible fixture and explicitly verifies that an unresolved row still blocks execution; the actual production inventory remains unchanged and blocking. The required CZ smoke execution and its final status are retained in `Data/Temp/calibration_hash_smoke.log`.
- The paleo CZ core/resolution and modern CZ resolution smoke pipelines completed successfully. All three stores have zero target errors; both resolution-test stores contain all three current CV evaluation artifacts. Modern CZ finished at 09:31:59 CEST on 2026-10-07. The core smoke reused its cached store; fresh resolution tests touched only the CZ validation stores, not production stores. Evidence is retained in `cz_smoke_validation.csv` under the execution-evidence directory.
- Initial refresh-driver attempts failed before executing targets because an NSE selection could not find its local vector, then because this installed targets version lacks an exported raw make API. The corrected driver embeds literal selections and completed all twelve stores. These were launcher failures, not failed analytical targets.
- One verified migration subprocess exited with a native access violation before completing the second representative. A plain vanilla subprocess with inherited UTF-8/project-library settings resumed the migration; completed results were reused, and all ten migrations were subsequently verified content-matched. No failed fit or target was hidden.

Detailed execution evidence lives under `Data/Temp/Main_analysis_execution/calibration_recovery_20261007/`: before/after store metadata, cache comparisons, `prepared_fold_refresh_status.csv`, `prepared_fold_validation.csv`, `representative_compatibility.csv`, partition-count comparisons, representative-selection differences and per-representative migration logs. The refresh log is `Data/Temp/refresh_modern_local_fold_ladder.log`. The initial publication-blocker table is preserved as dated history at [History/2026-10-07_pre_recalibration/budget_publication_blockers.csv](sjsdm_cv_fit_budget/History/2026-10-07_pre_recalibration/budget_publication_blockers.csv), not as a current blocker list.

## Authorized regional recovery and calibration restart

The user approved repairing the regional blockers and rerunning only the ten required recalibrations. Targeted normal preparation attempted the ten affected regional units with two preparation workers, cached interpolation, and only prepared-fold endpoints requested. All thirty unit-resolution rows are now classified `expected_infeasible`; none remains an unexplained failure, and no production model fitting was requested.

Eight stores contain fewer than the existing minimum of four projected location rows: `eu_r003` (1), `am_r001` (3), `am_r009` (1), `am_r012` (2), `as_r003` (3), `as_r004` (2), `as_r005` (2), and `as_r007` (1). The spatial basis function now emits a counted feasibility message rather than an assertion. The classifier recognizes only this specific target/message contract and its exact legacy equivalent. Arbitrary engine errors remain unexpected. The mathematical construction and minimum row threshold are unchanged; no new four-unique-coordinate requirement was introduced.

The current basis construction succeeds on the cached coordinates for `as_r001` and `as_r002`, but both units have four cores and remain correctly excluded by the existing five-core preparation minimum. Their obsolete cached `argument of length 0` basis-error metadata conflicted with this current feasibility evidence. After reproducing successful basis construction and verifying the four-versus-five core guard, `targets::tar_invalidate()` removed only the obsolete basis metadata row in each store. Complete before/after metadata snapshots were saved, and all other metadata rows were verified identical. Cached objects were not deleted. Successful projected-coordinate hashes and timestamps were unchanged across all ten stores; no interpolation was rebuilt.

The canonical inventory rebuild now passes with the same twenty required representatives and no unresolved preparation blockers. Detailed evidence is retained in `regional_recovery_status.csv`, `regional_cache_validation.csv`, the two Asia before/after metadata snapshots, and `Data/Temp/recover_paleo_regional_preparation.log`.

Exactly the ten incompatible directories listed above were moved into `Data/Temp/Sjsdm_cv_calibration/_archive/20261007_pre_v4_recalibration/`, preserving their profile/unit/resolution hierarchy. Each exact source and destination was validated against the intended roots. Every archived file's MD5 matches its pre-move value, and the original directories were verified absent before restarting calibration. All ten rows in `calibration_archive_status.csv` are `archived_verified`; per-directory file-hash manifests are retained alongside it. An initial attempt used an unavailable filesystem API and failed before moving anything; the corrected move completed successfully. Nothing was deleted.

The actual canonical master, `R/02_Main_analyses/02_Model_calibration/01_run_model_calibration.R`, started at **2026-10-07 10:05:12 CEST**, detached from the launching session, with PID **44428**. At the initial startup check, its modern continental Europe / family child had completed four converged screening fits. It subsequently finished all ten recalibrations and automatically reused the other ten content-matched accepted results. The master completed at **23:20:37 CEST**, approximately 13 hours 15 minutes after launch. It did not automatically launch Stage 03 production fitting.

Completed master log: [stage02_master_20261007_100512.log](../../../Data/Temp/Main_analysis_execution/calibration_recovery_20261007/stage02_master_20261007_100512.log). Canonical component logs and the successful 24-row `component_status.csv` are under `Data/Temp/Main_analysis_execution/02_model_calibration/20261007_100514/`. Process provenance is recorded in `calibration_rerun_process.csv`. During execution, the runner was confirmed alive after its launcher exited and its calibration child was observed on the GPU.

The sjSDM attachment diagnostics mentioned its obsolete default Python environment, but the explicitly configured `r-sjsdm-vscode` interpreter remained active, all Python dependencies loaded, and the saved first four fits succeeded. This startup diagnostic was not treated as a failed analytical fit or used to interrupt the verified working GPU process.

Validation after regional recovery passed: focused classifier/basis tests, the full test suite (`Data/Temp/regional_recovery_full_tests_verified.log`), R parsing and changed-source 80-column checks, selective function documentation/rendering, and the architecture generators/blocking validator (`Data/Temp/regional_recovery_architecture.log`, zero blocking findings). The paleo CZ core/resolution and modern CZ resolution smoke pipelines also passed with zero target errors (`Data/Temp/regional_recovery_smoke.log`). These checks reused their validation stores rather than resetting them; genuinely outdated validation targets were rebuilt normally. Their latest completion times were 09:55:49, 09:58:39, and 10:02:13 CEST respectively. Final-model budgets, tuning grids, and scientific thresholds were not changed by this recovery.

## Completion and published budgets

Final recovery acceptance passed: all ten recalibrations succeeded, all twenty required representatives had accepted content-matched evidence, and publication plus configuration regeneration and validation succeeded. Publication provenance records `2026-10-07T21:20:34Z`, 1,767 assigned unit-resolution rows and twenty representatives against source commit `5bbc8a449f6a6b45b68d150dc95b8ff1e3534cb9`.

The published modern spatial family CV initial/maximum iteration budgets changed from `1000/4000` to `500/2000` for Europe, America and Asia. CV sampling remains 200. Existing final-model iterations, sampling, step size, early stopping and ANOVA sampling remain unchanged across all six spatial tuning CSVs. The regularization grid is unchanged.

Following separate approval, the Stage 03 master was launched at **2026-10-08 08:19:47 CEST**. Its execution log is `Data/Temp/Main_analysis_execution/stage03_launch_20261008/stage03_master_20261008_081947.log`, and component status is recorded under `Data/Temp/Main_analysis_execution/03_model_fitting/20261008_081951/`. This is an execution-start record, not a claim that all production models or downstream figures have finished.

## Initial decision (superseded by approved continuation above)

Do not restart production fitting yet. Resolve the ten paleo-regional preparation blockers, then recalibrate only the ten incompatible representatives with the requested compute approval. Reuse the other ten accepted version-4 results. Publish budgets and regenerate/validate configuration only after all required evidence is content-matched; final-model fitting budgets and the scientific tuning grid remain unchanged.
