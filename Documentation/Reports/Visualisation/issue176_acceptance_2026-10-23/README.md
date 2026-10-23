# Predictor-inclusive variance figures: Issue #176 acceptance

## Scope and outcome

This plotting-only follow-up restores the paleo equal-split/Shapley compositional figure alongside the predictor-inclusive companion. It closes the remaining implementation gap in [Issue #176](https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/176): the issue explicitly requires preserving both the original compositional summaries and their figures. Modern already produced both views. Both periods now use the same existing helpers and export contracts.

The work was validated on 23 October 2026 as a follow-up to base commit `2a0c200c0dc49e16779ce984c23a3f68551b5ad7` on `OndrejMottl/issue176`. This report records implementation acceptance, not publication or merge status. PR #178 can use `Closes #176` once the follow-up is published for review; issue closure remains conditional on merging the accepted changes.

No models, calibration, synthesis definitions, analytical configuration, or target-store contracts were changed. The two plotting components consume the existing 22 October synthesis tables. Their source paths and checksums are recorded in [source_inventory.csv](source_inventory.csv).

## Preserved calculation and figure

The restored paleo plot uses `R2_Nagelkerke_percentage`, `prepare_spatial_variance_plot_data()`, `summarise_spatial_variance_stack()`, `summarise_spatial_biotic_component()`, and `plot_manuscript_spatial_variance()` exactly as the original compositional workflow did. The predictor-inclusive path still reads `R2_Nagelkerke_predictor_inclusive_percentage`, allows overlapping totals, and uses the separate non-stacked domain panels. No fraction-allocation function was modified.

For a direct regression check, the original paleo plotting script from commit `3d9442eaf08c3a18c32cb88d6ff7f55037b61b4a` was evaluated against the same current synthesis inputs and helpers. Only project setup was omitted and export directories were redirected to a temporary review directory. Its three CSV outputs and PNG are byte-for-byte identical to the restored production component outputs. The current paleo inclusive exports and both modern views also match their 22 October exports byte-for-byte. See [table_equivalence.csv](table_equivalence.csv) and [image_equivalence.csv](image_equivalence.csv).

## Issue acceptance evidence

| Requirement | Evidence | Result |
| --- | --- | --- |
| Full predictor-inclusive Climate, Biotic co-occurrence, and Spatial totals | Existing all-seven-fractions fixture in `test-compute_predictor_inclusive_variance_components.R`; shared implementation unchanged | Pass |
| Shared fractions are not divided in the new metric | Exact formula fixture; individual domains retain complete shared fractions | Pass |
| Separate domain displays rather than a stack | Both inclusive figures use `plot_manuscript_predictor_inclusive_variance()` with a common 0–100 scale | Pass |
| Explicit overlap explanation | Inclusive plot caption states that shared fractions count in full and totals overlap and need not sum to 100 percent | Pass |
| Preserve Shapley summaries and figures unchanged | Original paleo recipe equivalence, unchanged modern exports, and added arithmetic regression fixture | Pass |
| Same paleo/modern visual grammar | Both components use the same compositional and inclusive helpers, component palette, and ordering | Pass |
| Exact plot-ready unit and summary tables | Ten CSV exports covering both views and periods; checksums and row counts in the equivalence table | Pass |
| Focused tests and both plotting smoke runs | Seven focused test files, full test suite, and successful direct execution of components 03 and 04 | Pass |

## Exports and visual inspection

The following four dated figure bases each have a vector PDF, 600-dpi TIFF, and review PNG under `Outputs/Figures/Spatial/`:

- `paleo_variance_partitioning_2026-10-23`
- `paleo_variance_partitioning_predictor_inclusive_2026-10-23`
- `modern_variance_partitioning_2026-10-23`
- `modern_variance_partitioning_predictor_inclusive_2026-10-23`

All 12 files exist and are nonempty. The four PNGs were inspected for readable facets, labels, legends, clipping, and consistent colour semantics. They use the unchanged manuscript canvas, with 2000 × 1600 review PNGs and 4000 × 3200 submission TIFFs. TIFF metadata confirms 600 × 600 dpi. [figure_inventory.csv](figure_inventory.csv) records file sizes and hashes; [image_dimensions.csv](image_dimensions.csv) records raster dimensions and the density metadata reported by ImageMagick. TIFFs remain generated, ignored submission artifacts under the existing repository policy; PDF/PNG and exact CSV exports are available for review.

The paleo unit table has 687 component rows representing 229 unit–resolution combinations; modern has 825 component rows representing 275 combinations. Both cover all three spatial tiers and three taxonomic resolutions. Each compositional summary has 36 rows and its association summary nine; each predictor-inclusive summary has 27 rows. See [coverage.csv](coverage.csv) and [table_equivalence.csv](table_equivalence.csv). These are available-model counts, not a claim that all possible units are feasible.

Stage 05 still has seven ordered components. Restoring the paleo companion increases the complete suite from eight to nine figures; the master order and the other five components are unchanged.

## Validation and explicit waiver

- The regression tests were first run before restoring the compositional workflow and failed on the missing paleo view. They pass after the fix.
- Seven focused issue, arithmetic, result-loading, plot-data, and plotting test files pass with 123 assertions.
- The full test suite exits successfully: 5,564 passes, zero test failures, zero test-reporter warnings, and one opt-in VegVault integration skip across 117 test directories. See [full_test_summary.csv](full_test_summary.csv). Startup locale/package-version warnings and an end-of-session database-connection cleanup warning are present in the raw full-suite log; neither is a test failure.
- Both spatial variance plotting components exit successfully and write all expected CSV and figure outputs. No production fitting runner was invoked.
- Configuration regeneration in a temporary directory confirms that tracked generated configuration matches the modular sources and all 26 profiles remain semantically identical to the reference.
- Architecture inventories were regenerated: 649 scripts, 460 functions, 472 literal targets, and 19,782 expanded profile-target rows across 26 profiles. The blocking validator passes twice with zero findings; both runs produce the same dependency-map Git blob hash, `505c012f667bcf5b395bcfd35a939c12c1e3e792`. The regenerated manifest inventory is unchanged from the working-tree base.
- Changed R scripts parse and satisfy the 80-column and ASCII contracts; `git diff --check` passes.

The user explicitly waived the CZ model smoke rerun for this plotting-only change on 23 October 2026: “Waive CZ rerun for this plotting-only change.” No CZ pipeline or production model rerun was launched. The directly relevant paleo and modern plotting smoke runs were completed instead. This is a scoped waiver, not a change to the repository's general smoke-test policy.

Validation logs are preserved in [logs/](logs/), including the expected pre-fix regression failure, final focused/full tests, plotting runs, numerical audit, configuration check, inventory generation, and both architecture checks. The archival copies standardise newlines and remove trailing whitespace; raw operational logs under `Data/Temp/` were left untouched. [log_inventory.csv](log_inventory.csv) records both raw and archived checksums. [r_source_checks.csv](r_source_checks.csv) records the parsing, line-length, and ASCII checks.

## Reproduction

From the restored project environment, run the two unchanged entry paths in order:

```powershell
Rscript R/02_Main_analyses/05_Visualisation/_components/03_plot_paleo_variance_partitioning.R
Rscript R/02_Main_analyses/05_Visualisation/_components/04_plot_modern_variance_partitioning.R
```

Both scripts consume existing synthesis tables without opening target stores. Outputs are date-stamped, so another day's run will have different filenames but the same values when synthesis inputs and graphical settings are unchanged.
