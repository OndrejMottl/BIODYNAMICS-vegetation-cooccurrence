# Issue 141 cross-validation architecture v2 validation

**Validation date:** 2026-08-12
**Branch:** `issue141`
**Baseline commit:** `23645d39ee301ceac20e40e1acd5f6feb7275229`
**Validated implementation commit:** `e65d0890`
**Owning issue:** #141

## Outcome

The v2 cross-validation architecture is implemented and passes its contract, compatibility, scientific-equivalence, restartability, reference-pipeline, smoke, test-suite, and architecture checks. The implementation is not accepted for merge and Issue #141 must remain open because the exact three-pair clean benchmark missed one required performance gate: median staged wall-time reduction was 12.86% rather than at least 15%.

This result must not be replaced by selected runs or combined with the interrupted preliminary pair 947. The draft pull request remains explicitly blocked until a separately reviewed optimization makes the complete prescribed benchmark pass.

## Implemented contract

- Eight canonical public cross-validation artifact targets publish strict v2 envelopes.
- The registered v2 contract hash is `717435760b653dce608ce51380ec0fb1`.
- Writers produce only schema `2.0.0`; strict v1 readers convert at explicit external-store and historical-reporting boundaries without modifying v1 stores.
- The candidate engine separates fold preparation from one-candidate fit, prediction, scoring, timing, failure handling, and compact-cache construction.
- Live selected-fold fitting and cached selected-fold artifact assembly share builders without fake fit or prediction adapters.
- The public tuning sequence retains explicit runner entry points while delegating round planning, isolated-store execution, evidence validation, and tier loading.
- Core, temporal, and mapped-resolution pipelines share one literal execution segment beginning at the tuning schedule. Assignment and route-specific model context remain in their owning prefixes.
- The cumulative staged schedule remains 8→4→2, and each authorized candidate-fold work item remains restartable.
- All Issue #141 naming exceptions are retired without compatibility aliases. The reusable `run_sjsdm_selected_candidate_folds()` coordinator remains available to the reference pipelines.

The exact target, store, schema, and migration interfaces are recorded in `contract_inventory_v2.md`, `architecture_store_map_v2.md`, and `migration_matrix_v1_to_v2.md`. All v1 reports, including `architecture_findings_v1.csv`, remain unchanged historical evidence.

## Contract and compatibility validation

- Envelope tests snapshot exact top-level fields, payload keys, provenance keys, artifact types, classes, column order and types, uniqueness rules, status vocabulary, and deterministic seed fields.
- Hash tests confirm identical scientific content has an identical xxHash64 value and that creation time and migration trace do not affect that value.
- Negative tests cover unknown versions, wrong artifact types, malformed envelopes, incomplete v1 inputs, unknown payload fields, missing fields, and duplicate keys.
- Native and converted v2 artifacts pass the same artifact-specific validators.
- The frozen historical v1 schema hash remains `2d727fd54623501e0ac384e0674c17f3`; the v2 registry contract hash is distinct by design.
- The regenerated manifest inventory contains 18,256 profile-target rows across all 26 supported profiles.

## Scientific and execution validation

The exact paired benchmark produced identical exhaustive and staged assignments, candidates, deterministic seeds, statuses, selected regularization (`candidate_008`), OOF prediction payloads, evaluation payloads, coverage, and scientific decisions. The staged and exhaustive assignment artifacts are mutually identical. The historical v1 assignment hash `ec5dcdda6049a504cb0b69f845c64aa8` remains the frozen v1 fixture; v2 target serialization is not presented as the same byte representation.

The v2 evaluation values in every formal pair were:

| Measure | Value |
|---|---:|
| Fold-macro mean log loss | 0.30853704433834128 |
| Mean AUC | 0.65617680034118375 |
| Mean Tjur R-squared | 0.052077757906886069 |
| Evaluable coverage used | 0.6625 |

Fresh reference validation completed without target errors:

| Reference | Result | Runtime | Scientific result |
|---|---|---:|---|
| Direct CV reference | 340 completed, 42 skipped | 15m 8.3s | All five canonical v2 envelopes passed validation |
| Component reference | 24 completed, 0 skipped | 4m 44.8s | Passed |
| Structured regularization reference | 32 completed, 0 skipped | 27m 52.3s | Passed |
| Local scientific reference | 30 completed, 0 skipped | 1m 56.3s | All nine decision criteria passed; calibration caution retained |
| Decomposition reference | 28 completed, 0 skipped | 5m 10.8s | Passed |

The local scientific and decomposition runs exposed two stale source-store target names left by the earlier persisted-name migration. Their readers now use `model_formula_genus` and `model_anova_genus`, respectively, with focused contract regressions.

The mandatory production smoke covered paleo core, mapped paleo resolution, and modern spatial resolution. Paleo core completed 225 targets with 42 skipped in 2m 12.4s; mapped paleo resolution completed 375 targets with 42 skipped in 5m 13s; modern spatial resolution completed 2,215 targets with none skipped in 15m 21.3s. All three stores had zero target errors. Direct reads and artifact-specific validation passed for all 37 published canonical envelopes: 5 in paleo core, 16 in mapped paleo resolution, and 16 in modern spatial resolution.

## Restartability

An immediate same-code staged rerun did not refit models or rematerialize canonical v2 artifacts. Canonical artifact timestamps and target hashes remained unchanged. Fold preparation remains separately cached from candidate fitting, and failed candidate branches do not invalidate successful siblings.

## Exact clean paired benchmark

Pair 947 was interrupted and excluded before the prescribed three homogeneous pairs were started. Pairs 948–950 all used the same implementation and policy.

| Pair | Exhaustive wall time (s) | Staged wall time (s) | Reduction | Exhaustive fits | Staged fits |
|---:|---:|---:|---:|---:|---:|
| 948 | 1268.9789422 | 1105.8469907 | 12.86% | 120 | 70 |
| 949 | 1253.2831788 | 1108.1298661 | 11.58% | 120 | 70 |
| 950 | 1329.6223571 | 1113.0023440 | 16.29% | 120 | 70 |

The repository benchmark evaluator passed 14 of 15 gates:

| Gate | Observed | Required | Result |
|---|---:|---:|---|
| Median wall-time reduction | 12.86% | at least 15% | **Fail** |
| Every-pair wall-time reduction | 11.58% minimum | at least 10% | Pass |
| Fit-count reduction | 41.7% | at least 40% | Pass |
| Worst store growth | -9.76% | at most 25% | Pass |
| Worst peak RAM growth | 0.43% | at most 10% | Pass |
| Worst peak VRAM growth | 7.36% | at most 10% | Pass |
| GPU out-of-memory | None | None | Pass |
| Log-loss regression | 0 | at most 0.005 | Pass |
| AUC regression | 0 | at most 0.01 | Pass |
| Tjur R-squared regression | 0 | at most 0.01 | Pass |
| Evaluable-coverage decline | 0 percentage points | at most 2 percentage points | Pass |
| Selected-candidate review | Unchanged | Review only if changed | Pass |

The remaining evaluator gates cover the exact schedule, run completeness, scientific equivalence, and paired-run provenance; each passed.

## Repository validation

- Full test suite: 1,340 passed, 0 failed, 0 warnings, 1 documented integration skip.
- Architecture inventory: 521 R scripts, 387 reusable functions, and 421 targets.
- Blocking architecture validator: zero findings across zero finding types.
- Active-code and current-generated-artifact scans contain no obsolete Issue #141 function names; preserved historical reports and provenance are intentionally excluded.
- The maintained source, tests, contracts, and reports pass the Git diff whitespace check. Regenerated self-contained progress HTML preserves upstream third-party JavaScript whitespace exactly, as documented by the repository.
- The mandatory read-only change review was performed before publication.

## Acceptance status

The v2 migration is technically and scientifically coherent, but the user-approved acceptance contract requires every listed gate. Because the median clean staged wall-time reduction is below 15%, the work may be published only as a blocked draft pull request. Issue #141 and umbrella #140 remain open.
