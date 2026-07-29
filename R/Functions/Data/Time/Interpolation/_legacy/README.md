# Legacy interpolation functions

## Backstory

Issue #153 retired `make_community_interpolation_jobs()` after the production
pipeline adopted shared read-only inputs and a small per-dataset interpolation
index. The former function copied complete per-dataset community and
age-uncertainty data into each dynamic branch, which increased serialisation
and worker memory use.

The implementation remains here temporarily for historical comparison.
`load_project_functions()` excludes every function below a directory named
exactly `_legacy`, and active documentation generation applies the same
exclusion.

## Retirement contract

Do not call or update this function from active code. The replacement flow is:

1. `build_shared_interpolation_data()` builds shared worker inputs;
2. `build_community_interpolation_index()` builds small branch metadata;
3. `interpolate_community_dataset_from_shared_inputs()` executes one branch.

Remove the legacy implementation once the repository-wide refactor is complete
and no historical comparison is needed.
