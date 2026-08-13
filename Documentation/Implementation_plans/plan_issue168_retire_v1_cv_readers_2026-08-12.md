# Issue 168: retire temporary v1 cross-validation readers

## Context and scope

Issue #168 is the final implementation child of #140. PR #169 made cross-validation writers native v2 and retained temporary v1 readers; PR #172 is the clean implementation baseline. This change removes those readers without changing the public `2.0.0` envelope, the eight canonical target names, payload schemas, provenance columns, content-hash policy, registry hash, or scientific estimands.

Historical v1 reports, fixtures, manifests, correctness evidence, and benchmark records remain immutable. Old production outputs awaiting #171, frozen one-time validation stores, and ad hoc stores are historical and do not block retirement. Issue #166 and definitive production/model/manuscript reruns remain out of scope.

## 1. Establish the store-retirement gate

- Inventory actual cross-store caller edges for configured main, smoke, and maintained reference workflows.
- Record source store, canonical target, artifact type, metadata data hash, envelope content hash, provenance state, consumer, and retention decision in the Issue #168 retirement report.
- Retain a source only when current code or a maintained scientific/reference workflow consumes it across a store boundary.
- Treat the component and structured-regularization reference output stores as consumers of the native-v2 `cz_paleo_cv_reference_gpu` source, not as v1 artifacts.
- Require every retained source to resolve exactly one canonical target with a non-empty metadata data hash and a valid `2.0.0` envelope whose provenance has `source_schema_version = "2.0.0"`, `migration_applied = FALSE`, and `migration_function = NA`.
- If a retained v1 source is found, archive it intact below `Data/targets/issue168_archive/`, regenerate its canonical store with current code, and repeat the audit. Never import a v1 fit or prediction cache.
- Do not start reader removal until no retained edge depends on a v1 target and historical reports and fixtures are unchanged.

## 2. Make runtime reads native-v2-only

- Add failing tests first for canonical v2 loading, malformed or migrated envelope rejection, and absence of v1 probing when a canonical target is missing.
- Delete `convert_sjsdm_v1_artifact()`, its nine artifact-specific/table converters, `load_sjsdm_versioned_artifact()`, their tests, and generated function documentation.
- Remove `v1_target_name` from `load_sjsdm_cv_payload_field()` and read one validated v2 envelope.
- Remove the legacy tier-table branch from `load_sjsdm_tier_tuning_artifact()` while retaining the typed-empty result for a genuinely unavailable v2 tier decision.
- Require validated v2 tuning envelopes in `load_sjsdm_tuning_summaries()` and `has_sjsdm_tuning_evidence()`.
- Remove migration arguments from `build_sjsdm_artifact_provenance()` and always emit native-v2 migration fields.
- Require native-v2 provenance in `validate_sjsdm_artifact_envelope()` while preserving provenance columns and content-hash exclusions.
- Update maintained pipelines and reporting readers to use canonical design, selection, evaluation, and provenance payloads only.
- Require focused loader, provenance, envelope, reporting, tier, and pipeline-contract tests to pass, with no active converter, v1-target, or fallback branch remaining.

## 3. Retire compatibility records and regenerate architecture outputs

- Remove the fourteen temporary compatibility-ledger rows and delete the ledger if no validator or maintained document requires an empty file.
- Update the migration matrix, v2 store map, and v2 contract inventory to state that active reads are native-v2-only; retain useful historical mappings only when clearly marked completed.
- Do not edit the historical Issue #141 plan or validation record, frozen v1 manifest, correctness reports, benchmark evidence, or v1 fixtures.
- Regenerate function documentation and published function pages, script/function inventories, persisted-contract manifest inventory, dependency map, and current architecture findings.
- Resolve all 26 configured manifests and run the architecture generator/checker twice with deterministic output and no blocking finding.
- Confirm the registered v2 contract hash remains `717435760b653dce608ce51380ec0fb1`.

## 4. Validate behavior and closure readiness

- Run clean component and structured-regularization reference pipelines in isolated `issue168_native_v2` store suffixes while preserving existing reference stores.
- Confirm both workflows read v2 GPU reference artifacts and reproduce accepted assignments, decisions, output keys, and conclusions.
- Run the complete CZ smoke workflow and validate every emitted canonical envelope directly.
- Run a same-code unit/tier resume check and confirm no fitting target or canonical artifact rematerializes and content hashes remain unchanged.
- Run focused tests, parse changed R files, run the full suite, regenerate documentation, render the website, verify source/published parity, and run `git diff --check`.
- Perform the repository's mandatory read-only local change review and resolve all high- and medium-severity findings.
- Record commands, stores, hashes, test counts, workflow outcomes, resume evidence, and review findings in the retirement report.

Git staging, commits, pushes, issue updates, and issue closures require separate explicit authorization.
