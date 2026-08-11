# Fold-local CV pipeline integration (v1)

**Recorded:** 2026-07-15 **Validation runner:** `R/03_Supplementary_analyses/Testing/Smoke/run_cz_pipelines.R` **Validation result:** completed with exit code 0

## Purpose

This checkpoint integrates the corrected fold-local predictive evaluation into both cross-validation pipe segments. It publishes the corrected outputs under new target names while retaining `model_evaluation_cross_validated` as the historical pooled compatibility artifact.

The new target chain is:

1. `data_sjsdm_fold_local_metrics`
2. `list_sjsdm_fold_metric_summaries`
3. `list_sjsdm_metric_repeat_distributions`

## Fresh CZ validation

The complete CZ test runner was executed after the integration. GPU/CUDA preflight passed, and all three rebuilt target stores completed without a recorded target error.

| Store | New targets | Target errors |
|---|---:|---:|
| CZ paleo core | 3 | 0 |
| CZ paleo resolution test | 9 | 0 |
| CZ modern spatial resolution test | 9 | 0 |

The resolution stores each contain one complete three-target chain per taxonomic branch. Paleo produced `genus`, `family`, and `functional_type` branches; modern produced `genus`, `family`, and `ft_modern` branches.

## Direct paleo artifact contract

The fresh CZ paleo core output contains 960 fold-local metric rows and 11 columns:

`repeat_id`, `fold_id`, `taxon`, `prediction_source`, `metric_id`, `estimate`, `metric_status`, `n_observations`, `n_presences`, `n_absences`, and `prevalence`.

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

## Provenance extension

The final Phase 3 slice extended `data_sjsdm_model_provenance` additively from 24 to 29 columns. The five appended fields are:

- `fit_device`;
- `evaluation_prediction_source`;
- `evaluation_estimand`;
- `evaluation_aggregation_methods`;
- `evaluation_schema_version`.

A fresh isolated GPU reference recorded `gpu`, `out_of_fold`, `repeat_fold_taxon`, `fold_macro;observation_weighted`, and `sjsdm_fold_local_cv_v1`, respectively. The artifact retained three repeats, 15 successful fold fits out of 15, and had data hash `19cffe27d6c58bde`. The store reported zero target errors; all 120 tuning fits also had status `ok`.

The full regression suite reported 3,381 passes, zero failures, and the single documented opt-in VegVault integration skip. The mandatory fresh CZ gate then completed successfully and validated all seven provenance artifacts:

| Unit | Provenance hash |
|---|---|
| Paleo core, genus | `0abfbcbf3c16ebb7` |
| Paleo resolution, family | `434559507b4415f4` |
| Paleo resolution, functional type | `464cbb1f501ac889` |
| Paleo resolution, genus | `0abfbcbf3c16ebb7` |
| Modern resolution, family | `329cbbabb07d24b2` |
| Modern resolution, genus | `5abc60fd2eb43667` |
| Modern resolution, functional type | `d136f2f1cc74c502` |

All three stores had zero target errors and zero incomplete targets. Every provenance target contained one row, 29 columns, and the expected five values.

## Compatibility and remaining work

The integration is additive: it does not rename or replace the pooled v1 evaluation target. A contract test now requires both direct and from-shared segments to publish the three new targets and retain the historical target.

The historical 24 provenance fields retain their order and meaning. The five evaluation fields are appended, so consumers selecting existing columns remain compatible. The dedicated three-repeat GPU rerun and CPU/GPU comparison are recorded in `cz_paleo_cpu_gpu_reference_comparison_v1.md`. Phase 3 is complete; the predictive-performance decision and model-component experiments remain Phase 4 work.
