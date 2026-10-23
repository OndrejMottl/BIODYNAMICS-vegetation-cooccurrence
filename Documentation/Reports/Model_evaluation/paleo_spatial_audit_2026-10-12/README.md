# October paleo spatial result audit

## Decision

Do not publish an unqualified October paleo figure by running the existing synthesis and visualisation components unchanged. The audit found two blocked local stores whose six September model results are still readable and accepted by the synthesis loader, a repeated-error reporting defect, and two unavailable CV evaluations in a third local unit. The available fitted-model diagnostics otherwise pass the project's existing convergence thresholds. These findings require targeted recovery and explicit exclusions, not another blanket paleo rerun.

This read-only audit was completed on 2026-10-12 against branch `OndrejMottl/issue176`, commit `6483905b`. It inspected all 294 paleo spatial stores and 882 unit-resolution slots, cached fitted evaluations and ANOVA outputs, regularization-selection and CV artifact contracts/content hashes, selected-candidate tuning evidence, budget provenance, and the common-regularization sensitivity artifact. It did not fit models, rebuild synthesis, mutate target stores, change configuration or stop the active modern fitting master. The audit does not replace a full current-manifest `tar_outdated()` check or validation of every rejected tuning candidate.

## Available fitted results

The following counts exclude all six model slots in the two blocked stores. All 229 available fitted evaluations contain finite convergence diagnostics meeting the maintained criterion: absolute tail slope below 0.01 and median tail difference below 1. These are the diagnostics persisted by `diagnose_jsdm_convergence()`, including that function's existing rounding; this audit did not refit models or redefine convergence.

| Spatial tier | Genus | Family | Functional type | Total |
| --- | ---: | ---: | ---: | ---: |
| Continental | 3 | 2 | 3 | 8 |
| Regional | 18 | 15 | 17 | 50 |
| Local | 58 | 56 | 57 | 171 |
| Total | 79 | 73 | 77 | 229 |

Across the full 882 slots, 647 are classified expected-infeasible by existing preparation or full-model selection evidence, 229 have available fitted results outside unexpected-error stores, and six are blocked by unexpected store errors. All stores are present. At unit level, three continental, 18 regional and 63 local stores have no recorded target errors; 11 regional and 197 local stores retain classified expected-infeasibility errors; two local stores retain an unexpected MEM error.

Among the 229 available evaluations, 108 fitted-evaluation targets retain timestamps before the 8 October master restart, while 121 have later timestamps. Retained cached dates alone are not a failure: normal `targets` execution reuses unchanged descendants. A completed October runner therefore does not mean every final model was refitted in October. Conversely, old readable results in a store with a failing required upstream dependency must not be certified solely because their own metadata still say successful.

## Findings requiring recovery

### 1. Zero-positive-eigenvector MEM failure in two complete units

`am_r007_l004` and `am_r007_l006` both fail at `list_spatial_mev_core_basis` with `length of 'dimnames' [2] not equal to array extent`. Their final models are dated September and their October tuning/full-unit attempts failed at the shared basis. The local runner-status CSV nevertheless records both as `ok`.

A CPU-only reproduction using their actual cached projected coordinates found five input core rows but only three distinct coordinate pairs in each unit. The configured auto strategy selects the exact engine. The exact sjSDM calculation produces zero positive eigenvectors for both unique-coordinate matrices. Installed sjSDM 1.0.7 subsets the eigenvectors and then names columns using `1:ncol(SV)`; zero columns produce an incompatible name vector. The project's existing exact-engine compatibility helper catches only the separate one-positive-eigenvector error, `argument of length 0`, so it does not handle this case. This is reproducible geometry/engine behaviour, not a GPU or parallel-memory crash.

Under the current positive-MEM specification there is no basis to fit for these geometries. Recovery should diagnose and register that precise no-supported-MEM outcome, or require an explicitly approved scientific fallback. Do not silently fit a different spatial model, force old hashes current, broaden arbitrary engine errors into expected exceptions, or reuse the six old models as current results.

Evidence: [mem_reproduction.csv](mem_reproduction.csv), [target_errors.csv](target_errors.csv), [resolution_status.csv](resolution_status.csv).

### 2. Repeated errors are incorrectly reported as success

The spatial pipeline uses `error = "continue"`. `run_pipeline()` captures thrown exceptions and checks `extract_new_target_errors()` after execution. That helper anti-joins before and after metadata by `name`, `error` and `time`. For these repeated failures, the unsuccessful target retains its earlier successful-data timestamp and the same error text, so the new-error set is empty. `run_pipeline_units_with_status()` then treats the non-throwing return as `ok`, and the master accepts the component's exit status.

An isolated metadata reproduction confirmed that identical persistent errors yield zero newly detected rows, and a non-throwing callback is marked `ok` by the unit wrapper. The October local log independently confirms the basis failures. Endpoint readiness and persistent required-dependency errors must be validated after a run, separately from the useful distinction between newly introduced and historical errors. Expected-infeasible units must remain explicitly classified rather than causing blanket rejection of unrelated successful resolutions.

### 3. Synthesis accepts stale results from blocked stores

`load_spatial_model_results()` checks the ANOVA/evaluation targets themselves but does not reject them because an upstream shared basis is errored or the unit failed its current execution. A read-only call on just the two blocked stores returned 18 component rows spanning six unit-resolution models. Those are September cached results, not successful October recovery.

The association plot would therefore include six blocked legacy model values if synthesis were rebuilt unchanged. Synthesis must exclude or fail explicitly on these incompatible results and preserve their availability/error provenance. Do not alter the September snapshot or replace unavailable models with zero.

Evidence: [stale_rows_accepted_by_synthesis.csv](stale_rows_accepted_by_synthesis.csv).

### 4. Two incomplete CV evaluations in `eu_r009_l002`

Genus and functional type in `eu_r009_l002` have converged final fitted models but use `selected_after_incomplete_unit_cv`, borrowing `candidate_004` from the local tier. Their cached prepared fold `repeat_002__fold_001` has `preparation_status = "preparation_error"` and the same MEM dimension error; this is not a non-converged GPU fit. The full unit can fit, but that training fold cannot supply the required MEM basis through the current engine. Its context records five training core locations and 102 training samples.

Both selected-candidate tables contain 15 records, one with that preparation error. Their CV evaluation artifacts are structurally valid but record zero held-out fold fits rather than pretending complete predictive evaluation. The artifacts retain September timestamps, while tuning evidence was refreshed in October. These two models may contribute fitted association estimates only with the missing predictive-validation status retained explicitly. They must not be counted among models with complete held-out evaluation. Audit and recovery must inspect per-fold preparation statuses, not just whether the prepared-fold target can be read.

Evidence: [selected_cv_evidence.csv](selected_cv_evidence.csv), [resolution_status.csv](resolution_status.csv).

## CV and tier evidence

All 229 available results have readable, valid selection/CV-evaluation envelopes and matching selected candidate IDs. Their CV and final fitting budgets in evaluation provenance match the respective cached fitting configurations. All 202 models using unit-specific CV have complete, successful, converged evidence for their chosen candidate. Of the 27 models borrowing tier regularization, 25 have complete held-out evaluation and the two `eu_r009_l002` models described above have none. This gives 227 complete held-out evaluations, not 229.

All three tier-tuning artifacts pass envelope, payload and content-hash validation and contain all three resolution selections. Selected-source counts are continental 3 genus / 2 family / 3 functional type, regional 15 / 13 / 14, and local 47 / 46 / 44. The two blocked local units are absent from the published local tier-selection source lists. Source counts describe complete contributing tuning evidence, not all final models eligible for borrowed regularization.

The common-regularization sensitivity artifact is valid and dated 11 October. It indexes Europe continental, `eu_r005` regional and `eu_r005_l014` local, each at the three resolutions. All nine recorded sensitivity fits have `fit_status = "ok"` and `cv_converged = TRUE`; their recorded CV budgets are 500 initial iterations, 2000 maximum iterations and sampling 200. This does not remove the unit-level failures above and is not a fresh final-model convergence test of every sensitivity model.

Evidence: [tier_selection_audit.csv](tier_selection_audit.csv), [common_sensitivity_provenance.csv](common_sensitivity_provenance.csv).

## Recommended next steps

1. Correct exact MEM zero-eigenvector handling and register the precise geometry limitation, with full-unit and fold-level regression coverage. If fitting without the requested MEM basis is desired, approve that scientific fallback separately.
2. Correct execution status capture so persistent required failures cannot be reported `ok`; preserve independent successful resolutions and registered expected infeasibility.
3. Protect synthesis against blocked stale artifacts and carry availability plus incomplete-CV status into plot-ready outputs.
4. Refresh only the affected two complete units and the two affected CV resolutions in `eu_r009_l002` through the normal preparation/fitting contracts. Preserve interpolation, successful models and unrelated stores. Revalidate calibration compatibility if prepared scientific inputs or representative selection actually change; do not force hash updates or restart all paleo calibration by default.
5. Re-audit those outcomes, then rebuild the paleo synthesis component and generate an October-dated association figure. Keep the regenerated September figure as its historical data snapshot.

No fixes or production reruns were performed by this audit. The active modern master remains running; implementation affecting its shared functions requires coordination at a safe execution boundary.

## Reproducibility and limits

[unit_status.csv](unit_status.csv) covers all 294 stores; [resolution_status.csv](resolution_status.csv) has exactly 882 rows; [selected_cv_evidence.csv](selected_cv_evidence.csv) has exactly 229 available-result rows. Target errors are checked without filtering on target timestamps, because failed targets can retain old or missing timestamps. Successful envelope/content-hash validation verifies the cached artifact's internal contract; it does not independently rerun every target cue against a fresh manifest. Diagnostic sjSDM attachment notices about Python packages did not execute GPU fitting and were not interpreted as production failures. The observed MEM failures were separately reproduced by the pure-R exact engine.
