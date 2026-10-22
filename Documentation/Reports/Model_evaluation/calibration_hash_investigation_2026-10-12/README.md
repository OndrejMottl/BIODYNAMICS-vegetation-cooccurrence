# Calibration fingerprint investigation

## Outcome

The 10 calibration mismatches reported by the October 12 paleo recovery have a reproduced cause: the October 6 change to repeated-coordinate handling in `compute_spatial_mev_basis()` (commit `01741718`). They are not a `qs2` round-trip problem. Nine paleo spatial representatives have changed analytical spatial predictors; the modern continental Europe functional-type representative differs only in two operational memory-provenance fields. No production runner, calibration fit, budget publication, target invalidation, or Git operation was performed during this investigation.

## Evidence

The investigation read all 20 required representatives and isolated the same 10 mismatches. Candidate-grid, formula, and structural fitting fingerprints match their saved calibration evidence. Each affected representative has 15 prepared folds. Saved calibration work files contain metrics, attempts, and signatures, but do not contain the original prepared-fold payloads.

An isolated R process reconstructed each of the 150 affected folds from the currently cached raw community data, abiotic data, sample metadata, projected coordinates, fitting configuration, data-processing configuration, and the current recorded train/test indices. Only `compute_spatial_mev_basis()` was replaced inside that throwaway process with its exact tracked source from `01741718^`; repository source files and target stores were not modified. All 150 reconstructed historical fold hashes exactly reproduce the saved per-fold calibration hashes. As an additional control, rebuilding the first regional genus fold using the current function reproduced its current normalized cached payload with `identical() == TRUE`.

`fold_reconstruction_evidence.csv` records saved, current, and reconstructed historical hashes; exact analytical-equivalence checks; differences; and diagnostic runtimes. `representative_findings.csv` summarizes coverage. All 150 historical reconstructions retain identical observations, sample IDs, taxa mapping, abiotic predictors, alignment diagnostics, and fold assignments compared with the current cached records. The full normalized records are compared, not merely their dimensions or rounded summary statistics.

| Representatives | Folds checked | Historical hashes reproduced | Analytical findings |
|---|---:|---:|---|
| Paleo Europe continental: genus, family, functional type | 45 | 45 | Spatial predictors and their scaling changed in all folds. |
| Paleo `eu_r005` regional: genus, family, functional type | 45 | 45 | Spatial predictors and their scaling changed in all folds. |
| Paleo `eu_r005_l006` local: genus, family, functional type | 45 | 45 | Spatial predictors and their scaling changed in all folds. |
| Modern Europe continental: functional type | 15 | 15 | All normalized fold content is exactly identical after excluding only `basis_bytes` and `estimated_dense_matrix_bytes`. |

The exact spatial strategy previously constructed the eigenvectors on every location row, including repeated coordinate pairs. The current implementation constructs the basis on distinct coordinate pairs and expands it back to all location rows. That changes the actual paleo eigenvectors, train-only spatial scaling, and held-out spatial predictions. It is not merely an eigenvector-sign or runtime difference. For modern functional types, the full scientific fold contents remain bitwise identical; only the measured basis size and estimated dense matrix size change. These two operational fields currently remain inside the v4 calibration signature, which unnecessarily rejects that modern evidence.

## Why this was not caught before fitting

Stage 02 reads cached feasibility and prepared folds. Its compatibility check proves agreement with the cached payload it reads, but does not prove that the preparation targets are current under changed upstream functions. The October 7 migration/publication therefore accepted evidence against those still-cached paleo folds. Stage 03 subsequently rebuilt the affected prepared folds: October 8 for the paleo continental and regional representatives, October 9 for the paleo local representative, and October 11 for modern continental Europe. Those rebuilds introduced the current repeated-coordinate behavior. None of these representative stores was changed by the October 12 targeted paleo recovery.

The budget configuration constructor verifies numeric budgets and the optional `calibration_status == "calibrated"` label. That label is not an enduring content match against the live representative folds. Thus successfully publishing budgets once does not prevent production from later using them after the representative inputs change.

## Proposed narrow remediation, not executed

1. Add preparation-freshness enforcement before calibration reads or reuses representative evidence, based on the current pipeline and its preparation ancestors. A cached object merely existing is insufficient. Outdated analytical preparation must produce a useful recovery command, not silently launch full preprocessing or accept old evidence. Test code-change invalidation separately from harmless runner-authorization metadata changes.
2. Give calibration signatures a documented versioned distinction between analytical inputs and operational memory measurements. Continue hashing observations, sample and taxon identifiers, assignments, predictors, train-only scaling, and spatial strategy/engine settings. Exclude only the verified operational fields, retaining them in provenance. Do not relax equality for substantive predictor changes or use count-only equivalence.
3. Retain modern Europe functional-type calibration evidence through an explicit, audited compatibility migration: reproduce every saved v4 fold hash, require exact equality of the complete current and reconstructed historical fold records except the two operational memory fields, preserve original evidence and legacy fingerprints, then publish the new signature. Leave the other 10 already-compatible representative results untouched apart from any explicitly tested version migration.
4. Archive and recalibrate only the nine affected paleo representatives using the current prepared folds and unchanged calibration policy. Existing fit checkpoints belong to different analytical inputs and cannot be force-reused by replacing their signatures. Start with a bounded representative run and estimate the remaining cost from fresh timings; old accumulated runtime, especially failed historical high-rung attempts, is not a reliable ETA.
5. Revalidate all required evidence before publishing budgets. Compare new versus current production budgets and inspect the resulting target invalidation before resuming modern fitting. Do not globally reset final-model budgets, wipe preprocessing stores, or assume that recalibration requires every completed final model to be rerun. Preserve completed models and CV evidence unless an actual analytical or budget dependency changes.

The current October paleo figure remains a descriptive view of the rebuilt model stores, not final certification that their inherited CV budgets have been calibrated against the new spatial inputs. The investigation does not establish that the new accepted budgets or regularization decisions will differ; that requires the scoped recalibration.

## Execution boundaries and provenance

Source HEAD was `6483905b` on branch `OndrejMottl/issue176`, with all pre-existing recovery changes preserved. Diagnostics were sequential CPU fold reconstructions in disposable R processes; no `tar_make()`, sjSDM model-fitting call, GPU benchmark, or master runner was invoked. The installed sjSDM namespace was needed for its R spatial-eigenvector function; Python-dependency startup messages in the isolated sandbox are not GPU fitting failures and were not bypassed for any model fit. The sequential reconstruction completed successfully with all 150 expected records.

Ignored detailed logs are under `Data/Temp/Calibration_hash_investigation_20261012/`. Durable findings and fold hashes are stored beside this report. Modern production remains stopped pending an approved remediation. No source-code changes, budget edits, calibration-result rewrites, commits, or pushes were made during this investigation.
