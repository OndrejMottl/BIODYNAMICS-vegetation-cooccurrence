# Plan: Stabilize, optimize, and simplify cross-validation

**Date:** 2026-07-14
**Author:** plan-large-changes agent
**Status:** Draft

---

## Goal

Turn the cross-validation system introduced by issue #135 and PR #137 into a
correctness-audited, measurably faster, and maintainable production system. Work
is strictly sequential: stabilize the scientific and artifact contracts, optimize
the measured execution path, and only then simplify the architecture that remains.

## Background

- #135 and PR #137 introduced project-owned fold fitting, fold-local preprocessing,
  held-out MEM interpolation, tier-pooled tuning, selected-candidate out-of-fold
  prediction, common-regularization sensitivity, and fitted/predictive evaluation.
- #139 currently combines a complete audit with a large maintainability refactor.
- #138 owns profiling and runtime reduction for continental paleo and modern models.
- The existing issues are reorganized beneath one umbrella because a complete
  cleanup before profiling could optimize the wrong architecture, while performance
  work before a correctness audit could preserve accidental or incorrect contracts.

---

## Planning assumptions

- Git worktree: no worktree is created by this planning task. Each implementation
  issue should use its own branch or worktree from the then-current `main`.
- Refactor scope: large.
- Complexity: high.
- Duration: longer than one week.
- Execution order is strict; the three child issues are not parallel work streams.

---

## Scope

### In scope

- A PR-#137-wide read-only review and correctness stabilization.
- Reproducible performance baselines and measured runtime/storage optimization.
- A final maintainability refactor informed by the selected execution design.
- Contract tests for scientific invariants, public target names, artifact schemas,
  statuses, diagnostics, and provenance.
- Documentation of architecture, benchmark protocol, decisions, and migrations.

### Out of scope

- Changes to the scientific estimand without separate explicit approval.
- Combining isolated unit and tier stores into one nested targets graph.
- Continent-specific shortcuts that do not generalize.
- Compatibility wrappers without a demonstrated active consumer.
- A standalone validation-only phase or issue.

### Affected files and components

- The complete PR #137 diff against `main`, including source, tests, configuration,
  runners, documentation, generated files, and deleted/superseded paths.
- `R/Pipelines/_pipes/pipe_segment_model_cross_validation.R`
- `R/Pipelines/_pipes/pipe_segment_model_cross_validation_from_shared.R`
- `R/Pipelines/_pipes/pipe_segment_model_cross_validation_shared.R`
- `R/Pipelines/pipeline_sjsdm_tier_tuning.R`
- `R/Pipelines/pipeline_sjsdm_common_regularization_sensitivity.R`
- Paleo, modern, temporal, CZ, resolution-test, and spatial-resolution pipelines.
- `R/Functions/Modelling/Cross_validation/`
- `R/Functions/Modelling/Evaluation/read_spatial_model_results.R`
- Paleo, modern, and temporal orchestration runners.
- `config.yml`, function tests, integration fixtures, diagnostics, Quarto documents,
  generated documentation, and progress artifacts touched by PR #137.

---

## Refactoring strategy

Use a sandwich strategy rather than two full refactors:

1. Audit first and change only correctness, contract coverage, and benchmark
   readiness. Produce a versioned architecture map, contract inventory, findings
   register, and correctness reference outputs.
2. Profile the stabilized implementation under a predefined benchmark protocol.
   Structural changes are allowed only where required by the selected measured
   execution design.
3. Refactor the optimized implementation in independently reviewable slices:
   contract/schema handling, target declarations and pipe segments, runner/store
   orchestration, then dead code and documentation.

Public target names, artifact schemas, scientific behavior, and isolated-store
boundaries remain stable unless an explicit migration is approved. Schema versioning
is not added merely as cleanup; it requires an approved migration and compatibility
tests. Internal interfaces may change during the final refactor.

---

## Implementation phases

### Phase 1 - Audit and stabilize cross-validation contracts (#139)

**Goal:** Establish that the implementation is scientifically correct and define a
stable reference contract suitable for performance measurement.

**Tasks:**

- [x] Use `.ai/agents/changes-reviewer.agent.md` to inventory and review every file
  in PR #137 before editing code.
- [x] Produce an architecture/store map covering fold preparation, fitting,
  prediction, evaluation, target dependencies, isolated stores, and artifacts.
- [x] Produce a contract inventory for target names, artifact schemas, statuses,
  grouped assignments, leakage protections, MEM interpolation, tier weighting,
  predictive metrics, deterministic seeds, and provenance.
- [x] Maintain a findings register with severity, file/line evidence, impact,
  correction, owner, and disposition.
- [x] Correct all high/medium correctness findings that affect scientific validity,
  contract reliability, or benchmark trustworthiness.
- [x] Explicitly disposition any non-blocking maintainability finding to
  the final refactor issue; do not silently defer correctness findings.
- [x] Add contract-level regression tests and capture versioned correctness reference
  outputs/metadata for the stabilized implementation.
- [x] Preserve production candidate counts, repeats, folds, scheduling, fitting
  behavior, and performance configuration; isolate diagnostic reference profiles.

**Validation:**

- Run focused `testthat::test_file()` checks for every corrected contract.
- Run `Rscript R/03_Supplementary_analyses/Testing/Run_tests.R` because shared model
  infrastructure and broad contracts are in scope.
- Generate and compare manifests for every affected pipeline, including
  `pipeline_paleo_spatial_resolution.R`, `pipeline_modern_spatial_resolution.R`,
  `pipeline_paleo_temporal.R`, `pipeline_sjsdm_tier_tuning.R`, and
  `pipeline_sjsdm_common_regularization_sensitivity.R`.
- Run `R/03_Supplementary_analyses/Testing/Smoke/run_cz_pipelines.R` with fresh `project_cz_paleo` and
  `project_cz_modern` target stores. Both workflows must complete, emit the expected
  tier/OOF/evaluation/provenance artifacts, and match documented correctness
  reference values within contract-specific tolerances.
- Parse/render affected Quarto and generated documentation where those files change.
- Run the mandatory change-review workflow before closing the issue.
- Closure gate: no unresolved correctness finding of high or medium severity; any
  deferred maintainability finding has an explicit disposition in the final child.

**Handoff to Phase 2:** versioned architecture/store map, contract inventory,
findings register, test suite, and correctness reference outputs/metadata.

**Phase status:** Complete and ready for pull-request review. The final
whole-branch review is recorded in `issue139_closure_review_v1.md`. All PR #137
files are inventoried and reviewed, no high/medium finding remains unresolved,
required validation evidence is versioned, and generated pipeline progress
artifacts are included as a dedicated documentation commit.

### Phase 2 - Profile and reduce cross-validation runtime (#138)

**Goal:** Select and implement a materially faster execution design using evidence
from reproducible representative workloads.

**Tasks:**

- [ ] Begin only after Phase 1 is merged into `main` and its closure gate passes.
- [ ] Define the benchmark protocol before optimizing: dataset snapshot/hash,
  hardware and software versions, CPU/GPU settings, random seeds, cache/store state,
  repetitions, workload scripts/configurations, measured stages, and collection
  method.
- [ ] Benchmark clean-store and restart/resume behavior for CZ paleo and modern, plus
  representative continental paleo and modern workloads selected from
  `project_paleo_spatial_continental`, `project_modern_spatial_continental`, and the
  temporal Europe/America/Asia configurations as applicable.
- [ ] Record stage wall time, fit counts, peak memory, GPU/CPU utilization, target
  store size, cache behavior, and restart behavior.
- [ ] Predefine numerical thresholds for material runtime improvement, acceptable
  performance variance, and scientific equivalence before choosing an optimization.
- [ ] Evaluate reuse/materialization of tuning OOF predictions, adaptive search,
  fold/repeat sensitivity, representative tier subsets, GPU scheduling, and
  restartable orchestration.
- [ ] Treat options that alter prediction semantics or the statistical procedure as
  experiments only unless predefined equivalence criteria pass. Any intentional
  scientific-method change requires separate explicit approval.
- [ ] Implement at least one generalizable measured optimization and document the
  selected/rejected alternatives and trade-offs.
- [ ] Record and freeze the selected execution design and public contracts for the
  final refactor; internal interfaces remain refactorable.

**Validation:**

- Re-run the exact benchmark protocol on the same data snapshot and hardware with
  the predefined repetition count.
- The selected change must meet the predefined material-improvement threshold and
  remain within predefined tolerances for candidate selection, OOF predictions,
  Tjur R2, AUC, log loss, fold diagnostics, tier weighting, and provenance.
- If restartability/orchestration changes, interrupt at a documented target boundary,
  resume from the same store, and verify identical artifacts without unintended fits.
- Run focused tests, the full test suite, affected manifests, fresh CZ paleo/modern
  workflows, and the representative production benchmark.
- Run the mandatory change-review workflow before closing the issue.

**Handoff to Phase 3:** benchmark protocol/results, selected execution design,
rejected-option record, scientific equivalence results, public-contract snapshot,
and allowable post-refactor performance-regression threshold.

### Phase 3 - Simplify the optimized cross-validation architecture (new issue)

**Goal:** Remove demonstrated duplication and clarify ownership without changing the
optimized execution behavior or public/scientific contracts.

**Tasks:**

- [ ] Begin only after Phase 2 is merged into `main` and its closure gate passes.
- [ ] Use the Phase-1 findings register and Phase-2 execution-design record as the
  authoritative inputs.
- [ ] Slice A: consolidate explicit contract/schema/status/provenance construction
  where duplication is demonstrated; preserve schemas exactly unless a separately
  approved migration includes compatibility tests.
- [ ] Slice B: consolidate direct/shared target-building boundaries and separate fold
  preparation, fitting, prediction, scoring, and target declarations.
- [ ] Slice C: simplify runner sequencing and target-store reads without hiding or
  combining isolated unit/tier store boundaries.
- [ ] Slice D: remove dead/stale compatibility paths, simplify large functions through
  coherent data transformations, and document artifact regeneration policy.
- [ ] Add helpers only when they remove demonstrated duplication or clarify ownership.
- [ ] Do not change candidate/repeat/fold counts, scheduling, parallelism, fitting
  behavior, the scientific estimand, or performance policy.

**Validation:**

- After each slice, run the most focused tests and affected `tar_manifest()` checks;
  the relevant pipeline must remain runnable before proceeding.
- Automatically compare public target names, artifact schemas, status/provenance
  fields, and Phase-1 correctness reference outputs before and after each slice.
- Run the full suite for every slice changing shared infrastructure.
- After all slices, run fresh `project_cz_paleo` and `project_cz_modern` workflows and
  compare expected artifacts and reference outputs.
- Re-run Phase 2's exact benchmark protocol. Runtime and storage must remain within
  the predefined allowable regression threshold unless a measured improvement is
  documented.
- Parse/render affected Quarto/generated documentation and run the mandatory
  change-review workflow before closing the issue.
- Closure gate: no unresolved high/medium finding, or an explicit accepted follow-up
  issue for each exceptional deferral.

---

## Dependency and branch rules

- #138 is blocked by the revised #139.
- The final simplification issue is blocked by #138.
- Each implementation branch/PR starts from updated `main` only after its predecessor
  is merged. Do not maintain parallel long-lived branches for these children.
- Use durable branch/PR names describing behavior, not phase numbers.
- No state-changing git operation is performed without explicit user instruction.

---

## Risks and mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Correctness changes contaminate the timed baseline | Medium | Phase 1 captures correctness references; Phase 2 records its timed baseline only after stabilization merges. |
| Runtime work embeds accidental architecture | Medium | Permit only structure required by the selected measured design; reserve broad cleanup for Phase 3. |
| Optimization silently changes the statistical procedure | High | Predefine equivalence criteria; treat semantic changes as experiments requiring separate approval. |
| Final cleanup regresses performance | Medium | Re-run the exact Phase-2 protocol with a predefined allowable regression threshold. |
| Schema or target migration breaks stored artifacts | High | Preserve public contracts; require explicit approval and compatibility tests for any migration. |
| Broad refactor leaves the pipeline unrunnable | Medium | Use ordered slices with focused tests/manifests and a runnable gate after every slice. |
| Long-lived branches drift from `main` | Medium | Work strictly sequentially and branch from updated `main` after each predecessor merges. |

---

## Open questions to resolve inside Phase 2

- Which exact continental paleo, modern, and temporal subsets are representative yet
  affordable enough for repeated benchmarking?
- What numerical threshold defines a material improvement?
- What metric-specific tolerances define scientific equivalence?
- What runtime/storage regression threshold will guard the final refactor?

These values must be recorded before optimization begins, not chosen after results
are observed.

---

## GitHub issues scaffold

### Umbrella issue

**Title:** Stabilize, optimize, and simplify cross-validation architecture

**Labels:** existing `💻code`, `🧮Modelling`, and `🔀pipeline`

**Body:**

```markdown
## Background

Issue #135 and PR #137 introduced a scientifically stronger project-owned cross-validation system, but the implementation grew while its requirements and architecture were changing. #139 currently mixes correctness audit and broad cleanup, while #138 owns runtime optimization. Those activities need an explicit order so that profiling uses trustworthy contracts and final abstractions reflect the optimized execution design.

## Goal

Deliver a correctness-audited, measurably faster, and maintainable cross-validation system without weakening fold-local preprocessing, grouped assignments, held-out MEM interpolation, tier weighting, predictive evaluation, deterministic seeds, isolated-store boundaries, or provenance.

## Approach

Work is strictly sequential:

1. #139 audits PR #137, fixes correctness/contract defects, and establishes reference outputs.
2. #138 profiles the stabilized implementation and selects a measured execution design.
3. The final child simplifies the optimized architecture and guards against scientific and performance regressions.

Each child owns its validation and mandatory review closure. Each successor starts from updated `main` after its predecessor is merged.

## Acceptance criteria

- [ ] All three sub-issues close in order.
- [ ] No child defers its required validation to a separate validation-only phase.
- [ ] Scientific invariants and public artifact/provenance contracts are preserved or explicitly migrated with approval and compatibility tests.
- [ ] Runtime and storage changes are supported by a reproducible benchmark protocol.
- [ ] The final architecture passes correctness-reference comparisons and the post-refactor performance guard.
- [ ] #135 and PR #137 documentation describe the final reviewed and optimized architecture.

## Sub-issues

- [ ] #139 Audit and stabilize cross-validation contracts
- [ ] #138 Profile and reduce cross-validation runtime for large continental models
- [ ] #TBD Simplify the optimized cross-validation architecture
```

### Revised existing issue #139

**New title:** Audit and stabilize cross-validation contracts

**Change:** retain the complete PR-#137 review boundary and known hotspots, but move
all broad maintainability refactoring to the new final child. Add the Phase-1 tasks,
validation gate, handoff artifacts, dependency, and umbrella links described above.

### Revised existing issue #138

**Title:** unchanged

**Change:** retain its profiling/options/constraints content. Add that it is blocked
by revised #139; add the predefined benchmark protocol, scientific-boundary rules,
handoff artifacts, exact validation expectations, and umbrella links described above.

### New final child issue

**Title:** Simplify the optimized cross-validation architecture

**Labels:** existing `💻code`, `🧮Modelling`, and `🔀pipeline`

**Body:**

```markdown
## Context

PR #137 introduced the current cross-validation architecture. #139 inventories and stabilizes its contracts, and #138 selects a measured production execution design. Broad cleanup must follow those issues so it simplifies the architecture that actually survives profiling.

## Goal

Remove demonstrated duplication, clarify responsibility boundaries, and simplify orchestration without changing the optimized execution behavior, scientific estimand, public target names, artifact schemas, or isolated-store boundaries.

## Dependencies

- Blocked by #138.
- Consume #139's architecture map, contract inventory, findings register, and correctness reference outputs.
- Consume #138's benchmark protocol/results, selected execution design, public-contract snapshot, and allowable performance-regression threshold.
- Start from updated `main` only after #138 is merged.

## Ordered implementation slices

- [ ] Consolidate demonstrated contract/schema/status/provenance duplication. Preserve schemas unless an explicitly approved migration includes compatibility tests.
- [ ] Consolidate direct/shared target-building boundaries and separate fold preparation, fitting, prediction, scoring, and target declarations.
- [ ] Simplify runner sequencing and target-store reads without hiding or combining isolated store boundaries.
- [ ] Remove dead/stale compatibility paths and clarify generated-artifact regeneration.

Keep affected pipelines runnable after every slice. Add helpers only when they remove demonstrated duplication or clarify ownership.

## Constraints

- Preserve whole-core/whole-plot grouping, fold-local preprocessing, held-out MEM interpolation, candidate selection, tier weighting, predictive metrics, deterministic seeds, and provenance.
- Do not change candidate/repeat/fold counts, scheduling, parallelism, fitting behavior, or performance policy.
- Preserve public target names and artifact schemas unless a migration is explicitly approved and compatibility-tested.
- Do not combine isolated unit and tier stores into one nested targets graph.

## Validation

- Run focused tests and affected manifests after every slice; run the full suite for shared infrastructure changes.
- Automatically compare public target names, artifact schemas, status/provenance fields, and #139 correctness reference outputs before/after each slice.
- Run fresh CZ paleo and modern workflows and verify expected artifacts.
- Re-run #138's exact benchmark protocol and remain within its predefined allowable performance-regression threshold.
- Parse/render affected Quarto/generated documentation.
- Complete the mandatory change-review workflow before closure.

## Acceptance criteria

- [ ] Ordered slices merge with a runnable pipeline gate after each slice.
- [ ] Demonstrated duplication and ownership problems from #139 are removed or explicitly justified.
- [ ] Scientific behavior and public contracts match the approved references.
- [ ] Performance remains within #138's guard threshold or improves measurably.
- [ ] No unresolved high/medium finding remains, except an explicitly accepted follow-up issue.
- [ ] #135 and PR #137 documentation describe the final architecture.

## Links

- Part of: Stabilize, optimize, and simplify cross-validation architecture
- Predecessors: #139, then #138
```

---

## Issue metadata

- Repository: `OndrejMottl/BIODYNAMICS-vegetation-cooccurrence`
- Preserve the current labels and assignee on #138 and #139.
- Apply the existing `💻code`, `🧮Modelling`, and `🔀pipeline` labels to new issues.
- Leave new issues unassigned and without a milestone.
- Link #139, #138, and the new simplification issue as GitHub sub-issues of the
  umbrella issue in that order.

---

## Completion checklist

- [ ] Umbrella and final simplification issues are created.
- [ ] #139 and #138 are revised without losing their retained scope or metadata.
- [ ] All three children are linked to the umbrella in strict execution order.
- [ ] Dependency and handoff links are visible in every child.
- [ ] This plan remains the detailed planning record; issue bodies are self-contained.
