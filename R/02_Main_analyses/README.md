# Main analyses

This directory is an executable, numbered reproduction workflow. Run exactly one master script in each folder, from `01_Preparation` through `05_Visualisation`. The master scripts run their `_components/` sequentially in isolated R sessions, stream progress, and write logs under `Data/Temp/Main_analysis_execution/`.

```powershell
Rscript R/02_Main_analyses/01_Preparation/01_run_preparation.R
Rscript R/02_Main_analyses/02_Model_calibration/01_run_model_calibration.R
Rscript R/02_Main_analyses/03_Model_fitting/01_run_model_fitting.R
Rscript R/02_Main_analyses/04_Synthesis/01_run_synthesis.R
Rscript R/02_Main_analyses/05_Visualisation/01_run_visualisation.R
```

The stages are deliberately action-specific. Preparation never fits a model. Calibration consumes only cached folds and publishes independent CV budgets. Model fitting uses those budgets and resumes existing target stores. Synthesis never launches fitting, and visualisation consumes completed model and synthesis products.

Rerun the same master script after interruption. `{targets}` reuses completed preparation and fitting work, accepted calibration representatives are reused, and every failed component has its own log. Use scripts under `_components/` only to recover or inspect a specific analysis; they are not additional mandatory steps.

Expected insufficient-data units are recorded and skipped. Missing preparation evidence, unpublished calibration budgets, incompatible legacy model artifacts, or unexplained target errors stop the dependent stage with a message naming the prerequisite master script.

The one-time migration from historical shared CV/final budgets is not part of clean reproduction. Its audit and invalidation utilities live under `R/03_Supplementary_analyses/One_time/Cross_validation/Fit_budget_migration/`.
