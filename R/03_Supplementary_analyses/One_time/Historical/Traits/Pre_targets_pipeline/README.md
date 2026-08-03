# Historical pre-targets trait workflow

## Purpose and backstory

These three scripts preserve the sequential trait-processing workflow that
predated `pipeline_traits_reference.R`. They previously lived in an `_archive`
folder under active data processing, where their superseded status was easy to
miss.

## Historical sequence

The original order was:

1. `01_extract_trait_data.R`
2. `02_classify_and_align_taxa.R`
3. `03_build_trait_table.R`

The scripts are retained for provenance only. They are not supported entry
points and may refer to function names or intermediate artifacts that have
since been replaced.

## Current workflow

Use the stable traits reference runner instead:

```powershell
Rscript R/03_Supplementary_analyses/Validation/Scientific_references/Traits/run_traits_reference_pipeline.R
```

## Retirement policy

Keep this folder while the transition from the sequential workflow to the
`{targets}` pipeline needs to remain auditable. Remove it only after verifying
that the reference pipeline and its documentation fully preserve the required
reproducibility record.
