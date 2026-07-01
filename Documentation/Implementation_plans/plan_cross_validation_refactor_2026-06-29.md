# Plan: Refactor cross-validation for predictive JSDM evaluation

**Date:** 2026-06-29  
**Author:** Codex using the `plan-large-changes` workflow  
**Status:** Phase 2 in progress
**Related issue:** [#135 - Add cross-validation to all model pipelines](https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/135)

---

## Goal

Replace the first cross-validation implementation with a scientifically explicit,
shared workflow for paleo and modern JSDMs. The new workflow will assign complete
sampling locations to spatially stratified folds, use feasibility-adaptive fold counts,
rebuild all learned preprocessing and Moran eigenvector map (MEM) predictors within
each fold, tune regularization from held-out likelihood, and report predictive power
from out-of-fold probabilities using Tjur R2, AUC, and log loss. Small spatial IDs
will use an explicit feasibility hierarchy that preserves as much training data as
possible without weakening core grouping, MEM requirements, or model-quality checks.

---

## Implementation Workspace

- Implement in the existing main worktree at
  `D:/GITHUB/BIODYNAMICS_vegetation_cooccurrence`.
- Continue on the current `OndrejMottl/issue135` branch; do not create a separate
  worktree for this refactor.
- The user retains full control of all git state-changing operations. Do not stage,
  commit, push, merge, or alter branches without an explicit request.

---

## Background

Issue #135 originally requested a reusable held-out validation step without replacing
the production modelling framework. The first implementation added
`sjSDM::sjSDM_cv()` to the shared model pipe and uses grouped folds based on
`dataset_name`. Subsequent inspection and CZ runs identified limitations that require
a deliberate refactor:

- Paleo `dataset_name` identifies a core and therefore keeps repeated ages together.
- Modern `dataset_name` identifies an individual plot and is unique for every row, so
  the current grouped strategy degenerates to random row-wise folds.
- MEMs, abiotic scaling, spatial scaling, and response filtering are currently prepared
  before `sjSDM_cv()` receives the data. Test observations therefore influence learned
  preprocessing and the MEM basis.
- Production predictions interpolate MEM values from training locations, whereas the
  current CV reads exact MEM values computed using all locations. CV therefore does
  not reproduce the production prediction path.
- `model_evaluation` reports fitted-data McFadden and Nagelkerke pseudo-R2 and
  fitted-data species AUC. It does not report cross-validated predictive R2.
- `sjSDM_cv()` retains test predictions, but its fixed input matrices cannot support
  fold-local MEM construction and scaling.

The user has explicitly removed the backward-compatibility requirement and requested
a clean refactor. All new and changed functions must follow repository TDD guidance.

The primary estimand for this plan is **interpolation within the sampled domain**:
each fold should contain sampling locations distributed throughout the modelled area.
Geographic extrapolation into an entirely unsampled region is a different estimand and
is retained as a secondary sensitivity analysis rather than the primary tuning scheme.

---

## Design Decisions

### Fold unit

- Build folds from unique sampling locations, not model-matrix rows.
- Paleo: one location is one core; all ages from the core stay in the same fold.
- Modern: one location is one vegetation plot.
- Expand location-level assignments back to sample rows only after folds are fixed.

### Spatial stratification

- Project coordinates to the configured equal-area metric CRS, currently EPSG:3035
  for Europe.
- Overlay a configurable spatial grid and assign each unique location to one grid cell.
- Randomly distribute whole locations within each occupied cell across folds.
- Use a deterministic greedy balancing rule for cells with fewer locations than folds.
- Balance both the number of locations and the number of sample rows because paleo
  cores contain different numbers of ages.
- Derive grid size from projected extent and location density rather than hard-coding
  kilometre widths by spatial tier. Select the finest candidate grid whose occupied
  cells retain approximately one fold's worth of locations; finalize the exact occupancy
  criterion during CZ calibration.
- Use three deterministic assignment repeats in production and one in CZ validation.
  Shift the grid origin deterministically between production repeats to quantify
  sensitivity to arbitrary cell boundaries.
- Store the assignment as a readable table containing at least `repeat_id`, `fold_id`,
  `location_id`, `grid_cell_id`, and `n_samples`.

This design gives each fold broad spatial coverage. It is spatially stratified CV, not
spatial-block extrapolation CV.

### Adaptive fold count

- Use five folds by default at every spatial tier. Do not use a fixed `5 / 4 / 3` rule:
  fewer folds remove more locations from each training partition and can make small
  local IDs less viable.
- Require every training partition to satisfy the configured `min_n_cores`,
  `min_n_samples`, and `min_n_taxa` checks plus the relevant MEM hard minimum.
- When five-fold CV violates those requirements, increase the fold count toward
  leave-one-location-out so each training partition retains more data.
- Never reduce data-quality thresholds to make CV pass and never silently create an
  invalid fold.
- Pool out-of-fold predictions across all folds before calculating taxon metrics, so
  individual small folds do not need to contain both response classes.

With the current `min_n_cores = 5`, the expected location-count policy is:

| Available locations | Strategy | Smallest training set |
|---:|---|---:|
| 7 or more | Five-fold spatially stratified CV | At least 5 locations |
| 6 | Six-fold leave-one-location-out | 5 locations |
| 5 | Tier-pooled regularization; final fit uses all data | No viable holdout |
| Fewer than 5 | No model under current full-model checks | Not applicable |

Calculate this classification from configuration and actual fold contents rather than
hard-coding these four numbers, so future changes to quality thresholds propagate.

### Observed local-data constraints

The existing target stores support this adaptive policy:

- Paleo local stores contain many very small IDs: among stores with known counts, 75
  have fewer than five cores, nine have five cores, two have six cores, and eight have
  seven cores.
- Existing genus-model success is poor at five cores (1 of 9) and six cores (1 of 2),
  but substantially better at seven cores (7 of 8).
- Modern local IDs are generally much larger, but the same feasibility policy should be
  used instead of maintaining a separate modern CV implementation.

These are diagnostic observations from current stores, not replacement thresholds for
the existing configurable model-quality checks.

### Small-sample feasibility hierarchy

Assess CV feasibility before creating folds. Keep the scientific fold unit fixed as a
whole location; adapt the number of folds or source of regularization rather than
falling back to row-wise random CV.

Use the following ordered decision tree for each spatial ID:

1. **Spatially stratified grouped k-fold:** use five folds when every
   training partition passes the existing sample, taxon, and MEM requirements.
2. **Leave-one-location-out:** use one complete core or plot as the test partition when
   grouped k-fold is not viable but every `n_locations - 1` training partition still
   supports model and MEM fitting. Pool all held-out predictions before calculating
   metrics; do not require metrics to be defined within a single-location fold.
3. **Tier-pooled regularization:** when the full model is viable but removing any
   location would violate fitting or MEM requirements, do not tune on that ID. Select a
   shared candidate by aggregating held-out tuning loss across eligible IDs from the
   same spatial tier and taxonomic resolution, then fit the small ID on all its data.
4. **No model:** when the complete ID fails the full-model data requirements, do not fit
   a model or produce a variance decomposition.

Do not use random sample-row CV as a small-data fallback. For paleo data it would place
ages from the same core in training and test partitions and produce optimistic tuning.

Every fitted model must expose regularization and feasibility provenance:

```text
cv_strategy
effective_folds
n_locations
n_samples
cv_feasibility_status
regularization_source
regularization_source_id
```

Supported `cv_strategy` values should include
`spatially_stratified_group_kfold`, `leave_one_location_out`, and `none`. Supported
`regularization_source` values should include `unit_cv`, `tier_pooled_cv`, and
`parent_tier`. A leave-one-location-out model therefore uses
`cv_strategy = "leave_one_location_out"` with
`regularization_source = "unit_cv"`. The first implementation should prefer
`tier_pooled_cv` over `parent_tier`. Parent-tier borrowing is disabled by default and
requires an explicit project configuration when no same-tier tuning source exists.

### Fold-local preprocessing

Each fold must be run independently and must perform all learned operations using the
training partition only:

1. Filter constant and insufficiently represented taxa from training responses.
2. Apply the retained taxon set to test responses.
3. Fit abiotic scaling on training predictors and apply it to test predictors.
4. Compute 2-D or spatiotemporal MEMs from training locations/samples only.
5. Fit spatial scaling on training MEMs.
6. Interpolate training MEMs to held-out coordinates and ages with the same machinery
   used for grid prediction.
7. Fit the candidate sjSDM on the training input.
8. Predict probabilities for the test input.

Use the full-ID taxon inclusion rules to define the scientific response set, then remove
taxa that are constant in an individual training partition and record their incomplete
out-of-fold coverage. Do not weaken `min_n_cores`, `min_n_samples`, or `min_n_taxa` to
make a fold fit.

Use one effective MEV count per ID across all folds: the minimum of the configured count
and the number available in every viable training partition. Record this count and use
it for the final comparison metadata.

The generic fold-preparation logic should be shared with decomposition diagnostics.
`prepare_decomposition_fold_input()` already implements train-only response filtering
and scaling, but its MEMs are currently computed at route level and then subset. Refactor
the common behaviour rather than maintaining two independent implementations.

### Tuning and final fitting

- Replace the package-native CV orchestration with a project-owned fold runner because
  `sjSDM_cv()` cannot rebuild preprocessing inside each fold.
- Generate one deterministic regularization candidate table and reuse it across folds.
- Retain held-out negative log likelihood as the selection criterion. Normalize it per
  observed response value before fold and ID aggregation so sample-rich models do not
  dominate by construction.
- Store compact candidate-by-fold metrics rather than predictions for every candidate.
- After selecting regularization, rerun only the selected candidate across the folds to
  materialize out-of-fold predictions. This adds one fit per fold but avoids storing all
  candidate prediction matrices.
- For tier-pooled tuning, first aggregate normalized loss within each eligible ID, then
  give every ID equal weight. Report a sample-weighted sensitivity only if it changes
  candidate selection materially.
- Apply shared tier-level regularization only within the same spatial tier, taxonomic
  resolution, response family, and model predictor structure.
- Refit the selected final model on all available data for ANOVA, inference, and grid
  prediction.

### Tier-pooled tuning orchestration

Production spatial IDs currently run in isolated target stores. Tier-pooled tuning must
not create hidden reads from sibling stores or a cycle in which small-ID fitting waits
for a shared candidate that itself waits for every final model.

Use an explicit two-stage workflow:

1. Eligible IDs run feasibility checks and candidate-by-fold tuning only.
2. A dedicated tier-level aggregation pipeline in a shared targets store reads completed
   tuning summaries and selects one candidate per tier and taxonomic resolution.
3. Per-ID final fitting consumes the immutable tier-level regularization artifact.
4. IDs with `regularization_source = "unit_cv"` may fit from their own selected candidate;
   tier-dependent IDs wait for the shared artifact.

The shared artifact must include its source IDs, candidate table hash, weighting rule,
selection metric, and creation timestamp. Do not communicate shared regularization
through mutable global variables or an undocumented CSV edit.

### Cross-scale variance decomposition

CV does not calculate variance decomposition directly. It affects the final full-data
ANOVA indirectly by selecting regularization. Different fold counts are therefore
acceptable when they preserve the same location-level estimand and selection objective,
but changing the source of regularization can contribute to apparent differences among
spatial scales.

Use two complementary decomposition outputs when comparing scales:

- **Primary decomposition:** each model uses the best supported regularization source
  from the feasibility hierarchy.
- **Common-regularization sensitivity:** select one candidate from an equal-weight
  aggregate of normalized losses across eligible spatial tiers, refit a defined
  comparison subset with that candidate, and repeat the full-data decomposition.

Interpret a scale pattern as robust only when its qualitative direction persists under
the common-regularization sensitivity analysis. Every decomposition table must retain
the CV strategy, regularization source, sample count, location count, retained taxon
count, and effective MEV count used by its fitted model.

### Predictive metrics

For binomial models, calculate metrics from pooled out-of-fold probabilities separately
for every repeat:

- Tjur R2 per taxon:
  `mean(prediction | presence) - mean(prediction | absence)`;
- macro mean and median Tjur R2 across evaluable taxa;
- AUC per taxon plus macro mean and median AUC;
- log loss per taxon and community mean log loss;
- prevalence, numbers of presences/absences, and explicit metric status per taxon;
- optional community McFadden and Nagelkerke pseudo-R2 against fold-local null
  predictions as supplementary outputs.

Negative out-of-fold Tjur or likelihood pseudo-R2 values must be retained. They indicate
performance worse than the relevant null or reversed probability separation. Taxa that
do not contain both classes across pooled out-of-fold observations must return `NA` with
an explicit reason rather than being silently discarded.

Keep fitted and predictive evaluation conceptually separate:

- fitted evaluation: final-model convergence, with McFadden and Nagelkerke pseudo-R2
  retained only as supplementary descriptive diagnostics;
- cross-validated evaluation: out-of-fold predictive metrics;
- ANOVA: full-data variance decomposition, not a cross-validated R2.

The first implementation will use the same folds for tuning and selected-candidate
out-of-fold reporting. Label these values as tuning-CV estimates. Nested outer CV is
deferred because it would multiply the already substantial model-fitting cost; add it
later if unbiased publication-level external performance is required.

---

## Scope

### In scope

- Spatially stratified location-level fold construction for modern and paleo data.
- Whole-core grouping for paleo and whole-plot grouping for modern.
- Feasibility-adaptive and data-validated fold counts that preserve configured training
  quality thresholds at every spatial tier.
- Explicit CV feasibility classification and leave-one-location-out fallback.
- Tier-pooled regularization for IDs that support a full model but not an independent
  fold fit.
- Repeated deterministic fold assignment.
- Fold-local taxa filtering, abiotic scaling, MEM construction, MEM interpolation, and
  spatial scaling.
- Project-owned regularization tuning and selected-candidate out-of-fold prediction.
- Cross-validated Tjur R2, AUC, log loss, and supporting diagnostics.
- Clear separation of fitted and predictive evaluation targets.
- Regularization provenance attached to fitted models and decomposition outputs.
- A common-regularization decomposition sensitivity analysis for cross-scale
  comparability.
- Integration into every active pipeline that consumes `pipe_segment_model_fit`.
- Mandatory TDD for every created or adjusted function: write or update the roxygen2
  specification first, add tests before implementation, demonstrate that the tests fail,
  implement until they pass, and run the required focused, full-suite, and CZ checks.
- CZ paleo and modern executable validation.

### Out of scope

- Cross-validated ANOVA or variance decomposition.
- A single combined spatiotemporal extrapolation score.
- Temporal forward-chaining validation; this should be a separate paleo audit.
- Replacing the production MEM interpolation algorithm beyond changes required to make
  it usable for held-out locations.
- Gaussian or abundance-model metrics in the first pass; unsupported families should
  fail explicitly until their predictive metric contract is designed.
- Publication-ready geographic block extrapolation CV in the first pass.
- Treating decomposition from IDs with failed full-model checks as valid output.
- Git operations, worktree creation, or GitHub issue mutation as part of planning.

### Affected files and components

Existing files expected to change or be replaced:

- `config.yml`
- `R/Functions/Modelling/Cross_validation/make_cross_validation_indices.R`
- `R/Functions/Modelling/Cross_validation/run_sjsdm_cross_validation.R`
- `R/Functions/Modelling/Cross_validation/summarise_sjsdm_cross_validation.R`
- `R/Functions/Modelling/Cross_validation/select_sjsdm_regularization.R`
- `R/Functions/Modelling/Decomposition_diagnostics/prepare_decomposition_fold_input.R`
- `R/Functions/Modelling/Evaluation/evaluate_jsdm.R`
- `R/Pipelines/_pipes/pipe_segment_config_model.R`
- `R/Pipelines/_pipes/pipe_segment_config_model_by_resolution.R`
- `R/Pipelines/_pipes/pipe_segment_model_fit.R`
- `R/Pipelines/_pipes/pipe_segment_model_spatial_shared.R`
- `R/Pipelines/_pipes/pipe_segment_model_spatial_samples.R`
- `R/Functions/Prediction/Inference/predict_spatial_resolution_grid_age.R`, only if
  MEM interpolation interfaces are generalized.
- Diagnostics and result readers that currently assume the old `model_evaluation`
  structure.

Affected pipelines:

- `R/Pipelines/pipeline_paleo_core.R`
- `R/Pipelines/pipeline_paleo_resolution_test.R`
- `R/Pipelines/pipeline_paleo_temporal.R`
- `R/Pipelines/pipeline_paleo_spatial_resolution.R`
- `R/Pipelines/pipeline_modern_spatial_resolution_test.R`
- `R/Pipelines/pipeline_modern_spatial_resolution.R`
- A new tier-level regularization aggregation pipeline or shared tuning-store runner.

Likely new function responsibilities under
`R/Functions/Modelling/Cross_validation/`:

- resolve an effective fold count;
- assess full-model, grouped-CV, and leave-one-location-out feasibility;
- construct a location-level spatial grid and assignment table;
- expand location folds to sample rows;
- generate deterministic regularization candidates;
- prepare one fold with train-only preprocessing and MEM projection;
- fit and score one tuning candidate on one fold;
- rerun the selected candidate and collect out-of-fold predictions;
- calculate Tjur R2 and other predictive metrics;
- aggregate repeat-, model-, and taxon-level evaluation tables.
- aggregate tuning evidence across eligible IDs within a spatial tier;
- attach regularization provenance to final-model and decomposition outputs.

Each exported function must live in its own script with roxygen2 documentation and a
matching focused test file.

---

## Target Data Contracts

### Fold assignment

Return a tibble rather than a deeply nested index list:

```text
repeat_id
fold_id
location_id
grid_cell_id
n_samples
row_indices
```

`row_indices` may be a list-column or replaced by a separate normalized sample-level
assignment table if that produces clearer target inspection.

### Tuning summary

One row per repeat, candidate, and fold:

```text
repeat_id
fold_id
candidate_id
alpha_cov
alpha_coef
alpha_spatial
lambda_cov
lambda_coef
lambda_spatial
n_train_locations
n_test_locations
n_train_samples
n_test_samples
n_taxa_retained
negative_log_likelihood_test
auc_macro_test
fit_status
cv_strategy
regularization_source
```

### Out-of-fold predictions

Use a long or matrix-backed structure with explicit identifiers:

```text
repeat_id
fold_id
sample_id
taxon
observed
predicted_probability
null_probability
```

The implementation may use matrices internally for performance, but the returned object
must preserve row and taxon alignment explicitly and validate complete out-of-fold
coverage.

### Cross-validated evaluation

Return separate tables for model/repeat summaries and taxon-level metrics. Include
counts, undefined-metric reasons, and repeat variability. Do not overwrite or relabel
fitted-data pseudo-R2 as cross-validated R2.

---

## Pipeline Orchestration

Spatial stratification is calculated inside the targets pipeline. Pure functions under
`R/Functions/Modelling/Cross_validation/` perform the calculations, but the canonical
fold assignments are pipeline targets stored with each spatial ID. Do not generate or
maintain fold files manually outside targets.

### Per-ID target graph

The CV branch starts from raw aligned model inputs and projected coordinates:

```text
data_sample_ids_checked
data_community_*
data_abiotic_wide
data_coords_projected
config_cross_validation
        |
        v
data_cross_validation_locations
        |
        v
data_cross_validation_feasibility
        |
        v
data_cross_validation_fold_assignments
        |
        v
data_cross_validation_fold_spec
        |
        v
data_cross_validation_fold_input
        |
        +-------------------------------+
        |                               |
        v                               v
data_regularization_candidates   fold-local diagnostics
        |
        v
model_cross_validation_candidate_result
        |
        v
model_cross_validation_tuning_summary
        |
        v
model_regularization_selected
        |
        v
model_cross_validation_selected_predictions
        |
        v
model_evaluation_cross_validated
```

Target responsibilities:

1. `data_cross_validation_locations` joins checked sample IDs to projected coordinates,
   collapses rows to unique cores or plots, and records represented sample counts.
2. `data_cross_validation_feasibility` runs the full-model and fold-training checks and
   selects grouped k-fold, leave-one-location-out, tier-pooled regularization, or no
   model.
3. `data_cross_validation_fold_assignments` creates the grid, assigns grid cells, places
   complete locations in folds, and expands assignments to sample rows.
4. `data_cross_validation_fold_input` dynamically branches over repeat/fold
   specifications and performs training-only filtering, scaling, and MEM construction
   plus held-out MEM interpolation.
5. `model_cross_validation_candidate_result` branches over compatible fold inputs and
   regularization candidates and returns compact metrics, not fitted model objects.
6. After selection, `model_cross_validation_selected_predictions` reruns only the
   selected candidate for each fold and materializes aligned out-of-fold probabilities.

The exact target names may be shortened during implementation, but their ownership and
data contracts must remain explicit.

### Raw-input boundary

The CV branch must not consume any object learned from all observations. In particular,
it must not use these current full-data targets as fold inputs:

```text
data_model_input
data_abiotic_scaled_list
data_spatial_mev_core
data_spatial_mev_samples
data_spatial_scaled_list
```

It may reuse raw community/abiotic data, checked sample identifiers, projected
coordinates, and configuration. The final full-data model continues to use the existing
full-data preparation branch after regularization has been selected.

Conceptually, CV and final preparation form parallel dependency branches that meet at
the final model:

```text
raw aligned data + coordinates
        |                         |
        |                         +--> full-data scaling and MEMs
        |                                      |
        +--> CV tuning --> selected params     |
                              |                |
                              +-------> final full-data model
```

This avoids imposing an unnecessary execution order on full-data preparation while
ensuring the final model depends on selected regularization.

### Pipeline segment placement

- Split coordinate projection from full-data MEM construction if necessary so CV can
  depend on `data_coords_projected` without depending on global MEM targets.
- Start `pipe_segment_model_cross_validation.R` during Phase 1 with lightweight per-ID
  location, grid-calibration, assignment, partition-diagnostic, and feasibility
  targets after aligned raw data and projected coordinates are available. Extend the
  same segment in later phases with fold-local preparation, tuning, predictions, and
  evaluation targets; do not replace the lightweight targets with one opaque fold-plan
  object.
- Keep full-data spatial preparation and `pipe_segment_model_assemble.R` as the final-fit
  branch.
- Simplify `pipe_segment_model_fit.R` so it consumes `data_model_input` and
  `model_regularization_selected` and then produces the final fitted model and fitted
  evaluation.
- Let targets dependencies, rather than list order alone, control execution.

### Stable Phase 1 data contracts

The location-assignment table uses one row per location and repeat with these columns:

```text
repeat_id                 integer assignment repeat
fold_id                   integer held-out fold
location_id               character core or plot identifier
grid_cell_id              character spatial cell; NA for leave-one-location-out
n_samples                 integer sample rows represented by the location
row_indices               list of aligned sample-row indices
cv_strategy               character resolved assignment strategy
assignment_source         character assignment provenance
```

Supported `assignment_source` values in Phase 1 are `per_id`,
`shared_pre_resolution`, `branch_fallback`, `branch_no_holdout`, and
`leave_one_location_out_fallback`.

The selected-candidate out-of-fold prediction table implemented in Phase 3 must use one
row per sample and taxon with `repeat_id`, `fold_id`, `row_index`, `location_id`,
`dataset_name`, `age`, `taxon`, `observed`, `predicted_probability`, and
`prediction_status`. Candidate-scoring tables remain separate and identify candidates
with `candidate_id`; they must not overload the selected prediction schema.

The taxon-level predictive evaluation table implemented in Phase 3 must use one row per
repeat, taxon, and metric with `repeat_id`, `taxon`, `metric_id`, `estimate`,
`metric_status`, `n_observations`, `n_presences`, `n_absences`, and `prevalence`.
Community macro summaries remain a separate table with `repeat_id`, `metric_id`,
`summary_statistic`, `estimate`, `n_taxa_evaluable`, and `metric_status`.

### Resolution branches

Pipelines that map over genus, family, and functional type should derive spatial grid
cells from one shared projected coordinate surface and a predictor-valid sample universe
defined before response taxonomic filtering. This universe should contain locations and
samples with valid coordinates and abiotic predictors, independent of which taxa survive
within a resolution branch. Use one shared initial location-fold assignment for
overlapping locations so taxonomic resolutions are not compared under unnecessarily
different partitions.

Each resolution branch must then:

1. subset the shared assignment to its checked sample/location universe;
2. rerun feasibility and fold-balance checks;
3. use the shared assignment when it remains valid;
4. rebuild a branch-specific assignment only when subsetting makes the shared folds
   invalid, and record that fallback in fold metadata.

The implementation must define which pre-resolution sample universe owns the shared
assignment. Do not infer this implicitly from whichever resolution branch happens to
execute first.

### Tier-pooled execution stages

Tier-pooled regularization requires orchestration above an isolated per-ID model store:

```text
Stage 1 - ID tuning
  Run feasibility and candidate scoring for eligible IDs.
  Publish compact tuning summaries and provenance.

Stage 2 - Tier aggregation
  Read completed summaries through an explicit store index.
  Select and publish one immutable candidate per tier/resolution/model structure.

Stage 3 - ID final fitting
  Unit-CV IDs consume their own selected candidate.
  Fold-infeasible IDs consume the tier-level artifact.
  Fit full-data models and calculate ANOVA/evaluation outputs.
```

The top-level spatial runners should orchestrate these stages explicitly. The tier
aggregation stage should be a dedicated targets pipeline or shared target store, not an
imperative calculation hidden inside an ID runner. Stage completion and artifact hashes
must be checkable before final fitting begins.

### Execution and resources

- Use dynamic target branching for fold-local preparation and candidate scoring when it
  improves resumability.
- Do not allow concurrent branches to contend for one GPU. Define target resources or a
  sequential GPU worker policy before enabling candidate-level parallelism.
- Preserve failed candidate/fold branches as structured diagnostics where possible.
- Keep fold assignment and feasibility targets lightweight and independently rerunnable.
- Record target-store size and branch runtime during CZ validation before selecting the
  final branching granularity.

---

## Refactoring Strategy

- Split CV orchestration out of `pipe_segment_model_fit.R` into a dedicated
  `pipe_segment_model_cross_validation.R`; keep final full-data fitting in the existing
  model-fit segment.
- Replace `run_sjsdm_cross_validation()` rather than adding fold-local behaviour behind
  its current package-native contract.
- Extract a generic train/test preparation helper from
  `prepare_decomposition_fold_input()` and make both decomposition diagnostics and CV
  delegate to it.
- Keep regularization selection independent of the fitting backend by consuming a stable
  candidate-by-fold metric table.
- Keep per-ID and tier-pooled regularization selection on the same candidate and metric
  schemas so fallback models do not require a separate fitting implementation.
- Keep tier-level aggregation as an explicit pipeline/store boundary; individual ID
  stores should consume a versioned shared artifact rather than discover sibling stores
  implicitly.
- Keep predictive evaluation independent of the runner by consuming observed and
  predicted out-of-fold values.
- Prefer explicit target names such as `model_evaluation_fitted` and
  `model_evaluation_cross_validated`. If a combined `model_evaluation` object remains,
  it should contain clearly named `fitted` and `cross_validated` elements and all
  downstream consumers must be updated.
- Remove superseded helpers, tests, and target names once their replacements are wired.
  Do not carry compatibility wrappers solely to preserve the first implementation.
- Preserve reproducibility by using independent deterministic seeds for fold assignment,
  tuning candidate generation, and model fitting.

---

## Implementation Phases

### Phase 1 - Define fold and metric contracts

**Goal:** Establish deterministic spatially stratified folds, adaptive fold counts, and
tested predictive metric definitions before changing model fitting.

**Tasks:**

- [x] Finalize configuration names for spatial grid stratification, repeats, fold limits,
  minimum locations, seeds, and small-sample behaviour.
- [x] Create a location-table helper that validates one coordinate per location and
  records the number of sample rows represented by each location.
- [x] Create the effective-fold-count resolver with five-fold default, data-driven
  increases toward leave-one-location-out, and explicit feasibility statuses.
- [x] Create a CV feasibility assessor that evaluates the existing full-model checks,
  MEM location requirements, grouped-fold training partitions, and leave-one-location-
  out training partitions before selecting a strategy.
- [x] Replace `make_cross_validation_indices()` with a deterministic spatially stratified
  location assignment helper.
- [x] Add leave-one-location-out assignment using the same location and sample schemas.
- [x] Implement balancing across grid cells, folds, location counts, and sample counts.
- [x] Implement deterministic grid-origin shifts across production repeats and a
  single-repeat CZ override.
- [x] Implement standalone Tjur R2, AUC, and log-loss evaluators from observed values and
  predicted probabilities.
- [x] Define stable assignment, prediction, and evaluation schemas.
- [x] Add the lightweight per-ID CV targets to
  `pipe_segment_model_cross_validation.R`. Multi-resolution pipelines should calibrate
  from their shared pre-resolution location universe and create a branch-specific
  fallback only when subsetting invalidates the shared folds.

**Validation:**

- This phase is not complete until its validation passes.
- For every helper, follow the full repository TDD cycle: roxygen2 stub, failing tests,
  implementation, focused passing tests.
- Test whole-core preservation, modern single-row locations, deterministic repeats,
  cells with fewer locations than folds, fold balancing, adaptive fold reduction,
  invalid small samples, feasibility transitions, leave-one-location-out folds, grid
  shifts, and complete row coverage.
- Test known Tjur values, negative Tjur values, undefined one-class taxa, probability
  clipping, and pooled rather than fold-averaged metrics.
- Run the full test suite and `Rscript R/02_Main_analyses/Run_CZ_test.R` at the required
  TDD closure point.
- Run the mandatory change-review workflow before closing the phase.

**Phase 1 closure (2026-06-29):**

- The full test suite passed with 2,838 assertions, no failures or warnings, and one
  expected opt-in VegVault integration skip.
- Fresh `Run_CZ_test.R` validation completed in 30 minutes 42 seconds. The paleo core,
  paleo resolution, and modern resolution stores contained zero errored targets.
- The median-occupancy rule selected a 266 km grid for CZ paleo and a 50.3 km grid for
  CZ modern. Both retained a maximum fold-location difference of one.
- Paleo genus, family, and functional-type branches reused the shared pre-resolution
  assignment. Modern functional type reused it; modern genus and family correctly
  recorded `branch_fallback` after response filtering removed 33 shared locations and
  invalidated the configured fold-balance threshold.
- Every CZ branch resolved to feasible five-fold spatially stratified grouped CV. The
  tested adaptive path retains leave-one-location-out and no-holdout outcomes for small
  production IDs.
- The mandatory review found no violations in the Phase 1 implementation files.

---

### Phase 2 - Build fold-local preprocessing and MEM projection

**Goal:** Make one train/test split reproduce the production prediction path without test
data influencing learned preprocessing.

**Tasks:**

- [x] Extract generic fold preparation from
  `prepare_decomposition_fold_input()`.
- [x] Filter taxa from training responses only and preserve an explicit retained-taxa
  mapping for test observations.
- [x] Fit abiotic scaling on training data and apply its attributes to test data.
- [x] For spatial models, compute 2-D MEMs from training locations only and interpolate
  them to held-out modern plots.
- [x] For spatiotemporal models, compute MEMs from training core-age samples only and
  interpolate them to every held-out paleo core-age sample.
- [x] Fit spatial scaling on training MEMs and apply it to interpolated test MEMs.
- [x] Record diagnostics for unavailable MEVs, dropped taxa, missing predictors, and
  train/test row alignment.
- [x] Make decomposition diagnostics delegate to the shared fold preparation path.

**Validation:**

- This phase is not complete until its validation passes.
- Use TDD for every changed or created function and first demonstrate failing leakage
  and alignment tests against the pre-refactor behaviour.
- Test that changing held-out predictor values cannot change training scaling or MEMs.
- Test that held-out locations are absent from MEM construction inputs.
- Test exact row/taxon alignment and finite projected spatial predictors in both 2-D and
  spatiotemporal modes.
- Run focused decomposition tests to prevent regression in the existing diagnostic
  workflow.
- Run a small real `sjSDM` CPU smoke fit with fold-local spatial predictors.
- Run the full test suite and the CZ pipeline at the required TDD closure point.
- Run the mandatory change-review workflow before closing the phase.

---

### Phase 3 - Replace package-native CV orchestration

**Goal:** Tune regularization and materialize selected-model out-of-fold predictions from
independent fold fits.

**Tasks:**

- [ ] Generate a deterministic candidate table from configured alpha/lambda ranges.
- [ ] Implement a fold-and-candidate runner with injectable fit and predict functions for
  unit testing.
- [ ] Return compact tuning metrics and diagnostics without retaining every candidate
  model or prediction matrix.
- [ ] Update `summarise_sjsdm_cross_validation()` and
  `select_sjsdm_regularization()` to consume the new schema, or replace them with more
  accurately named helpers.
- [ ] Retain held-out negative log likelihood as the default regularization criterion.
- [ ] Rerun the selected candidate once per fold and return aligned out-of-fold
  probabilities and fold-local null probabilities.
- [ ] Aggregate cross-validated Tjur R2, AUC, and log loss per repeat and taxon.
- [ ] Implement tier-pooled candidate aggregation from per-response normalized loss with
  equal ID weighting and an optional sample-weighted sensitivity report.
- [ ] Define the shared tier-level tuning artifact, including source-ID and candidate
  provenance, and implement its dedicated aggregation pipeline or runner.
- [ ] Apply tier-pooled regularization to fold-infeasible but full-model-viable IDs and
  record the source tier and candidate identifier.
- [ ] Preserve fit errors as structured statuses so one failed candidate does not produce
  an opaque pipeline failure without context.
- [ ] Measure runtime and store size relative to the first `sjSDM_cv()` implementation.

**Validation:**

- This phase is not complete until its validation passes.
- Follow TDD for candidate generation, runner orchestration, selection, selected-model
  reruns, and evaluation aggregation.
- Test selection direction, ties, failed candidates, repeat isolation, seed stability,
  complete out-of-fold coverage, negative predictive R2, pooled-ID weighting, and
  regularization provenance.
- Test that aggregation cannot mix tiers, taxonomic resolutions, response families,
  predictor structures, or incompatible candidate tables.
- Verify with injected functions that each fold fits only its training rows and predicts
  only its test rows.
- Compare one tiny fixed-matrix run against `sjSDM_cv()` to validate likelihood and AUC
  conventions where preprocessing is intentionally held fixed.
- Run one real CPU smoke tuning run with a reduced candidate set.
- Run the full test suite and CZ pipeline at the required TDD closure point.
- Run the mandatory change-review workflow before closing the phase.

---

### Phase 4 - Integrate all pipelines and expose predictive evaluation

**Goal:** Make the new CV workflow the shared production path and expose interpretable
predictive outputs in targets and diagnostics.

**Tasks:**

- [ ] Add the finalized cross-validation configuration to `config.yml`, including
  adaptive fold feasibility, production/CZ repeats, grid calibration, and small-sample
  policy.
- [ ] Extend the Phase 1 `pipe_segment_model_cross_validation.R` with tuning,
  selected-model prediction, and evaluation targets, and simplify
  `pipe_segment_model_fit.R` to final full-data fitting and fitted evaluation.
- [ ] Add explicit targets for fold assignment, tuning candidates, tuning summary,
  selected regularization, out-of-fold predictions, and cross-validated evaluation.
- [ ] Add a scale/tier aggregation target that selects shared regularization before
  fold-infeasible IDs are fitted.
- [ ] Update spatial runners to support the explicit tuning-summary stage, shared
  tier-selection stage, and final-fit stage without cross-store dependency cycles.
- [ ] Update all six affected pipeline assemblies and their mapped target naming.
- [ ] Replace ambiguous evaluation target structure with explicit fitted and predictive
  outputs, then update diagnostics, result readers, and prediction input readers.
- [ ] Add fold-balance and metric summaries to CZ diagnostics so failures are visible
  without manually reading target objects.
- [ ] Propagate `cv_strategy`, effective folds, feasibility status, location/sample
  counts, and regularization source into final evaluation and decomposition summaries.
- [ ] Add a common-regularization decomposition sensitivity path for representative
  continental, regional, and local models before broad production execution.
- [ ] Remove superseded package-native CV functions, tests, and config keys.
- [ ] Update issue #135 acceptance criteria after user approval; do not mutate the issue
  automatically during implementation.

**Validation:**

- This phase is not complete until its validation passes.
- Run targeted tests for every changed pipeline/configuration helper.
- Run `targets::tar_manifest()` for:
  - `pipeline_paleo_core.R`;
  - `pipeline_paleo_resolution_test.R`;
  - `pipeline_paleo_temporal.R`;
  - `pipeline_paleo_spatial_resolution.R`;
  - `pipeline_modern_spatial_resolution_test.R`;
  - `pipeline_modern_spatial_resolution.R`.
- Run `Rscript R/03_Supplementary_analyses/Testing/Run_tests.R`.
- Run `Rscript R/02_Main_analyses/Run_CZ_test.R` from fresh CZ stores.
- Inspect CZ fold tables to confirm whole paleo cores, spatial coverage in every fold,
  modern plot coverage, and configured fold counts.
- Exercise all feasible strategy states with focused fixtures or representative stores:
  grouped k-fold, leave-one-location-out, tier-pooled regularization, and no-model.
- Confirm finite out-of-fold Tjur R2, AUC, and log loss for evaluable taxa and explicit
  statuses for non-evaluable taxa.
- Confirm final model fitting consumes the selected regularization values.
- Confirm primary and common-regularization decompositions retain provenance and can be
  joined without silently mixing taxonomic resolutions or predictor structures.
- Compare CZ runtime and target-store size with the first implementation.
- Run the mandatory change-review workflow before closing the phase.

---

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Grid-stratified folds appear spatially balanced but still place nearby train/test locations together | High | State that the primary estimand is interpolation; add a separate geographic-block sensitivity analysis when extrapolation is the scientific question. |
| MEM basis leaks held-out locations or cannot be evaluated at test locations | High | Construct MEMs only from training coordinates and force test values through the same interpolation interface used by production predictions. |
| Different folds produce different numbers of positive MEVs | Medium | Use the minimum effective MEV count available across every viable fold of an ID and record it in comparison metadata. |
| Local units have too few locations for stable tuning | High | Start from five folds, increase toward leave-one-location-out to preserve training data, then use tier-pooled regularization before any explicit parent-tier fallback. |
| A small ID supports a full MEM model but no held-out MEM training partition | High | Use tier-pooled regularization and all available data for the final fit; never substitute row-wise CV. |
| Large IDs dominate tier-pooled candidate selection | Medium | Normalize loss per response, aggregate within ID, and weight IDs equally; report sample-weighted selection as a sensitivity when it differs. |
| Tier-pooled tuning creates a dependency cycle across isolated ID stores | High | Use an explicit two-stage aggregation pipeline and immutable shared artifact before final fitting. |
| Rare taxa lack both classes in individual folds | High | Pool out-of-fold predictions before taxon metrics, track prevalence, and return explicit undefined statuses when the pooled repeat still has one class. |
| Candidate selection and reported performance use the same folds | High | Label v1 results as tuning-CV estimates and defer nested outer CV to a publication-performance extension. |
| Custom CV substantially increases GPU runtime | High | Store compact summaries, rerun only the selected candidate for predictions, profile before parallelizing, and use reduced CZ candidate sets if scientifically acceptable. |
| Grid origin changes fold assignments | Medium | Use deterministic origins, optionally shift origins by repeat, and report repeat variability. |
| Balancing sample counts damages location balance or taxon prevalence | Medium | Use a deterministic multi-objective assignment and validate all three dimensions after construction. |
| Cross-validated Tjur R2 is mistaken for variance explained | Medium | Name and document it as the coefficient of discrimination; report AUC and log loss alongside it. |
| Downstream readers silently assume the old `model_evaluation` schema | High | Search all target-name consumers, update them in the same phase, and remove the old schema rather than leaving mixed semantics. |
| Cross-scale decomposition patterns are driven by different regularization sources | High | Attach provenance and compare primary decompositions with a common-regularization sensitivity refit. |

---

## Remaining Open Question

The core design is resolved. One calibration choice remains:

1. **Adaptive-grid occupancy criterion (resolved in Phase 1):** use median locations per
   occupied cell and select the finest candidate that reaches the configured occupancy
   target while preserving deterministic fold-balance thresholds. Each single-response
   pipeline/ID stores its own calibration. Multi-resolution pipelines store one shared
   pre-resolution calibration and only recalibrate a response branch when subsetting
   invalidates shared fold coverage or balance. The rule is configured in `config.yml`;
   no global calibration artifact is created.
---

## Issue #135 Acceptance Criteria

Issue #135 was updated on 2026-06-29 to replace the first implementation scope with
these acceptance criteria:

- [ ] Folds are assigned at unique-location level and keep all paleo ages from a core
  together.
- [ ] Fold assignment is spatially stratified and reproducible for both paleo and modern
  data.
- [ ] Fold count defaults to five and adapts toward leave-one-location-out when required
  to preserve configured training-data quality thresholds.
- [ ] Every spatial ID is classified as grouped k-fold, leave-one-location-out,
  tier-pooled regularization, or full-model-infeasible before fitting.
- [ ] Taxon filtering, scaling, and MEM construction are training-only within each fold.
- [ ] Held-out MEM predictors are interpolated from training MEMs using the production
  prediction path.
- [ ] Regularization is selected from held-out negative log likelihood.
- [ ] Fold-infeasible but full-model-viable IDs use traceable tier-pooled
  regularization rather than row-wise CV.
- [ ] Every model exposes out-of-fold Tjur R2, AUC, log loss, taxon prevalence, and
  repeat/fold diagnostics.
- [ ] Fitted and cross-validated metrics have explicit, non-overlapping names.
- [ ] All active paleo and modern model pipelines use the shared workflow.
- [ ] All changed functions are delivered through the documented TDD cycle.
- [ ] Full tests, affected manifests, and fresh CZ paleo/modern runs pass.
- [ ] Cross-scale decomposition outputs retain CV and regularization provenance and
  include a common-regularization sensitivity comparison.

---

## End-of-Plan Checklist

- [x] Resolve the adaptive-grid occupancy rule through Phase 1 CZ calibration.
- [x] Confirm implementation in the main worktree on `OndrejMottl/issue135`.
- [x] Update issue #135 after explicit user approval.
- [x] Begin with Phase 1 contracts and tests before model-fitting integration.
- [x] Add only the lightweight Phase 1 CV targets before fold-local preprocessing and
  model-fitting orchestration are implemented.
- [x] Keep each phase runnable and validated before beginning the next phase.
- [ ] Record actual CZ runtime, fold balance, retained taxa, and predictive metrics.
- [ ] Do not describe tuning-CV metrics as unbiased external performance unless nested
  or untouched outer validation is implemented.
