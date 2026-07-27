# Cross-validation correctness reference metadata (v1)

**Recorded:** 2026-07-14
**Issue:** #139
**Reference base:** `a8ead627`

## Environment

- Platform: Windows, Europe/Prague execution context.
- R used for validation: 4.5.1 as resolved by the project launcher.
- Project dependency status: `renv` reported the project out of sync, while the library was synchronized with the lockfile. This warning is retained as environment metadata and was not changed by this slice.
- Existing long-running interactive R workers were left untouched.

## Regression reference

| Check | Reference result |
|---|---|
| Focused tier-source tests | 11 assertions passed across `test-collect_sjsdm_tuning_summaries.R` and `test-tier_tuning_pipeline_contract.R`. |
| Full test suite | `FAIL 0 | WARN 0 | SKIP 1 | PASS 3131`; the skip is the documented opt-in VegVault integration test. |
| External-store invalidation reproduction before correction | A stable external path changed from `first` to `second`, while the thoroughly-cued downstream target remained cached as `first`; `stale_cache_reproduced = TRUE`. |
| PR whitespace check | `git diff --check` reported no whitespace errors. |

## Repeated-origin stabilization

The next Issue #139 slice replaced the non-coprime y-origin multiplier with a deterministic reverse-order permutation.
Before correction, the four-repeat fixture produced only two distinct grid signatures.
After correction, the test matched the exact signatures for origin fractions `0`, `0.75`, `0.5`, and `0.25`; the focused test passed 10 assertions, and the full suite reported `FAIL 0 | WARN 0 | SKIP 1 | PASS 3132`.

## Direct regularization validation

The following Issue #139 slice added direct/final-fit upper-bound checks for `alpha_cov`, `alpha_coef`, and `alpha_spatial` while retaining finite non-negative lambda validation.
Before correction, all three invalid alpha calls reached the Python backend and failed with an unrelated `ZeroDivisionError`.
After correction, the focused fit test passed 52 assertions with parameter-specific R errors and explicit coverage of the inclusive zero/one alpha boundaries. The full suite reported `FAIL 0 | WARN 0 | SKIP 1 | PASS 3144`.

## Deterministic stochastic tuning scores

The CV-003 slice added separately hashed deterministic fit and score seeds for every repeat, fold, and candidate ID and retained both in fold-level tuning output. Joint likelihood scoring now restores the caller's R RNG and available PyTorch CPU/CUDA RNG states after applying the score seed.
Before correction, the new scorer test rejected the unknown `score_seed` argument and the runner lacked the provenance column and propagation path. After correction and review hardening, the focused scorer, fold-runner, and tuning-runner tests passed 20, 3, and 24 assertions. Coverage includes candidate-order independence, upper seed bounds, R restoration after normal and error paths, and PyTorch CPU determinism/restoration. The full suite reported `FAIL 0 | WARN 0 | SKIP 1 | PASS 3158`.

## Structured downstream tuning errors

The CV-013 slice injects prediction and scoring backend failures and asserts the exact fold-level schema, structured status/message, missing metric fields, retained fit/score seeds, and prediction-error short circuit. The red phase exposed that the direct fold helper returned the complete schema in a different column order from the public tuning runner; the helper now normalizes every success/error path to the public order. The focused fold and public-runner tests passed 16 and 24 assertions, and the full suite reported `FAIL 0 | WARN 0 | SKIP 1 | PASS 3171`.

## Fold-varying effective MEV provenance

The CV-011 slice accepts effective MEV counts that vary after fold-local rank clamping. Per-fold counts remain in the fold diagnostics; model provenance now records `n_effective_mev_min`, `n_effective_mev_max`, and an explicit status while retaining the legacy scalar only for constant-rank runs. Before correction, the varying-rank fixture aborted with `Selected folds must use one effective MEV count.` After correction and validation hardening, constant, varying, unavailable, and malformed-count cases passed 31 focused assertions, and the full suite reported `FAIL 0 | WARN 0 | SKIP 1 | PASS 3189`.

## Spatial runner failure policy

The CV-009 slice applies one explicit two-stage policy to all six spatial runners. Unit tuning-summary production remains fail-fast because tier selection requires complete evidence. Post-selection full-unit execution continues after individual failures and returns one row per requested unit with `ok`/`error` status and the captured error message. In the red phase, the helper stub produced four expected failures. After implementation and review hardening of forwarded-argument guards, the helper and six-runner source contract passed 23 focused assertions, all six runner files parsed successfully, and the full suite reported `FAIL 0 | WARN 0 | SKIP 1 | PASS 3212`.

## Cross-tier sensitivity readiness

The CV-010 slice preflights the configured continental, regional, and local representative store directories before a local runner starts the all-tier common-regularization sensitivity pipeline. A missing store now produces per-tier `ready`/`missing` evidence and an overall `skipped_missing_store` status instead of aborting after the local workflow has completed. Disabled profiles remain visible as `disabled`/`skipped_disabled` rows, including a valid all-disabled no-op. The isolated reproduction confirmed that `fs::dir_ls()` raises `ENOENT` for an absent tier root. The red phase produced four expected failures; after correction and review hardening, the helper and local-runner contract passed 16 focused assertions, both local runners parsed successfully, and the full suite reported `FAIL 0 | WARN 0 | SKIP 1 | PASS 3228`.

## Pooled tuning-loss estimand

The CV-012 slice defines `negative_log_likelihood_per_response` within each repeat and candidate as summed held-out negative log likelihood divided by summed held-out response values. This scientific disposition was explicitly approved after considering #138's possible fold/repeat simplification and #141's requirement to preserve the stabilized estimand. Before correction, unequal folds with 10 and 30 response values produced the equal-fold result `0.25`; after correction they produce the pooled result `0.275`. Repartitioning the same loss and response evidence from two folds into four retains `0.275`. The focused summary tests passed 17 assertions, and the full suite reported `FAIL 0 | WARN 0 | SKIP 1 | PASS 3231`.

## Project-owned decomposition CV documentation

The CV-017 slice replaces the stale `sjSDM::sjSDM_cv()` claim in `make_repeated_cv_indices()` with its actual project-owned consumer, `run_decomposition_route_cv()`, and adds an executable example. The red source-contract test produced two expected failures; after correction it passed five focused assertions, and the full suite reported `FAIL 0 | WARN 0 | SKIP 1 | PASS 3233`. Targeted HTML, TXT, PDF, and QMD documentation plus the published function page and search entry were regenerated. Extracted PDF text contains the project-owned consumer and no stale package-native reference; all three PDF pages were rendered and visually inspected without clipping, overlap, or illegible content.

## Generated CV documentation synchronization

The CV-005--CV-007 slice removes the generated artifacts and published pages for `run_predictive_ablation_cv()` and `apply_decomposition_scale_attributes()`, publishes the replacement `apply_scale_attributes()`, and rebuilds the full Quarto site so every embedded sidebar, search entry, listing, and sitemap reflects the current API. The red generated-documentation contract produced two expected failures and one pass; after regeneration it passed all three focused assertions. Inventory searches across raw function docs, function QMD, published function pages, search, listings, and sitemap returned zero matches for both deleted APIs. The full suite reported `FAIL 0 | WARN 0 | SKIP 1 | PASS 3236`.

The interpolation PDF build initially stopped before producing output because the two roxygen argument descriptions used a Unicode ellipsis. Replacing that glyph with the ASCII `...` retained the contract while allowing the PDF toolchain to complete. `interpolate_mev_to_grid.pdf` and `interpolate_st_mev_to_grid.pdf` each contain three pages; extracted text in both records optional scale attributes and the unscaled fallback. Every page was rendered at 2x resolution and visually inspected without clipping, overlap, broken glyphs, or illegible content.

## Function coverage evidence

The CV-014 closure slice regenerated `covr_report.html`, `covr_report.json`, and `covr_report_summary.json` from the stabilized function and test inventories. Both `run_predictive_ablation_cv` and `apply_decomposition_scale_attributes` have zero matches in the HTML and JSON reports. The replacement `apply_scale_attributes` and current tuning APIs, including `make_sjsdm_regularization_candidates` and `run_sjsdm_tuning_candidates`, are represented in both formats. The JSON report contains 4,261 coverage records, parses successfully, and reports 92.05% line coverage, up from the stale report's 89.59%. The full suite remained `FAIL 0 | WARN 0 | SKIP 1 | PASS 3236`.

## Accepted maintainability handoff

The remaining low-severity maintainability findings are explicitly accepted for [Issue #141](https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/141), after #138 selects and benchmarks the production execution design. CV-015 and CV-016 feed #141's target-building and responsibility-boundary slices; CV-019 feeds its generated-artifact/documentation cleanup; and CV-020 feeds its responsibility/ownership cleanup. Deferring these changes keeps #139's stabilized behavior fixed for #138. None is a correctness defect, public-contract gap, or unresolved high/medium finding.

## Manifest reference

The following manifests parsed successfully after the initial tier-source correction and contained no duplicate target names.

| Configuration | Pipeline | Target count |
|---|---|---:|
| `project_paleo_spatial_continental` | `pipeline_paleo_spatial_resolution.R` | 201 |
| `project_modern_spatial_continental` | `pipeline_modern_spatial_resolution.R` | 202 |
| `project_paleo_temporal_europe` | `pipeline_paleo_temporal.R` | 1676 |
| `project_paleo_spatial_continental` | `pipeline_sjsdm_tier_tuning.R` | 8 |
| `project_paleo_spatial_local` | `pipeline_sjsdm_common_regularization_sensitivity.R` | 12 |

## Fresh CZ correctness reference

The mandatory `R/03_Supplementary_analyses/Testing/Smoke/run_cz_pipelines.R` runner completed from fresh stores at `afca4e7969dc1a303fc590dc8c6147410968a5b9`. The unrelated single-chain R model in another project was left untouched. The runner rebuilt the following stores and every store reported zero errored targets:

| Store | Pipeline result | Metadata rows | Targets with warnings |
|---|---:|---:|---:|
| `Data/targets/cz_paleo/pipeline_paleo_core` | 199 completed, 42 skipped in 4m 4.5s | 504 | 15 |
| `Data/targets/cz_paleo/pipeline_paleo_resolution_test` | 302 completed, 42 skipped in 7m 2s | 608 | 21 |
| `Data/targets/cz_modern/eu_r005_l014/pipeline_modern_spatial_resolution_test` | 2,143 completed, 0 skipped in 31m 19.4s | 2,406 | 8 |

The warning counts are retained as execution metadata. They include expected model/runtime warnings; none was a target error. The runner also reported the existing `renv` out-of-sync state while confirming that the installed library was synchronized with the lockfile.

### Selection, OOF, and evaluation values

All seven units selected `candidate_001`, with `alpha_cov = alpha_coef = alpha_spatial = 0.5`, `lambda_cov = lambda_coef = lambda_spatial = 0`, `regularization_source = "unit_cv"`, and candidate-table hash `b1ec181e66cb1f650aadf945f81a4f52`. Each tuning summary used five successful folds out of five and had status `ok`. Each selected-fold diagnostic used fit seeds `1001724`, `1002724`, `1003724`, `1004724`, and `1005724`; all 35 fits had status `ok` and a constant effective MEV count of three.

| Unit | Pooled NLL/response | Tuning AUC | OOF rows (`ok`; constant) | CV Tjur R2 | CV AUC | CV log loss | Evaluable taxa |
|---|---:|---:|---:|---:|---:|---:|---:|
| Paleo core, genus | 0.372794719882305 | 0.662205197009247 | 3,280 (3,154; 126) | 0.0822344302346783 | 0.584032815911536 | 0.709862222843946 | 13 |
| Paleo resolution, family | 0.371306411530498 | 0.728270231977899 | 1,845 (1,435; 410) | 0.061437454146472 | 0.599024464483106 | 0.533153292955781 | 7 |
| Paleo resolution, functional type | 0.339961223868591 | 0.715334310569551 | 1,640 (1,146; 494) | 0.142172007517578 | 0.694161845651381 | 0.673215889104419 | 4 |
| Paleo resolution, genus | 0.372794719882305 | 0.662205197009247 | 3,280 (3,154; 126) | 0.0822344302346783 | 0.584032815911536 | 0.709862222843946 | 13 |
| Modern resolution, family | 0.269548240774910 | 0.676424827975462 | 78,120 (78,120; 0) | 0.0348487214431627 | 0.678855584138029 | 0.387926020471409 | 42 |
| Modern resolution, functional type | 0.307747827656280 | 0.652368233709273 | 9,465 (9,086; 379) | 0.0714288561540667 | 0.649644455402221 | 0.401579070433793 | 4 |
| Modern resolution, genus | 0.201868481361653 | 0.688366184910107 | 169,260 (169,260; 0) | 0.0244397935445291 | 0.682972129949325 | 0.321386179863504 | 91 |

`constant_in_training` OOF rows intentionally contain missing probabilities and are excluded from the evaluable-taxon summaries. All non-missing probabilities were within the asserted probability bounds. The fitted-model McFadden/Nagelkerke R2 references are, respectively: paleo genus `0.275477842757313`/`0.930932655793091`; paleo family `0.201289823833747`/`0.624092691349606`; paleo functional type `0.233779236151304`/`0.628291238106094`; modern family `0.230356335033106`/`0.998691852594157`; modern functional type `0.141903066162187`/`0.383288634847381`; and modern genus `0.299187419285322`/`0.999999767927401`.

### Provenance reference

Every unit recorded `selection_status = "selected"`, `cv_strategy = "spatially_stratified_group_kfold"`, `cv_feasibility_status = "grouped_kfold_feasible"`, one repeat, five successful fold fits, and `effective_mev_status = "constant_across_folds"`. Unit-specific dimensions were:

| Unit | Locations | Samples | Taxa | Minimum taxa retained per fold |
|---|---:|---:|---:|---:|
| Paleo genus | 27 | 205 | 15 | 14 |
| Paleo family | 27 | 205 | 6 | 7 |
| Paleo functional type | 27 | 205 | 6 | 5 |
| Modern family | 1,860 | 1,860 | 42 | 42 |
| Modern functional type | 1,893 | 1,893 | 5 | 4 |
| Modern genus | 1,860 | 1,860 | 91 | 91 |

The family provenance reports six response taxa while seven taxa can be retained in a fold because fold-local filtering and the final fitted-model response inventory are deliberately separate provenance concepts.

### Artifact hashes

The values below are `targets` data hashes. The paleo core genus and paleo resolution genus artifacts are identical where their scientific content is identical. `data_sjsdm_tier_regularization_artifact*` has hash `d60541852a9ce986` and value `NULL` in every unit: this is the expected pre-tier sentinel because these CZ unit pipelines select from unit CV rather than consume a pooled tier artifact.

| Unit | Tuning summary | Selected candidate | OOF predictions | OOF diagnostics | Provenance | CV evaluation | Fitted evaluation |
|---|---|---|---|---|---|---|---|
| Paleo core, genus | `73ba417c63322763` | `e08d7a665e80fb58` | `88a9a4f6749d4a5e` | `07c928b76744b3a0` | `5f0dcaaf038c9a7d` | `ae74e61f9a853be5` | `0ee206fbbf217ba6` |
| Paleo resolution, family | `76c5c6ef0cddba8b` | `00fa954be5fafcd2` | `9eb16ee8ef3e3853` | `ae33229bd3a58ab4` | `eecbef50e84e9c2a` | `1ed5f60395f8d86d` | `d3d15d82c41bb4c3` |
| Paleo resolution, functional type | `a455cad35bee9135` | `8a07d5008269db9e` | `a3d0da351a5d985f` | `af387ff19d4b7711` | `ca2b4d2e6c8dc12a` | `1982f76d0d406334` | `522009a6c236b9c2` |
| Paleo resolution, genus | `73ba417c63322763` | `e08d7a665e80fb58` | `88a9a4f6749d4a5e` | `07c928b76744b3a0` | `5f0dcaaf038c9a7d` | `ae74e61f9a853be5` | `ab250c21722224fb` |
| Modern resolution, family | `ed0949fa105fede3` | `d179a21cdc4ae902` | `16cecf1c2bb3995f` | `fc960498121655b0` | `c63003c886b72af2` | `16c2f1b27b9d2cb5` | `5d623d49baecb719` |
| Modern resolution, functional type | `9f2c4af3d0c03a3a` | `0c73918e53b9ae34` | `e87786981d154b06` | `0af55dacabd1c465` | `23a6e25238baab1c` | `6164cc2b4429f398` | `489ea22ce5429b39` |
| Modern resolution, genus | `abf84ab85d102927` | `49881f47561e6b39` | `c5da146959add926` | `22432f55f38cb514` | `7d890613c39753e3` | `922ea46f6c789ae5` | `0a53446e25643f39` |

### Schema and comparison contract

The fresh artifacts matched the v1 contract inventory. Exact column order is part of the structural reference:

- Tuning summary: `repeat_id`, `candidate_id`, six regularization parameters, `n_folds_total`, `n_folds_successful`, `n_response_values`, `negative_log_likelihood_test`, `negative_log_likelihood_per_response`, `auc_macro_test`, `summary_status`, `cv_strategy`, `regularization_source`, `source_id`, `tier_id`, `taxonomic_resolution`, `response_family`, `predictor_structure`, `candidate_table_hash`.
- Selected candidate: `candidate_id`, six regularization parameters, `selection_metric`, `selection_metric_value`, `n_repeats`, `candidate_rank`, `cv_strategy`, `regularization_source`.
- OOF predictions: `repeat_id`, `fold_id`, `row_index`, `location_id`, `dataset_name`, `age`, `taxon`, `observed`, `predicted_probability`, `null_probability`, `prediction_status`.
- OOF diagnostics: `repeat_id`, `fold_id`, `candidate_id`, `fit_seed`, `n_train_samples`, `n_test_samples`, `n_taxa_retained`, `n_effective_mev`, `fit_status`, `error_message`, `cv_strategy`, `regularization_source`.
- Model provenance: the original reference contained 24 fields ending with `effective_mev_status`. The current additive contract appends `fit_device`, `evaluation_prediction_source`, `evaluation_estimand`, `evaluation_aggregation_methods`, and `evaluation_schema_version`. The 29-column extension preserves the historical field order and ends with schema version `sjsdm_fold_local_cv_v1`.
- CV evaluation: taxon metrics use `repeat_id`, `taxon`, `metric_id`, `estimate`, `metric_status`, `n_observations`, `n_presences`, `n_absences`, `prevalence`; community summaries use `repeat_id`, `metric_id`, `summary_statistic`, `estimate`, `n_taxa_evaluable`, `metric_status`.

Future comparisons must match target presence, schema and column order, candidate ID and parameters, categorical statuses, seeds, row counts, and provenance counts exactly. Hash equality is the strongest same-environment check but is not required across supported runtime changes. For row-aligned numeric comparisons, use maximum absolute tolerance `1e-4` for OOF/null probabilities, pooled NLL per response, tuning/CV AUC, Tjur R2, log loss, and fitted R2. Missing-value positions must match exactly. Any candidate-selection change, status change, structural mismatch, or value outside tolerance requires scientific review rather than automatic acceptance.

## Dedicated real-CV reference

The production-like CZ paleo reference run is recorded separately in [`cz_paleo_cv_reference_v1.md`](cz_paleo_cv_reference_v1.md). It used three assignment repeats and eight regularization candidates in an isolated store. All 120 tuning fits and all 15 selected-candidate refits succeeded; fully regularized `candidate_008` reduced mean held-out NLL/response from `0.384313689888821` to `0.306641469176137`. Mean OOF log loss was `0.367094477482017`, improving on the fold-prevalence null by `0.0220725980703752`, while mean Tjur R2 remained low at `0.0288530573204427`. The report retains exact repeat-level metrics, null comparisons, convergence evidence, provenance, schemas, hashes, execution interruption/resume evidence, and scientific limitations.

The isolated GPU rerun and comparison are recorded in
[`cz_paleo_cpu_gpu_reference_comparison_v1.md`](cz_paleo_cpu_gpu_reference_comparison_v1.md).
CPU and GPU selected the same regularization candidate and produced identical
OOF keys, seeds, fold statuses, and diagnostics. Proper scoring losses and the
fold-local Tjur R2 conclusion were stable, although elementwise probabilities,
AUC, and unstable calibration slopes did not meet strict `1e-4` numerical
parity. The historical CPU store remains unchanged.

A subsequent fresh GPU reference verified the additive provenance extension.
The one-row artifact recorded `gpu`, `out_of_fold`, `repeat_fold_taxon`,
`fold_macro;observation_weighted`, and `sjsdm_fold_local_cv_v1` in the five new
columns. All 120 tuning fits and all 15 selected-candidate fold refits succeeded,
the store contained zero target errors, and the provenance data hash was
`19cffe27d6c58bde`.

The mandatory fresh CZ gate then verified the same 29-column contract across
all seven direct and resolution units. Every row recorded the expected five
values, and all three stores had zero errors and zero incomplete targets. The
fresh provenance hashes were `0abfbcbf3c16ebb7` for paleo core/genus,
`434559507b4415f4` for paleo family, `464cbb1f501ac889` for paleo functional
type, `329cbbabb07d24b2` for modern family, `5abc60fd2eb43667` for modern genus,
and `d136f2f1cc74c502` for modern functional type.

The Phase 4 taxon-level interpretation is recorded in
[`cz_paleo_taxon_eligibility_diagnostic_v1.md`](cz_paleo_taxon_eligibility_diagnostic_v1.md).
The GPU artifact contains 159 evaluable fold-taxon Tjur estimates; 116 are
positive, but only 30 reach `0.1`. Carpinus and Fagus are the only taxa whose
mean exceeds the provisional threshold, while Pinus, Alnus, and Picea have no
evaluable model discrimination estimates because constant training responses
make their predictions unavailable. The evidence is classified as a technical
CV pass and a provisional scientific-prediction failure.

The controlled predictor-component comparison is recorded in
[`cz_paleo_predictor_component_diagnostic_v1.md`](cz_paleo_predictor_component_diagnostic_v1.md).
All 45 new GPU fold fits succeeded on identical assignments and seeds. Mean
fold-macro Tjur R2 was `0` for intercept-only, `0.0251` for spatial-only,
`0.0308` for abiotic-only, and `0.0526` for the full model. The full model
improved every primary metric over both reduced predictor models in all three
repeats. Both predictor blocks contain complementary signal, but the full model
continues to fail the working `0.1` scientific gate.

The component implementation passed 49 focused assertions, the full suite with
3,430 passes and the single opt-in integration skip, and a fresh mandatory CZ
gate with exit code 0. Direct metadata checks found zero errors in the paleo
core, paleo resolution, and modern resolution stores.

The Phase 5 structured regularization experiment is recorded in
[`cz_paleo_structured_regularization_diagnostic_v1.md`](cz_paleo_structured_regularization_diagnostic_v1.md).
The isolated GPU pipeline completed all 240 tuning fits and all 15 independent
selected-candidate refits. Covariance lambda `0.01` minimized mean tuning NLL at
`0.305712`, compared with `0.306926` for the `(0.1, 0.1, 0.1)` reference, but
the improvement reversed in one of three repeats. The independently refitted
candidate was worse than the reference on fold-macro AUC (`0.643` versus
`0.661`), Tjur R2 (`0.0408` versus `0.0526`), log loss (`0.324` versus `0.308`),
and Brier score (`0.0913` versus `0.0891`). The result is retained as evidence
that regularization alone does not resolve the CZ scientific-performance
failure; it does not change the accepted reference candidate.

The structured-search contract passed 15 focused assertions and the full suite
passed 3,460 assertions with no failures or warnings and one expected opt-in
integration skip. The mandatory fresh CZ gate completed with exit code 0 in 56
minutes 37 seconds. Metadata contained zero errors across 515 paleo-core rows,
625 paleo-resolution rows, 2,423 modern-resolution rows, and 288 isolated
structured-search rows.

The Phase 5 acceptance and sparse-taxon sensitivity are recorded in
[`cz_paleo_selection_guardrail_diagnostic_v1.md`](cz_paleo_selection_guardrail_diagnostic_v1.md).
The declared eligibility rule retained nine of 16 taxa. Their original-reference
fold-macro Tjur R2 was `0.068596`, compared with `0.052599` across all taxa and
the provisional scientific gate of `0.1`. The structured-search winner was
rejected in both scopes because tuning NLL improved in only two of three
repeats, every independent refit comparison deteriorated, and candidate Tjur
R2 remained `0.040832` across all taxa and `0.053210` for eligible taxa. The
incremental pipeline built the new evidence without new model fits and exited
successfully with 20 targets completed and 12 skipped.

The guardrail implementation passed 37 focused assertions and the full suite
passed 3,482 assertions with no failures or warnings and one expected opt-in
integration skip. The mandatory fresh CZ gate completed with exit code 0 in 43
minutes 32 seconds. Metadata contained zero errors across 517 paleo-core rows,
627 paleo-resolution rows, 2,425 modern-resolution rows, and 300 isolated
regularization-diagnostic rows. A final incremental refresh completed 13
targets, skipped 19 cached targets, and preserved all three diagnostic hashes.

## Versioned scientific-performance decision

Policy `sjsdm_scientific_performance_v1` makes the scientific-reference
decision executable rather than leaving it as report prose. It separates
technical CV validity, held-out predictive skill, and calibration. Required
scientific evidence includes all- and eligible-taxon mean Tjur R2 of at least
`0.1`, AUC above `0.5` in every repeat, positive log-loss and Brier improvement
in every repeat, at least 80% positive taxa, and at least 80% fold-taxon
evaluability. Tjur R2 is explicitly not interpreted as percent variance
explained.

The `eu_r005_l010` reference passes all nine technical/scientific criteria.
Its minimum repeat AUC is `0.777`, minimum log-loss improvement is `0.0826`,
minimum Brier improvement is `0.0336`, positive-taxon fraction is `0.947`, and
minimum repeat Tjur evaluability is `0.840`. The executable statuses are
`technical_cv_status = pass`, `scientific_prediction_status = pass`, and
`calibration_status = caution`. The policy, assessment, criteria, and decision
hashes are `c6829cc0c376ba58`, `6d70ba767d55d5c0`, `ad00fab32fcdb3d0`, and
`b85a1b2e4eb42af5`, respectively. The deterministic GPU prediction artifact
reproduced hash `58dfb9ed9d89f853`, and the store contains zero target errors.
