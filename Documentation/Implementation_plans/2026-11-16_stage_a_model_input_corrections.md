# Stage A implementation plan: model input corrections

## Context

Stage A of the model input corrections and rebuild plan (`2026-11-16_model_input_corrections_and_rebuild_plan.md`) fixes the code behind [#208], [#206], [#203], [#181] and [#204] without rerunning any production model. Stage B then reruns only what Stage A invalidates. That only works if Stage A changes exactly the targets it means to. This plan sets out the edits, the guards that keep spatial stores intact, and the evidence Stage B needs (pilot, distortion, MEM tables, audit).

Facts found in the code that shape this plan:

- `targets` invalidates a target when the body of any function it calls changes. Functions edited here that sit in target commands: `build_jsdm_environment_formula()` (all formula targets), `compute_jsdm_variance_partition()` (all partition targets), `project_coords_to_metric()` (all `data_coords_projected`), and `compute_jsdm_variance_partition_with_progress()` (the default `anova_function` of `run_sjsdm_common_regularization_sensitivity()`, so the sensitivity stores' decomposition targets).
- `load_sjsdm_tuning_summaries()` is called by the tier-tuning target `data_sjsdm_tier_tuning_summaries` (`pipeline_sjsdm_tier_tuning.R:194-205`). Its existing `sjsdm_tier_unit_requests.csv` mechanism (`load_sjsdm_tuning_summaries.R:111-145`) can already restrict a store to listed targets, so step 4 does not need to edit it.
- `data_coords_projected` reads its CRS from `config_spatial_predictors` (`pipe_segment_model_spatial_shared.R:43-76`), which also feeds the MEM targets. Its shape must not change either.
- The semantic reference `configuration_profile_reference_v1.rds` is compared with `identical()` (`run_configuration_generation.R:996-1054`). Steps 2, 4 and 5 all change resolved profiles, so the generator fails from step 2 on, not only in step 5.
- All three temporal stores date from June 2026, under old target names (`model_anova_*`, `model_jsdm_*`). They have no `list_jsdm_variance_partition_timeslice_*` and no `data_sjsdm_cv_model_provenance_timeslice_*`.
- `Data/Input/spatial_grid.csv` is not tracked. Continent ids are `europe`, `america` and `asia`.

## Deviations from the rebuild plan (for Ondřej to confirm)

1. **Configuration reference.** It is updated in steps 2, 4 and 5, through one reviewed tool with a declared-changes CSV (step 2b), not only in step 5.
2. **Tuning with infeasible slices.** `load_sjsdm_tuning_summaries()` is not edited. `run_sjsdm_tuning_sequence()` writes the existing requests file for temporal stores, listing only feasible slices.
3. **Cascade classification.** The rules are taken from a real sparse-slice run with the current code. Static reading suggests the list also needs `data_abiotic_scaled_list`, `data_community_filtered`, `data_network_metrics` and `formula_jsdm_environment`.
4. **Audit expectations.**
   - "Only the partition targets" means partition targets **and their downstream targets**. `tar_outdated()` propagates downstream.
   - Always-cued non-config targets are reported but do not count.
   - The common-regularization sensitivity stores become outdated through step 3. This is reported for a Stage B decision (rerun or ledger).
5. **Provenance tables.** [#208] also asks for a check that published tables carry provenance and build dates. Step 1 adds it, so the "Done" condition of Stage B can be tested.

## Rules (from the rebuild plan, restated where they bind this stage)

- Read `AGENTS.md`, `.ai/r-coding.md`, `.ai/r-functions.md`, `.ai/debugging.md`, `.ai/git-workflow.md` and `r_naming_decisions_v1.md` before editing. Functions are developed test first (`.ai/r-functions.md`).
- Run R with `rig run -r 4.5.1 <script>` from the repository root. For `run_pipeline()` progress widgets and the CZ smoke run, set `RSTUDIO_PANDOC="C:/Program Files/Quarto/bin/tools"`.
- Never run a production store's pipeline. Read-only calls on production stores (`tar_meta`, `tar_read_raw`, `tar_outdated`, `tar_network`) are allowed. Everything that builds runs on copies under `Data/Temp/`.
- Store copies keep the last two path components, `Data/Temp/<purpose>/<store root>/<scale_id>/<pipeline_name>`, because `resolve_scale_id_from_store()` reads `basename(dirname(store))`.
- Build on copies with `targets::tar_make(names = ..., shortcut = TRUE, script = <pipeline>, store = <copy>)` in a `callr` process with `R_CONFIG_ACTIVE` set. First dry-run the same names with `tar_outdated(shortcut = TRUE)`. Stop if the set includes interpolation or any target that writes files outside the store.
- Git: creating the branch `model-input-corrections` from `main` is authorised by the rebuild plan. No `add`, commit, push or merge. Propose the one-line commit messages at the end.

## Preconditions

- `git merge-base --is-ancestor rerun-project-docs main` succeeds. Otherwise stop and report.
- `git checkout -b model-input-corrections main` in the main checkout. Keep the untracked rebuild-plan file.
- Disk: about 5 GB free for store copies.

## Step 0: baseline and invalidation map (no commit; outputs feed step 6)

- **Manifest snapshot.** For each production pipeline under one representative profile, save `tar_manifest(fields = c("name", "command"))` to `Data/Temp/stage_a/manifest_before/`:
  - `pipeline_paleo_spatial_resolution`: paleo local
  - `pipeline_modern_spatial_resolution`: modern local
  - `pipeline_paleo_temporal`: Europe
  - `pipeline_sjsdm_tier_tuning`: paleo local, modern local, temporal Europe
  - `pipeline_sjsdm_common_regularization_sensitivity`

  Every later step diffs against this snapshot. Only the expected commands may change.
- **Invalidation map.**
  - For the same pipelines, run `tar_network(targets_only = FALSE, outdated = FALSE)` with a real store.
  - List the targets that directly depend on each function this stage edits: `build_jsdm_environment_formula`, `compute_jsdm_variance_partition`, `compute_jsdm_variance_partition_with_progress`, `project_coords_to_metric`, `classify_sjsdm_unit_pipeline_error`, `run_sjsdm_tuning_sequence`, `load_spatial_model_results`, `run_pipeline` and `run_configuration_generation`.
  - Save the result as `invalidation_map.csv` in the Stage A report folder (below).
  - Expected: only formula, partition, coordinate and sensitivity-decomposition targets.
  - **If a function lands in an unexpected pipeline, stop and redesign that edit before making it.** One way to redesign: move the new logic into a new function used only on the intended path.

Stage A report folder: `Documentation/Reports/Model_evaluation/stage_a_model_input_corrections_2026-11/`, with a README listing each file and the script that made it.

## Step 1 ([#208]): store-freshness validator and provenance

New functions in `R/Functions/Pipeline/Stores/Freshness/`, with mirrored tests in `R/03_Supplementary_analyses/Testing/testthat/Pipeline/Stores/Freshness/`. Final names are checked against `r_naming_decisions_v1.md`.

- **`load_model_store_index()`**
  - Returns one row per production store: `store_kind`, `profile_id`, `pipeline_script`, `store_path`, `store_suffix` and `store_exists`. Store kinds are spatial unit, temporal, tier tuning and sensitivity.
  - Spatial unit rows come from `build_spatial_model_store_index()` (`Stores/Spatial_models/`).
  - Temporal, tier-tuning and sensitivity rows come from `resolve_pipeline_store_path()` and each main, active profile's `target_store` (`load_config_value()`).
  - It accepts a `path_store_root` override, so the audit can point at copies.
- **`diagnose_model_store_freshness()`** returns findings for one store. It does not abort.
  - Mirror `validate_sjsdm_cv_preparation_freshness.R:100-234`:
    - set `R_CONFIG_ACTIVE` to the store's profile with `withr::with_envvar()`;
    - re-evaluate always-cued `config_*` commands with `resolve_scale_id_from_store` partially applied to the store, and compare them with `identical()`;
    - run one `tar_outdated(shortcut = TRUE, callr_function = NULL)` over all other targets, then re-check each candidate on its own.
  - Finding classes: `outdated`, `missing_metadata`, `config_changed`, and `always_cued_not_evaluated` (reported, not blocking).
  - Add a `function_*` injection argument for each `targets` call, as the CV validator has, so tests use stubs.
- **`load_model_store_freshness_ledger()`** reads and validates `Documentation/Implementation_inventories/Model_stores/model_store_freshness_ledger.csv`.
  - Columns: `store_path` (relative to the repository), `target_pattern` (anchored regex), `reason`, `evidence`, `owner`, `expiry_issue`.
  - It aborts on missing values or duplicate (`store_path`, `target_pattern`) rows.
  - Ships with the header only.
- **`apply_model_store_freshness_ledger()`** marks covered findings and appends a finding for each stale ledger row: no matching outdated target, or the store is missing. Pattern: `apply_r_architecture_exceptions.R` (`Pipeline/Definitions/Architecture/`).
- **`validate_model_store_freshness()`** aborts on uncovered blocking findings or stale rows.
- **`validate_model_table_provenance()`** aborts when a published model table lacks, or has missing values in: `regularization_source`, `candidate_id`, `cv_strategy`, `final_model_built_at` or `variance_partition_built_at`.

Then:

- **Workflow folder** `R/03_Supplementary_analyses/Validation/Model_stores/`:
  - `Validate_model_stores.R` takes scope arguments (store kind, data source, scale, explicit store paths, store-root override). It writes `Data/Temp/Model_store_validation/model_store_freshness_<timestamp>.csv` and exits non-zero on failure.
  - `README.md` has the five required H2s (template: `Validation/Configuration/README.md`). It states that the full sweep takes hours (one `tar_outdated` per store) and should run in the background.
  - Register the README in `vec_workflow_readme_paths` (`check_r_architecture.R:2282-2294`).
- **Spatial provenance.**
  - `load_spatial_model_results()` requests `time` from `meta_fn`. It adds `final_model_built_at` (the `time` of `mod_jsdm_selected_<res>`) and `variance_partition_built_at` (the `time` of `list_jsdm_variance_partition_<res>`).
  - Extend `.build_empty_spatial_model_results()` and the tests.
  - Check the Stage 04 components 01–03 for explicit `dplyr::select()` calls and carry the two columns through.
- **Temporal provenance** in `04_analyse_paleo_temporal_patterns.R`:
  - replace `model_anova_{timeslice}` (`:238`) with `list_jsdm_variance_partition_{timeslice}`;
  - add `cv_strategy`, `regularization_source` and `candidate_id` from `data_sjsdm_cv_model_provenance_timeslice_*` (`tar_read_raw`), plus `final_model_built_at` and `variance_partition_built_at` from `tar_meta(fields = c(name, error, time))`;
  - a missing target gives `missing_model`, not an error.
- **Documentation.** In `Documentation/Materials/main_analysis_workflow_guide.md`, add a required-check paragraph under "Stage 04: synthesis" (line 269) and a row in "Practical decisions" (lines 328-337).
- **Gate.**
  - Targeted tests pass.
  - Smoke run (read-only) on the three temporal stores fails (expected), and one European local fossil store passes.
  - Run the validator on the five audit stores (step 6 list), the production sensitivity store and the temporal stores. Save the result as the **baseline** in `baseline_store_freshness.csv`.
  - If a spatial baseline is not clean, report it and continue: the audit compares the change from the baseline.

## Step 2 ([#206]): no age terms for single-age input

- In `build_jsdm_environment_formula.R:52`, change the line to `is_age_present <- "age" %in% vec_names && isTRUE(use_age) && dplyr::n_distinct(data[["age"]], na.rm = TRUE) > 1L`.
  - Add no new locals: the formula environment holds them.
  - Update the roxygen `@details`.
- Tests in `testthat/Modelling/Fit_inputs/test-build_jsdm_environment_formula.R`:
  - single-age input gives `~ a + b`;
  - single age plus NA gives no age terms;
  - the existing multi-age tests are unchanged.
- In `Configuration/Profiles/Main/Paleo/temporal.yml`, set `model_fitting.use_age_in_formula: false` in the three profiles.
  - This also changes `predictor_structure` (`;age=FALSE`) in the temporal model context. That is intended, because Stage B refits the temporal models.
  - The frozen `issue_138` staged profiles inherit the value. Declare them in 2b.
- **2b. Configuration reference tool.** It is needed from this step on.
  - Extract the "fragments to reference-comparable resolved profiles" part of `run_configuration_generation()` (concatenate fragments, `config::get(use_parent = FALSE)`, strip `_profile`, `file`, `grouped_fold_ladder` and `fit_budget`; lines 820-994) into `build_configuration_reference_profiles()`. The generator calls it, and its tests pass unchanged.
  - Add `save_configuration_profile_reference()`. It diffs new against current resolved profiles as (`profile_id`, `key_path`) pairs. It aborts unless that set equals the rows declared in `Documentation/Implementation_inventories/Configuration/configuration_reference_changes.csv` (`change_id, profile_id, key_path, issue, rationale`). Then it recomputes `semantic_hashes` and the aggregate hash the way `create_configuration_profile_reference.R` does, and writes the `.rds`.
  - Script: `Validation/Configuration/Update_configuration_reference.R`, documented in that README and in `Configuration/README.md`.
  - Order: edit fragments, declare the rows, run the update script, then `Generate_configuration.R` and `Check_configuration.R`.
- **Gate.**
  - A one-off check in a fresh session: source the `main` version of the function into the global environment under another name. For multi-age input, `serialize()` of both formulas must be identical.
  - Read-only scan of every fossil spatial store's `data_model_input_<res>$data_abiotic_to_fit$age`: expect no single-age unit. Report any.
  - On a copy of one European local fossil store, rebuild `formula_jsdm_environment_*` (shortcut). `tar_outdated(names = starts_with("mod_jsdm"), shortcut = TRUE)` must be empty. **If not, stop: the edit would invalidate every paleo fit.**

## Step 3 ([#203]): association penalty and seed in the partition sub-models

- **Runtime reading first** (`Data/Temp/debug_anova_penalty.R`): `body(sjSDM:::anova.sjSDM)`, `body(sjSDM:::update.sjSDM)`, `formals(sjSDM::bioticStruct)`, and `str(mod$settings)` / `names(mod)` on a small fitted model. Record:
  - how the sub-models are built;
  - whether `update.sjSDM` forwards `seed`;
  - where the model stores `lambda`, `alpha`, `df` and the seed.

  If the sub-models are not built through `update(..., biotic = bioticStruct(diag = ...))`, stop and report before writing code.
- **Design (recommended).** New `build_jsdm_variance_partition_method(mod)` in `Modelling/Variance_partitioning/Model/`.
  - It returns a clone of `anova.sjSDM`, made with `rlang::new_function()` as in `compute_jsdm_variance_partition_with_progress.R:96-106`.
  - The clone's environment is a child of the sjSDM namespace that binds:
    - `bioticStruct` to a wrapper filling `lambda` and `alpha` (and any other non-default setting, such as `df`) from the full model's biotic settings, keeping the caller's `diag`;
    - `update` to a wrapper adding the model seed.
  - The body is not rewritten. A digest guard on the bodies of `anova.sjSDM` and `update.sjSDM`, the formals of `bioticStruct` and the sjSDM version fails closed if upstream changes.
  - If the seed is not stored on the model, stop and ask Ondřej. Options: an argument with the fit seed `900723` (`pipe_segment_model_fit.R:88`) as default, or a pipe-command change.
- `compute_jsdm_variance_partition()` keeps its name, signature and pipe command (`pipe_segment_model_anova.R:51`). It calls the built method. The output keeps the `sjSDManova` layout (`results`, `N`, `lls`, `species`).
- `compute_jsdm_variance_partition_with_progress()` uses `build_jsdm_variance_partition_method(mod)` as `method_original` when `anova_function` is NULL. It keeps its own `get_conditional_lls` guard.
- **Tests.**
  - A stub `anova_function` that calls `bioticStruct(diag = TRUE)` and `update()` receives the model's `lambda`, `alpha` and seed.
  - With `lambda_cov = 0` on a small simulated model, the fractions match `sjSDM:::anova.sjSDM()`. Set the tolerance from the spread of two default-anova runs with different seeds, and record it in the test.
  - The existing tests pass.
- **`run_pipeline()`** gains `shortcut = FALSE`, forwarded to `tar_make()`. Test it like "forwards the callr backend" (`test-run_pipeline.R:128`).
- **Pilot** (`R/03_Supplementary_analyses/One_time/Issues/issue_203/`, README registered):
  - From `Outputs/Tables/Visualisation/{paleo,modern}_variance_partitioning_unit_2026-10-23.csv`, pick about 5 penalised units (candidate 005–008) across local, regional and continental fossil tiers plus one modern, and one `lambda_cov = 0` unit as a real-model equivalence check.
  - Copy each store, then rebuild only `list_jsdm_variance_partition_<res>` (shortcut).
  - Record the published and new shares of the three components, F_ABS (the three-way fraction) and the runtime in `variance_partition_penalty_pilot.csv`.
  - Draft the [#203] comment.

## Step 4 ([#181]): temporal slice failures

- **Window key.** Add a top-level `temporal_slices.age_window`, in temporal profiles only: Europe `c(0, 17500)`, America `c(0, 19500)`, Asia `c(0, 10500)`. Do not reuse `vegvault_data.age_lim`.
  - New `build_temporal_slice_ages(age_window, time_step)` returns `age` and `age_name`.
  - Use it in `pipeline_paleo_temporal.R:123-137`, in the temporal branch of `pipeline_sjsdm_tier_tuning.R:80-97`, and in runners 07–09 (lines 43-54).
  - Declare the profile changes in the reference CSV and rerun 2b.
- **Cascade rules.**
  - On a copy of the Asia temporal store, build every `*_timeslice_0` target (shortcut; 1 sample, inside the window) and record each errored target and message.
  - Extend the temporal cascade tribble in `classify_sjsdm_unit_pipeline_error.R:137-167` with anchored target~message pairs for exactly those cascades.
  - Leave the pipe segments untouched.
  - Tests: an `insufficient_samples` root with the observed cascade gives `expected_infeasible`; the same cascade without a root stays `unexpected_error`.
- **Per-slice status.** New `classify_sjsdm_timeslice_status(data_target_errors, vec_slice_ids, vec_window_slice_ids)` returns `slice_id`, `status`, `reason_code`, `root_target` and `root_error`.
  - `status` is one of `ok`, `expected_infeasible`, `unexpected_error` or `outside_window`.
  - It runs `classify_sjsdm_unit_pipeline_error()` on each slice's rows.
- **Tuning** (`run_sjsdm_tuning_sequence.R`).
  - Add `slice_ids = NULL`. When it is set (temporal, one store), a store-level `expected_infeasible` result is classified per slice.
  - The store stays active, and `tuning_target_names` shrinks to the feasible slices for the endpoint and evidence checks (`:391-463`).
  - Write `sjsdm_tier_unit_requests.csv` with `source_store` and `target_name` for feasible slices only. Relax the nested-store assertion at `:212-213` for this mode.
  - Any `unexpected_error` slice still aborts.
  - Test with injected stubs.
- **Runner status.** Runners 07–09 catch the expected-infeasible condition from `run_pipeline()`, build the per-slice table, and write `Data/Temp/Main_analysis_execution/03_model_fitting/paleo_temporal_<continent>_slice_status_<run_id>.csv`. They abort on any `unexpected_error`, as `02_fit_paleo_spatial_regional.R:149-188` does.
- **Stage 04 and figures.**
  - `04_analyse_paleo_temporal_patterns.R` uses `classify_sjsdm_timeslice_status()` and labels slices outside the window `outside_window`.
  - Add `outside_window` to `scale_shape_manual` in `05_Visualisation/_components/07_plot_paleo_temporal_trajectories.R:343-359`.
- **0 ka `ZeroDivisionError`** (`.ai/debugging.md`):
  1. On a copy of the Europe temporal store, rebuild `data_model_input_timeslice_0`, `formula_jsdm_environment_timeslice_0` and `list_sjsdm_prepared_tuning_folds_timeslice_0` with the current code. Dry-run first; if interpolation is outdated, use shortcut and record it.
  2. In `Data/Temp/debug_zero_division_timeslice_0.R`, which does not source the project setup, fit sjSDM on that input with candidate_001 (all penalties off, as in June) and the profile budget, then one CV fold fit.
  3. If it fails, test one candidate per script: batch size (`floor(0.1 * n)`, see `2026-10-16_modern_local_small_fold_recovery.md:12`), zero-variance predictor or taxon columns, MEM columns, sampling.
  4. Apply the minimal fix with a comment and add a regression test.
  5. If it does not reproduce, record which change since June removed it, with evidence, and check America 0 ka the same way.
- **Gate.** Targeted tests pass. `tar_manifest` of the spatial tier-tuning pipelines is identical to step 0, and the temporal manifests contain only window slices.

## Step 5 ([#204]): region-appropriate projection

- **Distortion** (`One_time/Issues/issue_204/diagnose_projection_distortion.R`, README registered). Use the 9 Nov method recorded in [#204]:
  - up to 300 random cores (fixed seed) from `data_coords_analysis` in each continental fossil store;
  - pairs more than 50 km apart;
  - ratio of projected to ellipsoidal geodesic distance (`sf` with s2 off, or the closest installed alternative; no new packages).
  - Candidates:
    - America: EPSG:3035, ESRI:102008, and LAEA and AEQD centred on the continental bbox midpoint from `spatial_grid.csv`;
    - Asia: the same set with ESRI:102025;
    - Europe: 3035 only, as a control.
  - Report the median, `lwr_90`, `upr_90` and maximum; modern plots are reported for information.
  - Pick the narrowest 5–95 % range per continent. Write `projection_distortion.csv` and draft the [#204] comment.
- **Configuration.**
  - Add a top-level `spatial_crs_by_continent` to `default.yml`: `europe: 3035` plus the chosen values. Values are EPSG integers or CRS strings.
  - Add top-level `continent_id` to the three temporal profiles. This key already exists for `cz_smoke`, and only the `*_test` pipelines read it.
  - Add a comment marking `model_fitting.spatial_crs` superseded and kept until the full rerun.
  - Before editing, grep pipelines and target-called functions for whole-profile reads (`load_config(`). Expected: only definition-time reads.
- **Resolver.** New `resolve_spatial_crs(scale_id, continent_id, crs_by_continent, file_spatial_grid)` in `Data/Spatial/Coordinates/`.
  - A scale id is mapped through `resolve_continent_ids_from_scale_ids()`; otherwise the profile's `continent_id` is used. If both exist, they must agree.
  - It aborts when there is no continent or no map entry.
  - `project_coords_to_metric()` also accepts one CRS string accepted by `sf::st_crs()`. The integer branch stays textually unchanged. `build_land_prediction_grid()` relaxes its check the same way if needed.
- **Pipeline.**
  - In `pipe_segment_model_spatial_shared.R`, add the always-cued `config_spatial_crs_for_unit`, with command `resolve_spatial_crs(scale_id = resolve_scale_id_from_store(), continent_id = load_active_config_value("continent_id"), crs_by_continent = load_active_config_value("spatial_crs_by_continent"))`.
  - `data_coords_projected` uses it.
  - Leave `config_spatial_predictors` and `config_model_fitting` alone.
  - `Predict_on_full_grid.R:114-134` switches to the resolver.
- **Generator rule** after `run_configuration_generation.R:908-927`, with a new `path_spatial_grid` argument that aborts when the file is missing:
  - every grid `continent_id` has an entry;
  - no non-Europe entry equals 3035;
  - every main `paleo_temporal` profile has a `continent_id` that resolves.

  Add test fixtures with a small grid. Declare the profile changes in the reference CSV, rerun 2b, then generate and check.
- **MEM diagnostic** (`issue_204/diagnose_mem_projection_change.R`).
  - Put `threshold_r2 <- 0.99` at the top, with a comment that it was fixed before the run.
  - For every American and Asian fossil and modern unit and resolution, read `data_coords_analysis`, `config_spatial_predictors` and `data_spatial_mev_samples_<res>` (read-only).
  - Rebuild the MEMs with the new CRS using `compute_shared_spatial_mev_basis()` and `prepare_spatial_predictors_for_fit()`.
  - Regress each new MEM on all stored MEMs and record the minimum R² and both MEM counts. A count change flags a refit.
  - Write `mem_projection_r2_by_unit.csv` and `fossil_projection_refit_list.csv`.
- **Gate.**
  - On the European fossil copies, the rebuilt `data_coords_projected` keeps its hash in `tar_meta(fields = data)`.
  - On a North American copy it changes.
  - `tar_manifest` diff: only `data_coords_projected` and the new target change.

## Step 6: invalidation audit

- **Copies** under `Data/Temp/store_audit/`, keeping the layout:
  - Europe fossil continental (about 1 GB);
  - one European fossil local (reuse step 2's copy);
  - one North American fossil local;
  - one European modern local or regional (avoid the 4.1 GB continental);
  - the paleo-local tier-tuning store.
- **Rebuild** with shortcut only `config_*`, `formula_jsdm_environment_*`, `data_sample_ids_checked*` and `data_coords_projected`. Then run `Validate_model_stores.R` with the store-root override.
- **Expected change from the baseline:**
  - European stores: partition targets and their downstream targets only.
  - North American store: everything downstream of `data_coords_projected` (MEMs, CV folds, fits) plus the partitions.
  - Tier-tuning store: nothing beyond always-cued targets.
  - Production sensitivity store (read-only validator): the decomposition targets, reported for a Stage B decision.
  - Temporal stores: still outdated.
- Anything else: stop and report. Write `invalidation_audit.csv`.

## Finishing the stage

1. Run `generate_r_architecture_inventories.R`, `Document_functions.R`, `check_r_architecture.R`, `Generate_configuration.R` and `Check_configuration.R`, then `Testing/Run_tests.R`. As of 9 Nov, `test-r-architecture-repository-contract.R` called bare `Rscript`; if it still fails for that reason, run `check_r_architecture.R` directly and report it.
2. CZ smoke run: `R/03_Supplementary_analyses/Testing/Smoke/run_cz_pipelines.R`. Keep the refreshed `Documentation/Progress/` artifacts.
3. Ask for an independent review with `.ai/agents/changes-reviewer.agent.md`. A self-review does not count.
4. Report in this order:
   - what changed, per step;
   - check results;
   - what was not verified;
   - the drafted [#203] and [#204] comments;
   - suggested ledger rows for Stage B;
   - proposed commits and PR relationships: Part of [#181], [#203], [#204], [#207], [#208]; Closes [#206].
5. Proposed commits, one per step:
   1. `Model stores: add freshness validator, ledger and build-date provenance`
   2. `build_jsdm_environment_formula(): drop age terms for single-age input`
   3. `compute_jsdm_variance_partition(): carry association penalty into sub-models`
   4. `Temporal pipeline: model a slice window and classify infeasible slices`
   5. `Spatial projection: resolve a per-continent CRS for coordinates`
   6. `Model stores: record the stage A invalidation audit`

## Risks

| Risk | Guard |
|---|---|
| The formula edit changes the formula hash, invalidating every paleo fit and CV run | Serialize check and store-copy check in step 2, before steps 3–6 |
| A config key addition changes a hashed config target | Shapes of `config_model_fitting`, `config_data_processing` and `config_spatial_predictors` stay frozen; grep check; manifest diffs |
| Stage A edits a function used by spatial tier-tuning targets | Step 0 invalidation map; `load_sjsdm_tuning_summaries()` stays unchanged |
| Copy runs rebuild heavy upstream targets or write outside the store | Dry-run `tar_outdated` before every `tar_make`; shortcut |
| sjSDM internals differ from the design assumption | Runtime reading first; digest guard; stop and report |
| A full validator sweep is slow | Scope arguments; background run; documented runtime |

<!-- Issue and pull-request links -->

[#181]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/181
[#203]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/203
[#204]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/204
[#206]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/206
[#207]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/207
[#208]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/208
