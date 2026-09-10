# Structured expected-infeasibility handling

## Objective

Treat scientifically expected data limitations as explicit, auditable outcomes while preserving fail-fast behaviour for programming, environment, schema, and data-integrity failures.

## Implementation

- Keep analytical validators unchanged so this orchestration improvement does not invalidate cached preprocessing. `{targets}` persists target names and messages rather than R condition subclasses, so classify the existing stable validator contracts at the runner boundary.
- Extend `classify_sjsdm_unit_pipeline_error()` with an explicit target-and-message taxonomy and stable `reason_code` output. Cover insufficient cores, samples, taxa, filter survivors, functional-type groups, and zero spatial records without relying on broad text such as `"Too few"` alone.
- Allow dependency errors and empty-pattern errors only as cascades of a recognized feasibility root. Never classify an unknown root error as expected.
- Extend preparation status rows with `reason_code` and preserve the exact root error. Repeated expected errors from resumable stores reuse the stored classification only when the current top-level failure matches the recognized root or its empty-pattern cascade. Other target, cache, dependency, and per-unit runner failures remain unexpected but are deferred until every spatial ID has been attempted.
- Keep core-count validation before interpolation so infeasible spatial units do not allocate shared memory or create dynamic interpolation branches.

## Validation

- Test every reason category, multiple expected roots, dependency cascades, and mixed expected/unexpected failures.
- Test both spatial and temporal preparation continuation, all-unit attempts, and fail-fast behaviour for failures without target metadata.
- Run focused tests, syntax and 80-column checks, the full test suite, and the CZ smoke pipelines before final acceptance.

## Compatibility

Messages, analytical validators, and existing target/store names remain unchanged. The new `reason_code` and count fields are additive. Runner-side classification changes do not invalidate cached analytical targets.
