# Plan: Scalable shared Moran eigenvector construction

**Date:** 2026-07-24  
**Author:** Codex following the repository large-change planning workflow  
**Status:** Draft; scientific-method approval required before implementation  
**Parent work:** Issue #138, shared cross-validation runtime optimization

---

## Goal

Remove the dense-MEM bottleneck that prevents the common modelling engine from
reaching CV on continental data, while retaining exact current behavior for
small inputs and preserving fold-local leakage protection. Large spatial inputs
will use one deterministic, documented low-rank Moran-eigenvector method shared
by paleo, modern, spatial, temporal, continental, regional, and local
pipelines. The method will not become the production path until paired
scientific and computational gates pass.

---

## Failure evidence

Modern continental repetition 113 failed before CV in
`data_spatial_mev_core`. It contained 19,864 projected locations and 19,778
unique coordinate pairs. The attempted dense path reported:

```text
Error: cannot allocate vector of size 2.9 Gb
```

A single dense double matrix at this size is approximately 2.94 GiB.
`sjSDM::generateSpatialEV()` creates the all-pairs distance matrix plus several
additional dense matrices and then performs a dense eigendecomposition. The
run reached a 21.14 GiB process working set and a 45.70 GiB system-used memory
peak. It did not execute any CV fit.

The diagnostic record is:

`Documentation/Reports/Cross_validation_performance/representative_modern_continental_failure_preliminary_v1.md`

---

## Scientific basis and preferred design

Murakami and Griffith developed a Nyström approximation for Moran eigenvectors
specifically to avoid full eigendecomposition for large spatial samples. Their
published comparisons report small approximation errors for positive spatial
dependence when a sufficiently rich basis is retained. The `spmoran` package
provides the reference implementation through `meigen_f()` and projects the
training basis to new locations through `meigen0()`.

The preferred implementation is therefore:

1. **Exact mode:** retain `sjSDM::generateSpatialEV()` unchanged for inputs below
   a shared limit.
2. **Fast mode:** use the package-backed Nyström approximation for inputs above
   the shared limit.
3. **Automatic mode:** choose exact or fast from the unique-location count and
   a common dense-work threshold, never from project, continent, or pipeline
   identity.
4. **Fold-local projection:** construct the fast basis from training locations
   only and project it to held-out locations with the matching Nyström
   extension. Never construct the basis using held-out locations.
5. **Public compatibility:** continue exposing the existing MEV data frames and
   column names. Keep basis state and method provenance in explicit internal
   list objects or companion targets; do not attach invisible attributes.

This route is preferred over a custom "fit exact MEMs on landmarks, then IDW"
shortcut. The shortcut would reuse current interpolation code, but it is not
the published Nyström construction and would create a new scientific method
that the project would have to validate and maintain independently.

The fast path changes the connectivity kernel and basis construction relative
to `sjSDM::generateSpatialEV()`. It is therefore an approximation strategy, not
a numerically identical optimization. That difference is the reason for the
approval and equivalence gates below.

---

## Scope

### In scope

- Shared 2-D spatial MEM construction.
- Fold-local training construction and held-out projection.
- Chunk-bounded prediction where any fallback interpolation remains necessary.
- Shared configuration, validation, provenance, and diagnostics.
- Exact-versus-fast paired fixtures and downstream predictive comparisons.
- Representative CZ and continental validation.

### Out of scope

- Project-, continent-, or resolution-specific thresholds.
- Changes to the staged candidate-pruning rules.
- Changes to grouped folds, seeds, response preprocessing, or selection
  metrics.
- Approximation of spatiotemporal MEMs without separate evidence that the same
  method is valid for that construction.
- Treating repetition 113 as a staged-tuning benchmark.

### Likely affected components

- `config.yml`
- `renv.lock`
- `R/Functions/Modelling/Spatial_effects/compute_spatial_mev.R`
- A new shared MEM basis/provenance helper under
  `R/Functions/Modelling/Spatial_effects/`
- `R/Functions/Modelling/Spatial_effects/interpolate_mev_to_grid.R`
- `R/Functions/Modelling/Cross_validation/prepare_fold_spatial_predictors.R`
- `R/Functions/Modelling/Cross_validation/prepare_sjsdm_cross_validation_fold.R`
- `R/Pipelines/_pipes/pipe_segment_model_spatial_shared.R`
- Focused spatial, fold-preparation, configuration, provenance, contract, and
  benchmark tests

---

## Shared configuration contract

Add one shared spatial-MEM block under `model_fitting`, with names finalized
after inspecting existing configuration validators:

```yaml
spatial_mev:
  strategy: "auto"
  strategy_version: "spatial_mev_nystrom_v1"
  exact_max_locations: 1999
  fast_eigenvectors: 200
```

Rules:

- `strategy` accepts `exact`, `fast`, and `auto`.
- `exact` fails closed with a clear estimated-cost diagnostic if the configured
  shared safety limit is exceeded; it must not silently allocate an
  unbounded matrix.
- `fast` always exercises the low-rank path, including in paired fixtures.
- `auto` uses only the shared location-count rule.
- `exact_max_locations` is one common engine value. The initial value follows
  the reference implementation's switch to approximation for 2,000 or more
  locations and remains subject to measured memory/runtime evidence.
- `fast_eigenvectors` is validated against the requested public `n_mev` and the
  number of unique training locations.
- Reduced CZ profiles may explicitly keep `exact` so their current basis is
  unchanged and the small fixtures continue to test the reference path.

No production profile may override these values based on continent identity.

---

## Implementation phases

### Phase 1 - Lock contracts and exact-path compatibility

**Goal:** Introduce the method interface without changing current small-input
results.

**Tasks:**

- Add failing tests for valid and malformed strategy configuration.
- Add deterministic method-selection tests around the shared boundary.
- Split basis construction from public data-frame extraction so projection
  state and provenance remain explicit.
- Preserve exact `sjSDM::generateSpatialEV()` output below the boundary,
  including row order, `mev_*` names, clamping behavior, and warnings.
- Add a pre-allocation guard to exact mode with an actionable error.

**Validation:**

- Focused `compute_spatial_mev()` and configuration tests pass.
- Exact-path fixture output matches the pre-change result within the existing
  numerical tolerance.
- Affected target manifests resolve without public target renaming.
- The full suite passes because this changes shared modelling infrastructure.
- A fresh `R/02_Main_analyses/Run_CZ_test.R` passes and uses exact mode.

### Phase 2 - Add the deterministic fast basis and fold-local projection

**Goal:** Make large spatial inputs bounded in memory without weakening
held-out separation.

**Tasks:**

- Add the version-pinned `spmoran` dependency and record it in `renv.lock`.
- Implement a small adapter around `spmoran::meigen_f()` that returns:
  public MEV values, explicit projection state, and provenance.
- Implement held-out projection through `spmoran::meigen0()`.
- Route shared-core and fold-local construction through the same adapter.
- Keep training-only basis estimation mandatory in CV.
- Preserve the existing IDW path for exact-basis compatibility; make its
  distance work chunk-bounded so prediction cannot create an unbounded
  prediction-by-training matrix.
- Handle duplicate coordinates, deterministic ordering, insufficient unique
  locations, non-finite coordinates, ties, and fewer available positive
  eigenvectors fail-closed.

**Validation:**

- TDD covers deterministic repeated results, duplicate coordinates, row-order
  restoration, exact/fast dispatch, malformed inputs, and bounded chunks.
- A leakage test proves changing held-out coordinates cannot alter the fitted
  training basis.
- A projection test proves every held-out row is generated from the matching
  training basis state.
- Fold-preparation, public-schema, and affected-manifest tests pass.
- The full suite and fresh CZ workflow pass.

### Phase 3 - Add provenance and paired scientific gates

**Goal:** Make the approximation visible and reject it if scientific behavior
is not sufficiently close.

**Tasks:**

- Record method, strategy version, input/unique-location counts, requested and
  retained eigenvector counts, exact/fast decision, projection method, and
  timing/memory fields in additive provenance.
- Build deterministic medium-size paired fixtures that can execute both exact
  and fast paths on identical coordinates, assignments, responses, and seeds.
- Compare bases using sign- and rotation-invariant diagnostics such as
  principal angles or projection-matrix similarity; do not compare columns
  naively because eigenvector signs and tied eigenspaces are not identifiable.
- Compare spatial structure retained by the bases and downstream held-out
  predictions.
- Apply the existing Issue 138 predictive gates to paired downstream results:
  mean repeat log loss may worsen by at most `0.005`, AUC and Tjur R2 by at
  most `0.01`, and evaluable-taxon coverage by at most two percentage points.
- Report any changed selected candidate for scientific review.

**Validation:**

- Paired fixtures pass their structural and downstream gates.
- Exact and fast technical statuses, fold grouping, response filtering,
  leakage protections, target names, and public schemas match.
- Provenance is complete for successful, failed, and resumed work.
- Focused tests, the full suite, and fresh CZ workflow pass.

### Phase 4 - Re-run representative modern continental validation

**Goal:** Demonstrate that the common engine reaches and completes staged CV
without the dense-MEM failure.

**Tasks:**

- Optionally resume the failed store only as diagnostic restart evidence.
- Run a clean modern continental repetition with a new repetition identifier
  and isolated store.
- Measure MEM construction/projection, fitting, prediction, scoring,
  aggregation, final fitting, RAM/VRAM, utilization, and storage.
- Verify all 70 staged fits and cached selected-candidate OOF assembly.
- Compare the accepted run against the Issue 138 runtime, fit-count, storage,
  memory, and predictive gates.
- Repeat representative validation for applicable temporal/spatiotemporal
  paths only if Phase 2 explicitly supports their MEM construction.

**Validation:**

- No dense allocation or GPU memory failure occurs.
- No CV work item uses held-out locations to construct its training basis.
- The clean run has a terminal harness summary, zero unexpected target errors,
  complete finalists, and explicit provenance.
- Repetition 113 remains labelled diagnostic and excluded from acceptance
  aggregates.
- Focused tests, the full suite, and a fresh CZ workflow still pass after any
  benchmark-driven corrections.

---

## Decision gates

Implementation can begin after approval of the package-backed Nyström strategy.
Production `auto` mode can be enabled only if all of the following hold:

- exact small-input behavior remains compatible;
- deterministic paired fixtures pass;
- fold-local leakage protections are unchanged;
- predictive regression is within the Issue 138 allowances;
- peak memory is bounded well below the failed dense path;
- the clean modern continental run completes;
- no project- or continent-specific branch or threshold is introduced.

If the fast path fails scientific equivalence, do not relax the gates. Retain
the exact path and evaluate another published scalable basis construction.

---

## Risks and mitigations

| Risk | Likelihood | Mitigation |
|---|---:|---|
| Fast and exact methods use different connectivity kernels | High | Treat as a scientific method change; require paired basis and downstream predictive gates |
| Eigenvector signs or tied-basis rotations differ | High | Compare subspaces and predictions, not raw columns alone |
| Approximation changes selected tuning candidate | Medium | Report explicitly and require scientific review |
| Fold projection leaks held-out geometry | Medium | Persist training basis state and test invariance to held-out changes |
| New package changes the reproducible environment | Medium | Pin in `renv.lock`, test in a fresh R session, and record versions |
| Duplicate or sparse coordinates destabilize the basis | Medium | Normalize duplicates deterministically and fail closed on insufficient support |
| Exact mode is forced on unsafe input | Medium | Preflight the shared safety limit before dense allocation |
| Generic IDW fallback still allocates a large matrix | Medium | Process prediction locations in bounded chunks |

---

## Rejected alternatives

- **Retry repetition 113 unchanged:** rejected because the failed operation is a
  deterministic dense allocation before CV.
- **Increase RAM or page-file capacity:** rejected as the primary solution
  because dense storage and eigendecomposition scale poorly and the same
  engine must support larger units.
- **Disable MEMs for modern continental runs:** rejected because it changes the
  scientific model only for one pipeline.
- **Add a Europe/continental threshold:** rejected because optimization belongs
  to the shared engine.
- **Exact MEMs on custom landmarks followed by IDW:** not selected initially
  because it lacks the direct published/reference implementation available for
  the Nyström method.

---

## Approval question

Approve the package-backed Nyström fast path as the candidate shared method,
subject to the exact-versus-fast scientific gates above. Approval authorizes
implementation and testing; it does not authorize enabling production
`auto` mode if the gates fail.

