# Age Scaling Diagnostic Helper Functions

This folder contains helper functions created for the age-scaling diagnostic
work. They are kept separate from the core modelling helpers because they are
diagnostic infrastructure rather than the final production pipeline.

The functions support:

- Loading CZ and continental Asia targets for diagnostic runs.
- Rebuilding fold-local model inputs with train-only scaling.
- Comparing center-scaled age with z-scored age.
- Running checkpointed predictive ablation cross-validation.
- Summarising predictive decomposition shares.
- Comparing sjSDM ANOVA component shares with held-out predictive shares.

The key technical finding from these helpers is that age must be scaled to unit
standard deviation when it is used in an interaction term such as `bio1 * age`.
Centering age alone leaves it on a much larger numerical scale than the other
predictors and can make decomposition diagnostics unstable or undefined.

Scripts using these helpers are in:

`R/03_Supplementary_analyses/_Diagnostics/age_scalling`

Outputs and the narrative summary are in:

`Documentation/Reports/Diagnostics/age_scalling`
