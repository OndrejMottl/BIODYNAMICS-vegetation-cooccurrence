# Age Scaling Diagnostic Reports

This folder contains the generated tables, figures, checkpoint folders,
reports, and summary for the age-scaling diagnostic work.

The root folder is kept as an index. Run-specific outputs live in subfolders
so reruns can preserve previous diagnostics and avoid mixing unrelated tables.

## Contents

- `cz_baseline/`
  Initial CZ route comparison outputs.
- `cz_age_main/`
  CZ age-main diagnostic outputs using center-scaled age.
- `cz_age_z/`
  CZ diagnostic outputs using z-scored age.
- `asia_age_minimal/`
  Minimal whole-Asia comparison of current, z-scored main, and z-scored
  interaction routes.
- `asia_method_comparison/`
  Method comparison outputs for sjSDM ANOVA versus held-out predictive
  decomposition.
- `cz_predictive_pilot/`
  Early CZ predictive-decomposition pilot outputs and figure.
- `Summary.md`
  Narrative summary of the diagnostic process and findings.

## Linked Code

Diagnostic scripts:

`R/03_Supplementary_analyses/_Diagnostics/age_scalling`

Diagnostic helper functions:

`R/Functions/Modelling/age_scalling_diagnostic`
