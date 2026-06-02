# Age Scaling Diagnostic Summary

## Question

The original decomposition diagnostics suggested unstable or implausible
predictor importance. The main concern was whether this reflected a problem
with sjSDM ANOVA decomposition itself, with predictive cross-validation, or with
the way age entered the model.

The working hypothesis became:

1. The issue may be caused by age being centered but not scaled.
2. The problem may be amplified when using the ecological interaction
   `bio1 * age`.
3. If scaling age fixes convergence and decomposition stability, the original
   ANOVA approach may still be valid.

## Folder Structure

The generated results are organized by run so old diagnostics can be retained
for back comparison:

- `cz_predictive_pilot/`
  Early CZ predictive-ablation pilot outputs.
- `cz_baseline/`
  Initial controlled CZ route comparison.
- `cz_age_main/`
  CZ test of age as a main effect with center-only scaling.
- `cz_age_z/`
  CZ test of z-scored age, including the generated report.
- `asia_age_minimal/`
  Whole-Asia minimal comparison of current, z-main, and z-interaction routes.
- `asia_method_comparison/`
  Whole-Asia comparison of sjSDM ANOVA and predictive ablation.

Implementation plans are stored separately in:

`Documentation/Implementation_plans`

## Stage 1: Initial CZ Predictive Diagnostic

The first CZ diagnostic compared multiple pooled and temporal routes using
predictive ablation cross-validation.

Main findings:

- The no-age pooled spatiotemporal route was stable.
- Routes using age in the original formula were unstable or undefined.
- Associations had little or no held-out predictive gain.

This stage raised concern that both ANOVA and predictive CV could be unstable,
but it did not yet isolate the cause.

## Stage 2: CZ Age Main Effect Diagnostic

The next CZ test added age as a main effect rather than an interaction, while
keeping the original center-only age scaling.

Main findings:

- Center-scaled age main-effect routes were still undefined.
- The no-age reference route remained stable.

This suggested that the issue was not only the interaction form. The numerical
scale of age was a likely contributor.

## Stage 3: Confirming the Age Scaling Problem

Inspection of the fitted abiotic predictors showed that `bio1` was scaled to
unit standard deviation, while `age` was only centered. Age therefore retained a
standard deviation around 1280 years. In an interaction such as `bio1:age`, this
creates a predictor on a much larger numerical scale than the other model
inputs.

The diagnostic fold-preparation helper was extended with:

- `age_scale_mode = "center"`
- `age_scale_mode = "z_score"`

For `z_score`, age is divided by the training-fold standard deviation after
train-only centering, and the same training scale is applied to the test fold.

## Stage 4: CZ Z-Scored Age Diagnostic

The CZ diagnostic was rerun with z-scored age.

Main findings:

- Z-scored age routes became fully defined.
- Z-scored age main effect improved over the no-age reference in most paired
  folds.
- Z-scored interaction became stable but was only weakly better than the
  no-age route in CZ.

Interpretation:

- The primary technical failure was age scaling, not necessarily ANOVA.
- CZ may be too small to strongly support the interaction, but the interaction
  became computationally usable once age was scaled.

## Stage 5: Minimal Whole-Asia Diagnostic

A minimal whole-Asia diagnostic compared:

- Current center-scaled age interaction.
- Z-scored age main effect.
- Z-scored age interaction.

The run used 3 folds and 3 repeats, with per-fold checkpoints.

Main findings:

- Current center-scaled age interaction had no defined decomposition folds.
- Z-scored age main effect had all folds defined.
- Z-scored age interaction had all folds defined.
- Z-scored interaction was slightly better than z-scored main effect in held-out
  loss, but the margin was small.

Component shares:

- Z-scored main effect: abiotic about 60%, spatial about 40%, associations 0%
  by predictive ablation.
- Z-scored interaction: abiotic about 71%, spatial about 29%, associations 0%
  by predictive ablation.

Interpretation:

- On the larger Asia dataset, `bio1 * age_z` is stable and defensible.
- The interaction has ecological support and is not contradicted by the minimal
  predictive diagnostic.

## Stage 6: ANOVA Versus Predictive Decomposition

A final method comparison was run for whole Asia using z-scored age interaction.
For each fold, the script:

1. Fit the full model on the training fold.
2. Ran sjSDM ANOVA on the full training model.
3. Fit reduced models for held-out predictive ablation.
4. Compared ANOVA shares and predictive shares for the same fold.

Main findings:

- All full and reduced models converged.
- ANOVA and predictive decomposition agreed on the component ranking:
  Abiotic > Spatial > Associations.
- Both methods identified Abiotic as the strongest component in every fold.
- Spearman rank agreement across components was 1 in every fold.
- Magnitudes differed:
  - ANOVA assigned nonzero share to Associations.
  - Predictive ablation assigned Associations 0% held-out gain.

Interpretation:

- ANOVA is coherent after age scaling and agrees with predictive CV on broad
  component ranking.
- Predictive ablation answers a different question: held-out predictive gain
  from removing each component.
- ANOVA answers the package-native model decomposition question: how variance
  is partitioned in the fitted sjSDM model.

## Final Decision

The evidence supports returning to the original sjSDM ANOVA decomposition as
the primary method, with one mandatory technical correction:

Age must be scaled to unit standard deviation before modelling when age enters
the formula, especially for `bio1 * age`.

The ANOVA approach remains the preferred production route because:

- It is the method designed by the sjSDM package authors.
- It requires minimal changes to the existing pipeline.
- It gives ecologically plausible nonzero association contributions.
- It agrees with predictive diagnostics on the strongest and weakest component
  ranking after the scaling issue is fixed.

Predictive decomposition should be retained as a diagnostic sensitivity check,
not as the primary decomposition method.

## Next Implementation Step

The production pipeline should be updated so age is z-scored in the same way as
the other abiotic predictors before model fitting. After that, rerun a focused
CZ and Asia check to confirm that model fitting and ANOVA decomposition remain
stable with `bio1 * age_z`.
