# Repository tests

## Purpose and backstory

This root contains the ordinary full `testthat` suite and targeted smoke workflows used to enforce repository and scientific contracts.

## Status and entry point

Status: active blocking validation. Run the full suite with:

```powershell
Rscript R/03_Supplementary_analyses/Testing/Run_tests.R
```

Use `Smoke/README.md` for the supported smoke workflows.

## Prerequisites and configuration

Restore the project environment and run from the repository root. Tests own their temporary state; smoke workflows use their documented profiles and stores.

## Outputs and interpretation

A zero exit status is required. Test reports and coverage artifacts are validation evidence, not scientific production outputs.

## Regeneration and retirement

Run the full suite after architecture or behavior changes. Retire tests only with the behavior or contract they protect, and update the function inventory.
