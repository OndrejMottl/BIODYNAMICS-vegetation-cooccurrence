# Abiotic data tests

## Backstory

Issue #153 moved Abiotic functions into a lifecycle-based data hierarchy.
These tests mirror that hierarchy so a function and its focused contract tests
can be located together:

- `Ingest/` covers external raster loading;
- `Transformation/` covers extraction and predictor selection;
- `Validation/` covers interpolation input contracts.

## Running the tests

Run the complete recursive suite from the repository root:

```powershell
Rscript R/03_Supplementary_analyses/Testing/Run_tests.R
```

The runner discovers nested `test-*.R` files and excludes `_outdated`
directories. Individual lifecycle folders can still be passed directly to
`testthat::test_dir()` during focused development.
