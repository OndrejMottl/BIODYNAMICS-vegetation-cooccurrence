# Community data tests

## Backstory

Issue #153 moved Community functions into a lifecycle-based data hierarchy.
These tests mirror that hierarchy so each function and its focused contract
tests remain easy to locate:

- `Ingest/` covers classification data loaded from local or remote sources;
- `Transformation/` covers data shape, proportions, modern records, and taxon
  selection;
- `Classification/` covers dataset identity, functional types, classification
  reference tables, and taxonomic resolution;
- `Quality_control/` covers colocation, duplicate records, and modern-record
  validation;
- `Metrics/` covers derived community metrics.

The path-only migration deliberately preserves function names, arguments,
objects, and behaviour. Semantic naming changes belong to the following
Community migration batch.

## Running the tests

Run the complete recursive suite from the repository root:

```powershell
Rscript R/03_Supplementary_analyses/Testing/Run_tests.R
```

The runner discovers nested `test-*.R` files and excludes `_outdated`
directories. Individual lifecycle folders can still be passed directly to
`testthat::test_dir()` during focused development.
