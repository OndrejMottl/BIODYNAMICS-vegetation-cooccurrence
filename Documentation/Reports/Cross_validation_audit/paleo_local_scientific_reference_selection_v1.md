# Paleo local scientific-reference selection v1

**Date:** 2026-07-16
**Audit:** CV predictive-performance audit, Phase 5
**Selected unit:** `eu_r005_l010`
**Role:** scientific predictive-performance reference
**Execution device:** GPU

## Decision

Use the European paleo genus unit `eu_r005_l010` for the next real predictive
performance benchmark. Retain Czechia (`eu_r005_l014`) as the engineering
stress test for sparse folds and small-sample behavior.

The new benchmark uses fresh deterministic three-repeat, five-fold spatial
assignments. Regularization is fixed prospectively at the existing accepted
reference values `(lambda_cov, lambda_coef, lambda_spatial) = (0.1, 0.1, 0.1)`.
It is not tuned on the benchmark folds.

## Pre-fit rule

A scientific-reference candidate had to:

- represent the same European paleo genus modelling problem as Czechia;
- contain at least 40 aligned locations and 15 response taxa;
- support the production spatially stratified 3 x 5 fold contract;
- make at least 80% of taxon-fold combinations evaluable after converting the
  binomial response to presence/absence; and
- be the smaller qualifying unit when predictive coverage was adequate.

Evaluability requires both the training and held-out partition to contain
presences and absences for a taxon. Grid calibration, fold assignment, and fold
adaptation used the production CV helpers and seed `900723`.

## Candidate comparison

| Unit | Samples | Locations | Taxa | Selected grid (km) | Evaluable taxon-folds | Taxa evaluable in >=80% folds | Taxa evaluable in every fold |
|---|---:|---:|---:|---:|---:|---:|---:|
| `eu_r005_l014` (CZ) | 205 | 27 | 16 | 266 | 66.2% | 9 | 3 |
| `eu_r005_l010` | 878 | 41 | 20 | 236 | 85.0% | 16 | 12 |
| `eu_r005_l006` | 1,840 | 102 | 28 | 175 | 94.8% | 26 | 20 |

`eu_r005_l010` clears the declared 80% threshold and offers more than four
times the samples of CZ while requiring less than half the samples of
`eu_r005_l006`. The larger candidate provides still better class coverage, but
its additional fitting cost is not needed for the first scientific reference.

## Interpretation boundary

This selection does not establish that predictive performance is acceptable.
It establishes that the response and fold structure are sufficiently stable to
make the next real GPU result scientifically informative. Tjur R2, AUC, loss,
calibration, uncertainty, and eligible-taxon results must be recorded after the
fresh run before the model receives a scientific-performance classification.

## Implementation

The isolated pipeline reads validated upstream inputs from
`Data/targets/paleo_spatial_local/eu_r005_l010/pipeline_paleo_spatial_resolution`
without modifying that store. Outputs are written under
`Data/targets/paleo_local_cv_scientific_reference_gpu`. The pipeline records
fresh fold assignments, fold predictions, fold-local metrics, repeat
distributions, and taxon eligibility.
