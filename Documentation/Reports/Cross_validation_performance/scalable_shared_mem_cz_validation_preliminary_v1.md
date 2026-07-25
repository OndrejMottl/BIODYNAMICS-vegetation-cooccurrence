# Scalable shared MEM CZ validation (preliminary v1)

**Date:** 2026-07-24
**Issue:** #143
**Strategy:** Exact compatibility mode
**Status:** Passed after one recoverable process-level interruption

## Scope

This validation ran the repository-wide test suite and all three workflows from
`R/02_Main_analyses/Run_CZ_test.R`. The shared strategy remained `exact`, as
required before downstream Nyström equivalence is accepted.

## Test suite

The complete test suite was rerun after adding the native paired benchmark and
shared `auto` profile contracts. It finished in 98.8 seconds:

- 3,915 passing assertions;
- zero failures;
- zero warnings;
- one expected VegVault integration skip.

The focused Issue 143 set contributes coverage for exact compatibility,
strategy validation, deterministic Nyström state, bounded projection chunks,
fold-local leakage protection, additive provenance, optional prediction-basis
loading, public schemas, and rotation-invariant subspace comparison.

## Paleo core

The fresh paleo core workflow completed:

- 218 targets completed;
- 42 targets skipped only where allowed by pipeline state;
- zero target errors;
- terminal pipeline summary present.

This paleo profile uses spatiotemporal predictors, so the new 2-D basis and
provenance targets correctly returned `NULL` without changing existing public
targets.

## Paleo resolution and resume evidence

The initial fresh runner was killed inside the first family tuning work item:

```text
callr subprocess failed: could not start R, exited with non-zero status,
has crashed or was killed
```

There was no `targets` error row. All shared MEM and fold-preparation targets
were complete, while
`list_sjsdm_tuning_work_item_result_family_347fb6e69921efbd` remained
dispatched.

The same store was resumed with `fresh_run = FALSE`. The interrupted work item
completed in 8.5 seconds, the remaining family, genus, and functional-type work
items continued, and the workflow ended successfully:

- 118 targets completed during resume;
- 279 completed targets reused or skipped;
- zero target errors;
- terminal pipeline summary present.

This interruption occurred during GPU fitting on the spatiotemporal path, not
during 2-D MEM construction. It is therefore retained as process-recovery
evidence rather than attributed to the scalable MEM implementation.

## Modern spatial workflow

The modern CZ spatial workflow then ran fresh and completed:

- 2,196 targets completed;
- zero skipped targets;
- zero target errors;
- terminal pipeline summary present;
- elapsed pipeline time 14 minutes 51.7 seconds.

The shared 2-D basis contained 1,893 rows, below the common 1,999-location exact
safety boundary. Its provenance recorded:

- requested and selected strategy: `exact`;
- strategy version: `spatial_mev_exact_v1`;
- engine: `sjsdm_exact`;
- projection: `idw`;
- explicit input, unique-location, retained-vector, timing, basis-size, and
  dense-matrix estimates.

The existing `data_spatial_mev_core` schema remained available. The additive
`list_spatial_mev_core_basis` and `data_spatial_mev_provenance` targets were
consumed without errors by fold preparation, tuning, cached OOF evaluation,
final fitting, and ANOVA.

## Decision

Exact compatibility, contracts, the full suite, and fresh CZ validation pass.
Production remains on `strategy: exact`. The unresolved gate is paired
downstream exact-versus-Nyström predictive equivalence on identical folds,
responses, and seeds. Only after that gate passes should the shared default
move to `auto` and the representative modern continental Issue 138 run resume.
