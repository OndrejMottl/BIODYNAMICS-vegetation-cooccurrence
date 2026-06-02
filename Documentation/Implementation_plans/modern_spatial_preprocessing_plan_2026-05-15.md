# Modern Spatial Preprocessing Plan

Date: 2026-05-15

## Goal

Add a modern-specific preprocessing quality gate before modern spatial analyses. The first focus is identifying duplicated datasets and other data-quality issues in the extracted modern community data, then turning those checks into reusable functions and pipeline segments.

## Scope

In scope:
- Modern-only preprocessing and QA
- Duplicate site detection
- Duplicate community detection
- Duplicate metadata key detection
- Taxonomic harmonisation checks
- Missingness and impossible-value checks
- Deterministic duplicate filtering once the policy is defined
- Integration into the modern community preprocessing pipe segment

Out of scope:
- Paleo preprocessing changes
- Model-fitting changes
- Visualization work
- New dependencies unless later approved

## Phase 1: Diagnostic script

Create a standalone script that reads the modern extracted community data and reports the likely issues before any filtering happens.

Checks to include:
- Exact duplicate sites, especially same coordinates
- Exact duplicate community composition
- Duplicate metadata records or keys
- Taxonomic harmonisation anomalies
- Missingness and impossible values

Deliverable:
- A reproducible QA script that prints or saves diagnostic tables for inspection

Validation:
- Run the script successfully for a modern config
- Confirm it produces non-empty diagnostics where expected

## Phase 2: Detection functions

Convert the diagnostic logic into reusable functions with tests.

Functions to build:
- detect_duplicate_sites()
- detect_duplicate_communities()
- detect_duplicate_metadata_keys()
- check_modern_data_impossible_values()
- make_modern_data_quality_report()

Validation:
- Add targeted testthat coverage for each function
- Run the fast test suite after implementation

## Phase 3: Duplicate filtering

Add a deterministic filtering function for modern duplicate records.

Requirements:
- Preserve the schema used by downstream modern targets
- Make the tie-breaking rule explicit and stable
- Keep a dropped-record log for auditability

Validation:
- Targeted tests for the filtering function
- Confirm downstream classification still works on cleaned data

## Phase 4: Pipeline integration

Wire the QA and filtering functions into the modern preprocessing pipe segment so modern analysis uses cleaned data.

Likely touch points:
- R/Pipelines/_pipes/pipe_segment_community_prepare_modern.R
- R/Pipelines/pipeline_modern_spatial_resolution.R

Validation:
- Run targets::tar_manifest() for the modern pipeline script
- Smoke-run one modern spatial unit

## Phase 5: Rollout

Verify the new preprocessing behaves consistently for continental, regional, and local modern configs.

Validation:
- Run manifest checks under each modern config
- Smoke-run at least one unit per modern scale
- Re-run the fast test suite

## Suggested next implementation order

1. Write the diagnostic script.
2. Extract reusable detection functions.
3. Define and implement the deduplication policy.
4. Integrate into the modern pipe segment.
5. Validate across all modern spatial scales.
