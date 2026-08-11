# Traits reference pipeline

## Purpose and backstory

This folder owns the stable runner for the functional-trait reference pipeline. It previously lived under `R/01_Data_processing`, although it uses a frozen reference profile and produces validation artifacts rather than normal production data-processing outputs.

## Status and entry point

Status: active frozen scientific-reference workflow.

Run from the repository root:

```powershell
Rscript R/03_Supplementary_analyses/Validation/Scientific_references/Traits/run_traits_reference_pipeline.R
```

The runner activates `project_traits_reference` and explicitly authorises its reference role and frozen status.

## Prerequisites and configuration

Run from the repository root with the restored environment, source trait inputs, and approved manual-correction table available.

## Outputs and interpretation

The `{targets}` store is `Data/targets/traits_reference`. The pipeline extracts trait records, performs quality control and taxonomic alignment, classifies functional types, and builds the reference trait table. Its documented human review gate may require updates to `Data/Input/trait_manual_corrections.csv`.

## Regeneration and retirement

Regenerate when the trait reference inputs or approved corrections change. Keep the runner while `project_traits_reference` remains an active supported reference profile.
