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
