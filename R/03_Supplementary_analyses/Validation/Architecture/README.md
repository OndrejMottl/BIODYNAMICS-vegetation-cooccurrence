# R architecture inventory and validation

## Purpose and backstory

This folder owns the maintained repository-wide R architecture contracts. It preserves the Issue #150 baseline, enforces completed migrations, and publishes the final dependency map delivered by Issue #157.

## Status and entry point

Status: active blocking validation. Run from the repository root:

```powershell
$path_architecture = "R/03_Supplementary_analyses/Validation/Architecture"
Rscript "$path_architecture/generate_r_architecture_inventories.R"
Rscript "$path_architecture/generate_persisted_contract_manifest_inventory.R"
Rscript "$path_architecture/check_r_architecture.R"
```

The ordinary full test suite also runs the repository-level validator.

## Prerequisites and configuration

Use a restored project environment. The checker reads the maintained script, function, persisted-contract, profile, and manifest inventories together with the exact exception ledger under `Documentation/Implementation_inventories/R_architecture/`.

## Outputs and interpretation

`architecture_findings_v1.csv` is the preserved report-only handoff from PR #165 and is not rewritten. The maintained checker writes:

- `architecture_findings_current.csv`, whose statuses are only `blocking` or `excepted`;
- `r_architecture_dependency_map.md`, deterministically built from maintained inventories;
- refreshed version-one inventories when the generator is explicitly run.

All current contracts block unless they match one complete, exact row in `r_architecture_exceptions.csv`. The 39 current exceptions belong to Issue #141 and expire when #141 closes. Malformed, duplicate, orphaned, or unmatched exceptions fail validation.

Static caller discovery does not prove runtime reachability. Literal target discovery covers direct declarations, while the manifest inventory expands configured pipeline builders and dynamic suffixes. Scientific or public contracts still require review by their owning issue before a rename.

## Regeneration and retirement

Regenerate after approved path, symbol, target, profile, or contract changes. Review generated diffs and run the checker twice when deterministic output is being verified. Keep the historical version-one report. This validator remains active after Issue #157; remove each Issue #141 exception when #141 resolves the corresponding finding.
