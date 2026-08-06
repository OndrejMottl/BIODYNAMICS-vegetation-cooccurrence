# Issue 154 final validation

## Scope

This report closes the implementation of Issue #154 from baseline commit
`b9acfeae7b1c0955cc702a5943ed86cccdcc9fd6`. The validation covers the
non-CV modelling hierarchy, approved interface renames, runtime diagnostics,
spatial effects, evaluation, variance partitioning, decomposition, HMSC
retirement, and the final internal-function and dollar-access audits.

Cross-validation remains owned by #141. Persisted-name and store migration
remain owned by #156 and #155, respectively.

## Architecture contracts

- The regenerated inventories contain 453 scripts, 329 functions, and 114
  literal persisted-target contracts.
- The generator preserved every pre-existing ownership and migration decision:
  323 function rows, 442 script rows, and 114 contract rows were compared with
  their pre-generation snapshots with zero missing rows and zero changed
  decision fields.
- Two formerly blank retired-row keys initially exposed `NA` serialization.
  The generator now writes missing CSV fields as blanks.
- A second generator run produced identical SHA-256 hashes for all three
  inventories.
- The blocking architecture checker completed with zero blocking findings.
  Its 93 remaining findings are report-only: 76 function-naming findings, two
  missing-function findings, two missing-script findings, and 13 nested-helper
  findings owned by other issues.

## Internal-function and access audit

The final review promoted six substantial helpers to normal reusable
functions:

- `fit_decomposition_variant()`;
- `compute_predictive_fold_shares()`;
- `summarise_predictive_model_metrics()`;
- `compute_fast_spatial_mev_basis()`;
- `allocate_shapley_variance_components()`; and
- `diagnose_torch_cuda_details()`.

Fifteen small, simple, or repetitive helpers remain under `Internal/`. Their
exact allowlist is blocking in the architecture checker. The detailed
rationale is recorded in
`issue154_internal_and_dollar_audit_v1.md`.

The repeated dollar scan covered 325 active function files and found 247 raw
matches in 38 files. The sole #154 match is the regular-expression anchor
`"\\d+$"`; no prohibited dollar access remains in active non-CV modelling
functions. All out-of-scope matches are assigned to #141, #150, #153, or
#155.

## Manifest and persisted-name comparison

Baseline and current manifests were generated in separate worktrees under
`R_CONFIG_ACTIVE=project_cz_paleo`. Exact ordered target-name vectors are
identical in every pipeline.

| Pipeline | Targets | Changed commands | Unmatched after approved rename normalization |
|---|---:|---:|---:|
| `pipeline_paleo_core.R` | 127 | 3 | 0 |
| `pipeline_paleo_resolution_test.R` | 258 | 9 | 0 |
| `pipeline_paleo_spatial_resolution.R` | 232 | 9 | 0 |
| `pipeline_paleo_temporal.R` | 663 | 35 | 0 |
| `pipeline_modern_spatial_resolution.R` | 233 | 9 | 0 |
| `pipeline_modern_spatial_resolution_test.R` | 246 | 9 | 0 |
| `pipeline_paleo_local_cv_decomposition_reference.R` | 28 | 1 | 0 |

Raw command digests changed because target expressions call the approved new
function names. After replacing only the approved old/new interface names,
every parsed target expression is structurally identical to its baseline
expression. Protected modelling targets and all 28 decomposition-reference
target names remain unchanged.

## Behaviour and integration validation

- Six promoted-function test files passed with 24 focused expectations in
  total. These cover errors, empty inputs, typed schemas, fixed-seed spatial
  behaviour, Shapley allocation, predictive aggregation, and Torch/CUDA
  diagnostics.
- All 21 changed or added R files parse successfully.
- `R/___setup_project___.R` sources successfully in a fresh session.
- The complete test runner passed with exit code 0 in 140.7 seconds.
- Regenerated coverage is 94.98 percent.
- The supported three-pipeline Czechia smoke workflow passed with exit code 0
  in 2,235.5 seconds. Chrome did not open for static progress PNG generation,
  but the HTML progress artifacts were written and all three scientific
  pipelines completed successfully.
- Existing specification tests retain the schema, status, provenance,
  formula, scaling, variance-fraction, decomposition-share, convergence, and
  fixed-seed assertions recorded in the baseline plan.

## Documentation validation

- The master documentation workflow rebuilt function documentation, coverage,
  the website, and manuscript artifacts.
- A final focused website render completed with exit code 0 after retired
  pages were removed.
- All 58 affected exported functions have HTML, text, source-QMD, and
  published-HTML artifacts: 232 required artifacts with none missing.
- The `document` package returned a null PDF path for ten exported functions;
  this is its existing optional-output behaviour. The six newly promoted
  functions all have generated PDF artifacts.
- Forty-two stale old-name documentation artifacts were retired.
- Website search, listings, sitemap, and code-reference overview contain zero
  retired-name matches.
- The website renderer emits existing fenced-div warnings for sjSDM triple
  colon references. It also depends on function documentation being generated
  first because several tracked historical QMD files have malformed YAML; the
  repository master renderer already enforces that order. Those unrelated
  source files were restored unchanged after rendering.

## Mandatory change review

- No stale approved old symbols remain in active R callers outside the
  architecture retirement assertions.
- No changed R line exceeds 80 characters.
- No added R line introduces prohibited dollar access, `paste()`/`paste0()`,
  or base apply-family calls.
- The architecture generator is decision-preserving and idempotent.
- Smoke progress outputs, manuscript churn, site-library churn, and unrelated
  function-documentation churn are excluded from the change set.
- Renderer collateral is retained locally under ignored `Data/Temp` recovery
  directories and is not part of the staged change.

No scientific estimand, seed, convergence meaning, persisted target name,
result schema, status, provenance field, or store contract changed.
