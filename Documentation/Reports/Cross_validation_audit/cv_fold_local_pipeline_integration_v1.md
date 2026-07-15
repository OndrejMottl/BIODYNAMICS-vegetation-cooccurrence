# Fold-local CV pipeline integration (v1)

**Recorded:** 2026-07-15  
**Validation runner:** `R/02_Main_analyses/Run_CZ_test.R`  
**Validation result:** completed with exit code 0

## Purpose

This checkpoint integrates the corrected fold-local predictive evaluation into
both cross-validation pipe segments. It publishes the corrected outputs under
new target names while retaining `model_evaluation_cross_validated` as the
historical pooled compatibility artifact.

The new target chain is:

1. `data_sjsdm_fold_local_metrics`
2. `list_sjsdm_fold_metric_summaries`
3. `list_sjsdm_metric_repeat_distributions`

## Fresh CZ validation

The complete CZ test runner was executed after the integration. GPU/CUDA
preflight passed, and all three rebuilt target stores completed without a
recorded target error.

| Store | New targets | Target errors |
|---|---:|---:|
| CZ paleo core | 3 | 0 |
| CZ paleo resolution test | 9 | 0 |
| CZ modern spatial resolution test | 9 | 0 |

The resolution stores each contain one complete three-target chain per
taxonomic branch. Paleo produced `genus`, `family`, and `functional_type`
branches; modern produced `genus`, `family`, and `ft_modern` branches.

## Direct paleo artifact contract

The fresh CZ paleo core output contains 960 fold-local metric rows and 11
columns:

`repeat_id`, `fold_id`, `taxon`, `prediction_source`, `metric_id`, `estimate`,
`metric_status`, `n_observations`, `n_presences`, `n_absences`, and
`prevalence`.

The aggregation artifact contains:

- `data_source_summaries`: 24 rows by 16 columns;
- `data_paired_improvements`: 8 rows by 16 columns.

The repeat-distribution artifact contains:

- `data_source_repeat_distributions`: 24 rows by 13 columns;
- `data_paired_repeat_distributions`: 8 rows by 14 columns.

The fresh direct-store data hashes are:

| Target | Data hash |
|---|---|
| `data_sjsdm_fold_local_metrics` | `b72f171a59b7ec76` |
| `list_sjsdm_fold_metric_summaries` | `6354c2f7f63ccc2a` |
| `list_sjsdm_metric_repeat_distributions` | `9909a52ce4e42802` |

## Compatibility and remaining work

The integration is additive: it does not rename or replace the pooled v1
evaluation target. A contract test now requires both direct and from-shared
segments to publish the three new targets and retain the historical target.

The current model-provenance table does not yet contain a fitting-device field.
Recording device, estimand, aggregation method, source, and schema in provenance
therefore remains a separate Phase 3 task. The dedicated three-repeat GPU rerun
and CPU/GPU comparison are recorded in
`cz_paleo_cpu_gpu_reference_comparison_v1.md`.
