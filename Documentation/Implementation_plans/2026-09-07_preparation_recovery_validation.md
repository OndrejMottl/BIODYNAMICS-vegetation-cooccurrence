# Preparation recovery and validation

## Objective

Make stage 01 resumable and truthful after mixed legacy-cache, data-feasibility, and memory-pressure failures without invalidating readable completed work.

## Changes

- Validate every requested prepared-fold target from target metadata and by reading the target after each unit run.
- Report preparation at target resolution so partial genus, family, functional-type, or temporal coverage remains visible and reusable.
- Classify legacy `qs` deserialization failures separately and invalidate only the unreadable target or named dependency before one bounded retry. Do not install the archived `qs` package.
- Normalize the known empty/`.` VegVault query-plan condition to the existing `no_spatial_records` outcome while retaining meaningful database and backend errors.
- Resolve interpolation workers from explicit shared or dedicated runner arguments, with an optional numeric override and an available-memory cap preventing unsafe fan-out. Do not use environment variables as the user-facing interface.
- Keep target names, stores, scientific configuration, and completed readable targets unchanged.

## Validation

- Add focused tests for endpoint validation, partial preparation, legacy-cache recovery, VegVault no-data normalization, and worker resolution.
- Parse changed R files and enforce the 80-column source contract.
- Run focused tests, architecture generation and validation, the full test suite, and CZ smoke pipelines as time and the shared workstation permit.
