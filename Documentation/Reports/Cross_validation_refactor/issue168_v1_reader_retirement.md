# Issue 168 native-v2 reader retirement

**Issue:** #168
**Baseline:** `main` at `709c2b3d` (PR #172)
**Branch:** `issue168-retire-v1-cv-readers`
**Date:** 2026-08-12

## Decision

The retirement gate passed before reader changes began. Inspection followed actual cross-store caller edges in maintained pipelines and reporting code rather than target-name heuristics. Every retained source inspected exposed exactly one successful canonical target for each requested artifact, a non-empty metadata data hash, a valid `2.0.0` content hash, and native provenance (`source_schema_version = "2.0.0"`, `migration_applied = FALSE`, `migration_function = NA`).

No retained v1 source was found, so no store was archived or regenerated before reader removal. Old main-production outputs awaiting #171, frozen one-time validation stores, and ad hoc stores are historical and do not block retirement. Component and structured-regularization reference output stores are retained consumers of `cz_paleo_cv_reference_gpu`; they are not v1 artifact sources.

## Retained cross-store audit

| Consumer | Source store | Canonical target | Artifact type | Metadata hash | Content hash | Provenance | Decision |
|---|---|---|---|---|---|---|---|
| Component reference | `Data/targets/cz_paleo_cv_reference_gpu/pipeline_paleo_core` | `list_cross_validation_design_artifact` | `cross_validation_design` | `656a560a4541d183` | `fc10ad6649059c94` | Native v2 | Retain |
| Component reference | `Data/targets/cz_paleo_cv_reference_gpu/pipeline_paleo_core` | `list_sjsdm_regularization_selection_artifact` | `sjsdm_regularization_selection` | `2bd89c39344a661a` | `02b70ebb0ee34990` | Native v2 | Retain |
| Structured-regularization reference | `Data/targets/cz_paleo_cv_reference_gpu/pipeline_paleo_core` | `list_cross_validation_design_artifact` | `cross_validation_design` | `656a560a4541d183` | `fc10ad6649059c94` | Native v2 | Retain |
| Structured-regularization reference | `Data/targets/cz_paleo_cv_reference_gpu/pipeline_paleo_core` | `list_sjsdm_regularization_selection_artifact` | `sjsdm_regularization_selection` | `2bd89c39344a661a` | `02b70ebb0ee34990` | Native v2 | Retain |
| Staged tier aggregation | `Data/targets/cz_paleo_cv_staged_reference_gpu/pipeline_paleo_core` | `list_sjsdm_cv_tuning_artifact` | `sjsdm_cv_tuning` | `b58333c6dfcfef15` | `cbcb156ad3530e15` | Native v2 | Retain |
| Staged unit completion | `Data/targets/cz_paleo_cv_staged_reference_gpu/pipeline_sjsdm_tier_tuning` | `list_sjsdm_tier_tuning_artifact` | `sjsdm_tier_tuning` | `f9cc7edafe3dd84a` | `1bf0fdf49899ca95` | Native v2 | Retain |
| CZ paleo smoke/reporting | `Data/targets/cz_paleo/pipeline_paleo_core` | `list_sjsdm_cv_evaluation_artifact` | `sjsdm_cv_evaluation` | `e37c3e475859a393` | `d14b6e8bd530fc17` | Native v2 | Retain |
| CZ modern shared-design smoke | `Data/targets/cz_modern/eu_r005_l014/pipeline_modern_spatial_resolution_test` | `list_cross_validation_shared_design_artifact` | `cross_validation_shared_design` | `1f6480b019968b1c` | `8ac4f8e92243fbe8` | Native v2 | Retain |

The same retained GPU source also contained valid native-v2 tuning (`823d9200997fd85e`), prediction (`182679941e679d53`), and evaluation (`afd24d9327795810`) artifacts. The staged unit source contained valid selection (`09d1e9523aad1a6b`), prediction (`d3ad03c99a12b4b0`), and evaluation (`2ff0f69ae8c0320d`) artifacts. These establish complete native-v2 source coverage for the maintained reference path.

## Implementation evidence

The TDD red run produced 9 expected failures across 38 assertions: legacy fallback calls were still attempted, raw legacy tuning tables were accepted, migrated provenance was accepted, and migration-only function arguments remained public. After implementation, the focused loader, tier, provenance, envelope, reporting, and pipeline-contract checks passed 84 assertions with no failures or warnings.

Implementation removed the generic converter, nine artifact/table converters, the versioned loader, their matching tests, all active v1 target arguments, the tier fallback branch, and raw tuning-table acceptance. The fourteen-row compatibility ledger was deleted because no validator requires an empty ledger.

## Validation log

### Tests and fail-closed behavior

The initial TDD red run produced 9 expected failures across 38 assertions. A later restartability regression produced 2 expected failures before the tier creation-time dependency was corrected. Focused loader, tier, provenance, envelope, reporting, and pipeline-contract tests then passed, including explicit rejection of raw legacy tier and tuning tables, migrated provenance, malformed envelopes, and missing canonical targets without a v1 probe.

The final repository wrapper command was `Rscript R/03_Supplementary_analyses/Testing/Run_tests.R`. It passed in 181.5 seconds as part of the final combined validation. The full suite contains 4,443 expectations across 105 recursively discovered test directories: 4,442 passes, 1 skip, 0 failures, and 0 warnings.

All 23 changed or added R files parsed successfully. The active-source search across `R/Functions`, `R/Pipelines`, `R/02_Main_analyses`, and the smoke root found no `convert_v1_*`, `convert_sjsdm_v1_artifact`, `load_sjsdm_versioned_artifact`, `v1_target_name`, `v1_target_names`, or legacy tier-target fallback.

### Reference behavior

The component reference was run from `project_cz_paleo_cv_component_reference_gpu` into `Data/targets/cz_paleo_cv_component_reference_gpu/issue168_native_v2/pipeline_cz_paleo_cv_component_reference`. It completed 24 targets with 0 skipped in 4m 12.8s. Assignments, the selected candidate, and the spatial-only, intercept-only, and abiotic-only repeat distributions were identical to the established reference objects; their xxHash64 object digests were `f9e929c6793792e5`, `e597c8eb822670e8`, `382d0ea123580d2f`, `b0f20b1aec089cfd`, and `2ca8052f12dcb5db`.

The structured-regularization reference was run from `project_cz_paleo_cv_regularization_reference_gpu` into `Data/targets/cz_paleo_cv_regularization_reference_gpu/issue168_native_v2/pipeline_cz_paleo_cv_regularization_reference`. It completed 32 targets with 0 skipped in 25m 13s. Assignments, selected candidate, selected regularization, selection diagnostic, both guardrail objects, and selected repeat distributions were identical to the established reference objects; their digests were `f9e929c6793792e5`, `e597c8eb822670e8`, `6ed395ee9b68a2e3`, `2a1a4fd466dffbbd`, `09d5580d8f0a78b9`, `022065677b9716b4`, and `e7f9111b59c1bf92`.

### CZ smoke artifacts

`Rscript R/03_Supplementary_analyses/Testing/Smoke/run_cz_pipelines.R` completed the fresh paleo core, paleo resolution, and modern spatial workflows in 1,952.3 seconds. The runner exited successfully; its only diagnostics were the repository's existing target/renv messages. Every emitted canonical artifact was read directly and passed native-v2 envelope validation.

| Smoke store | Canonical target | Metadata hash | Content hash |
|---|---|---|---|
| `Data/targets/cz_paleo/pipeline_paleo_core` | `list_cross_validation_design_artifact` | `2e4b182af2461177` | `8a2a22ca7f23084d` |
| `Data/targets/cz_paleo/pipeline_paleo_core` | `list_sjsdm_cv_tuning_artifact` | `4bdc0913742db813` | `1b03253f6e6d359b` |
| `Data/targets/cz_paleo/pipeline_paleo_core` | `list_sjsdm_regularization_selection_artifact` | `301d4730375ce121` | `584cb6ace2a4ab18` |
| `Data/targets/cz_paleo/pipeline_paleo_core` | `list_sjsdm_cv_prediction_artifact` | `d8d3d4f2e62696f0` | `5b766326dbbcad3f` |
| `Data/targets/cz_paleo/pipeline_paleo_core` | `list_sjsdm_cv_evaluation_artifact` | `0513c4c842e48367` | `d14b6e8bd530fc17` |
| `Data/targets/cz_paleo/pipeline_paleo_resolution_test` | `list_cross_validation_shared_design_artifact` | `bf5dafca2ff126af` | `b481aa4508d5917b` |
| `Data/targets/cz_modern/eu_r005_l014/pipeline_modern_spatial_resolution_test` | `list_cross_validation_shared_design_artifact` | `42b846c10ebe0d5c` | `8ac4f8e92243fbe8` |

Each row had `source_schema_version = "2.0.0"`, `migration_applied = FALSE`, and `migration_function = NA`.

### Same-code resume

The retained staged stores were first synchronized to current code without deletion. The tier creation-time target was then made content-dependent instead of always-cued, with a red/green pipeline-contract regression, so unchanged native-v2 source summaries cannot rematerialize the public tier envelope.

An immediate same-final-round rerun targeted `list_sjsdm_cv_tuning_artifact` in `Data/targets/cz_paleo_cv_staged_reference_gpu/pipeline_paleo_core` with `SJSMD_TUNING_MAX_ROUND=3`, followed by `list_sjsdm_tier_tuning_artifact` in `Data/targets/cz_paleo_cv_staged_reference_gpu/pipeline_sjsdm_tier_tuning`. Exact pre/post metadata comparison covered 70 dynamic tuning-fit branches and both canonical artifacts. All 72 target hashes and timestamps were identical. The unit artifact remained at metadata hash `44e38b96e47f26c0` and content hash `cbcb156ad3530e15`; the tier artifact remained at metadata hash `039e7e70f25a7d96` and content hash `1bf0fdf49899ca95`.

### Architecture and documentation

`generate_persisted_contract_manifest_inventory.R` recorded 18,270 profile-target rows and resolved all 26 configured profiles in 663.4 seconds on the final code. `generate_r_architecture_inventories.R` recorded 525 scripts, 390 function-inventory rows, and 423 literal targets. The blocking checker passed twice with 0 findings across 0 types, and both outputs were byte-identical before, between, and after the two runs. The final SHA256 hashes are `F261DD07EFB236864C8A4E2A16529529BE4DA6F979F42A6C953664A6B1025288` for `architecture_findings_current.csv` and `958F6212A5419FB87FB68F850BE39B28F36F8E4E1EFD915592A096103EC74C30` for the dependency map.

The registered v2 contract MD5 remains `717435760b653dce608ce51380ec0fb1`. Function documentation was regenerated for 340 active functions and the website rendered successfully. Raw HTML, PDF, TXT, Quarto source, and published HTML each contain the same 340 function names with zero set differences. The 11 retired APIs disappeared from all five documentation layers: 33 raw function files, 11 Quarto pages, and 11 published pages were removed.

### Protected history and local review

The historical Issue #141 plan, validation record, frozen baseline/manifest material, correctness reports, benchmark evidence, and frozen fixtures were not edited. `git diff --check` passes. Smoke/reference-only progress dashboards and two reproducible trait artifacts generated during validation were cleaned from the worktree; the isolated targets stores remain available under their documented `issue168_native_v2` paths.

The mandatory local read-only review covered all active runtime changes, deleted APIs and tests, fixture adapters, pipeline contracts, compatibility records, inventories, generated function documentation, and published website outputs. One medium-severity finding was identified and resolved: an always-cued tier creation timestamp caused canonical artifact rematerialization on same-code resumes. A regression and content-dependent source-evidence dependency now prevent it. One test-infrastructure finding was also resolved by inventorying the nested reporting-fixture adapter. No high- or medium-severity findings remain.

No files were staged or committed, and no branch was pushed. No GitHub issue or pull-request mutation was performed.
