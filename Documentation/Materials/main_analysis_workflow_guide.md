# Main analysis workflow: from raw data to figures

This guide explains the complete five-stage modelling workflow. It distinguishes preparation, CV-budget calibration, regularization tuning, final-model fitting, synthesis, and visualisation, and explains what is cached and reused after interruption.

> **Core distinction:** Calibration selects a computational budget for cross-validation. Production tuning uses cross-validation to select regularization. Final fitting estimates the model on all available data using a separate final-model budget.

## Complete workflow

```text
Raw data and configuration
        |
        v
01 Preparation
  Clean and classify data, interpolate where required, determine CV
  feasibility, assign folds, and cache fold-specific model inputs.
        |
        v
02 Model calibration
  Use representative prepared folds to determine suitable CV-only
  iteration and sampling budgets, then publish those budgets.
        |
        v
03 Model fitting
  Tune regularization with the published CV budgets, fit final models
  on all data with separate budgets, and evaluate the models.
        |
        v
04 Synthesis
  Combine outputs across units, tiers, resolutions, and time periods.
        |
        v
05 Visualisation
  Build manuscript and diagnostic figures from current outputs.
```

For a complete reproduction, run these master scripts in order:

```powershell
Rscript R/02_Main_analyses/01_Preparation/01_run_preparation.R
Rscript R/02_Main_analyses/02_Model_calibration/01_run_model_calibration.R
Rscript R/02_Main_analyses/03_Model_fitting/01_run_model_fitting.R
Rscript R/02_Main_analyses/04_Synthesis/01_run_synthesis.R
Rscript R/02_Main_analyses/05_Visualisation/01_run_visualisation.R
```

Each master script starts its components sequentially in fresh R subprocesses. Scripts in `_components/` are recovery and selective-rerun entry points, not additional mandatory stages.

## Vocabulary

| Term | Meaning in this project |
|---|---|
| Analysis | One broad data design: paleo spatial, modern spatial, or paleo temporal. |
| Spatial tier | Continental, regional, or local. |
| Unit or spatial ID | One geographic analysis unit, such as `europe`, `eu_r005`, or `eu_r005_l006`. |
| Resolution | Genus, family, or functional type. Temporal analyses currently use genus time slices. |
| Model context | A compatible combination of tier, resolution, response family, predictor structure, and regularization grid. |
| CV repeat | One independently seeded assignment of locations to folds. Production uses three repeats by default. |
| CV fold | One held-out partition within a repeat. Five grouped folds are preferred. |
| Regularization candidate | One combination of six sjSDM alpha and lambda settings. The default grid contains eight candidates. |
| Candidate-fold fit | One temporary model fitted to a training fold for one candidate and scored on its held-out fold. |
| Calibration representative | A selected complex unit-resolution combination used only to determine an adequate CV fit budget. |
| Final model | The model fitted once to all available data for a unit and resolution after regularization selection. |
| Target | A cached object in a `{targets}` store. It may be data, a fold, a candidate result, a final model, or a summary. |

The current spatial grid contains 3 continental, 29 regional, and 262 local units. Because each can be analysed at three resolutions, there are up to 882 unit-resolution models per time period. Data limitations mean that not every potential model is feasible.

## Stage 01: preparation

### Purpose and order

Preparation performs the expensive data work shared by later fits. It stops at prepared CV folds and does **not** fit regularization candidates or final models.

The master runner executes:

1. Paleo spatial continental, regional, and local.
2. Modern spatial continental, regional, and local.
3. Paleo temporal Europe, America, and Asia.

Continental spatial preparation comes first because it publishes corrected functional-type classifications consumed by downstream tiers.

### What happens inside a spatial unit

For each unit, the pipeline works toward three endpoints:

```text
list_sjsdm_prepared_tuning_folds_genus
list_sjsdm_prepared_tuning_folds_family
list_sjsdm_prepared_tuning_folds_functional_type
```

The upstream work is:

1. Select geographic and temporal records.
2. Harmonise taxa and apply current trait/classification rules.
3. Build genus, family, and functional-type responses.
4. Extract and transform environmental predictors.
5. Interpolate paleo community data where required.
6. Check full-model and location-based holdout feasibility.
7. Create deterministic location-level CV assignments.
8. Prepare each fold once, including training/test responses, predictors, coordinates, and fold-local spatial terms.
9. Store those folds for calibration and production tuning.

`prebuild_interpolation = TRUE` allows the runner to request interpolation dependencies before fold targets. It does not mean “always recompute interpolation.” `{targets}` skips content-matched objects. A changed input, configuration hash, function dependency, missing object, or unreadable legacy object can make interpolation outdated.

### CV feasibility

The preferred strategy is spatially stratified grouped five-fold CV. If five folds leave too few training locations, the fold count is adapted and may become leave-one-location-out CV.

| Feasibility result | Later action |
|---|---|
| Grouped K-fold feasible | Tune regularization using this unit's CV. |
| Leave-one-location-out required | Tune using leave-one-location-out CV. |
| Holdout infeasible but full model feasible | Use compatible tier-pooled regularization for the final model. |
| Full model infeasible | Record the reason and do not fit a model. |

Too few samples, taxa, locations, viable groups, or an empty query are expected data limitations. They do not prevent independent units from being attempted. Unknown pipeline, cache, or dependency failures remain errors.

### Cache and resources

A typical spatial store is:

```text
Data/targets/paleo_spatial_regional/eu_r005/
  pipeline_paleo_spatial_resolution/
```

Preparation is primarily CPU- and RAM-intensive. The `shared` resource profile caps interpolation at four workers; `dedicated` caps it at eight, subject to available memory.

```powershell
Rscript R/02_Main_analyses/01_Preparation/01_run_preparation.R dedicated
```

## Stage 02: model calibration

### What is calibrated

Calibration determines the CV-only fit budget:

- `cv_n_iter_initial`: first iteration allowance for a candidate-fold fit;
- `cv_n_iter_max`: largest allowance after automatic escalation;
- `cv_n_sampling`;
- `cv_n_step_size`;
- `cv_n_early_stopping`.

It does not select final regularization for every unit and does not replace final-model parameters.

### Why representatives are used

Calibrating every potential model would be more expensive than production. The inventory selects a deterministic complex representative for each eligible analysis, tier, and resolution. Other units inherit the conservative accepted budget for their compatible group.

A representative must have readable prepared folds and sufficient CV feasibility. The inventory generated on 11 September 2026 contains 20 representatives: nine modern spatial, nine paleo spatial, and two eligible paleo-temporal profiles.

### One calibration rung

Screening uses eight candidates, three folds from repeat 1, sampling 100, and therefore 24 candidate-fold fits per rung. The iteration ladder is:

```text
500, 1,000, 2,000, 4,000, 8,000, 16,000, 32,000, 64,000
```

When adjacent screening rungs appear stable, the two leaders are confirmed with five folds, repeats 1 and 2, and sampling 200: 20 candidate-fold fits per confirmation rung. If the iteration ladder never passes, the design can hold 64,000 iterations and increase sampling through 400, 800, 1,600, 3,200, 6,400, and 8,000.

### Current acceptance rule

The current code accepts the smallest budget for which:

1. Fits are complete, finite, and converged.
2. The repeat-1 winner is unchanged at the next rung.
3. Candidate-loss rank correlation with the next rung is at least 0.95.
4. Winning normalized loss changes by no more than 1%.
5. The repeat-1 winner is either the repeat-2 winner or is within 2% of the repeat-2 minimum loss.

The accepted `cv_n_iter_max` is four times the accepted initial budget, capped at 64,000. During production, a successful but non-converged candidate-fold fit starts at `cv_n_iter_initial` and doubles iterations with the same deterministic seed until convergence or `cv_n_iter_max`.

Convergence means both:

```text
tail loss slope < 0.01
median loss difference < 1
```

Fit, prediction, and scoring errors are recorded; only a successful but non-converged fit is escalated.

### How near-tied candidates are handled

An exact repeat-2 winner match is recorded, but it is not required when candidates are practically tied. The repeat-1 provisional winner is confirmed when its repeat-2 normalized loss is no more than 2% above the repeat-2 minimum. The accepted-budget evidence records the repeat-2 winner, the relative loss gap, the tolerance, and whether the match was exact or practically equivalent.

This prevents genuine CV-repeat variability between practically indistinguishable candidates from forcing escalation to very large iteration budgets. It does not weaken convergence, fold-completeness, adjacent-rung stability, rank-correlation, or loss-change requirements.

### Checkpoints and publication

Calibration writes restartable objects beneath:

```text
Data/Temp/Sjsdm_cv_calibration/<profile>/<unit>/<resolution>/
```

`calibration_checkpoint.qs` records completed screening and confirmation rungs. Separate rung work checkpoints are written after every candidate-fold fit, so a crash loses at most the fit that was running. `calibration_result.qs` records an accepted representative and is reused when its contract and input hash match. Compatible version-2 results and fit evidence are migrated without refitting; policy-dependent confirmation decisions are recomputed under the current contract.

Only after every representative is accepted does publication:

1. Resolve inherited budgets for all units and profiles.
2. Write spatial CV columns into six CSVs under `Data/Input/Model_tuning/`.
3. Write temporal CV budgets into `Configuration/Profiles/Main/Paleo/temporal.yml`.
4. Save provenance under `Documentation/Reports/Model_calibration/sjsdm_cv_fit_budget/`.
5. Regenerate root `config.yml` from human-authored fragments.
6. Validate the generated configuration.

Until publication succeeds, `calibration_status: pending_calibration` is intentional and stage 03 must not start.

## Two independent fitting budgets

| CV-only columns | Final-model-only columns |
|---|---|
| `cv_n_iter_initial` | `n_iter` |
| `cv_n_iter_max` | — |
| `cv_n_sampling` | `n_sampling` |
| `cv_n_step_size` | `n_step_size` |
| `cv_n_early_stopping` | `n_early_stopping` |
| — | `n_samples_anova` |

CV fits are numerous and need the smallest reliable budget. The final model is fitted once on all data and can retain a larger budget. `n_samples_anova` controls variance partitioning, not candidate fitting.

Changing only a CV budget should invalidate CV and model descendants while preserving preparation. Changing only a final budget should invalidate the final model and its descendants, not prepared folds.

## Stage 03: tuning and final fitting

Stage 03 verifies stage-01 evidence and published stage-02 budget provenance.

### Production regularization tuning

The default staged search is:

| Round | CV repeat | Candidates entering | Tier-wide survivors |
|---|---:|---:|---:|
| 1 | 1 | 8 | 4 |
| 2 | 2 | 4 | 2 |
| 3 | 3 | 2 | 1 final survivor |

With five folds, an eligible unit ordinarily contributes `8 × 5 + 4 × 5 + 2 × 5 = 70` candidate-fold fits instead of 120 for an exhaustive eight-candidate, three-repeat search. Leave-one-location-out units have a different fold count.

After each round, successful evidence is aggregated across compatible units in the tier with equal unit weighting. This determines which candidates survive. Only complete, converged evidence is eligible.

For feasible units, unit CV evidence supplies regularization within the staged process. A full-model-feasible unit without valid holdouts inherits compatible tier-pooled regularization. A full-model-infeasible unit produces no model.

Candidate-fold models are temporary. Held-out metrics, predictions, convergence diagnostics, actual budgets, seeds, timings, and errors are retained.

### Out-of-fold evaluation

Predictions made during tuning are cached. After selection, matching held-out predictions are assembled and evaluated. These cross-validated metrics differ from evaluation of the full-data final model.

### Final full-data model

For each feasible unit and resolution, one sjSDM is fitted to all available data using selected regularization and the final-only `n_iter`, `n_sampling`, `n_step_size`, and `n_early_stopping`. The GPU fit uses deterministic seed 900723.

The final fit does not use `cv_n_iter_initial` or `cv_n_iter_max`; candidate-fold fits do not use historical final `n_iter`.

After fitting, the pipeline:

1. Computes standard errors separately with CPU parallelisation.
2. Evaluates the full-data fitted model.
3. Runs variance partitioning/ANOVA using `n_samples_anova`.
4. Persists regularization, CV, convergence, and budget provenance.

The local spatial component also runs the representative common-regularization sensitivity after all three tier artifacts exist.

The master fitting order is paleo spatial continental, regional, and local; modern spatial continental, regional, and local; then paleo temporal Europe, America, and Asia. Within a spatial tier, tuning rounds finish before final per-unit pipelines resolve regularization and fit final models.

## Stage 04: synthesis

Synthesis does not fit models. It runs paleo spatial synthesis, modern spatial synthesis, and then the matched paleo-modern comparison.

## Stage 05: visualisation

Visualisation consumes current model and synthesis products. It builds paleo maps, paleo variance figures, modern variance figures, paleo-modern and functional-type comparisons, and temporal continent figures. It must not trigger tuning, fitting, or synthesis.

## Restart and cache behaviour

After a normal interruption or PC crash, rerun the same master script without deleting stores or requesting a fresh run.

Expected reuse:

- content-matched `{targets}` objects are skipped;
- prepared folds are reused by calibration and fitting;
- accepted calibration representatives are reused;
- complete calibration rungs are reused, but an incomplete rung is repeated;
- completed production tuning branches and final targets are reused.

A target reruns when its content contract is outdated. Common causes are changed data, traits, configuration, functions, or upstream hashes; a missing or unreadable object; or explicit invalidation. Calling a pipeline again does not imply that every target is recomputed.

Do not archive or delete stores merely to recover from a crash. Reset stores only for an intentional clean rerun or incompatible migration.

## Logs and evidence

Every master stage writes:

```text
Data/Temp/Main_analysis_execution/<stage_id>/<run_id>/
```

This contains component logs and `component_status.csv`. Other important locations are:

| Location | Contents |
|---|---|
| `Data/targets/` | Preparation, tuning, final-model, evaluation, and synthesis targets. |
| `Data/Temp/Sjsdm_cv_calibration/` | Calibration checkpoints and accepted results. |
| `Documentation/Reports/Model_calibration/sjsdm_cv_fit_budget/` | Inventory, representatives, attempts, accepted budgets, timing, and publication provenance. |
| `Data/Input/Model_tuning/` | Per-unit spatial CV and final-model budgets. |
| `Configuration/Profiles/Main/` | Human-authored profiles, including temporal budgets. |
| `config.yml` | Generated combined configuration; do not maintain it independently. |

## Resource use

| Operation | Main resource | Notes |
|---|---|---|
| Extraction, interpolation, fold preparation | CPU and RAM | Multiple interpolation workers can cause high peak memory use. |
| Calibration candidate fits | GPU | Representatives run sequentially. |
| Production candidate-fold fits | GPU | Branches are restartable; avoid competing simultaneous GPU fits. |
| Final sjSDM fit | GPU | One per feasible unit-resolution. |
| Standard errors | CPU | Performed after the GPU fit. |
| Variance partitioning/ANOVA | CPU and fitted model | Controlled by `n_samples_anova`. |
| Synthesis and plotting | CPU | Consumes stored outputs. |

`Parallel processing is not supported when device = 'gpu'. Setting parallel to 0L.` is an sjSDM informational message. It means a single GPU fit cannot use sjSDM's CPU-parallel option; it is not a pipeline failure.

## Practical decisions

| Situation | Action |
|---|---|
| Preparation crashed | Rerun stage 01 or its specific component. |
| Expected small-data unit failed | Confirm expected infeasibility; do not force a model. |
| Calibration crashed | Rerun stage 02; accepted results and complete rungs are reused. |
| Calibration escalates although fits converge | Inspect stability and near ties; more iterations may not help. |
| CV candidate did not converge | Let it double iterations up to `cv_n_iter_max`. |
| Final model did not converge | Adjust final-only parameters; CV budgets are separate. |
| Only `n_samples_anova` changed | Rebuild variance-partition descendants; no CV refit is needed. |
| Stage 03 reports unpublished budgets | Finish stage 02; do not bypass it. |

## Current rerun snapshot: 12 September 2026

- Stage 01 has enough validated evidence for calibration.
- Stage 02 is interrupted after nine of 20 representatives were accepted.
- All nine modern spatial representatives are accepted.
- Paleo continental Europe family is checkpointed through six screening and five confirmation rungs.
- Its interrupted 16,000-iteration confirmation exposed the near-tie problem above.
- Stage 03 has not received fully published calibrated budgets and should not run.
- Stages 04 and 05 therefore cannot yet represent the rebuilt analysis.

The next decision is not simply how many more iterations to run. It is how calibration should treat practically tied candidates across CV repeats. After that policy is corrected and tested, stage 02 can resume from compatible evidence or invalidate only evidence affected by the changed calibration contract.
