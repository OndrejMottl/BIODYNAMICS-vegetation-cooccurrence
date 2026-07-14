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
