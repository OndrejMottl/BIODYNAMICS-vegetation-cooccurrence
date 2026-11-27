# Stage V implementation plan: VegVault 2.0.0 and vaultkeepr 0.2.0

## Context

The rebuild plan ([2026-11-16_model_input_corrections_and_rebuild_plan.md](2026-11-16_model_input_corrections_and_rebuild_plan.md)) waits for a corrected VegVault release before the full rebuild. That release is VegVault 2.0.0.

- **Database.** The build is accepted but not yet published:
  - file `D:\GITHUB\VegVault\VegVault\Outputs\Data\VegVault\VegVault_2.0.0.sqlite`, 6.5 GB;
  - SHA-256 `559577c774b8cae272e711b9be6d24ad8376b3d5445390976460f1dd25b1b398`, checked on 25 Nov 2026 against the build manifest;
  - built at VegVault commit `f19d588`.
- **Package.** It comes with vaultkeepr 0.2.0, on branch `0.2.0` at `4a65799`, not yet tagged.
- **Release notes.** `D:\GITHUB\VegVault\_release_2.0.0_evidence\release_notes\VegVault_v2.0.0.md`.

2.0.0 is a major release:

- the schema is new;
- every database id is renumbered;
- trait units are standardised at the source;
- taxa are reclassified;
- fossil pollen is a fresh Neotoma download.

The rebuild plan assumed a corrected release that would drop in under the same path. This stage makes every repository change that 2.0.0 needs, so that Stage B rebuilds once.

Facts found in the code and the two upstream repositories that shape this plan:

- **The database is invisible to `{targets}`.** `Data/Input/VegVault.sqlite` is not a file target, and vaultkeepr functions are not hashed. Replacing the database under the same path would leave every store up to date.
  - `pipe_segment_traits_extract.R` says so on purpose: re-extraction is manual.
  - The store validator already re-evaluates always-cued `config_*` targets and reports a changed value as blocking (`diagnose_model_store_freshness.R:209-353`). A configuration target that reads the database version therefore makes a database change visible, without validator changes.
- **vaultkeepr 0.2.0 is mostly compatible.** No export is renamed or removed. Changes that matter here:
  - `renv.lock:10748-10795` pins 0.1.0 from GitHub `HEAD` (sha `edf90b6`), and `R/___Init_project___.R:120-125` installs `ref = "HEAD"`.
  - A 2.0.0 database needs 0.2.0: 0.1.0 lets trait datasets through the geographic box and is slow.
  - `open_vault()` now opens read-only and checks the database version (from 1.0.0 up to, but not including, 3.0.0).
  - `get_traits()` adds `trait_unit`, `conversion_rule_key` and `derivation_rule_key`.
  - `get_traits(classify_to = NULL)` now resolves to `"original"`, which joins the whole `TraitsValue` table. The release notes report this path as very slow on 2.0.0.
  - The `select_dataset_by_geo()` default now includes `traits`. The community plan does not use trait datasets, and `load_trait_records_from_vegvault()` already passes `sel_dataset_type`, so neither changes.
  - `get_age_uncertainty()` output is now sorted.
- **The trait correction layer stops with an error on a new version, as designed** (`Data/Input/Trait_corrections/README.md`).
  - `validate_trait_source_scale_rules()` stops when the `version_control` version changes.
  - `build_trait_analysis_release.R:57-63` accepts only `"1.0.0"`.
  - The v1 source rules and the 57 `scale` decisions correct units that 2.0.0 already corrects at the source. 55 of those decisions are "×10/×100/×1000 below an upper bound" selectors, so they would correct small v2 values a second time.
  - Review candidate ids are hashes of `stage|taxon|domain` and do not depend on the VegVault version (`build_trait_review_candidates.R:227-239`). Left in place, the v1 decisions would silently match the v2 candidates.
  - An empty rule file passes the version check, because `any()` over zero rows is `FALSE`. It also breaks `save_trait_source_scale_report()`.
  - `filter_complete_trait_records.R:29-43` and `resolve_trait_taxon_ids.R:77-92` keep fixed column lists that drop `trait_unit`.
  - Until this layer is migrated, the trait reference pipeline cannot finish, and neither can any functional-type model.
- **Taxa are classified in this project, not in VegVault.**
  - `get_taxa()` returns the original names. The project classifies them with taxospace (cache in `Data/Temp/taxospace`, about 15,800 entries) and `Data/Input/aux_classification_table.csv`, which takes precedence (`build_combined_classification_table.R`). `validate_taxa_classification_coverage()` stops on any unclassified name.
  - VegVault 2.0.0 now sets 116 combined pollen types (for example "Larix Pseudotsuga") to their shared family with no genus, or leaves them unclassified when the families differ. These corrections do not reach this pipeline.
  - Seven of the 116 are in the auxiliary table, and they already follow the same rule.
  - The fresh Neotoma download adds 166 fossil datasets, and the plot taxa are merged, so new names will appear.
- **Abiotic data.**
  - The variable set (`bio1`, `bio4`, `bio6`, `bio12`, `bio15`, `bio18`, `bio19`, `HWSD2`), the grid and the 500-year slices are unchanged.
  - `bio4` at age 0 is fixed. Its values were already ×100 in 1.0.0 and only the unit label changed. Predictors are scaled, so no code changes.
  - `bio12` is still capped at 6553.5 mm, by decision.
  - `bio18` and `bio19` have accepted zero bands (22-26° N, 31-34° N, 11-16° N), and a block of the southern Amazon has no precipitation values at some past ages. All of these appear to lie outside the project windows (checked in V5).
  - `HWSD2` is not used.
- **Names and ids.**
  - BIEN dataset names are now `bien_<plot_id>`, which still matches `classify_dataset_prefix()`.
  - Fossil sample names are now `fossilpol_<Neotoma dataset id>_<level>`.
  - Hard-coded ids remain in `save_trait_source_scale_report.R:64` (`data_source_type_id = 4`) and in the supplementary `Predict_from_model.R:83-115`.
- **Temporal exclusions.** `main` has only the Asia 0 ka exclusion (`temporal.yml:112`). The temporary Europe and America 0 ka exclusions are on the unmerged branch `bes-2026-presentation`.

## Decisions (Ondřej, 25-26 Nov 2026)

- **Traits: retire the v1 corrections and sort the v2 review automatically first.** Drop the source-scale rules and every `scale` decision. Regenerate the review queues on v2 and run the existing automated sorting; Ondřej decides only what it cannot settle. Keep the design that stops with an error when the input changes.
- **Scope: hold Stage B until [#179] has an adoption decision,** so that the functional-type models are fitted once. [#202] is not added to the rebuild.
- **Checkpoint for [#179]: 4 Dec 2026 (decided 26 Nov 2026).** If [#179] has no adoption decision by then, Stage B uses the current hierarchical classification, which [#179] itself names as a valid outcome.

## Rules

- Read `AGENTS.md`, `.ai/r-coding.md`, `.ai/r-functions.md`, `.ai/git-workflow.md` and `r_naming_decisions_v1.md` before editing. Every name proposed below is a proposal, to be checked against `r_naming_decisions_v1.md`. Functions are developed test first.
- Run R with `rig run -r 4.5.1 <script>` from the repository root. For `run_pipeline()` progress widgets and the CZ smoke run, set `RSTUDIO_PANDOC="C:/Program Files/Quarto/bin/tools"`.
- Never run a production store's pipeline. Everything that builds runs on stores under `Data/Temp/`. Read-only calls on production stores are allowed.
- Never write to either VegVault file. Every direct connection is opened read-only.
- Git: Ondřej creates the branch `vegvault-2-migration` from `main`, or asks for it by name.
  - No `git add`, `git mv`, commit, push, merge or tag without his request. Each one-line commit message is proposed at the end of its step.
  - Moving tracked files uses `git mv` (`.ai/git-workflow.md`), so step V3 waits for that request.
- `renv`: Ondřej authorises the vaultkeepr installation and the snapshot; do not run them otherwise.
- New trait function files need rows in `r_function_inventory_v1.csv` with the owner field `#153` and status `migrated`. Without them, `check_r_architecture.R` (trait root at `:471`) reports a blocking finding.
- **Invalidation.** Every pipeline `tar_source()`s all of `R/Functions/`. Each edit to a shared function below invalidates its targets in every store, which is intended before a full rebuild. Two rules follow:
  - finish all Stage V edits before Stage B starts;
  - still never change the shape of `config_model_fitting` or `config_data_processing`.

## Preconditions

- Stage A is merged into `main` ([#214]).
- The 2.0.0 file is unchanged since the check. Its SHA-256 matches the value above, and `version_control` reads `2.0.0`.
- Disk: about 7 GB for the copy of the database, plus store space under `Data/Temp/`. 537 GB were free on 25 Nov.

## Step V0: inputs and dependencies (each action on Ondřej's request)

- **v1 file.** Rename `Data/Input/VegVault.sqlite` (1.0.0, 102 GiB) to `Data/Input/VegVault_1.0.0.sqlite`. Keep it until Stage B is finished; steps V3 and V5 read it.
- **v2 file.** Copy the 2.0.0 file to `Data/Input/VegVault.sqlite` and check its SHA-256.
- **Worktrees.** Their symlink instructions in `.ai/git-workflow.md` stay valid, because the path does not change.
- **vaultkeepr.**
  - Install `OndrejMottl/vaultkeepr@4a65799` through renv and take a snapshot limited to vaultkeepr.
  - Set the ref in `R/___Init_project___.R:120-125` to the same commit.
  - When the `v0.2.0` tag exists, and before Stage B, re-pin to the tag and confirm that `git diff 4a65799 v0.2.0 -- R/` in the vaultkeepr repository is empty.
- **v1 trait store.** Copy `Data/targets/traits_reference` to `Data/targets/_archive/2026-11_vegvault_1_0_0_traits_reference/` before anything rebuilds it. The retirement check in V3 compares against it.

## Step V1: database-version dependency and provenance

- **Configuration.**
  - Add `vegvault_data.vegvault_version: "2.0.0"` to `Configuration/Defaults/default.yml`.
  - Update the semantic configuration reference through the reviewed tool, declaring the change in `configuration_reference_changes.csv`.
  - Regenerate `config.yml`.
- **Function `load_vegvault_database_version()`** (`R/Functions/Data_access/Vegvault/`).
  - It reads `version_control` read-only, in the same way as vaultkeepr: it skips rows without a version and takes the highest `id`.
  - It returns `version`, `git_commit` and `manifest_sha256` (the last two exist from 2.0.0 on), and stops with an error when `version` differs from the configured version.
  - It may reuse `read_vegvault_scalar()`, which has no production caller yet.
- **Target `config_vegvault_release`** with `tar_cue(mode = "always")`.
  - It goes in `pipe_segment_config_common.R` and in `pipeline_traits_reference.R`. It holds the configured version and the returned record.
  - Because it is an always-cued `config_*` target, the freshness validator re-evaluates it, so a database swap, or a rebuilt 2.0.0 with another manifest hash, is reported as `config_changed`.
- **Dependent targets.** `data_vegvault_extracted` (`pipe_segment_vegvault_extract.R`), `data_age_uncertainty` (`pipe_segment_community_prepare_paleo.R:49-67`), `vec_trait_domain_names` and `data_traits_continent` (`pipe_segment_traits_extract.R`) take `config_vegvault_release` as an argument.
  - `build_vegvault_plan()` and `load_trait_records_from_vegvault()` check it against the version of the vault they open. vaultkeepr 0.2.0 stores that version as the `database_version` attribute of the pipe.
- **Read-only connections.** Add `flags = RSQLite::SQLITE_RO` to every direct `DBI::dbConnect()` on VegVault:
  - `load_trait_records_from_vegvault.R:168-169`
  - `load_trait_domain_names_from_vegvault.R`
  - `resolve_trait_taxon_ids.R`
  - `validate_trait_source_scale_rules.R`
  - `save_trait_source_scale_report.R`
- **Provenance.** Stage 04 tables gain a `vegvault_version` column read from each store's `config_vegvault_release`, next to the build dates added in Stage A. This changes a persisted table format, so update the inventories.
- **Tests.**
  - The version reader: rows without a version, and `"2.10.0"` against `"2.9.0"` ordered by `id`.
  - A mismatch stops with an error.
  - The validator reports `config_changed` on a test store after the database is swapped.
- **Commit:** `VegVault access: track the database version and open it read-only`.

## Step V2: extraction on vaultkeepr 0.2.0

- **Integration tests** on the real database (`RUN_VEGVAULT_INTEGRATION=true`; the tests with `skip_if_not(file.exists(...))` now run against v2):
  - The empty-window path of `build_vegvault_plan()` still raises `biodynamics_vegvault_no_records`. It depends on vaultkeepr's empty or "." error text (`:120-147`) and on `res_plan[["data"]]` (`:154-179`).
  - `extract_age_uncertainty_from_vegvault()` still receives `sample_name` and `iteration_*` columns.
- **Traits call.** Pass `classify_to = "original"` explicitly in `load_trait_records_from_vegvault.R:136`. This makes the current behaviour visible without changing it.
- **Runtime, first.** Time `load_trait_records_from_vegvault()` for the largest continental window. If it is too slow for one run per continent, narrow `get_traits()` to the selected samples or datasets inside vaultkeepr before 0.2.0 is tagged. The package is Ondřej's, so the fix belongs there and not in a local workaround.
- **Known-outdated script.** `Predict_from_model.R:83-115` hard-codes v1 ids. It is outside the rebuild; record it in the step report and leave it.
- **Commit:** `VegVault extraction: confirm the vaultkeepr 0.2.0 interface`.

## Step V3: trait correction layer

### V3a: version-specific correction folders

- With Ondřej's `git mv` request, move the four v1 decision files to `Data/Input/Trait_corrections/VegVault_1_0_0/`, a read-only record of provenance:
  - `trait_source_scale_rules.csv`
  - `trait_review_decisions_raw.csv`
  - `trait_review_decisions_classified.csv`
  - `trait_review_programmatic_spot_check_decisions.csv`
- Create `Data/Input/Trait_corrections/VegVault_2_0_0/` with:
  - a header-only `trait_source_scale_rules.csv`;
  - header-only `trait_review_decisions_raw.csv` and `trait_review_decisions_classified.csv`;
  - header-only `trait_review_manual_resolutions_raw.csv` and `trait_review_manual_resolutions_classified.csv`, which follow the format of the spot-check decisions;
  - `trait_domain_units.csv` (V3c).
- `Review_submission/` stays where it is, because it does not depend on the version.
- **Function `resolve_trait_correction_directory()`** returns the folder for the version in `config_vegvault_release`, and stops with an error naming the missing folder when there is none. The next VegVault version therefore stops at a clear point, and v1 decisions cannot be carried over by accident.
- **Wiring.**
  - Every `file_trait_*` path and `path_trait_corrections` in `pipe_segment_traits_qc.R` and `pipe_segment_traits_qc_classified.R` is built from the resolved folder.
  - The new folder target is tracked through the existing `file_*` targets.
- **Carried over: nothing.**
  - The v1 `exclude` decisions are all `value <= 0` selectors, and the automated policy proposes them again wherever zeros remain.
  - The `scale` decisions are dropped by decision; V3e lists them with their v2 evidence, for information only.

### V3b: empty source-scale step

The step stays in the pipeline, empty and typed, so that a later release can add rules keyed to v2 source ids. Its targets are recorded as persisted formats, and removing functions cannot be undone (`.ai/r-coding.md`).

- `validate_trait_source_scale_rules()` takes a `vegvault_version` argument from `config_vegvault_release`. It drops its own query, which orders `version_control` by `date(update_date)`, unlike vaultkeepr, and stops with an error when any rule names another version.
- `apply_trait_source_scale_rules()` returns the records unchanged and typed empty audits, with the same columns as the non-empty case, when there are no approved rules.
- `save_trait_source_scale_report()`:
  - drops `path_vegvault`, the TRY check with `data_source_type_id = 4` (`:59-84`) and the "PROVISIONAL" text;
  - takes `vegvault_version`;
  - writes "No approved source-scale rules for VegVault <version>" when the rule set is empty.
- Update the wiring in `pipe_segment_traits_qc.R:61-70` and `:243-267`.

### V3c: trait units

- Keep `trait_unit`, `conversion_rule_key` and `derivation_rule_key` in `filter_complete_trait_records.R:29-43` and `resolve_trait_taxon_ids.R:77-92`.
- **`VegVault_2_0_0/trait_domain_units.csv`** has one row per domain (six).
  - Columns: `vegvault_version`, `vegvault_build_reference`, `trait_domain_name`, `trait_unit`, `evidence_status`, `included_in_primary`, `rationale`, `evidence_reference`, `review_status`, `reviewer`, `reviewed_at`.
  - The unit strings are copied exactly from `TraitsDomain.trait_unit` with a read-only query.
  - It is tracked with `format = "file"`.
  - It is a reviewed record tied to one version, like the decisions, so it does not go into the configuration, and it leaves the shape of every `config_*` target unchanged.
- **New functions** `load_trait_domain_units()` and `validate_trait_domain_units()`. The second stops with an error unless:
  - all six rows are approved;
  - the version and build reference match `config_vegvault_release`;
  - `TraitsDomain` has the same units and no other domain;
  - every record has exactly the unit of its domain, with no `NA`;
  - every record carries a conversion or derivation rule key (confirm this on v2 with a read-only query first).
- New targets at the top of `pipe_segment_traits_qc.R`, checked against `data_traits_raw`: `file_trait_domain_units`, `data_trait_domain_units` and `data_trait_domain_units_validated`.

### V3d: the trait analysis release

- `build_trait_analysis_release()` loses the 1.0.0 lock (`:57-63`) and its hard-coded statuses. It takes the validated domain units and the version.
  - The status table is the unit table plus `release_id`, `release_date` and `vegvault_version`.
  - It stops with an error when the domain set or a record's unit differs from the table. The six-domain check stays.
- **Release id:** `vegvault_2_0_0_reviewed_<YYYY_MM_DD>`, dated on the day the classified review is approved.
- **Statuses.** `source_standardised` for five domains, and `source_derived` for leaf mass per area (reciprocal of SLA, VegVault rule `sla_to_lma`). `provisional_units`, `interim_source_uncertainty` and `interim_reviewed` are retired, unless V3e finds a remaining unit problem.
- `pipe_segment_traits_table.R:57-91` takes the version and the unit table and drops the "interim" wording.
- **Sensitivity variants.** The four variants in `resolve_functional_type_trait_transformations.R` stay; only their roxygen text changes. Their original reason (provisional units) no longer applies. Whether they still run in Stage B is Ondřej's decision.

### V3e: one-time runners

All three go in `R/03_Supplementary_analyses/One_time/Trait_corrections/`. The v1 runners there stay untouched as provenance; most check v1 counts, dates or `1.0.0`, and now stop with an error, as intended.

- **`run_trait_source_rule_retirement_check.R`**
  - For each of the ten v1 source rules, it finds the v2 source by its description (ids are renumbered) and compares the per-taxon medians with the archived v1 trait store.
  - Each rule is classified as `fixed_at_source`, `quarantined` or `still_unscaled`. The release notes confirm only sources 294 and 509.
  - Any `still_unscaled` rule stops the migration. Either correct it in VegVault, or add a 2.0.0 rule keyed to its v2 source id.
  - It also lists the v1 `scale` and `exclude` keys with their v2 evidence.
- **`run_trait_review_vegvault_2_0_0_triage.R`**
  - Run once per review stage. It reads candidates and records from the trait store under `Data/Temp/`.
  - It uses a neutral historical scope and no v1 adjudications. v1 evidence must not be reused: after deduplication and unit conversion, almost no candidate meets the exact-count rule of `build_trait_review_evidence_packets.R:347-356`.
  - It chains the existing builders: reconciliation, evidence packets, diagnosis, policy outputs, programmatic sorting, programmatic reconciliation and interim closure.
  - Each candidate gets one proposal, in this order of precedence:
    1. policy (`none`, or exact-zero `exclude`);
    2. closure (`none` for insufficient evidence, `exclude` for non-positive values);
    3. Ondřej's queue.
  - Scaling proposals derived from submission thresholds, which are in v1 units, are never approved automatically.
  - It writes proposals only, to `Data/Temp/Trait_corrections/<stage>/vegvault_2_0_0_triage/`, plus a report in `Outputs/Reports/Trait_corrections/<stage>/`.
- **`run_trait_review_vegvault_2_0_0_approval.R`**
  - Ondřej approves by fixing the SHA-256 of the reviewed proposal and resolution files, with reviewer and date.
  - The runner merges his resolutions, runs `validate_trait_review_decisions()`, simulates `apply_trait_review_decisions()`, and only then writes the decision file in `VegVault_2_0_0/`.
- **Expected load** (estimate from the code, not a run):
  - 3,500-4,300 raw candidates, including about 1,875 mandatory taxon-domain keys from the immutable submission;
  - a classified queue near the v1 size of 4,223;
  - about nine in ten settled automatically, leaving Ondřej tens of cases, not hundreds.

### V3f: order of work

1. Run the trait pipeline on a store under `Data/Temp/`. It stops at the raw decision check.
2. Run the retirement check.
3. Run `recover_trait_review_submission.R`, then the raw sorting. Ondřej resolves his queue, then the raw approval runner writes the decisions.
4. Run the pipeline again. It classifies the taxa (V4 may be needed first) and stops at the classified decision check.
5. Run the classified sorting, Ondřej's approval, and the classified approval runner.
6. Run the pipeline to the release and the trait table.

### V3 tests and commits

- **Rewrite:**
  - `test-build_trait_analysis_release.R` (encodes 1.0.0, the old id and `provisional_units`);
  - `test-validate_trait_source_scale_rules.R` (use the `vegvault_version` argument; add "zero rows pass" and "a mismatched row stops");
  - `test-save_trait_source_scale_report.R` (drop `data_source_type_id = 4` and "PROVISIONAL"; add the zero-rule report).
- **Extend:**
  - `test-apply_trait_source_scale_rules.R` (typed empty audits);
  - `test-filter_complete_trait_records.R` and `test-resolve_trait_taxon_ids.R` (the three new columns are kept).
- **Check** `test-load_continental_trait_records_from_vegvault.R`.
- **Add** tests for `resolve_trait_correction_directory()`, `load_trait_domain_units()` and `validate_trait_domain_units()`.
- **Commits:**
  1. `Trait corrections: keep VegVault 1.0.0 decisions as provenance and start a 2.0.0 folder`
  2. `Trait units: check one unit per domain against the VegVault 2.0.0 record`
  3. `Trait release: build the reviewed VegVault 2.0.0 analysis release`
  4. `Trait review: sort and approve the VegVault 2.0.0 review queues`

## Step V4: taxonomy

- **Diagnostic**, read-only, in `R/03_Supplementary_analyses/Diagnostics/`. For each continent window and data source (fossil pollen, plots, traits), it lists:
  - v2 names covered neither by the taxospace cache nor by the auxiliary table, which would stop the community and trait classification checks;
  - VegVault's combined pollen types found in project windows, with their 2.0.0 placement (`D:\GITHUB\VegVault\_release_2.0.0_evidence\full_build_dev\combined_pollen_types.csv`) next to the project's current classification.
- **Auxiliary table.** Add rows to `Data/Input/aux_classification_table.csv` that follow VegVault's rule: the shared family and no genus, or unclassified when the families differ. Fill other missing names through the existing `missing_taxa_template.csv` workflow.
- **Cache.** Keep `Data/Temp/taxospace`. Deleting it would change classifications that this stage does not intend to change.
- **Commit:** `Taxa: classify the new VegVault 2.0.0 names and combined pollen types`.

## Step V5: v1 against v2 for the project windows

A read-only comparison of the two files for the continental windows of `spatial_grid.csv` and the three temporal profiles. It reports:

- datasets, samples and taxa per data type and continent, from both files;
- TRY trait records per continent: TRY coordinates outside the valid range are now missing, so some datasets leave the windows;
- the number of Asia samples at 0 ka. The exclusion at `temporal.yml:112` stays while it is below `min_n_samples` (10).
- `bio4` at age 0: positive and continuous in every window, and close to the 500 cal yr BP values of the same gridpoints (the queries of the Stage A report);
- `bio12` cells at 6553.5 mm, `bio18` and `bio19` zeros in the accepted bands, and the masked Amazon block: none expected inside project extents.

Outputs go to `Documentation/Reports/Model_evaluation/vegvault_2_migration_2026-11/`: one CSV per table, one figure for the co-author material, and a README listing each file and the script that made it. These results replace the release checks of Stage B step 1.

**Commit:** `VegVault 2.0.0: compare the project windows with 1.0.0`.

## Step V6: documentation

- **`Data/Input/README.md`:** VegVault 2.0.0, its SHA-256, the DOI once deposited (a placeholder until then), vaultkeepr 0.2.0, and the archived v1 file.
- **`Data/Input/Trait_corrections/README.md`:**
  - rewrite the sections on source rules, the interim release and provisional leaf mass per area;
  - describe the folder layout, the domain unit table, the three runners and the procedure for the next VegVault version;
  - mark the v1 workflow sections as provenance.
- **Header comments** of `pipeline_traits_reference.R` and `run_traits_reference_pipeline.R`, and the README of the latter.
- **`.ai/agents/trait-correction-policy-reviewer.agent.md`** points at the v1 output folders. Mark it as v1-only, or point it at the v2 folders.
- **`Documentation/Manuscript/sections/03_methods.qmd`.**
  - The setup chunk (`:15-81`) reads the v1 decision files. Update its paths in V3a, or the render breaks.
  - The prose at `:119`, `:125` and `:331-365` waits for the manuscript rewrite: the version; present-day climate from CHELSA V2.1, not TraCE21k; the trait-correction method.
- **Commit:** `Documentation: describe the VegVault 2.0.0 inputs and trait corrections`.

## Finishing the stage

1. Run `generate_r_architecture_inventories.R`, `Document_functions.R`, `check_r_architecture.R`, `Generate_configuration.R` and `Check_configuration.R`, then `Testing/Run_tests.R`.
2. Run the CZ smoke run (`R/03_Supplementary_analyses/Testing/Smoke/run_cz_pipelines.R`) on fresh stores under `Data/Temp/`.
3. Ask for an independent review with `.ai/agents/changes-reviewer.agent.md`. A self-review does not count.
4. Report, in this order:
   - what changed, per step;
   - check results;
   - what was not verified;
   - the retirement-check, V4 and V5 tables;
   - Ondřej's decision queue;
   - the proposed commits and PR relationships: Part of [#180]; needed before [#179], [#205] and [#207].

**Done when:**

- all checks pass;
- the CZ smoke run and the trait pipeline, through to the release, pass on v2;
- the retirement check has no `still_unscaled` rule;
- the V4 and V5 tables are drafted.

## After Stage V

- **Stage C and [#179] run alongside each other** on v2. The modern viability check of [#179] uses the plot threshold that Ondřej sets from the Stage C diagnostics.
- **Schedule.**
  - Dates: the grant ends on 31 Dec 2026; the methods meeting is in the week of 14 Dec; Round 1 is due on 11 Jan 2027.
  - Compute: the published spatial units alone took about 140 h (`refit_cost_by_unit.csv`).
  - [#179] has no implementation yet and specifies a full benchmark. It is the largest risk to these dates.
  - Decision checkpoint: 4 Dec 2026 (Ondřej, 26 Nov 2026). If [#179] has no adoption decision by then, Stage B uses the current hierarchical classification, which [#179] itself names as a valid outcome.
- **Before Stage B starts:**
  - re-pin vaultkeepr to its tag (V0);
  - remove the Europe and America 0 ka exclusions if `bes-2026-presentation` has been merged;
  - keep the Asia exclusion unless V5 finds at least 10 samples.

## Risks

| Risk | Check |
|---|---|
| Swapping the database leaves stores up to date | `config_vegvault_release`, and a test that the validator reports `config_changed` |
| v1 trait corrections applied to v2 values | Version-specific folders; header-only v2 decisions; retirement check |
| `get_traits(classify_to = "original")` too slow on continental windows | Timing first in V2; fix in vaultkeepr before tagging |
| VegVault 2.0.0 rebuilt under the same version string | `manifest_sha256` is part of `config_vegvault_release` |
| vaultkeepr changes between `4a65799` and the tag | Empty `R/` diff before Stage B |
| New taxon names stop the classification checks | V4 diagnostic before V3f step 4 |
| A v1 source rule is not fixed at source | Retirement check stops the migration |
| Edits to shared trait functions invalidate functional-type targets | Intended before the rebuild; all edits finish before Stage B |
| [#179] delays Stage B past the dates above | Decision checkpoint on 4 Dec 2026 |

<!-- Issue and pull-request links -->

[#179]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/179
[#180]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/180
[#202]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/202
[#205]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/205
[#207]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/207
[#214]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/pull/214
