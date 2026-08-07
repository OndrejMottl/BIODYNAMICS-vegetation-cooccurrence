# Issue 155 final validation

Date: 2026-08-06

Branch:
`refactor/issue155-pipeline-prediction-visualisation-presentation`

Baseline: clean `main` at `5b9df9bd`, the merge commit of PR #163.

## Scope delivered

- `R/Functions/Utility/` is absent.
- Configuration, definitions, stores, orchestration, data access, prediction,
  and visualisation helpers use capability-owned paths with mirrored tests.
- The approved global API renames are complete across active R, QMD/Rmd,
  YAML, configuration, tests, inventories, and generated documentation.
- The single-use `coerce_null_to_na_integer()` helper is inlined and retired.
- `run_pipeline()` retains its public signature while delegating store
  resolution, interpolation prebuild, metadata loading, execution status,
  error extraction, and progress output.
- Progress object construction is pure; file writing and monitoring have
  separate contracts.
- IAVS owns 26 presentation-local helpers through a deterministic local
  loader. The four compatibility wrappers, six Oracle scale aliases,
  `add_panel()`, and `build_base_terminal_plot()` are retired.
- The Issue #155 inventory records 59 migrated global functions, 26 localized
  functions, 11 retired functions, and four unchanged baseline VegVault
  functions.

## Baseline note

The clean PR #163 baseline suite had one failure: its generated-documentation
contract still required artifacts for the retired `apply_scale_attributes()`
name. The approved replacement is
`scale_predictors_with_training_attributes()`. Issue #155 corrected that stale
expectation after confirming all replacement artifacts exist.

## Architecture and source validation

- Architecture inventory generation completed with 462 scripts, 336
  functions, and 114 literal targets.
- Architecture validation completed with zero blocking findings. The remaining
  47 findings are pre-existing report-only items: 36 naming reviews, nine
  nested-helper reviews, and two missing-script inventory reviews.
- Issue #155 makes placement, naming, mirrored tests, retirement,
  presentation localization, substantive nested helpers, inventory coverage,
  and generated-documentation freshness blocking.
- A fresh project source loaded 304 global symbols. No approved old symbol,
  retired helper, or IAVS-local helper loaded globally.
- The deterministic IAVS loader sourced 26 files and exposed all required
  renamed writer, theme, and path contracts.
- All 175 changed or added R files parse successfully.
- Added R lines contain zero lines over 80 columns, zero prohibited dollar
  access, and zero unnamespaced `paste()` or `paste0()` calls.
- `git diff --check` passes.

## Manifest comparison

Clean-baseline and Issue #155 manifests were generated in separate worktrees
under `R_CONFIG_ACTIVE=project_cz_paleo`. Ordered target names are identical.
After replacing only the approved Issue #155 new symbols with their baseline
names, every command expression is identical.

| Pipeline | Targets | Raw changed commands | Unmatched after normalization |
|---|---:|---:|---:|
| `pipeline_paleo_core.R` | 127 | 10 | 0 |
| `pipeline_paleo_resolution_test.R` | 258 | 12 | 0 |
| `pipeline_paleo_spatial_resolution.R` | 232 | 11 | 0 |
| `pipeline_paleo_temporal.R` | 663 | 20 | 0 |
| `pipeline_modern_spatial_resolution.R` | 233 | 11 | 0 |
| `pipeline_modern_spatial_resolution_test.R` | 246 | 11 | 0 |
| `pipeline_paleo_local_cv_decomposition_reference.R` | 28 | 0 | 0 |

## Behaviour and integration validation

- Focused data/access, configuration, stores, orchestration, prediction,
  visualisation, and IAVS tests pass.
- The complete normal test runner passes with exit code 0 in 163.8 seconds.
- Instrumented coverage passes and reports 96.31 percent, above the 94.98
  percent PR #163 result.
- The supported Czechia smoke passes with exit code 0 in 2,121.7 seconds.
  Manifest counts remain 127 paleo-core, 258 paleo spatial-resolution, and
  246 modern spatial-resolution targets.
- The known Chrome-debugging timeout prevented one static progress PNG write;
  both HTML progress artifacts were written, a later screenshot completed,
  and all three scientific pipelines completed successfully.

## Documentation and presentation validation

- Function documentation, coverage, website, and manuscript workflows
  completed. Issue #155 enforces 236 current HTML/text/QMD/published-HTML
  artifacts for its 59 migrated global functions; none are missing.
- All 292 old-name, retired, and globally documented IAVS artifacts are absent.
- Renderer-only collateral was removed from the change set recoverably. The
  pre-cleanup working copy, clean-baseline archive, and moved noise remain in
  ignored
  `Data/Temp/documentation_generation_noise_20260806_issue155/`.
- The IAVS render completed in 119 seconds and produced a 29-slide HTML deck,
  PDF, 12 GIF files, and 62 PNG files in the published presentation tree.
- Representative title, model-core, spatial-results, paleo-prediction,
  contemporary-results, and functional-type PDF pages were rasterized and
  visually inspected. No clipping, overlap, missing imagery, broken glyphs,
  or illegible labels were found.

## Boundaries preserved

- Issue #136 retains future prediction contexts, climate backends, scenarios,
  horizons, and future-prediction pipelines.
- Issues #140 and #141 retain CV algorithms, scheduling, schemas, stores, and
  performance policy.
- Issue #156 retains persisted target, artifact-field, store-layout, and
  profile-key renames.
- Issue #157 retains repository-wide enforcement and final architecture-map
  closure.
- No dependency, seed, scientific estimand, target name, artifact schema,
  store layout, configuration key, CV behavior, commit, push, or PR was added.
