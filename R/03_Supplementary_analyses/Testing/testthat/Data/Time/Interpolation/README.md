# Interpolation tests

## Backstory

Issue #153 split temporal interpolation tests by runtime responsibility:

- `Core/` covers grouped interpolation, validation, and sequential/parallel equivalence;
- `Community/Age_uncertainty/` covers paleo community interpolation across bounded age-model iteration batches;
- `Branching/` covers small per-dataset indexes and dynamic branch execution;
- `Shared_memory/` covers read-only worker inputs backed by `{mori}`;
- `_outdated/Jobs/` preserves the former self-contained job-builder tests for historical comparison only.

The old job builder copied nested data into every branch. Production pipelines now keep the large inputs in shared memory and branch over small metadata objects.

## Running the tests

Run active focused tests after sourcing `R/___setup_project___.R`:

```r
base::c(
  "Branching",
  "Community/Age_uncertainty",
  "Core",
  "Shared_memory"
) |>
  purrr::walk(
    ~ testthat::test_dir(
      here::here(
        "R/03_Supplementary_analyses/Testing/testthat/Data/Time/Interpolation",
        .x
      )
    )
  )
```

The project test runner excludes every `_outdated` directory.
