# Plan: Memory-safe parallel paleo interpolation with row ranges

**Date:** 2026-09-01 **Status:** Approved for implementation by the user during the clean spatial rerun

## Goal

Remove the worker-local full-table scans that exhausted Windows committed memory during continental paleo preprocessing while retaining the existing `{mirai}`/`{mori}` shared-input architecture and numerically identical interpolation results.

## Failure evidence

The production America input contains 619,150 community rows and 19,796,000 age-uncertainty rows across 404 datasets. Both inputs are already contiguous by `dataset_name`. The current worker evaluates `dataset_name == selected_dataset` against the complete shared tables. The age-uncertainty comparison alone allocates a 75.5 MB logical vector in every concurrent worker. Sixteen workers produced five branch failures, including four `cannot allocate vector of size 75.5 Mb` errors, before the pipeline fell back to sequential execution.

`{mori}` is working as intended for the source objects: the shared targets persist only small descriptors. The remaining defect is worker-local filtering and interpolation expansion, not serialization of the complete source tables.

## Design

1. Extend `build_community_interpolation_index()` to receive both community and age-uncertainty inputs and return constant-size start/end row ranges for every community dataset.
2. Require each dataset to occupy exactly one contiguous run in both inputs. Abort clearly if that invariant is violated rather than silently selecting incorrect rows.
3. Extend `interpolate_community_dataset_from_shared_inputs()` to validate and slice those ranges directly. It must not compare `dataset_name` across a complete shared table.
4. Preserve the target name `list_community_interpolation_index`, branch count, branch ordering, output schema, interpolation algorithm, seeds, and downstream interfaces. The branch metadata schema changes additively inside the isolated target store and will invalidate the affected interpolation targets.
5. Keep `max_expanded_rows = 4e6` unchanged initially so the first benchmark isolates the effect of range selection. Reduce it only if range indexing still leaves unacceptable peak memory.

## TDD and validation phases

### Phase 1: Lock the range-index contract

- Update roxygen2 specifications before implementation.
- Update focused tests to require community and uncertainty start/end indices, deterministic dataset ordering, empty uncertainty ranges, empty-community sentinels, and clear rejection of discontiguous inputs.
- Update interpolation tests to require exact equality with direct filtering while supplying row ranges.
- Confirm the new expectations fail against the pre-change implementation.

### Phase 2: Implement range construction and slicing

- Implement constant-size range metadata in the existing capability-owned functions without introducing a new public helper.
- Update the paleo pipe segment to pass `data_age_uncertainty` into the index target.
- Keep R source lines within 80 characters and retain one top-level function per file.
- Run focused tests and inspect the affected target manifest.

### Phase 3: Repository validation

- Run the interpolation test directory.
- Run the full test suite.
- Run the fresh CZ smoke pipelines.
- Regenerate the R architecture inventories and persisted-contract manifest, run the blocking architecture checker, and review generated diffs.
- Confirm no unrelated source or configuration changes were introduced.

### Phase 4: America worker ladder

- Reset only America shared/interpolation targets before each attempt; retain Europe and unrelated target stores.
- Run the current America interpolation target at 16 workers.
- If any branch errors or Windows committed memory becomes unsafe, terminate that attempt cleanly and retry from reset shared/interpolation targets at 12, then 10, 8, 6, and 4 workers.
- Preserve one log per attempt plus start/end timestamps, completed/error branch counts, peak committed memory, and final worker decision.
- Accept the highest worker count that completes all 404 branches with zero errors and adequate commit headroom.
- Compare the accepted output against a sequential reference on deterministic focused fixtures; target-level output contracts and branch count must match.

### Phase 5: Resume the spatial rerun

- Preprocess Asia once at the accepted worker count.
- Resume continental tuning with interpolation prebuilding disabled so Europe, America, and Asia preprocessing cannot be invalidated again.
- Continue the remaining paleo, modern, synthesis, and visualisation stages through the fail-fast controller.

## Acceptance criteria

- Workers no longer allocate full-table dataset-selection masks.
- Focused, full-suite, CZ smoke, manifest, and architecture checks pass.
- America completes all 404 interpolation branches with zero errors at the highest safe worker count in the prescribed ladder.
- No tuning, trait, CV, model, or unrelated target store is reset by the benchmark ladder.
- Europe preprocessing and completed round-1 tuning remain cached.
- Logs and provenance clearly distinguish failed worker-count attempts from the accepted clean preprocessing result.

## Risks and mitigations

- **Non-contiguous future inputs:** fail closed with the affected dataset names; sort once upstream only in a separately reviewed change.
- **Large fossil-core expansions remain worker-local:** retain bounded `max_expanded_rows`; reduce it if range indexing alone is insufficient.
- **Changing branch metadata invalidates preprocessing:** expected and limited to the current paleo interpolation targets.
- **Sixteen workers remain unsafe:** use the measured ladder rather than a guessed global worker count.
- **Benchmark attempts contaminate tuning:** run only through `data_community_interpolated`; tuning remains disabled until a worker count is accepted.
