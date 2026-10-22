# October paleo spatial recovery

## Outcome

The October association-summary figure now uses 229 admissible paleo unit-resolution models: 8 continental, 50 regional, and 171 local. The six historical models in `am_r007_l004` and `am_r007_l006` are excluded. Their files remain recoverable in their stores; they are not accepted as current results behind a failed spatial basis. The September 27 snapshot was preserved.

Canonical refreshed outputs are `Outputs/Tables/paleo_patterns_unit_2026-10-12.csv`, `Outputs/Tables/paleo_patterns_summary_2026-10-12.csv`, and `Outputs/Figures/Spatial/paleo_spatial_association_summary_2026-10-12.{pdf,tiff,png}`. Exact plotted data are in `Outputs/Tables/Visualisation/paleo_spatial_association_summary_{unit,group}_2026-10-12.csv`. These are current-store descriptive outputs, not a claim that the separate calibration compatibility issue below has been resolved.

## Recovery performed

- Stopped only the approved Stage 03 master (PID 23860, source commit `6483905b`) and its verified descendants. No unrelated computation was stopped. Completed modern America target hashes and timestamps remain unchanged.
- Reproduced the exact sjSDM zero-column MEM failure. The dimension-preserving calculation confirms zero positive eigenvectors in both affected units. They now have the registered `no_positive_spatial_eigenvectors` outcome; no no-spatial fallback, eigenvalue tolerance, or new location-count threshold was introduced.
- Refreshed the three affected units' prepared-fold endpoints without rebuilding interpolation or fitting GPU models. At `eu_r009_l002`, genus and functional-type fold `repeat_002__fold_001` is explicitly unsupported by its training geometry. The full-data models remain usable, but their existing tier-pooled selections do not provide complete held-out CV evaluation; missing predictive metrics must not be interpreted as zero.
- Corrected run status to inspect current-run target progress, including repeated errors whose metadata timestamps remain unchanged. Expected data limitations are classified separately from unexpected failures. All six spatial fitting components now block progression after unexplained post-selection unit failures.
- Corrected the calibration inventory so historical feasibility counts cannot override a failed shared MEM basis. The required representative identifiers are unchanged.
- Protected synthesis against historical ANOVA results behind failed shared or resolution-specific upstream targets. Independent successful resolutions remain available, and unreadable metadata do not admit historical model objects.

`cache_comparison.csv` records before/after target hashes and timestamps. All 53 inspected interpolation/full-model targets across the three affected stores were retained unchanged. `basis_status.csv` records the two expected-infeasible units, and `unsupported_cv_folds.csv` records the two fold-specific limitations.

## Modern restart blocker

Modern fitting has not been restarted. The live compatibility check accepts 10 of the 20 required representative results and rejects 10 because their prepared-fold fingerprints differ from the accepted calibration evidence. The mismatching representatives are all nine paleo spatial representatives (Europe continental, `eu_r005` regional, and `eu_r005_l006` local, each at three resolutions) and modern continental Europe functional types. Their candidate-grid, formula, and CV-fitting fingerprints still match. None of those representative prepared-fold stores was modified by this recovery, so the discrepancies predate this intervention.

An isolated `qs2` round trip of a currently cached fold object preserved both equality and its hash; that test does not explain the historical mismatch. Matching counts or convergence alone are insufficient to re-approve changed calibration inputs. Original evidence and published budgets have not been replaced, budgets have not been reset, and no additional calibration fits have been launched. The next decision is a scoped investigation/reconciliation of those fingerprints, followed by a costed proposal if genuine recalibration is necessary, before resuming the remaining modern components.

## Validation and execution records

Focused regression tests and the final full test suite pass. The paleo and modern CZ smoke pipelines completed with zero recorded target errors. Configuration generation confirms that all 26 profiles match their generated fragments and the semantic reference; tuning grids and fitting budgets were not changed. Architecture generators expanded 19,782 profile-target rows across 26 profiles, and the blocking validator reports zero findings. `git diff --check` passes. Final complete-suite and architecture acceptance is recorded in `Data/Temp/Paleo_recovery_20261012/acceptance.log`, with a compact durable record in `validation_status.csv`.

Execution logs, original metadata snapshots, and diagnostics are retained under `Data/Temp/Paleo_recovery_20261012/`. A complete-suite rerun during reference-page regeneration was rejected because one HTML artifact was temporarily absent; validation was then sequenced after rendering. Quarto's project scan also encountered test-created `_snaps` directories disappearing during that run; the canonical reference pages were rendered from a stable temporary website-source snapshot instead. These were validation orchestration problems, not failures of production models.

No commits or pushes were made. This report supplements, rather than replaces, the [original read-only audit](../paleo_spatial_audit_2026-10-12/README.md).
