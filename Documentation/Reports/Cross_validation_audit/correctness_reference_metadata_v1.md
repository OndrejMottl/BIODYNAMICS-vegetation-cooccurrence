# Cross-validation correctness reference metadata (v1)

**Recorded:** 2026-07-14
**Issue:** #139
**Reference base:** `a8ead627`

## Environment

- Platform: Windows, Europe/Prague execution context.
- R used for validation: 4.5.1 as resolved by the project launcher.
- Project dependency status: `renv` reported the project out of sync, while the library was synchronized with the lockfile. This warning is retained as environment metadata and was not changed by this slice.
- Existing long-running interactive R workers were left untouched.

## Regression reference

| Check | Reference result |
|---|---|
| Focused tier-source tests | 11 assertions passed across `test-collect_sjsdm_tuning_summaries.R` and `test-tier_tuning_pipeline_contract.R`. |
| Full test suite | `FAIL 0 | WARN 0 | SKIP 1 | PASS 3131`; the skip is the documented opt-in VegVault integration test. |
| External-store invalidation reproduction before correction | A stable external path changed from `first` to `second`, while the thoroughly-cued downstream target remained cached as `first`; `stale_cache_reproduced = TRUE`. |
| PR whitespace check | `git diff --check` reported no whitespace errors. |

## Repeated-origin stabilization

The next Issue #139 slice replaced the non-coprime y-origin multiplier with a deterministic reverse-order permutation.
Before correction, the four-repeat fixture produced only two distinct grid signatures.
After correction, the test matched the exact signatures for origin fractions `0`, `0.75`, `0.5`, and `0.25`; the focused test passed 10 assertions, and the full suite reported `FAIL 0 | WARN 0 | SKIP 1 | PASS 3132`.

## Direct regularization validation

The following Issue #139 slice added direct/final-fit upper-bound checks for `alpha_cov`, `alpha_coef`, and `alpha_spatial` while retaining finite non-negative lambda validation.
Before correction, all three invalid alpha calls reached the Python backend and failed with an unrelated `ZeroDivisionError`.
After correction, the focused fit test passed 52 assertions with parameter-specific R errors and explicit coverage of the inclusive zero/one alpha boundaries. The full suite reported `FAIL 0 | WARN 0 | SKIP 1 | PASS 3144`.

## Deterministic stochastic tuning scores

The CV-003 slice added separately hashed deterministic fit and score seeds for every repeat, fold, and candidate ID and retained both in fold-level tuning output. Joint likelihood scoring now restores the caller's R RNG and available PyTorch CPU/CUDA RNG states after applying the score seed.
Before correction, the new scorer test rejected the unknown `score_seed` argument and the runner lacked the provenance column and propagation path. After correction and review hardening, the focused scorer, fold-runner, and tuning-runner tests passed 20, 3, and 24 assertions. Coverage includes candidate-order independence, upper seed bounds, R restoration after normal and error paths, and PyTorch CPU determinism/restoration. The full suite reported `FAIL 0 | WARN 0 | SKIP 1 | PASS 3158`.

## Structured downstream tuning errors

The CV-013 slice injects prediction and scoring backend failures and asserts the exact fold-level schema, structured status/message, missing metric fields, retained fit/score seeds, and prediction-error short circuit. The red phase exposed that the direct fold helper returned the complete schema in a different column order from the public tuning runner; the helper now normalizes every success/error path to the public order. The focused fold and public-runner tests passed 16 and 24 assertions, and the full suite reported `FAIL 0 | WARN 0 | SKIP 1 | PASS 3171`.

## Fold-varying effective MEV provenance

The CV-011 slice accepts effective MEV counts that vary after fold-local rank clamping. Per-fold counts remain in the fold diagnostics; model provenance now records `n_effective_mev_min`, `n_effective_mev_max`, and an explicit status while retaining the legacy scalar only for constant-rank runs. Before correction, the varying-rank fixture aborted with `Selected folds must use one effective MEV count.` After correction and validation hardening, constant, varying, unavailable, and malformed-count cases passed 31 focused assertions, and the full suite reported `FAIL 0 | WARN 0 | SKIP 1 | PASS 3189`.

## Spatial runner failure policy

The CV-009 slice applies one explicit two-stage policy to all six spatial runners. Unit tuning-summary production remains fail-fast because tier selection requires complete evidence. Post-selection full-unit execution continues after individual failures and returns one row per requested unit with `ok`/`error` status and the captured error message. In the red phase, the helper stub produced four expected failures. After implementation and review hardening of forwarded-argument guards, the helper and six-runner source contract passed 23 focused assertions, all six runner files parsed successfully, and the full suite reported `FAIL 0 | WARN 0 | SKIP 1 | PASS 3212`.

## Cross-tier sensitivity readiness

The CV-010 slice preflights the configured continental, regional, and local representative store directories before a local runner starts the all-tier common-regularization sensitivity pipeline. A missing store now produces per-tier `ready`/`missing` evidence and an overall `skipped_missing_store` status instead of aborting after the local workflow has completed. Disabled profiles remain visible as `disabled`/`skipped_disabled` rows, including a valid all-disabled no-op. The isolated reproduction confirmed that `fs::dir_ls()` raises `ENOENT` for an absent tier root. The red phase produced four expected failures; after correction and review hardening, the helper and local-runner contract passed 16 focused assertions, both local runners parsed successfully, and the full suite reported `FAIL 0 | WARN 0 | SKIP 1 | PASS 3228`.

## Pooled tuning-loss estimand

The CV-012 slice defines `negative_log_likelihood_per_response` within each repeat and candidate as summed held-out negative log likelihood divided by summed held-out response values. This scientific disposition was explicitly approved after considering #138's possible fold/repeat simplification and #141's requirement to preserve the stabilized estimand. Before correction, unequal folds with 10 and 30 response values produced the equal-fold result `0.25`; after correction they produce the pooled result `0.275`. Repartitioning the same loss and response evidence from two folds into four retains `0.275`. The focused summary tests passed 17 assertions, and the full suite reported `FAIL 0 | WARN 0 | SKIP 1 | PASS 3231`.

## Project-owned decomposition CV documentation

The CV-017 slice replaces the stale `sjSDM::sjSDM_cv()` claim in `make_repeated_cv_indices()` with its actual project-owned consumer, `run_decomposition_route_cv()`, and adds an executable example. The red source-contract test produced two expected failures; after correction it passed five focused assertions, and the full suite reported `FAIL 0 | WARN 0 | SKIP 1 | PASS 3233`. Targeted HTML, TXT, PDF, and QMD documentation plus the published function page and search entry were regenerated. Extracted PDF text contains the project-owned consumer and no stale package-native reference; all three PDF pages were rendered and visually inspected without clipping, overlap, or illegible content.

## Generated CV documentation synchronization

The CV-005--CV-007 slice removes the generated artifacts and published pages for `run_predictive_ablation_cv()` and `apply_decomposition_scale_attributes()`, publishes the replacement `apply_scale_attributes()`, and rebuilds the full Quarto site so every embedded sidebar, search entry, listing, and sitemap reflects the current API. The red generated-documentation contract produced two expected failures and one pass; after regeneration it passed all three focused assertions. Inventory searches across raw function docs, function QMD, published function pages, search, listings, and sitemap returned zero matches for both deleted APIs. The full suite reported `FAIL 0 | WARN 0 | SKIP 1 | PASS 3236`.

The interpolation PDF build initially stopped before producing output because the two roxygen argument descriptions used a Unicode ellipsis. Replacing that glyph with the ASCII `...` retained the contract while allowing the PDF toolchain to complete. `interpolate_mev_to_grid.pdf` and `interpolate_st_mev_to_grid.pdf` each contain three pages; extracted text in both records optional scale attributes and the unscaled fallback. Every page was rendered at 2x resolution and visually inspected without clipping, overlap, broken glyphs, or illegible content.

## Function coverage evidence

The CV-014 closure slice regenerated `covr_report.html`, `covr_report.json`, and `covr_report_summary.json` from the stabilized function and test inventories. Both `run_predictive_ablation_cv` and `apply_decomposition_scale_attributes` have zero matches in the HTML and JSON reports. The replacement `apply_scale_attributes` and current tuning APIs, including `make_sjsdm_regularization_candidates` and `run_sjsdm_tuning_candidates`, are represented in both formats. The JSON report contains 4,261 coverage records, parses successfully, and reports 92.05% line coverage, up from the stale report's 89.59%. The full suite remained `FAIL 0 | WARN 0 | SKIP 1 | PASS 3236`.

## Manifest reference

The following manifests parsed successfully after the initial tier-source correction and contained no duplicate target names.

| Configuration | Pipeline | Target count |
|---|---|---:|
| `project_paleo_spatial_continental` | `pipeline_paleo_spatial_resolution.R` | 201 |
| `project_modern_spatial_continental` | `pipeline_modern_spatial_resolution.R` | 202 |
| `project_paleo_temporal_europe` | `pipeline_paleo_temporal.R` | 1676 |
| `project_paleo_spatial_continental` | `pipeline_sjsdm_tier_tuning.R` | 8 |
| `project_paleo_spatial_local` | `pipeline_sjsdm_common_regularization_sensitivity.R` | 12 |

## Pending scientific references

Fresh `project_cz_paleo` and `project_cz_modern` stores, artifact hashes/schemas, selected candidates, OOF metrics, provenance values, and contract-specific tolerances are not yet recorded in this version.
The mandatory CZ runner uses `fresh_run = TRUE`; it was intentionally not started while an existing interactive R session had active workers.
These references remain a closure requirement for Issue #139 and must be added without overwriting this metadata record.
