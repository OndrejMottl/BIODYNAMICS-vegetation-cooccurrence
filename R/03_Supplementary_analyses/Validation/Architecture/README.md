# R architecture inventory and validation

## Purpose and backstory

This folder supports issue #150 and the repository-wide refactor tracked by
issue #149. It records the baseline R architecture and the approved
replacement paths and symbols as each owning issue completes its migration.

## Status and entry point

Status: active validation tooling.

Run from the repository root:

```powershell
$path_architecture = "R/03_Supplementary_analyses/Validation/Architecture"
Rscript "$path_architecture/generate_r_architecture_inventories.R"
Rscript "$path_architecture/check_r_architecture.R"
```

## Inputs and outputs

The generator parses active R files, the deterministic function-loader
contract, pipeline target declarations, and test references. It writes:

Under `Documentation/Implementation_inventories/R_architecture/`:

- `r_script_path_inventory_v1.csv`;
- `r_function_inventory_v1.csv`;
- `r_contract_inventory_v1.csv`.

Review generated diffs before accepting them. A changed inventory may represent
a legitimate migration or an unclassified file, function, or target.
Regeneration preserves existing migration, ownership, naming, retirement, and
persisted-target decisions. It refreshes dynamic caller and test references
and appends newly discovered entries.

The checker writes findings to
`Documentation/Reports/R_architecture/architecture_findings_v1.csv`.
Main-analysis placement is blocking: only inventoried production analyses may
remain under `R/02_Main_analyses`. Migrated Abiotic functions, their approved
canonical or domain verbs, and their mirrored tests are also checked as
blocking contracts. Migrated Community function placement and mirrored tests
are blocking, with naming blocked for the Community capabilities whose
semantic migrations are complete. Migrated Time/Ages function placement,
canonical naming, and mirrored tests are blocking. Migrated
Time/Interpolation branching and shared-memory functions, their active tests,
and exact `_legacy` retirement paths are also blocking. Function naming for
other not-yet-migrated domains and other architecture contracts remain
report-only until their owning issues make them blocking. Non-CV modelling
placement, naming, mirrored tests, approved internal-helper classification,
and prohibited `$` access are blocking Issue #154 contracts. Deferred #141 and
#155 functions remain with their owners. The retired HMSC function symbols,
their former `R/Functions/Modelling/_legacy` paths, and their obsolete tests
are blocking contracts and must not return.

## Interpretation limits

Caller discovery is static text matching and does not prove runtime
reachability.
Literal target discovery covers direct `targets::tar_target()` declarations;
dynamic target builders remain owned by their function and pipeline
inventories.
Scientific and public-contract status must be reviewed by the owning issue
before a persisted name changes.

## Regeneration and retirement

Regenerate after an approved architecture batch changes paths, symbols, or
literal targets. Keep version 1 as the pre-migration record. Retire this tooling
only after #157 replaces it with the final blocking architecture checks and
documents the replacement.
