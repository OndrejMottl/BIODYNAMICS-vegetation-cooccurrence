# Age Scaling Diagnostic Scripts

This folder contains the diagnostic scripts used to identify and test the
age-scaling issue in paleo decomposition models.

The folder name uses `age_scalling` to match the project diagnostic label used
during this investigation.

## Scripts

- `run_cz_decomposition_diagnostic.R`
  Initial CZ diagnostic comparing pooled, spatial, spatiotemporal, and temporal
  routes.
- `run_cz_decomposition_age_main_diagnostic.R`
  CZ diagnostic testing age as a main effect while age was still center-scaled.
- `run_cz_decomposition_age_z_diagnostic.R`
  CZ diagnostic testing z-scored age main effect and z-scored age interaction.
- `run_asia_decomposition_age_minimal_diagnostic.R`
  Minimal whole-Asia diagnostic comparing current center-scaled age interaction
  with z-scored age main and interaction routes.
- `run_asia_decomposition_method_comparison_diagnostic.R`
  Method comparison diagnostic comparing sjSDM ANOVA decomposition with held-out
  predictive ablation decomposition on the same folds.

## Outputs

All diagnostic outputs are written to:

`Documentation/Reports/Diagnostics/age_scalling`

The helper functions used by these scripts live in:

`R/Functions/Modelling/Decomposition_diagnostics`

The consolidated narrative summary is:

`Documentation/Reports/Diagnostics/age_scalling/Summary.md`
