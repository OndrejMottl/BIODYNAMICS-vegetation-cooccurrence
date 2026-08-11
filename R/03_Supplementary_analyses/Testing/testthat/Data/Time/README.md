# Time data tests

## Backstory

Issue #153 moved temporal data functions into a lifecycle-based data hierarchy. The `Ages/` tests cover extracting sample ages from an in-memory VegVault result and joining them to keyed records. The join contract rejects duplicate age keys so records cannot be multiplied silently.

Active dynamic-branch and shared-memory tests now live under `Interpolation/`; its README records the retired self-contained job-builder design. Remaining core interpolation tests will move into this hierarchy with their corresponding function refactor.

## Running the tests

Run the complete recursive suite from the repository root:

```powershell
Rscript R/03_Supplementary_analyses/Testing/Run_tests.R
```

For focused development, source `R/___setup_project___.R` and pass `Ages/` to `testthat::test_dir()`.
