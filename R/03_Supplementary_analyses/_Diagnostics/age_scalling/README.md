# Age Scaling Diagnostic Scripts

## Purpose and backstory

This folder contains the diagnostic scripts used to identify and test the age-scaling issue in paleo decomposition models.

The folder name uses `age_scalling` to match the project diagnostic label used during this investigation.

## Status and entry point

Status: retained active diagnostic evidence. Select the script matching the question below; the files are not a sequential pipeline.

### Scripts

- `run_cz_decomposition_diagnostic.R` Initial CZ diagnostic comparing pooled, spatial, spatiotemporal, and temporal routes.
- `run_cz_decomposition_age_main_diagnostic.R` CZ diagnostic testing age as a main effect while age was still center-scaled.
- `run_cz_decomposition_age_z_diagnostic.R` CZ diagnostic testing z-scored age main effect and z-scored age interaction.
- `run_asia_decomposition_age_minimal_diagnostic.R` Minimal whole-Asia diagnostic comparing current center-scaled age interaction with z-scored age main and interaction routes.
- `run_asia_decomposition_method_comparison_diagnostic.R` Method comparison diagnostic comparing sjSDM ANOVA decomposition with held-out predictive ablation decomposition on the same folds.

## Prerequisites and configuration

Run from the repository root with the matching diagnostic profile and isolated target store. Do not use a production target store.

## Outputs and interpretation

All diagnostic outputs are written to:

`Documentation/Reports/Diagnostics/age_scalling`

The helper functions used by these scripts live in:

`R/Functions/Modelling/Decomposition_diagnostics`

The consolidated narrative summary is:

`Documentation/Reports/Diagnostics/age_scalling/Summary.md`

These artifacts diagnose model behavior and do not redefine production model contracts.

## Regeneration and retirement

Regenerate only to reproduce the age-scaling investigation. Retire the scripts only after the report, configuration, and model-comparison provenance have a durable replacement.
