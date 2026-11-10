# Per-taxon variance partition diagnostics

## Purpose and backstory

This diagnostic asks whether the variance partition can be compared between nested spatial extents on the same taxa, without refitting any model. It was started in November 2026 while revising the manuscript direction, after the association share was found to track the number of taxa in a model. Every stored variance-partition object already holds the site-by-taxon log-likelihood of each fraction, so the partition can be read per taxon.

The workflow also documents how the published model-level share is defined and why per-taxon values do not add up to it. The published share (`R2_Nagelkerke_percentage`) clamps each of the seven fractions at zero on the Nagelkerke scale and splits shared fractions equally among climate, associations, and space. Nagelkerke R2 of a fraction is `1 - exp(-deviance / n_samples)` with the deviance summed over taxa, so it saturates as taxa are added and is not additive across taxa or across fractions. Only the deviance is additive.

## Status and entry point

Status: exploratory diagnostic. Nothing here is a production result and no decision rule has been frozen.

Run the three scripts in order from the repository root:

```powershell
$path_diagnostic = "R/03_Supplementary_analyses/Diagnostics/Modelling/Variance_partitioning/Taxon_partition"
Rscript "$path_diagnostic/extract_taxon_variance_partition.R"
Rscript "$path_diagnostic/reconcile_taxon_variance_partition.R"
Rscript "$path_diagnostic/compare_nested_extent_partition.R"
```

## Prerequisites and configuration

Project dependencies must be restored for the R version in use. The work list comes from the newest `paleo_variance_partitioning_unit_*.csv` and `modern_variance_partitioning_unit_*.csv` in `Outputs/Tables/Visualisation/`, and from the `model_anova_timeslice_*` targets of the three `Data/targets/paleo_temporal_<continent>/pipeline_paleo_temporal` stores. The spatial stores named in the unit tables must be present. The scripts only read the stores; they need no fitting backend and no configuration profile.

## Outputs and interpretation

All tables are written to `Outputs/Tables/Diagnostics/Taxon_variance_partition/` with the run date in the file name.

| File | Content |
|---|---|
| `model_variance_partition_<date>.csv` | Deviance, Nagelkerke R2, and McFadden R2 of every fraction for every stored model. |
| `taxon_variance_partition_<date>.csv` | The same quantities for every taxon of every model. |
| `model_share_definitions_<date>.csv` | Association share and climate-to-space balance of every model under five definitions. |
| `taxon_allocation_reconciled_<date>.csv` | Per-taxon climate, association, and space allocation on the deviance scale, plus the unique fractions. |
| `nested_extent_contrasts_<date>.csv` | Child and parent shares on shared taxa and on all taxa, one row per child unit. |

The reconciled per-taxon allocation drops a fraction for every taxon when that fraction is negative for the whole model, then splits shared fractions equally. Summed over the taxa of a model it equals the published rule applied on the deviance scale (`deviance_clamped`). It differs from the published share only by the Nagelkerke transform.

Read the results with these limits in mind. Single-taxon values are noisy and should not be interpreted taxon by taxon; compare sums over sets of taxa. Units that share a parent are not independent, so the printed p-values are optimistic. The value "at equal size" is a regression intercept and is partly an extrapolation, because parent models almost always hold more taxa. Only two or three continental models exist per data source and resolution.

## Regeneration and retirement

Rerun all three scripts after the spatial or temporal stores, or the published unit tables, change. Retire the workflow if the per-taxon comparison is dropped from the manuscript plan, or replace it with tested functions under `R/Functions/` and a pipeline target if the comparison becomes a core analysis.
