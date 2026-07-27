# R architecture inventory and validation

## Purpose and backstory

This folder supports issue #150 and the repository-wide refactor tracked by
issue #149. It records the pre-migration R architecture before files and
symbols move.
The first inventory is intentionally a baseline: current paths remain the
intended paths until the owning issue records an approved replacement.

## Status and entry point

Status: active validation tooling.

Run from the repository root:

```powershell
Rscript R/03_Supplementary_analyses/Validation/Architecture/generate_r_architecture_inventories.R
Rscript R/03_Supplementary_analyses/Validation/Architecture/check_r_architecture.R
```

## Inputs and outputs

The generator parses active R files, the deterministic function-loader
contract, pipeline target declarations, and test references. It writes:

- `Documentation/Implementation_inventories/R_architecture/r_script_path_inventory_v1.csv`;
- `Documentation/Implementation_inventories/R_architecture/r_function_inventory_v1.csv`;
- `Documentation/Implementation_inventories/R_architecture/r_contract_inventory_v1.csv`.

Review generated diffs before accepting them. A changed inventory may represent
a legitimate migration or an unclassified file, function, or target.

The checker writes findings to
`Documentation/Reports/R_architecture/architecture_findings_v1.csv`.
Main-analysis placement is blocking: only inventoried production analyses may
remain under `R/02_Main_analyses`. Function naming, function placement, and
other not-yet-migrated contracts remain report-only until their owning issues
make them blocking.

## Interpretation limits

Caller discovery is static text matching and does not prove runtime reachability.
Literal target discovery covers direct `targets::tar_target()` declarations;
dynamic target builders remain owned by their function and pipeline inventories.
Scientific and public-contract status must be reviewed by the owning issue
before a persisted name changes.

## Regeneration and retirement

Regenerate after an approved architecture batch changes paths, symbols, or
literal targets. Keep version 1 as the pre-migration record. Retire this tooling
only after #157 replaces it with the final blocking architecture checks and
documents the replacement.
