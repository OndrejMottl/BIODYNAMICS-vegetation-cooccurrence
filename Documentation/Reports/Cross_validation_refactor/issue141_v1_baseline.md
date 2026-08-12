# Issue 141 v1 baseline

**Captured:** 2026-08-11
**Baseline commit:** `23645d39ee301ceac20e40e1acd5f6feb7275229`
**Owning issue:** #141

## Purpose

This record freezes the inputs used to evaluate the cross-validation v2 contract migration. The referenced v1 files remain unchanged historical evidence; Issue #141 adds v2 records instead of rewriting them.

## Manifest baseline

`Documentation/Implementation_inventories/R_architecture/r_manifest_contract_inventory_v1.csv` contains 16,830 profile-target rows across 26 configured profiles and their supported pipeline entry points. Its SHA-256 hash is `871f25033450ecd3509122e6673d48619957ad28acb4483d35fd46b590cd27c2`.

The v2 review compares every addition, removal, rename, dependency, command, branching declaration, format, and store boundary against manifests regenerated from this commit. Canonical v2 artifact targets are expected additions; retained computational targets are treated as internal unless `contract_inventory_v2.md` declares them public.

## Contract and store baseline

| Evidence | SHA-256 |
|---|---|
| `Documentation/Reports/Cross_validation_audit/contract_inventory_v1.md` | `84a06128ba44904e214ae73b09b36ea9408ca711b3c70b65061519aee15f4be5` |
| `Documentation/Reports/Cross_validation_audit/architecture_store_map_v1.md` | `e8e8333a270592f1181a7a13ce5495367d53e2b204daa31a3e64c7b9fa55354e` |
| `Documentation/Reports/Cross_validation_audit/correctness_reference_metadata_v1.md` | `6d732f16eeac4c89e1d117db69ba81f302f6556edf675fdaee1e81f18c8c0ea2` |
| `Documentation/Reports/Cross_validation_performance/issue141_handoff_v1.md` | `e6a0b266730fc2b298a6f16469323ba3bc31039d64b739bbdd69bb918406c035` |
| `Documentation/Reports/Cross_validation_performance/benchmark_policy_revision_v2.md` | `2f5d47bbc0e6625406adc9d8e187528c216a0c2e5b1b5a6fa1398d212ae3434c` |

## Frozen correctness and performance references

- Assignment hash: `ec5dcdda6049a504cb0b69f845c64aa8`.
- Historical v1 schema hash: `2d727fd54623501e0ac384e0674c17f3`.
- The v1 schema hash is a converter fixture, not the expected v2 schema hash.
- Scientific payload comparison excludes v2-only envelope and migration metadata.
- The optimized production schedule remains cumulative 8→4→2 tuning.
- Benchmark acceptance uses the exact three clean paired runs and thresholds in `benchmark_policy_revision_v2.md`.

## Restart boundary

V1 stores remain read-only compatibility inputs. V2 unit pipelines perform clean v2 tuning and do not import v1 fitted objects or prediction caches. Same-code restart evidence is therefore measured within the completed v2 graph, while external v1 readers are tested to leave source stores unchanged.
