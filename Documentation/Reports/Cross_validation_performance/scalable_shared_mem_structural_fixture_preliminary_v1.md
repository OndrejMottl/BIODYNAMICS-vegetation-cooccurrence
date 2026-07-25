# Scalable shared MEM structural fixture (preliminary v1)

**Date:** 2026-07-24
**Issue:** #143
**Status:** Structural evidence only; production remains on exact mode

## Purpose

This fixture checks the first scientific and computational properties of the
proposed common Nyström MEM engine before any production switch. It is not a
project-, continent-, or pipeline-specific optimization. Both methods received
the same 2,025 projected locations, requested the same 20 public MEM columns,
and used the shared seed `900723`.

The reference path used `sjSDM::generateSpatialEV()`. The candidate path used
the package-backed `spmoran::meigen_f()` Nyström implementation with 200
eigenpairs and retained its explicit basis state for prediction through
`spmoran::meigen0()`.

## Fixture result

| Measure | Exact | Nyström |
|---|---:|---:|
| Input locations | 2,025 | 2,025 |
| Public MEM columns | 20 | 20 |
| Construction elapsed time | 5.34 s | 0.06 s |
| Retained basis object size | 473,184 bytes | 4,239,400 bytes |
| One dense double matrix estimate | 32,805,000 bytes | avoided |

The low-rank path was 89 times faster for basis construction in this
preliminary run. The stored candidate basis was larger because it retains the
state needed for scientifically matching out-of-sample projection; it remained
small at 4.24 MB.

## Rotation-invariant structural comparison

Raw MEM columns were not compared directly because eigenvector signs and
rotations inside tied or near-tied eigenspaces are not identifiable. The
comparison used canonical correlations between the 20-dimensional column
spaces:

| Diagnostic | Value |
|---|---:|
| Mean squared canonical correlation | 0.92283257 |
| Minimum canonical correlation | 0.71620959 |
| Maximum principal angle | 44.257583 degrees |

This is encouraging but is not an acceptance decision. The two methods use
different connectivity constructions, and the weakest retained direction is
not close enough to infer predictive equivalence from structural evidence
alone.

## Additional checks completed

- Two repeated Nyström constructions were byte-identical.
- The real package path reported `spmoran_nystrom`; silent fallback to the
  package exact method is now rejected.
- Chunked `meigen0()` projection returned finite results in original prediction
  row order.
- Fast construction fails before fitting when unique coordinates cannot
  support the configured 200-vector basis.
- Five affected pipeline manifests resolved with the existing
  `data_spatial_mev_core` target plus additive basis and provenance targets.
- The paleo-temporal manifest still reports the independent factory error
  `no such index at level 1`; this occurred outside the shared MEM target
  segment and requires separate baseline comparison.

## Decision

Keep `model_fitting$spatial_mev$strategy: exact`. The next gate is a paired
downstream fixture using identical folds, responses, and seeds, followed by the
fresh CZ workflow. Production `auto` mode must remain disabled until the
existing log-loss, AUC, Tjur R2, coverage, schema, and leakage gates pass.

## Method reference

The candidate API and projection contract follow the
[`spmoran` 0.3.3 reference manual](https://cran.r-project.org/web/packages/spmoran/spmoran.pdf).
