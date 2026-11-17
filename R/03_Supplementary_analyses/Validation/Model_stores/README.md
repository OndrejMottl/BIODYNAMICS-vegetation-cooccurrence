# Model store freshness validation

## Purpose and backstory

Unit tests check what each function does, not whether the stores behind a published table were rebuilt after the code changed. In 2026 the temporal models stayed on unpenalised June fits while the spatial models were refitted with the calibrated cross-validated workflow, and nothing caught it (issue #208). This validator checks, before any table, figure or report is republished, that every store feeding published model results is current.

Selective reruns deliberately leave some targets outdated. Those are recorded in the model store freshness ledger, `Documentation/Implementation_inventories/Model_stores/model_store_freshness_ledger.csv`. Each row names a store, a target pattern, the reason, the evidence, an owner, and the issue with which it expires (a later full rerun of all models). The validator fails on any outdated target not covered by the ledger and on ledger rows that no longer cover anything.

## Status and entry point

Status: active; required before republishing model tables, figures, or reports.

Check every production store:

```powershell
rig run -r 4.5.1 R/03_Supplementary_analyses/Validation/Model_stores/Validate_model_stores.R
```

Restrict the run, or inspect copies of stores:

```powershell
rig run -r 4.5.1 R/03_Supplementary_analyses/Validation/Model_stores/Validate_model_stores.R --store-kind=temporal
rig run -r 4.5.1 R/03_Supplementary_analyses/Validation/Model_stores/Validate_model_stores.R --store=Data/targets/paleo_spatial_local/eu_r001_l001/pipeline_paleo_spatial_resolution
rig run -r 4.5.1 R/03_Supplementary_analyses/Validation/Model_stores/Validate_model_stores.R --store-root=Data/Temp/store_audit
```

Also check published tables for provenance columns (`regularization_source`, `candidate_id`, `cv_strategy`, `final_model_built_at`, `variance_partition_built_at`):

```powershell
rig run -r 4.5.1 R/03_Supplementary_analyses/Validation/Model_stores/Validate_model_stores.R --store-kind=temporal --table=Outputs/Tables/<table>.csv --table-availability=availability_status
```

Other arguments: `--profile=<profile_id>` (repeatable). `--store` and `--store-kind` are repeatable.

## Prerequisites and configuration

Run from the repository root with the pinned R version. Stores are listed by `load_model_store_index()` from the main, active profiles in `config.yml`: spatial unit stores, temporal stores, tier-tuning stores, and common-regularization sensitivity stores. With `--store-root`, the profiles' relative `target_store` paths are resolved below that root, so copies must keep the `<target_store>/<scale_id>/<pipeline_name>` layout.

The check builds nothing. Each store costs one `targets::tar_outdated()` call, which sources the pipeline definition (about 15 seconds); the manifest and network are read once per pipeline and profile. A full sweep of all production stores therefore takes a few hours; run it in the background or restrict it.

## Outputs and interpretation

Every run writes `Data/Temp/Model_store_validation/model_store_freshness_<timestamp>.csv` with one row per finding and prints a summary. Finding types:

- `outdated`, `missing_metadata`, `config_changed`, `errored_unexpected`, `diagnosis_failed`: blocking unless a ledger row covers them.
- `stale_ledger_row`: a ledger row that matches no outdated target; always blocking. Remove the row.
- `errored_expected`, `always_cued_not_evaluated`: informational. Expected errors are documented infeasible units; always-cued targets rerun on every build by design.
- `store_missing`: informational for spatial unit stores, because most grid units have no store; blocking for temporal, tier-tuning and sensitivity stores and for any store named with `--store`. A `--store` value that is not an indexed store aborts the run.

The script exits with an error when anything blocks. `resolution_status` in the CSV is `blocking`, `ledger_covered`, or `informational`.

## Regeneration and retirement

Run this check before every republication of model products and after every selective rerun, and keep the ledger in step with deliberate exceptions. Ledger rows are removed when their expiry issue closes. The workflow stays active while published results are built from `{targets}` stores.
