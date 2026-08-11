# Tier-wide staged-round contracts: preliminary validation v1

Date: 2026-07-20  
Branch: `issue138-cv-runtime`  
Base: `a6b8f863`

## Scope

This checkpoint adds the shared contracts required before staged tuning can be wired into the production target graph. It does not enable staged tuning and does not introduce project-, continent-, or unit-specific pruning.

The new contracts:

- select one repeat's deterministic work items from the shared schedule;
- require the preceding tier-wide decision before a later round can execute;
- reject partial decisions, candidate drift, duplicate decisions, and local candidate pruning;
- pool unit evidence with the existing equal-ID tier aggregation before selecting survivors;
- persist model context, strategy version, repeat, round, entering count, surviving count, rank, loss, and pruning decision;
- read survivor decisions from the isolated tier store with fail-closed behavior; and
- allow the tier collector to address explicit round-summary target prefixes while preserving the existing public target prefix as its default.

## TDD evidence

Each new function was introduced as a documented stub. Its focused tests were run and observed to fail before implementation, then pass after implementation. Coverage includes deterministic round selection, work-item identity preservation, missing tier evidence, candidate-table drift, partial/local pruning, tier pooling, incomplete source evidence, context matching, and missing tier targets.

The complete test suite passed:

- failures: 0
- warnings: 0
- expected skips: 1
- passed assertions: 3,689
- duration: 88.8 seconds reported by `{testthat}`

## Fresh CZ regression

`Rscript R/03_Supplementary_analyses/Testing/Smoke/run_cz_pipelines.R` completed with exit code 0 in 1,896.9 seconds (31 minutes 36.9 seconds). The active CZ configurations remain explicitly exhaustive, so this is a compatibility regression run and not a staged-search runtime result.

Post-run target metadata contained no errors:

| Store | Metadata rows | Errors |
|---|---:|---:|
| CZ paleo core | 546 | 0 |
| CZ paleo resolution test | 682 | 0 |
| CZ modern spatial resolution test | 2,480 | 0 |
| Total | 3,708 | 0 |

The regenerated files under `Documentation/Progress/` are validation output, not part of this source checkpoint.

## Subsequent implementation

The unit target graph now exposes cumulative round execution: round one runs without a tier artifact, while later rounds append only candidates authorized by the preceding tier decision. Existing dynamic work-item identities are preserved as the authorized set expands. The tier graph and shared spatial and temporal runners now enforce unit round, tier aggregation, survivor publication, and unit resume boundaries.

Staged tuning must remain disabled until paired exhaustive-versus-staged CZ fixtures and the specified scientific and runtime decision gates pass.
