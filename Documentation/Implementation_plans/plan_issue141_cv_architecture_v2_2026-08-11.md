# Issue #141 — Cross-validation architecture and v2 contract refactor

## Summary

Implement Issue #141 as a substantive refactor of the CV execution engine, pipeline graph, pipe segments, target interface, and persisted artifacts.

This is an explicitly approved v2 contract migration:

- Public target names may change.
- Pipeline branching and target composition may change.
- Persisted artifact schemas may change.
- Existing v1 artifacts remain readable through strict converters.
- New pipelines write only v2 artifacts.
- V1 tuning caches are not imported into the new target graph; v2 execution starts clean.

Preserve the scientific and performance baseline:

- Optimized staged 8→4→2 tuning from Issue #138 and PR #148.
- Correctness findings and scientific invariants from Issue #139 and PR #142.
- Grouped holdouts, leave-one-location-out fallback, fold-local response processing, fold-local scaling and MEM construction, held-out MEM interpolation, deterministic seeds, candidate definitions, tier weighting, metric definitions, and scientific decision rules.
- The staged benchmark gates and clean-run performance improvement.

## Preparation and issue contract

Before implementation:

- Fast-forward `main` and create `issue141` in the current worktree.
- Save this plan as `Documentation/Implementation_plans/plan_issue141_cv_architecture_v2_2026-08-11.md`.
- Rewrite Issue #141 to explicitly supersede its previous frozen-target/schema restriction.
- Describe the work as one PR containing independently green capability checkpoints.
- Record PR #142 as the scientific/correctness baseline, PR #148 as the performance baseline, and PR #167 as the architecture-exception baseline.
- Capture all 26 current manifests, v1 target/store inventories, reference outputs, seed evidence, assignment hash, schema fixtures, benchmark provenance, and same-code resume behavior.
- Add `contract_inventory_v2.md`, `architecture_store_map_v2.md`, and `migration_matrix_v1_to_v2.md`; retain all v1 reports unchanged as historical evidence.

## V2 persisted-artifact interface

Every public persisted CV result becomes a uniform named-list envelope:

```r
list(
  schema_version = "2.0.0",
  artifact_type = "<registered artifact type>",
  payload = list(...),
  provenance = <one-row tibble>,
  content_hash = "<stable xxhash64>"
)
```

Envelope rules:

- `schema_version`, `artifact_type`, `payload`, `provenance`, and `content_hash` are mandatory.
- `payload` is always a named list, even for a single table.
- Common provenance contains `created_at`, pipeline ID, configuration profile, source schema version, migration flag, and migration function.
- Native v2 artifacts record `source_schema_version = "2.0.0"` and `migration_applied = FALSE`.
- Converted v1 artifacts record their original version and converter name.
- The stable content hash covers the artifact type, schema version, payload, and stable scientific provenance. It excludes creation time and migration-trace fields.
- Unknown versions, malformed envelopes, unknown payload fields, missing required fields, or invalid key uniqueness fail closed.
- Writers produce only v2. No v1 downgrade writer or duplicate legacy target is added.

Add common infrastructure:

- `build_sjsdm_artifact_envelope()`
- `validate_sjsdm_artifact_envelope()`
- `compute_sjsdm_artifact_content_hash()`
- Artifact-specific payload validators.
- Artifact-specific v1-to-v2 converters.
- Strict loaders that attempt the canonical v2 target first and then the documented v1 target group.

## Canonical public target interface

Replace the large granular public contract with these canonical unversioned artifact targets:

| Target | Artifact type | Payload |
|---|---|---|
| `list_cross_validation_shared_design_artifact` | `cross_validation_shared_design` | Shared sample universe, locations, fold resolution, grid candidates/calibration, assignments, and assignment provenance |
| `list_cross_validation_design_artifact` | `cross_validation_design` | Locations, resolution, initial/final assignments, diagnostics, feasibility, and route provenance |
| `list_sjsdm_cv_tuning_artifact` | `sjsdm_cv_tuning` | Candidate table, schedule, fold metrics, repeat summary, stage timings, execution provenance, and prediction cache |
| `list_sjsdm_regularization_selection_artifact` | `sjsdm_regularization_selection` | Unit selection, optional tier selection, final selection for fitting, and decision provenance |
| `list_sjsdm_cv_prediction_artifact` | `sjsdm_cv_predictions` | OOF predictions and fold diagnostics |
| `list_sjsdm_cv_evaluation_artifact` | `sjsdm_cv_evaluation` | Pooled evaluation, fold-local metrics, fold summaries, repeat distributions, and model-CV provenance |
| `list_sjsdm_tier_tuning_artifact` | `sjsdm_tier_tuning` | Round decisions, final regularization selection, source losses, candidate aggregation, and weighting sensitivity |
| `list_sjsdm_common_regularization_artifact` | `sjsdm_common_regularization` | Common selection, candidate aggregation, model index, and sensitivity provenance |

Granular computational targets remain where they improve restartability, but they are classified as internal and may be renamed or recomposed. They are no longer part of the supported cross-store interface.

Rename unclear internal targets where they remain:

- `data_sjsdm_tuning_candidates` → `data_sjsdm_candidate_fold_metrics`
- `data_sjsdm_tuning_summary` → `data_sjsdm_candidate_repeat_summary`
- `data_sjsdm_selected_regularization_unit` → `data_sjsdm_unit_regularization_selection`
- `model_regularization_for_fit` → `data_sjsdm_regularization_selection_for_fit`
- `list_sjsdm_selected_fold_predictions` → `list_sjsdm_selected_fold_artifacts`
- `model_evaluation_cross_validated` → `list_sjsdm_pooled_cv_evaluation`
- `data_sjsdm_model_provenance` → `data_sjsdm_cv_model_provenance`

Mapped pipelines continue to suffix branch targets through their existing mapping mechanism; the canonical base target names themselves remain unversioned.

## Structural refactor

### 1. Assignment and fold preparation

- Keep shared pre-resolution assignment and branch-specific fallback as distinct capabilities.
- Add `prepare_ordered_fold_partition()` for common filtering, subsetting, and deterministic ordering.
- Use it in spatial and abiotic fold preparation.
- Keep abiotic `drop_na()` in the abiotic caller to avoid changing spatial missingness.
- Remove the nested spatial and abiotic partition helpers.
- Build the two design artifacts from their granular computation results rather than recomputing design steps inside one monolithic target.

### 2. Candidate execution engine

Refactor `run_sjsdm_tuning_fold_candidates()` into a fold coordinator.

Add `run_sjsdm_prepared_tuning_candidate()` to own one candidate lifecycle:

- Derive fit and score seeds.
- Fit one candidate.
- Predict one held-out fold.
- Score predictions.
- Record fit, prediction, and scoring timings.
- Convert failures into structured result rows.
- Return one candidate-fold metric row and one compact cache record.
- Never retain fitted model objects.

Then:

- `run_sjsdm_tuning_fold_candidates()` prepares one fold and delegates candidates.
- `run_sjsdm_tuning_work_item()` resolves one previously prepared fold and calls the same primitive directly.
- `run_sjsdm_tuning_candidates()` remains the bulk/reference coordinator.
- Remove the cached preparation adapter from the work-item path.
- Use explicit constructors for candidate-fold results and typed-empty tuning payloads.

### 3. Selected-fold execution

Split the current selected-candidate runner into:

- `run_sjsdm_selected_fold()` — prepare, fit, and predict one live fold.
- `build_sjsdm_fold_prediction_skeleton()` — construct exact failure rows.
- `build_sjsdm_selected_fold_artifacts()` — align responses, taxa and predictions; calculate null probabilities; construct predictions and diagnostics.
- `combine_sjsdm_selected_fold_artifacts()` — combine folds, order results, and validate OOF coverage.
- `run_sjsdm_selected_candidate_folds()` — remain the public multi-fold coordinator for reference analyses.

Refactor cached reuse so `build_sjsdm_cached_selected_folds()` validates cache keys and selected-candidate records, then calls the same artifact builder directly.

Do not call the live runner through fake prepare, fit, or predict functions. Preserve the tuning fit seed when probabilities come from the cache.

### 4. High-level tuning orchestration

Keep `run_sjsdm_tuning_sequence()` as the top-level public orchestrator and extract:

- `build_sjsdm_tuning_round_plan()`
- `build_sjsdm_tuning_store_paths()`
- `run_sjsdm_tuning_unit_round()`
- `run_sjsdm_tuning_tier_round()`
- `load_sjsdm_unit_tuning_store_paths()`

The top-level sequence will:

1. Build the deterministic exhaustive or staged round plan.
2. Run the required isolated unit stores.
3. Verify complete tuning evidence.
4. Run the corresponding tier survivor or final target.
5. Continue through the cumulative 8→4→2 schedule.

Keep the nine production runner entrypoints explicit and thin. Preserve environment variables, first-round fresh/prebuild behavior, error propagation, `callr` boundaries, unit/tier store isolation, and progress behavior.

### 5. Pipeline and pipe-segment redesign

Retain three assignment responsibilities:

- Shared pre-resolution design.
- Direct route design.
- Shared-assignment branch design and fallback.

Create `pipe_segment_model_cross_validation_execution.R` containing the common execution graph beginning at the tuning schedule and ending at v2 evaluation publication.

- Reduce the existing 724- and 685-line route segments to assignment/context prefixes.
- Append the execution segment directly for core and temporal pipelines.
- Append the branch prefix and execution segment together inside mapped resolution pipelines.
- Allow the internal target graph to change when needed for clearer ownership and restartability.
- Preserve one restartable branch per authorized candidate-fold work item.
- Keep fold preparation cached separately from model fitting.
- Add the v2 public artifact targets at stable stage boundaries.
- Remove redundant extraction-only public targets when their data are available in the corresponding envelope.
- Do not introduce opaque target factories; target declarations remain literal and reviewable in `R/Pipelines/`.

In the tier pipeline:

- Replace multi-statement unit-store discovery with `load_sjsdm_unit_tuning_store_paths()`.
- Keep the three staged survivor computations explicit.
- Publish one `list_sjsdm_tier_tuning_artifact` envelope instead of four separate public tables.
- Granular round targets may remain internal to preserve restartability.

## V1 read compatibility

V1 compatibility exists only at explicit read boundaries:

- Tier aggregation can read a v2 unit tuning artifact or construct its required v2 payload from the old unit tuning-summary target.
- Unit completion can read the v2 tier artifact or upgrade the v1 `data_sjsdm_tier_regularization_artifacts` table.
- Common-regularization sensitivity can read v2 tuning/selection artifacts or upgrade the documented v1 targets.
- Historical reporting loaders can assemble v2 design, prediction, and evaluation envelopes from the corresponding v1 public targets.

Rules:

- Loaders attempt the v2 canonical target before v1 names.
- V1 inputs are validated against frozen v1 fixtures before conversion.
- Conversion is pure and never rewrites the old store.
- Unknown or partially matching v1 schemas fail closed.
- V1 fit objects and prediction caches are not imported into the new target graph.
- Running a v2 unit pipeline performs a clean v2 tuning execution.
- Converted and native v2 artifacts must validate through the same downstream interface.
- Create a follow-up issue to remove v1 readers after all retained stores have been regenerated; record that issue as owner/expiry for compatibility exceptions.

## Function-symbol migration

The 32 PR #167 function-name exceptions are resolved within their owning structural checkpoints, never as a standalone rename pass.

- `make_*` constructors become `build_*`, except partition diagnostics becomes `diagnose_cross_validation_partitions`.
- `assess_sjsdm_*` and `assess_spatial_*` become `evaluate_*`.
- `assess_cross_validation_feasibility` becomes `resolve_cross_validation_strategy`.
- Grid calibration becomes `compute_cross_validation_grid_calibration()` and `compute_cross_validation_grid_calibration_from_resolution()`.
- `adapt_cross_validation_assignments` becomes `resolve_cross_validation_assignments`.
- `assemble_sjsdm_cached_selected_folds` becomes `build_sjsdm_cached_selected_folds`.
- Tier and external-store `read_*`/`collect_*` functions become `load_*`.
- Timing collection becomes `summarise_sjsdm_tuning_timings`.
- Work-item combination becomes `aggregate_sjsdm_tuning_work_items`.
- Staged policy retrieval becomes `build_sjsdm_staged_benchmark_policy`.
- Decomposition comparison becomes `compute_sjsdm_decomposition_fold_effects`.
- Predictor configuration becomes `build_sjsdm_predictor_comparison_structure`, avoiding collision with existing `.build_sjsdm_predictor_structure()`.

Each migration atomically moves the function, file and matching test; updates callers, roxygen links and current inventories; and removes only its exact exception row. No function aliases are added.

## Checkpoint sequence

1. **Approve and inventory v2**
   - Update Issue #141, save the plan, freeze v1 fixtures, and publish the v1→v2 migration matrix.
2. **Artifact envelope and compatibility layer**
   - Implement the constructor, hashing, validation, artifact-specific payload validators, v1 converters, and dual-version loaders.
3. **Assignment and fold-input refactor**
   - Extract shared partition logic, build design artifacts, and migrate assignment/grid functions.
4. **Candidate execution engine**
   - Introduce the one-candidate primitive and unify bulk and granular tuning execution.
5. **Selected-fold execution**
   - Separate live fitting from artifact construction and replace cached adapters.
6. **Orchestration and tier refactor**
   - Extract round planning and execution, update external-store reads, and publish tier v2 artifacts.
7. **Pipe-segment and target redesign**
   - Introduce the common execution segment, canonical artifact targets, and new internal target graph.
8. **Evaluation and architecture closure**
   - Extract evaluation helpers, publish the v2 evaluation artifact, finish function migrations, examples, test-fixture cleanup, documentation, and exception retirement.
9. **Correctness, performance, compatibility, and review**
   - Run v1 conversion tests, clean v2 reference runs, paired benchmarks, architecture validation, and mandatory review.

Each checkpoint must be green and runnable before commit. Use durable capability-oriented commit wording.

## Test and acceptance plan

### V2 contract tests

- Snapshot every envelope’s field names, field types, artifact type, payload keys, provenance keys, and content hash.
- Verify deterministic content hashes for identical scientific content.
- Verify creation time and migration trace do not alter the scientific content hash.
- Test native v2, valid v1 conversion, incomplete v1, unknown version, malformed payload, duplicate keys, and wrong artifact type.
- Confirm new manifests contain canonical artifact targets and no legacy public-output aliases.

The historical v1 schema hash `2d727fd54623501e0ac384e0674c17f3` remains the converter fixture. Generate and record a new v2 contract hash after the v2 schema is approved.

### Scientific equivalence

- Preserve assignment hash `ec5dcdda6049a504cb0b69f845c64aa8`.
- Compare v1 and v2 canonical payload content after removing envelope-only metadata.
- Require identical assignments, candidates, seeds, statuses, selected regularization, OOF probabilities, diagnostics, metrics, coverage, and scientific decisions.
- Exercise direct, shared-assignment, fallback, leave-one-location-out, infeasible, preparation-error, fit-error, prediction-error, and scoring-error paths.
- Run all scientific, component, regularization, and decomposition reference pipelines.

### Pipeline and restartability

Across all 26 supported pipeline/profile manifests:

- Review every target addition, removal, rename, dependency, command, branch, format, and store.
- Require one restartable unit per candidate-fold work item.
- Verify fold preparation is not repeated per candidate.
- Verify failed branches do not invalidate successful siblings.
- Verify same-code v2 reruns cause no unintended fits.
- Verify v1 external stores can be read without being modified.

### Performance

Execute the exact three clean paired `issue138_staged_benchmark_v2` comparisons and require:

- The v2 staged schedule remains 8→4→2.
- Median staged wall-time reduction ≥15%.
- Every paired run ≥10% faster.
- Fit-count reduction ≥40%.
- Store growth ≤25%.
- Peak RAM/VRAM growth ≤10%.
- No GPU OOM.
- Log-loss regression ≤0.005.
- AUC and Tjur R² regression ≤0.01.
- Evaluable-coverage decline ≤2 percentage points.
- Any changed selected candidate receives explicit scientific review.

### Final validation

- Run focused tests during TDD and the full suite after every shared execution or pipeline checkpoint.
- Run the architecture inventory generator, documentation generator, dependency-map generator, and blocking architecture validator.
- Regenerate function documentation and the website.
- Preserve `architecture_findings_v1.csv` and all v1 reports unchanged.
- Require zero obsolete function names in active code and current generated artifacts.
- Finish with `git diff --check` and mandatory read-only review.

## Assumptions and boundaries

- One PR in the current worktree on `issue141`.
- The user has approved a full versioned redesign with canonical unversioned target names and a uniform v2 envelope.
- V1 is read-compatible; v2 is the only write format.
- V2 unit execution is clean and does not import v1 tuning caches.
- Scientific behavior and optimized 8→4→2 execution remain unchanged unless benchmark evidence identifies a separately approved improvement.
- Issue #166 remains separate.
- Close #141 only after v2 compatibility, correctness, performance, and architecture gates pass; then verify and close umbrella #140.
