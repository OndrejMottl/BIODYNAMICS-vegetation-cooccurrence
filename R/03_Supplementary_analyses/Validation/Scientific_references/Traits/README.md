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

Run from the repository root with the restored environment, `Data/Input/VegVault.sqlite` (VegVault 2.0.0, see `Data/Input/README.md`), and the reviewed files of its release folder `Data/Input/Trait_corrections/VegVault_2_0_0/`.

## Outputs and interpretation

The `{targets}` store is `Data/targets/traits_reference`. The pipeline extracts trait records, performs quality control and taxonomic alignment, classifies functional types, and builds the reference trait table. The raw and classified review stages each stop at a check until every candidate has an approved decision in the release folder; `Data/Input/Trait_corrections/README.md` describes the review, the sorting and approval runners, and the decision schema.

## Regeneration and retirement

Regenerate when the trait reference inputs or approved corrections change. Keep the runner while `project_traits_reference` remains an active supported reference profile.
