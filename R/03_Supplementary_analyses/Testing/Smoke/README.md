# Pipeline smoke workflows

## Purpose and backstory

This folder contains small end-to-end workflows that exercise representative
pipeline paths. The Czechia runner was moved out of the main-analysis tree
under issue #152 because it is a destructive validation gate rather than a
primary analysis.

## Status and entry point

Status: active smoke validation.

Supported entry point:
`run_cz_pipelines.R`.

Run from the repository root:

```powershell
Rscript R/03_Supplementary_analyses/Testing/Smoke/run_cz_pipelines.R
```

## Prerequisites and configuration

Restore project dependencies and provide the configured paleo and modern input
data. The runner selects `project_cz_paleo` and `project_cz_modern`
internally. Both profiles are active smoke profiles generated from
`Configuration/Profiles/Validation/cz_smoke.yml`.

## Outputs and interpretation

The runner rebuilds the Czechia paleo core, paleo resolution, and modern
spatial test stores below `Data/targets`. Existing stores for these profiles
are replaced because every call uses `fresh_run = TRUE`. Success demonstrates
that representative pipelines execute; it does not validate all production
profiles or replace scientific reference comparisons.

## Regeneration and retirement

Run after shared pipeline, configuration, modelling, or preprocessing changes
when a fresh end-to-end gate is required. Keep the runner while these profiles
remain the repository's supported small integration test. Retire only with a
documented replacement and update all validation guidance. Related work: issue
#152, issue #149, and the frozen cross-validation contracts in issue #141.
