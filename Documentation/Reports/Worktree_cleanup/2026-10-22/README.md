# Approved worktree cleanup, 22 October 2026

## Scope and safeguards

The user approved seven dependency-ordered analysis commits and one separate manuscript-planning commit, explicitly authorizing staging and committing but excluding pushing. The starting commit was `6483905b0ca1174318743d8189b08ef9181da789` on `OndrejMottl/issue176`. Existing scientific implementation, calibrated budgets, historical recovery evidence, analysis outputs, and progress artifacts were retained. No production preparation, tuning, fitting, or sensitivity runner was restarted during cleanup.

An exact local copy of the 538 files in the execution-time dirty snapshot is preserved under the ignored directory `Data/Temp/Worktree_cleanup/20261022/originals/`. Its `archive_manifest.csv` contains matching original/archive SHA-256 hashes. These are local recovery copies, not a replacement for committed scientific evidence.

The earlier planning estimate of roughly 7 GiB was incorrect: Windows `cmd` removed the exponent operator in an inline size calculation. The actual snapshot occupied 69.78 MiB. For example, the atlas PDF is 4,414,368 bytes, not 431 MiB. No bulk deletion, compression, output exclusion, or size-driven scientific change was warranted.

## Commit groups

1. Calibration freshness, content-matched evidence migration, and prepared-fold preservation, with tests and calibration workflow documentation.
2. Resolution-aware fitting requests and pipeline error recovery, with verified spatial-basis infeasibility and tests.
3. Small-fold fitting and model-evaluation correctness, including stale-result exclusion and convergence extraction.
4. Restartable sensitivity phase checkpoints and likelihood progress reporting.
5. Calibration/recovery/completion evidence, implementation plans, and this validation record.
6. Dated synthesis tables, exact plot data, manuscript figure exports, and the existing-style serialized ANOVA output.
7. Function references, website metadata, architecture inventories, and maintained progress artifacts, including website mirrors.
8. The separate manuscript-planning draft. Its line wrapping was normalized with a rendered-HTML equivalence check; wording and scientific claims were not changed or newly validated by cleanup.

The verified zero-positive-MEM calculation and its tests travel with error classification in group 2 so that the dependent recovery behavior is reviewed together. No global tuning-parameter reset was performed. The apparently modified modern genus tuning CSV had no semantic Git diff and is not evidence of a new parameter change.

## Validation

The fresh full test suite passed 5,551 assertions with zero failures, zero test warnings, and one skip. Focused changed-file tests also passed. Generated configuration matched its modular sources and all 26 profiles remained semantically identical to their reference. Architecture inventories and the persisted manifest were regenerated, and the blocking architecture checker reported zero findings. Changed R sources and all main-analysis R entry points parsed successfully.

`source_preservation.csv` verifies that every changed R source/test file retained its exact initial content hash during this cleanup. The seven scientific-source/configuration fingerprints recorded with the 21 October validation also still match; see `prior_smoke_source_hash_check.csv`. The canonical CZ smoke run passed on 21 October, as recorded in `Data/Temp/Main_analysis_execution/modern_sensitivity_recovery_20261021/20261021_125430/component_status.csv`. It was not repeated merely to stage unchanged scientific code. The fresh tests and configuration/architecture checks are saved alongside this report.

Function documentation was regenerated selectively. The existing external Rd conversion produced empty HTML for `fit_jsdm_model()` and `run_pipeline()`; existence-only checks did not catch that upstream generator limitation. Those two HTML/QMD references were regenerated directly from their unchanged roxygen source using `roxygen2::roc_proc_text()` and `tools::Rd2HTML()`. Their complete prior PDFs and all complete prior function-site pages were preserved from verified local backups. An unnecessary project-wide Quarto resource sweep was stopped; regenerated website index/progress mirrors were retained, and no analytical process was stopped. The documentation generator implementation itself was not changed. `function_documentation_inventory.csv` verifies that all 145 expected reference files for the 29 changed functions are nonempty.

Whitespace normalization was limited to generated HTML, manuscript prose wrapping, and trailing console padding/line endings in versioned audit logs. Exact raw logs remain in the local archive; `log_formatting.csv` records their hashes and confirms that all non-whitespace text was preserved. No error, warning, result, or historical failure was removed. Before committing each batch, its exact staged paths, diff statistics, and whitespace check must be inspected. The final handoff should report the actual commit IDs and remaining worktree state; no push is authorized.

## Retained limitations

The publication outputs remain the accepted current draft, not a claim of final manuscript-layout approval. The clipped annotations, blank temporal sampling strip, and 28 cached temporal failures remain documented in `../../Model_evaluation/publication_products_2026-10-22/README.md`. Raw execution logs and stored historical errors retain their actual outcomes; successful recovery does not rewrite failed-run history.
