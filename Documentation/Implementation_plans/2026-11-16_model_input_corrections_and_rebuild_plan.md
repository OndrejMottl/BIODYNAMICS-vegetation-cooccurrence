# Model input corrections and rebuild plan

Issues: [#181], [#203], [#204], [#205], [#206], [#207], [#208] (all part of [#180]). Sequence (updated 25 Nov 2026):

1. **A** (merged in [#214]).
2. **V**: move to VegVault 2.0.0 and vaultkeepr 0.2.0.
3. The code and diagnostics of **C**, alongside the functional-type classification of [#179].
4. The full rebuild of **B**.

Each stage starts only after the previous one is merged into `main`.

## Decisions

- **One full rebuild from a corrected VegVault (16-17 Nov 2026).** VegVault 1.0.0 stores `bio4` as 0 at age 0 for 94 % of gridpoints (south of 65.6 degrees N; [VegVault#78]) and has trait unit errors ([VegVault#76]). Both are corrected at the source, in a new VegVault release expected around 30 Nov 2026, not patched in this pipeline. The new release changes the extracted data of every store, so Stage B rebuilds everything once instead of rerunning selected targets. This also clears the [#178] drift of the spatial stores, every penalised partition ([#203]) and every American and Asian projection ([#204]) without separate reruns.
- **Ledger.** The freshness ledger stays in place for targets left outdated on purpose, but after the full rebuild it should be empty.
- **Projection ([#204]):** chosen per continent by measured distortion. Europe keeps EPSG:3035 exactly.
- **Plot filter ([#205]):** plots get their own relative-abundance threshold. The value is chosen by Ondřej from the stage C diagnostics. Stage C's code and diagnostics run before the Stage B rebuild, so the 275 modern models are fitted once, with the new threshold.
- **The corrected release is VegVault 2.0.0 (25 Nov 2026).** It is built and accepted but not yet published, and comes with vaultkeepr 0.2.0. It is a major release, with a new schema, renumbered ids, trait units standardised at the source and corrected taxonomy, so it does not drop in under the old path. The new Stage V makes the repository changes it needs.
- **Traits (25 Nov 2026).** Retire the VegVault 1.0.0 trait corrections, regenerate the review queues on 2.0.0 and sort them automatically first; Ondřej decides only what the automated sorting cannot settle. The design that stops with an error on changed input stays.
- **Functional types (25 Nov 2026).** Stage B waits for an adoption decision in [#179], so that the functional-type models are fitted once. [#202] is not added to the rebuild. The Stage V plan proposes a decision checkpoint, after which Stage B uses the current classification.

## Rules for every stage

- Read `AGENTS.md` and the `.ai/` files it routes to before editing. All new names follow `Documentation/Implementation_inventories/R_architecture/r_naming_decisions_v1.md`.
- Run R with `rig run -r 4.5.1 ...` from the repository root. Do not run `renv::restore()`, `renv::snapshot()`, `sjSDM::install_sjSDM()` or pip/uv.
- No `git add`, commit, push or merge, and no issue or PR comments, unless Ondřej asks for that operation by name. Draft issue comments as text for him.
- **Invalidation hazard.** Every pipeline `tar_source()`s all of `R/Functions/` and there is no `tar_cue(depend = FALSE)`. Editing a shared function's body therefore invalidates every target that calls it, in every store. Downstream targets rerun only if the output hash changes. Never change the shape of `config_model_fitting` (passed whole to folds and fits) or `config_data_processing` (feeds the fossil interpolation). Never add locals to `build_jsdm_environment_formula()`: its formula stores the function environment, so new locals would invalidate `mod_jsdm` and all CV tuning in every paleo store.
- **Production stores.** Never run a production store's pipeline in stages A or C; use copies under `Data/Temp/`. Production stores are rebuilt only in Stage B.
- **Finishing a stage.** Run `generate_r_architecture_inventories.R`, `Document_functions.R`, `check_r_architecture.R`, `Generate_configuration.R` and `Check_configuration.R`. Then run the full suite with `R/03_Supplementary_analyses/Testing/Run_tests.R`. Report results, anything not verified, and the proposed commits.

## Stage A: code corrections ([#208], [#206], [#203], [#181], [#204])

Detailed implementation plan: [2026-11-16_stage_a_model_input_corrections.md](2026-11-16_stage_a_model_input_corrections.md).

**Status (17 Nov 2026):** implemented on branch `model-input-corrections`. Evidence and deviations are in `Documentation/Reports/Model_evaluation/stage_a_model_input_corrections_2026-11/`. Europe and America 0 ka still stop on the constant `bio4` predictor; the corrected VegVault release resolves this. The steps below are kept as the record of what Stage A set out to do.

**Start:** `rerun-project-docs` has been merged into `main`. Create branch `model-input-corrections` from `main` and work in the main checkout. Commit order (one commit per step): 1 to 6.

1. **[#208]: store-freshness validator and provenance.**
   - **Validator.** Add a workflow folder `R/03_Supplementary_analyses/Validation/Model_stores/`. Its README needs the 5 required headings and must be registered in `vec_workflow_readme_paths` in `check_r_architecture.R`. Put the functions under `R/Functions/Pipeline/Stores/`, with mirrored tests.
   - **Discovery and checking.** Find stores with `build_spatial_model_store_index()`, `resolve_pipeline_store_path()` and profile `target_store`. Use the `tar_outdated()` pattern from `validate_sjsdm_cv_preparation_freshness.R`.
   - **Ledger.** A CSV with columns: store, target pattern, reason, evidence, owner, expiry issue. The validator fails on any outdated target not covered by the ledger, and on stale ledger rows.
   - **Spatial provenance.** `load_spatial_model_results()` gains two columns: the final-model build date (`tar_meta` time of `mod_jsdm_selected_<res>`) and the partition build date.
   - **Temporal provenance.** In `04_analyse_paleo_temporal_patterns.R`, replace `model_anova_*` with `list_jsdm_variance_partition_*`. Add `cv_strategy`, `regularization_source`, `candidate_id` and both dates from `data_sjsdm_cv_model_provenance_timeslice_*`.
   - **Documentation.** Add the validator to `Documentation/Materials/main_analysis_workflow_guide.md` as a required check before republishing.
   - **Smoke check.** The validator flags the current temporal stores and passes on an up-to-date spatial store.
2. **[#206]: drop age terms for single-age input.**
   - In `build_jsdm_environment_formula.R:52`, extend the existing `is_age_present` expression with a single-age check (for example `dplyr::n_distinct(data[["age"]]) > 1L`). Add no new locals.
   - Set `use_age_in_formula: false` in the three profiles of `Configuration/Profiles/Main/Paleo/temporal.yml`.
   - Test: single-age input gives no age terms; the multi-age cases are unchanged.
3. **[#203]: carry the association penalty into the partition sub-models.**
   - First read `body(sjSDM:::anova.sjSDM)`, `body(sjSDM:::update.sjSDM)` and `str(mod$settings)` at runtime (sjSDM ships compiled R code).
   - Keep the name and pipe command of `compute_jsdm_variance_partition()`. Its body fits the same sub-models with `bioticStruct(diag, lambda = lambda_cov, alpha = alpha_cov)` and the model seed, and returns the same `sjSDManova` layout (`results`, `N`, `lls`, `species`).
   - Route `compute_jsdm_variance_partition_with_progress()` through the same routine and update its digest guard.
   - Tests: the sub-models receive `lambda` and `alpha`; with `lambda_cov = 0` the result matches `sjSDM:::anova.sjSDM()` within Monte Carlo tolerance.
   - Pilot on copies of about 5 penalised models across tiers: published versus new shares, the three-way fraction, and runtime. Draft the [#203] comment.
   - Add a `shortcut` pass-through to `run_pipeline()`.
4. **[#181]: temporal slice failures.**
   - **Slice window.** Add a new temporal-only key for the modelled-slice window: Europe 0–17500, America 0–19500, Asia 0–10500. Do not reuse `vegvault_data.age_lim`, which feeds the 8.5 h interpolation. Use the window in `pipeline_paleo_temporal.R:123-133` and `pipeline_sjsdm_tier_tuning.R:80-92`. Stage 04 labels slices outside the window `outside_window`.
   - **Cascade classification.** Extend the temporal cascade rules in `classify_sjsdm_unit_pipeline_error.R:137-167` to cover `data_spatial_mev_samples_*`, `data_spatial_scaled_list`, `data_model_input`, `mod_jsdm*` and `list_jsdm_variance_partition*` when the root cause is `insufficient_samples`. Leave the shared pipe segments untouched.
   - **Tuning with infeasible slices.** In `run_sjsdm_tuning_sequence.R:267-279`, accept `expected_infeasible` slices and tune only feasible ones. `load_sjsdm_tuning_summaries.R` skips them.
   - **Runner status.** Runners 07–09 write a status CSV, as `02_fit_paleo_spatial_regional.R` does.
   - **0 ka `ZeroDivisionError`.** Follow `.ai/debugging.md`. First rebuild Europe 0 ka on a store copy with the current code. If the error persists, write an MRE in `Data/Temp/debug_zero_division_timeslice_0.R` and test the candidate causes one at a time. Apply the minimal fix with a comment, plus a regression test.
5. **[#204]: region-appropriate projection.**
   - **Choose the projection.** Run a distortion script with the 9 Nov method on Albers equal-area (ESRI:102008 / 102025), and on Lambert azimuthal equal-area and azimuthal equidistant centred per continent. Pick the narrowest 5–95 % range and draft the [#204] comment.
   - **Configuration.** Add a per-continent CRS map in a key that `config_model_fitting` does not copy, with `europe: 3035`. Give each temporal profile a continent id. Leave `model_fitting.spatial_crs` unchanged and mark it superseded (removed at the full rerun).
   - **Resolver.** A new function resolves the CRS. Spatial units use `resolve_scale_id_from_store()` then `resolve_continent_ids_from_scale_ids()`; temporal units use the profile's continent id. It aborts when a continent has no entry.
   - **Projection target.** `data_coords_projected` uses the resolver. European output must stay byte-identical. `Predict_on_full_grid.R` also switches to the resolver.
   - **Configuration generator.**
     - Update the semantic reference `.rds`.
     - Add a rule after the fold-ladder check (`run_configuration_generation.R:908-927`): every `continent_id` in `spatial_grid.csv` has an entry, and no entry outside Europe is 3035.
     - Regenerate `config.yml`.
   - **MEM diagnostic.** Fix the R² < 0.99 threshold in the script before running it. For each North American and northern Asian unit (fossil and modern, all resolutions), regress the new MEMs on the stored MEMs and record the minimum R². Output the table and the refit list.
6. **Invalidation audit.**
   - Copy these stores to `Data/Temp/store_audit/`: Europe fossil continental and one local, one North American fossil local, one European modern, and one tier-tuning store.
   - Rebuild only `config_*`, `formula_jsdm_environment_*`, `data_sample_ids_checked*` and `data_coords_projected`, then run the step 1 validator.
   - Expected result:
     - European stores: only the partition targets outdated.
     - North American store: the coordinate chain plus the partition.
     - Tier-tuning store: unchanged.
   - Anything else: stop and report.

**Done:** all checks green, the CZ smoke run (`run_cz_pipelines.R`) passes, the audit matches expectations, and the pilot, distortion and MEM tables are drafted. PR relationships: Part of [#181], [#203], [#204], [#207], [#208]; Closes [#206].

## Stage V: VegVault 2.0.0 and vaultkeepr 0.2.0

Detailed implementation plan: [2026-11-25_vegvault_2_migration_plan.md](2026-11-25_vegvault_2_migration_plan.md).

**Start:** A is merged. Ondřej has put the 2.0.0 database in `Data/Input/VegVault.sqlite` (the 1.0.0 file is kept as `Data/Input/VegVault_1.0.0.sqlite`) and has installed vaultkeepr 0.2.0 through renv. Stage V builds no production store.

1. Make the database version a `{targets}` dependency (`config_vegvault_release`), so that a database change outdates the extraction targets and the store validator reports it.
2. Confirm the extraction functions on vaultkeepr 0.2.0, and time the continental trait extraction.
3. Retire the 1.0.0 trait corrections into a version-specific folder and check that each 1.0.0 source rule is fixed at the source. Then sort the 2.0.0 review queues automatically, with Ondřej's decisions on the rest, and build the 2.0.0 trait analysis release.
4. Classify the new taxon names and VegVault's combined pollen types in the auxiliary table.
5. Compare 1.0.0 and 2.0.0 for the project windows. This includes the `bio4` and `bio12` checks that Stage B step 1 previously held, and the Asia 0 ka sample count.
6. Update the input and trait-correction documentation.

**Done:** all checks green; the CZ smoke run and the trait reference pipeline, through to the release, pass on 2.0.0; no 1.0.0 source rule remains unfixed; the comparison tables are drafted. PR relationships: Part of [#180].

## Stage C: relative-abundance threshold for vegetation plots ([#205])

**Start:** V is merged, so the 2.0.0 database is in `Data/Input/VegVault.sqlite`; the diagnostics read its plot data. Work in a worktree or the main checkout; Stage C builds no production store. Stage C runs alongside [#179]. The modern viability check of [#179] uses the threshold Ondřej sets here.

1. **Relative abundance.** Add a modern-only target in `pipe_segment_community_prepare_modern.R` that converts each plot to relative abundance. Place it after colocated aggregation and before the Plantae filter, mirroring `prepare_community_proportions()` for pollen.
2. **Threshold key.** Add `minimal_relative_abundance_plots`, read by a modern-only config target and not added to `config_data_processing`.
   - `make_community_filter_targets()` gains an argument whose default reproduces the current fossil command text exactly.
   - The modern functional-type group-count selection uses the new threshold.
3. **Placement check.** `check_r_architecture.R:768-819` blocks new Community function files. Resolve this through the naming-decisions document, either with a ledgered exception or a rule change. Do not bypass it silently.
4. **Diagnostics.** Per continent, at 0.001, 0.0025, 0.005 and 0.01, report: records and plots removed, taxa lost after the core and sample filters, and matrix size. Stop there: Ondřej sets the value before Stage B starts.

**Done:** unit tests pass for cover and count sources, `tar_outdated()` on a fossil store copy shows nothing outdated by C's edits, and the diagnostics table is drafted for [#205]. PR relationships: Part of [#205].

## Stage B: full rebuild from the corrected VegVault and republication ([#207], and the rebuild parts of [#181], [#203], [#204], [#205], [#208])

**Start:**

- A, V and C are merged, and Ondřej has set the plot threshold.
- [#179] has an adoption decision, or its decision checkpoint has passed.
- The 2.0.0 database is in `Data/Input/VegVault.sqlite`.

Create branch `full-rebuild-corrected-vegvault` from `main` and run in the main checkout.

1. **Check the release (read-only).** Stop and report if any check fails.
   - Record the VegVault version, its SHA-256 and the vaultkeepr version, from `config_vegvault_release` and `renv.lock`.
   - The `bio4` and `bio12` checks and the comparison of the trait corrections were done in Stage V (comparison tables and the source-rule retirement check). Confirm that the database has not changed since: same SHA-256, and `config_vegvault_release` is not reported as changed.
   - The `bio12` cap at 6553.5 mm remains in 2.0.0. VegVault documents it as a lower bound ("at least 6553.5 mm").
2. **Decisions before the rebuild (Ondřej).**
   - Whether to keep a copy of the October stores for a before/after comparison of the published results. The rebuild overwrites them.
   - Whether to rerun the Stage 02 calibration on the corrected data or keep the calibrated settings.
3. **Remove the temporary 0 ka exclusions.** On 23 November 2026 the Europe and America temporal profiles got `temporal_slices.excluded_ages: c(0)` for an early cross-validated refit of their production stores for the BES 2026 talk (an exception to the production-store rule approved by Ondřej). Only the Stage 01 fold preparation ran; both fit runners stopped because the Stage 02 calibration no longer matches the configuration, and Ondřej chose to leave calibration and the temporal refit to this stage. No model was refitted; the June fits are also archived in `Data/targets/_archive/2026-11-23_june_temporal_fits/`. Remove both exclusions and their `configuration_reference_changes.csv` rows through the configuration reference update before rebuilding.
4. **Rebuild.** Run the main workflow in the order of `Documentation/Materials/main_analysis_workflow_guide.md`: the trait reference and functional-type classifications, Stage 01 preparation, tier tuning, every spatial tier (fossil and modern), the temporal runners 07-09 and the common-regularisation sensitivity. The recorded compute of the published spatial units alone is about 140 h (63 h fossil, 80 h modern; `refit_cost_by_unit.csv`), without tier tuning, temporal stores, sensitivity and the trait reference.
5. **Checks after the rebuild.**
   - `Validate_model_stores.R` passes on every store with an empty ledger.
   - Europe and America 0 ka are fitted. Asia 0 ka stays excluded (one sample) unless the release adds samples; then remove the exclusion through the configuration reference update.
   - Stage 04 shows no `unexpected_error` slice.
   - `bio4` varies continuously in the modern European and Asian stores.
6. **Republish.**
   - Stage 04 components 01-04 and the Stage 05 tables.
   - Temporal network metrics and residual association matrices.
   - Temporal similarity and half-life, using the [#183] engine.
7. **Documentation.** Correct the calibration statements in `Documentation/Reports/Third_report/_Project_status_and_direction.qmd`. Add a new dated publication-products README next to `publication_products_2026-10-22/` that records the VegVault version.

**Done:** the validator passes with an empty ledger, and every published table has provenance columns and build dates. PR relationships: Closes [#181], [#203], [#204], [#205], [#207], [#208].

### Additions from Stage V (25 Nov 2026)

- **Before the rebuild.**
  - Re-pin vaultkeepr to the `v0.2.0` tag, and confirm that its `R/` code is unchanged from the commit used in Stage V.
  - The functional-type classifications use the outcome of [#179].
- **Temporary 0 ka exclusions.** The Europe and America ones exist only on the branch `bes-2026-presentation`. If that branch is merged before the rebuild, remove them as its version of this plan describes. The Asia exclusion stays unless the Stage V comparison finds at least 10 samples at 0 ka.
- **Further decisions before the rebuild (Ondřej).**
  - When to delete `Data/Input/VegVault_1.0.0.sqlite` (102 GiB). It is needed until the published results have been compared with the rebuilt ones.
  - Whether the four trait sensitivity variants still run. Their reason, the provisional units of VegVault 1.0.0, no longer applies.
- **Publication products.** The publication-products README records the VegVault DOI and the vaultkeepr version, as well as the VegVault version.

<!-- Issue and pull-request links -->

[#178]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/pull/178
[#179]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/179
[#180]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/180
[#181]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/181
[#183]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/183
[#202]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/202
[#203]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/203
[#204]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/204
[#205]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/205
[#206]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/206
[#207]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/207
[#208]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/208
[#214]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/pull/214
[VegVault#76]: https://github.com/OndrejMottl/VegVault/issues/76
[VegVault#78]: https://github.com/OndrejMottl/VegVault/issues/78
