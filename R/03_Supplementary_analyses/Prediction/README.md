# Supplementary prediction workflows

## Purpose and backstory

These scripts run explicit prediction and full-grid projection workflows from completed fitted-model artifacts.

## Status and entry point

Status: analyst-invoked supplementary workflows. Use `Predict_from_model.R` for selected fitted models and `Predict_on_full_grid.R` for spatial grids.

## Prerequisites and configuration

Run from the repository root with the matching fitted-model store, profile, predictor schema, and spatial grid available. Review resource requirements before full-grid prediction.

## Outputs and interpretation

Outputs are derived predictions tied to the exact model, predictors, and grid used by the script. Preserve that provenance when interpreting or publishing them.

## Regeneration and retirement

Regenerate when the fitted model or prediction inputs change. Retire an entry point only after all downstream consumers use a documented replacement.
