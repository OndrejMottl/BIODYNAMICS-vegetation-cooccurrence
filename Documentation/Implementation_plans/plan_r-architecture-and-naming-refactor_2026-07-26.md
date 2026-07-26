# Plan: R architecture and naming refactor

**Date:** 2026-07-26
**Author:** plan-large-changes agent
**Status:** Approved
**GitHub umbrella:** [#149](https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/149)
**Implementation issues:** [#150](https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/150)
through [#157](https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/157)

---

## Planning assumptions

- Work in the current main worktree unless the user requests a separate worktree.
- Treat this as a large, high-complexity, long-running refactor.
- Do not add external R dependencies merely to support the refactor.
- Keep the existing top-level roots (`R/02_Main_analyses`,
  `R/03_Supplementary_analyses`, `R/Functions`, and `R/Pipelines`) during the
  first migration. Standardise and deepen their internal structure.
- Include all active code under `R/`, with domain-sized implementation batches.
- Preserve the public scientific and artifact contracts frozen for Issue #141.
- Keep `{config}` as the runtime configuration reader.
- Treat `Configuration/**` as the human-authored source and the tracked root
  `config.yml` as a generated compatibility artifact.
- Preserve all existing configuration profile IDs and resolved values during
  the first structural migration.
- Do not create compatibility wrappers without a demonstrated active consumer.
- Do not perform state-changing Git or GitHub operations without explicit user
  instruction.

---

## Background

[Issue #141](https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/141)
is ready to start: its predecessors
[#139](https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/139)
and
[#138](https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/138)
are closed, and `main` contains the accepted staged cross-validation design.
Issue #141 remains the final child of
[#140](https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/140).

Issue #141 is narrower than the requested repository-wide refactor. It freezes:

- scientific behavior and estimands;
- public target names and artifact schemas;
- grouped assignments and fold-local preprocessing;
- deterministic seeds, statuses, and provenance;
- isolated unit and tier target stores; and
- the staged-execution performance policy.

The broader refactor therefore needs its own umbrella. Issue #141 should remain
owned by #140 and be linked to the new umbrella as related required work, not
reparented or silently broadened.

### Current inventory

- `R/02_Main_analyses` contains 39 files.
- Fourteen root-level files are CZ reference, issue-specific benchmark,
  validation, or test runners rather than main analyses.
- Additional diagnostic, convergence-tuning, and repair scripts are mixed into
  the spatial and temporal main-analysis folders.
- `R/03_Supplementary_analyses` contains 360 files, but most are in a flat
  `Testing/testthat` folder or generated Quarto cache directories.
- `R/Functions` contains 306 files.
- `R/Functions/Modelling/Cross_validation` alone contains 75 function files.
- The current function inventory uses 53 distinct leading verbs. The most common
  are `get_` (40), `make_` (26), `build_` (19), `prepare_` (14), `run_` (13),
  `read_` (10), and `load_` (3).
- At least 30 named nested helpers occur inside function files, including the
  Issue #139 deferred hotspots.
- No current top-level function name uses `_simple` or `_basic`, but vague
  `simple`, `basic`, `new`, `old`, and `final` variants occur among internal
  objects.
- `R/___setup_project___.R` recursively loads `R/Functions`, which makes deeper
  folders feasible, but it does not currently reject duplicate symbols or make
  source-order assumptions explicit.
- The test and function-documentation tooling already enumerates source files
  recursively. Test discovery under a mirrored nested test tree still needs an
  executable verification.
- `config.yml` contains 452 lines and 26 top-level entries: one `default`, nine
  main profiles, two CZ smoke profiles, eight reference profiles, and six
  issue-specific profiles.
- Main, smoke, reference, and one-time profiles currently share one flat file
  without an enforceable role or selectability contract.
- Thirteen R files call `config::get()` directly, while additional callers use
  `get_active_config()`. Configuration retrieval is therefore not yet
  centralised behind one project function.

The earlier function-organisation PR #129 was useful but mostly reorganised
presentation helpers. It did not establish repository-wide folder ownership,
verb semantics, or enforceable migration rules.

---

## Goal

Make every active R file easy to locate from its purpose, every reusable
function easy to locate from its domain and lifecycle, and every function or
object name explicit about what it does and returns. Make each configuration
profile easy to find from its role, pipeline, and lifecycle. Close Issue #141
without changing its frozen scientific, public-artifact, store, configuration,
or performance contracts, then apply the same architectural discipline across
the remaining R code in small, reviewable domain migrations.

---

## Scope

### In scope

- Classify every active R script as production analysis, diagnostic, validation,
  reference generation, experiment, test, reusable function, pipeline
  definition, or obsolete.
- Restrict `R/02_Main_analyses` to stable main analysis runners, result
  synthesis, and final visualisation scripts.
- Move diagnostics, tests, validation workflows, sensitivity studies,
  benchmarks, reference generators, issue reproductions, and one-time scripts
  into explicit nested supplementary folders.
- Add a standard README to every diagnostic, validation, experiment, benchmark,
  archived, or one-time-script folder.
- Reorganise `R/Functions` by domain, capability, and lifecycle.
- Mirror the function hierarchy in the test hierarchy.
- Split oversized function folders, especially cross-validation.
- Extract named nested helpers when they have a coherent testable contract.
- Define and apply semantic function verb contracts.
- Rename files whenever their primary function or script entry point is renamed.
- Rename local objects within the domain batch that owns the containing code.
- Inventory persisted targets and artifacts separately from private local
  objects.
- Consolidate demonstrated schema, status, provenance, target-building, and
  runner duplication required by Issue #141.
- Remove dead and stale paths within the domain batch that proves them unused.
- Add report-only architecture and naming checks early, then make them blocking
  as each domain is migrated.
- Split the human-authored configuration into nested, role-specific source
  fragments while retaining a generated root `config.yml` for `{config}`.
- Define configuration profile roles, lifecycle metadata, and selectability
  rules.
- Add a deterministic configuration generator, semantic equivalence snapshot,
  generated profile catalog, and generated-file drift check.
- Centralise runtime configuration retrieval and guard production runners
  against accidental use of reference or one-time profiles.
- Update tests, configuration references, generated function documentation,
  Quarto documents, READMEs, plans, and repository instructions affected by
  path or name changes.

### Out of scope

- Changing the scientific estimand, grouped CV behavior, fold-local
  preprocessing, held-out MEM projection, tuning weights, or feasibility policy.
- Changing Issue #138's accepted `8 -> 4 -> 2`, three-repeat, five-fold staged
  execution policy.
- Combining isolated unit and tier target stores.
- Addressing downstream modern ANOVA runtime or temporal final-model
  standard-error singularities as part of Issue #141.
- Renaming frozen public Issue #141 targets or artifact fields without a
  separately approved, compatibility-tested migration.
- Introducing a package structure or exported public R package API in this
  refactor.
- Abandoning `{config}` or replacing it with a new runtime configuration
  framework.
- Changing configuration parameter values, profile IDs, or scientific behavior
  in the structural configuration migration.
- Retaining old function names through speculative compatibility wrappers.
- A single repository-wide mechanical rename PR.
- A standalone final validation-only or cleanup-only phase.

### Affected components

- `R/___setup_project___.R`
- `R/02_Main_analyses/**`
- `R/03_Supplementary_analyses/**`
- `R/Functions/**`
- `R/Pipelines/**`
- `Configuration/**` (new human-authored configuration sources and catalog)
- `config.yml` (generated and tracked runtime artifact)
- configuration access helpers, direct `config::get()` consumers, and their
  tests and documentation
- `.ai/r-coding.md`
- `.ai/r-functions.md`
- other `.ai/` or `AGENTS.md` path references affected by approved moves
- `Documentation/Functions/**`
- `Documentation/Website/Documentation/Functions/**`
- `Documentation/Functions_test_coverage/**`
- `Documentation/Reports/Cross_validation_audit/**`
- `Documentation/Reports/Cross_validation_performance/**`
- implementation plans, reports, and generated documentation containing moved
  paths or renamed symbols

Issue #141 specifically owns the active CV functions, CV pipeline segments,
tier-tuning pipelines, CV runner/store orchestration, CV tests, CV reference
generators, and Issue #138/139 handoff documentation. Each remaining file must
be assigned to exactly one repository-refactor child issue before it moves.

---

## Architectural principles

### One file, one owner, one purpose

- Each R function file contains one top-level function and has the exact same
  lower-snake-case basename.
- Each analysis or runner script has one obvious entry-point purpose.
- Each file is assigned to one migration issue and is not moved in one issue
  only to be substantially edited again in another.
- Path-only moves and semantic renames are separate commits or PRs within a
  domain issue.

### Main analyses are production-facing

`R/02_Main_analyses` may contain:

- stable production runners;
- primary result analyses and synthesis;
- final plots and tables used as project outputs.

It may not contain:

- unit, integration, smoke, or reference tests;
- diagnostics or debugging scripts;
- convergence investigations or tuning experiments;
- benchmark harnesses;
- issue-numbered reproductions;
- one-time repair/rerun scripts;
- reference-output generators.

### Proposed script tree

```text
R/
|-- 02_Main_analyses/
|   |-- Spatial/
|   |   |-- Paleo/
|   |   |   |-- Runners/
|   |   |   |-- Synthesis/
|   |   |   `-- Visualisation/
|   |   `-- Modern/
|   |       |-- Runners/
|   |       |-- Synthesis/
|   |       `-- Visualisation/
|   `-- Temporal/
|       `-- Paleo/
|           |-- Runners/
|           |-- Synthesis/
|           `-- Visualisation/
`-- 03_Supplementary_analyses/
    |-- Diagnostics/
    |   |-- Data_processing/
    |   |-- Modelling/
    |   `-- Pipelines/
    |-- Validation/
    |   |-- Cross_validation/
    |   |   |-- Correctness_references/
    |   |   |-- Performance_benchmarks/
    |   |   `-- Representative_workflows/
    |   `-- Scientific_references/
    |-- Sensitivity/
    |-- Experiments/
    |-- One_time/
    |   `-- Issues/
    |-- Testing/
    |   |-- Fixtures/
    |   |-- Smoke/
    |   `-- testthat/
    `-- Documentation/
```

The implementation inventory records the exact current-to-target path for every
file. Folder names should be standardised consistently in the migration; avoid
case-only rename operations on Windows.

### Proposed function tree

```text
R/Functions/
|-- Data/
|   |-- Abiotic/
|   |   |-- Ingest/
|   |   |-- Transformation/
|   |   `-- Validation/
|   |-- Community/
|   |   |-- Ingest/
|   |   |-- Transformation/
|   |   |-- Classification/
|   |   |-- Quality_control/
|   |   `-- Metrics/
|   |-- Traits/
|   `-- Time/
|-- Modelling/
|   |-- Cross_validation/
|   |   |-- Assignments/
|   |   |-- Feasibility/
|   |   |-- Fold_preparation/
|   |   |-- Candidate_design/
|   |   |-- Tuning/
|   |   |   |-- Planning/
|   |   |   |-- Execution/
|   |   |   |-- Aggregation/
|   |   |   `-- Selection/
|   |   |-- Prediction/
|   |   |-- Evaluation/
|   |   |-- Contracts/
|   |   `-- Provenance/
|   |-- Fit_inputs/
|   |-- Fitting/
|   |-- Spatial_effects/
|   |-- Evaluation/
|   |-- Variance_partitioning/
|   `-- Decomposition/
|-- Prediction/
|-- Pipeline/
|   |-- Configuration/
|   |-- Definitions/
|   |-- Orchestration/
|   `-- Stores/
|-- Visualisation/
|-- Presentation/
`-- Validation/
```

This is the initial taxonomy. The versioned path inventory is authoritative and
must prevent catch-all folders such as a growing `Utility` or a second
75-function capability folder.

Tests should mirror the function hierarchy:

```text
R/03_Supplementary_analyses/Testing/testthat/
`-- Modelling/
    `-- Cross_validation/
        |-- Assignments/
        |-- Tuning/
        `-- Evaluation/
```

Shared fixtures belong under `Testing/Fixtures/<domain>/` and are sourced
explicitly. Test-file-local fixtures stay local rather than leaking into the
shared test environment.

### Configuration architecture

Keep `{config}` and its existing runtime behavior, but move the authoring
complexity into a navigable source tree. Human maintainers edit categorized
fragments under `Configuration/`; a deterministic project function assembles
them into the ordinary flat root `config.yml` expected by `{config}`.

```text
Configuration/
|-- README.md
|-- manifest.yml
|-- Defaults/
|   `-- default.yml
|-- Bases/
|   |-- paleo_spatial.yml
|   |-- paleo_temporal.yml
|   `-- modern_spatial.yml
|-- Profiles/
|   |-- Main/
|   |   |-- Paleo/
|   |   |   |-- spatial.yml
|   |   |   `-- temporal.yml
|   |   `-- Modern/
|   |       `-- spatial.yml
|   |-- Validation/
|   |   `-- cz_smoke.yml
|   |-- References/
|   |   `-- cross_validation.yml
|   `-- One_time/
|       `-- Issues/
|           |-- issue_138.yml
|           `-- issue_143.yml
`-- Generated/
    `-- profile_catalog.md

config.yml  # generated and tracked; do not edit manually
```

Each fragment remains valid `{config}`-style YAML with profiles as top-level
keys. This permits deterministic textual assembly and avoids a second custom
configuration semantics layer. For example:

```yaml
base_paleo_spatial:
  inherits: default
  _profile:
    role: base
    status: active
    selectable: false
    pipeline: paleo_spatial
    description: Shared paleo-spatial settings.
  # Existing shared settings move here unchanged.

project_europe_paleo:
  inherits: base_paleo_spatial
  _profile:
    role: main
    status: active
    selectable: true
    pipeline: paleo_spatial
    description: Main European paleo-spatial analysis.
    related_issue: null
    retirement: null
  # Existing profile-specific settings remain unchanged.
```

Every profile has `_profile` metadata with:

- `role`: `base`, `main`, `smoke`, `reference`, or `one_time`;
- `status`: `active`, `frozen`, or `archived`;
- `selectable`: whether a supported runner may activate it directly;
- `pipeline`: the owning pipeline or workflow;
- `description`: a concise human-readable purpose;
- `related_issue`: required for issue-specific profiles; and
- `retirement`: the archival or deletion criterion for temporary profiles.

Base profiles use `role: base` and `selectable: false`. Normal production
runners accept only `main` profiles, plus explicitly supported `smoke` profiles.
Reference and one-time profiles require their dedicated validation or
historical runner; they cannot be selected accidentally by a production entry
point.

`Configuration/manifest.yml` is the only ordering authority:

```yaml
output: config.yml
fragments:
  - Configuration/Defaults/default.yml
  - Configuration/Bases/paleo_spatial.yml
  - Configuration/Bases/paleo_temporal.yml
  - Configuration/Bases/modern_spatial.yml
  - Configuration/Profiles/Main/Paleo/spatial.yml
  - Configuration/Profiles/Main/Paleo/temporal.yml
  - Configuration/Profiles/Main/Modern/spatial.yml
  - Configuration/Profiles/Validation/cz_smoke.yml
  - Configuration/Profiles/References/cross_validation.yml
  - Configuration/Profiles/One_time/Issues/issue_138.yml
  - Configuration/Profiles/One_time/Issues/issue_143.yml
```

The generator must:

1. read the manifest and verify every listed fragment exists;
2. parse fragments with `yaml` and reject duplicate top-level profile names;
3. require exactly one `default` profile;
4. validate `_profile` metadata, inheritance references, acyclicity, and a
   documented maximum inheritance depth;
5. assemble fragments in manifest order, preserving `!expr` values and useful
   comments;
6. parse the combined temporary file and resolve every selectable profile with
   `config::get()`;
7. compare every resolved profile with the versioned semantic reference;
8. write the tracked root `config.yml`; and
9. generate `Configuration/Generated/profile_catalog.md` with each profile's
   role, status, pipeline, inheritance, issue, and supported runner.

The generated file starts with a prominent source and regeneration notice. CI
or an equivalent repository check regenerates it in a temporary location and
fails when the tracked result is stale.

The initial migration is structural only. All 26 current profile IDs and their
resolved values remain semantically identical. New base profiles may reduce
duplication only when equivalence is proven for every descendant, and
inheritance must remain shallow enough to understand from the generated
catalog. Profile renames or parameter changes require later, separately
approved behavior migrations.

The authoring workflow is:

1. edit the appropriate categorized fragment;
2. regenerate `config.yml` and the profile catalog;
3. review both the fragment diff and resolved-profile equivalence;
4. run affected manifests and smoke checks; and
5. commit the source, generated artifact, catalog, and tests together.

---

## Naming contract

The standard is semantic, not merely a short allowlist. Each canonical verb
must document its return behavior, side effects, allowed scope, forbidden
synonyms, and examples in `.ai/r-coding.md`.

| Verb | Contract | Replace or disambiguate |
|---|---|---|
| `load_` | Retrieve an existing persistent object from a file, database, URL, target store, or configuration source. | Replace persistent-I/O uses of `read_`, `get_`, `extract_`, and `collect_`. |
| `save_` | Persist an object or artifact. | Replace ambiguous `write_` where the operation is project-level persistence. |
| `build_` | Construct a new structured object from supplied inputs without persistent I/O. | Replace `make_`, `assemble_`, and `generate_` when they mean construction. |
| `prepare_` | Transform data into a documented workflow-ready or model-ready contract. | Do not use for generic mutation or selection. |
| `validate_` | Enforce a contract and abort on invalid input or state. | Replace enforcement uses of `check_`, `verify_`, and `assert_`. |
| `diagnose_` | Return explanatory findings without defining model performance. | Replace diagnostic uses of `check_` and `assess_`. |
| `is_` / `has_` | Return a scalar or shape-documented logical predicate. | Do not use `check_` for predicates. |
| `resolve_` | Apply an explicit deterministic policy or fallback to choose one operational value or status. | Replace ambiguous `adapt_`, `calibrate_`, or `configure_` uses. |
| `compute_` | Return a pure mathematical or algorithmic result without evaluative judgement. | Distinguish from `evaluate_` and `diagnose_`. |
| `aggregate_` | Combine observations or evidence into grouped domain records. | Distinguish from `summarise_`. |
| `summarise_` | Reduce data to summary statistics or a reporting table. | Do not use for raw collection. |
| `fit_` | Fit a statistical or machine-learning model. | No generic `run_` for individual fits. |
| `predict_` | Generate predictions from a fitted model or documented predictive artifact. | Keep prediction side effects separate. |
| `score_` | Compute a documented metric set for one prediction/evidence contract. | Distinguish from broader model evaluation. |
| `evaluate_` | Produce a standardised performance or quality assessment from scores or fitted/predictive evidence. | Replace evaluative `assess_`. |
| `select_` | Choose rows, variables, candidates, or a winning model using a documented rule. | Do not use `get_`. |
| `run_` | Orchestrate a multi-step workflow with material side effects or pipeline execution. | Prohibited for row-level or single-calculation helpers. |
| `plot_` | Return a plot object without saving it. | Saving belongs to `save_`. |
| `render_` | Materialise a document or multi-file rendered output. | Keep distinct from returning a plot object. |

Precise domain verbs remain allowed when they remove ambiguity, including
`filter_`, `classify_`, `interpolate_`, `scale_`, `project_`, `cluster_`,
`deduplicate_`, and `normalise_`. Each must have one meaning across the
repository.

### Extraction versus loading

`extract_` is allowed only for selecting a component from an already in-memory
object. It must never mean reading a file, database, target store, or remote
resource. All persistent retrieval uses `load_`.

Configuration retrieval follows the same contract. Rename
`get_active_config()` to `load_active_config()`, update all callers, and make it
the canonical runtime boundary around `config::get()`. Direct package calls
remain only in the loader, configuration generator/equivalence tooling, and
focused tests. Do not retain a compatibility alias unless the caller inventory
demonstrates an active external consumer.

### Vague variants

Do not create pairs such as `xxx()` and `xxx_simple()` or `xxx_basic()`.

For each existing or proposed variant:

1. Use a strategy-specific name such as `_grouped`, `_pooled`,
   `_from_shared_inputs`, `_without_spatial_effect`, or
   `_for_reference_profile` when the distinction is a real domain concept.
2. Use a documented `method` or `strategy` argument when the input/output
   contracts are identical and only one policy axis differs.
3. Use separate domain names when the algorithms or contracts are genuinely
   different.
4. Do not use `new`, `old`, `final`, `temp`, `simple`, or `basic` as a semantic
   variant. `test` is allowed only for an actual training/test split or test
   fixture.

### Object names

Use type- and role-explicit prefixes where the type is stable:

- `data_`, `table_`, `list_`, `vec_`, `mat_`, `mod_`, and `plot_`;
- `path_`, `file_`, `dir_`, and `store_`;
- `config_`, `flag_`, `seed_`, `index_`, `formula_`, and `n_`;
- `res_` only for a function's explicit return object.

Use state suffixes such as `_raw`, `_validated`, `_aligned`, `_filtered`,
`_prepared`, `_selected`, and `_summary`. Do not reassign a transformed object
under the same name.

Local object renames occur inside the domain/function batch that owns the
code. A later repository-wide local-variable pass is prohibited because it
would create large low-value diffs. Persisted targets, artifact fields, store
names, and configuration keys are inventoried separately because renaming them
may invalidate stores or require a compatibility migration.

---

## README contract for non-main workflows

Every diagnostic, validation, sensitivity, benchmark, experiment, archived, or
one-time-script folder must contain a README with:

- purpose and backstory;
- active, reference, experimental, or archival status;
- supported entry point;
- prerequisites, configuration, and expected data/store state;
- exact run command;
- outputs and their locations;
- interpretation limits;
- regeneration policy;
- retirement or archival criteria; and
- related issue, PR, report, or scientific decision.

An issue number may remain in a durable path only under
`One_time/Issues/<issue>/` or an equivalent explicit historical evidence
folder.

---

## Migration control artifacts

Create versioned inventories before moving code:

1. `r_script_path_inventory_v1.csv`
   - current path;
   - intended path;
   - classification;
   - active/archival status;
   - owning issue;
   - callers and documentation references.
2. `r_function_inventory_v1.csv`
   - current path and function;
   - intended path and function;
   - canonical verb decision;
   - callers;
   - matching test;
   - nested-helper disposition;
   - owning issue.
3. `r_contract_inventory_v1.csv`
   - public/frozen target or field;
   - persisted but internal target/artifact;
   - private target/object;
   - migration permission;
   - store invalidation or compatibility consequence.
4. `r_naming_decisions_v1.md`
   - canonical verb contracts;
   - allowed domain verbs;
   - rejected synonyms;
   - difficult case-by-case decisions.
5. `configuration_profile_inventory_v1.csv`
   - profile ID and current source;
   - target fragment;
   - role, status, and selectability;
   - pipeline and inheritance parent;
   - target store and active consumers;
   - related issue and retirement criterion;
   - public, frozen, or internal status.
6. `configuration_profile_reference_v1.rds`
   - resolved values for all 26 profiles before the structural migration;
   - stable semantic hashes used for equivalence checks;
   - the `{config}` and R versions used to create the reference.

`Configuration/Generated/profile_catalog.md` is a regenerated human-readable
view, not a replacement for the versioned inventory or semantic reference.

Inventories are append-only within the refactor: do not delete historical names
after migration. Record status and replacement.

---

## Dependency order

```text
Standards, inventories, and loader safety
|---> Issue #141 CV simplification and CV-owned path cleanup
|---> Modular configuration sources and profile roles
|---> Non-CV script classification and relocation
      |---> Domain function/test migrations
            |---> Persisted internal target migrations
                  `---> Blocking architecture enforcement
```

Domain migrations may proceed only when they own disjoint files and do not
depend on unmerged symbol renames. Merge sequentially from updated `main`.
The configuration workstream exclusively owns structural changes to
`Configuration/**`, the generated root `config.yml`, and the canonical
configuration loader. Issue #141 consumes and validates its frozen profiles but
does not reorganise the configuration file independently.

---

## Implementation workstreams

### Define naming standards, inventories, and safe function loading

**Goal:** Establish enforceable architecture contracts and a reliable baseline
before any large move.

**Tasks:**

- [ ] Create the four versioned inventories listed above.
- [ ] Classify all 39 main-analysis scripts and every active pipeline/function
  file.
- [ ] Mark every target/artifact as public/frozen, persisted-internal, or
  private.
- [ ] Update the R coding/function guidance through the repository's
  proposal-first approval workflow.
- [ ] Make function loading deterministic by sorting paths explicitly.
- [ ] Reject duplicate top-level function symbols and duplicate basenames.
- [ ] Reject function-file basename mismatches and multiple top-level function
  declarations.
- [ ] Reject top-level executable code in function files unless explicitly
  allowlisted and justified.
- [ ] Verify legacy exclusions are explicit rather than dependent on incidental
  path matching.
- [ ] Add report-only checks for script classification, folder placement,
  naming, and stale path references.

**Validation:**

- Parse every active `.R` file.
- Start a clean R session and source the complete function tree.
- Compare the before/after loaded function-symbol inventory.
- Run focused loader/architecture tests.
- Generate all pipeline manifests.
- Run a fresh-store small CZ pipeline slice.
- Run the full test suite because shared loading infrastructure changes.
- Run the mandatory change-review workflow before merging.

### Modularise and type pipeline configuration profiles

**Goal:** Keep `{config}` at runtime while making main, smoke, reference, and
one-time profiles easy to locate, inspect, and select safely.

**Owned scope:**

- `Configuration/**`
- the generated and tracked root `config.yml`
- the canonical configuration loader and configuration role guards
- configuration generator, catalog, equivalence, and drift tests
- direct `config::get()` consumers

**Tasks:**

- [ ] Create the approved `Configuration/` tree, README, and deterministic
  manifest.
- [ ] Create the configuration profile inventory and semantic reference for all
  26 current profiles before changing their structure.
- [ ] Split the current flat profiles into default, base, main, validation,
  reference, and issue-specific source fragments.
- [ ] Preserve every existing profile ID and resolved value.
- [ ] Introduce only proven-equivalent base profiles and document a shallow
  maximum inheritance depth.
- [ ] Add complete `_profile` role, status, selectability, pipeline, issue, and
  retirement metadata.
- [ ] Build the deterministic generator for the tracked root `config.yml` and
  generated profile catalog.
- [ ] Preserve `{config}` features such as `!expr` and comments during assembly.
- [ ] Rename `get_active_config()` to `load_active_config()`, update its callers,
  and centralise direct `config::get()` calls behind it.
- [ ] Add role/selectability guards so normal production runners reject base,
  reference, archived, and one-time profiles.
- [ ] Add README backstory, supported commands, outputs, and retirement policy
  for historical issue-profile folders.
- [ ] Add a blocking check that the generated `config.yml` and catalog match
  their sources.
- [ ] Do not delete or rename profiles until the caller and historical-reference
  inventory proves the migration safe and the user separately approves it.

**Validation:**

- Deep-compare and hash old/new resolved configuration values for all 26
  profiles, including target-store, seed, graphical, data-processing,
  model-fitting, and scientific-performance fields.
- Require exactly one `default`; reject duplicate profile keys, missing
  fragments, incomplete metadata, unknown parents, inheritance cycles, and
  excessive inheritance depth.
- Resolve every selectable profile from the generated file with
  `config::get()`.
- Verify every source fragment is listed exactly once in the manifest and every
  manifest fragment is documented.
- Verify direct `config::get()` calls remain only in the canonical loader,
  generator/equivalence tooling, and focused tests.
- Regenerate in a temporary location and prove the tracked `config.yml` and
  profile catalog are current.
- Generate all affected pipeline manifests.
- Run fresh CZ paleo and modern smoke workflows.
- Verify the frozen Issue #141 profile IDs and exact resolved values. If any
  value changes, stop treating the change as structural and require the full
  Issue #138 paired benchmark and separate approval.
- Run focused configuration/runner tests, the full test suite, and the mandatory
  change-review workflow before merging.

### Simplify the optimised cross-validation architecture and close #141

**Goal:** Remove demonstrated CV duplication and clarify ownership while
preserving the accepted scientific, public, store, and performance contracts.

**Owned scope:**

- `R/Functions/Modelling/Cross_validation/**`
- CV-related functions in neighbouring modelling/pipeline folders
- the three CV pipe segments and their target builders
- tier-tuning and common-regularisation pipelines
- CV-related runner/store orchestration
- CV tests and fixtures
- CV reference, benchmark, Issue #138, Issue #139, and Issue #143 scripts and
  documentation
- CV-owned scripts currently misplaced in `R/02_Main_analyses`

The configuration workstream owns the structural reorganisation of
`config.yml`. Issue #141 validates and consumes its frozen CV profiles but does
not rename them, change their resolved values, or edit the configuration
architecture independently.

**Tasks:**

- [ ] Split CV functions into assignments, feasibility, fold preparation,
  candidate design, tuning planning/execution/aggregation/selection,
  prediction, evaluation, contracts, and provenance.
- [ ] Apply the canonical verb decisions to CV functions and matching files,
  tests, callers, and generated documentation.
- [ ] Extract the deferred named nested helpers from
  `run_sjsdm_selected_candidate_folds.R`,
  `prepare_fold_spatial_predictors.R`, and
  `prepare_model_fold_input.R`, plus other coherent CV-owned helpers.
- [ ] Extract the multi-statement tier-tuning `tar_target()` command deferred as
  CV-015.
- [ ] Consolidate demonstrated typed-empty schema, status, provenance, and
  target-building duplication.
- [ ] Separate fold preparation, fitting, prediction, scoring, selection, and
  target declaration responsibilities.
- [ ] Simplify runner sequencing and target-store reads without combining
  isolated stores.
- [ ] Localise the deferred CV test fixtures.
- [ ] Add the deferred roxygen examples where executable examples are safe.
- [ ] Move CV-specific diagnostics, reference generators, benchmark runners,
  and issue reproductions from main analyses into the new supplementary tree,
  with standard READMEs.
- [ ] Remove CV dead paths only after caller and reference inventories prove
  them unused.
- [ ] Update #135, PR #137 documentation, #140, and #141 closure evidence to
  describe the final architecture.

**Slice gates:**

For every mergeable slice:

- parse changed R files;
- source the function tree in a clean session;
- run the focused tests;
- compare old/new caller and symbol inventories;
- generate affected manifests;
- run a fresh-store small representative `tar_make()` slice;
- verify no stale old-path or old-symbol references remain outside the
  inventory and historical records.

For every shared-infrastructure or performance-sensitive slice, also run the
full suite and the relevant public-contract comparisons.

**Closure validation:**

- Preserve the Issue #139 public target, schema, status, provenance, grouped
  assignment, and correctness-reference contracts.
- Match the paired CZ schema hash
  `2d727fd54623501e0ac384e0674c17f3`.
- Match the grouped-assignment hash
  `ec5dcdda6049a504cb0b69f845c64aa8`.
- Run fresh CZ paleo and modern workflows.
- Run applicable representative spatial/temporal workflows.
- Re-run the exact Issue #138 paired protocol.
- Retain at least 15% median and 10% per-repetition wall-time improvement.
- Retain at least 40% CV-fit reduction.
- Keep target-store growth at or below 25%.
- Keep paired peak RAM and VRAM growth at or below 10%.
- Allow no GPU-memory failure.
- Keep log-loss, AUC, Tjur R2, evaluable-taxon coverage, and candidate-selection
  changes within the accepted Issue #141 guard.
- Parse/render affected Quarto and generated documentation.
- Run the full test suite and all affected manifests.
- Complete the mandatory change-review workflow before closing #141.

### Separate non-CV main analyses from supplementary workflows

**Goal:** Make `R/02_Main_analyses` contain only stable production-facing
analyses.

**Tasks:**

- [ ] Move non-CV diagnostics such as spatial-pipeline, modern-preprocessing,
  and temporal-continent diagnostics into `Diagnostics/`.
- [ ] Move convergence tuning and other sensitivity investigations into
  `Sensitivity/`.
- [ ] Move one-time repair/rerun scripts into `One_time/` or replace them with a
  reusable supported runner when they remain operationally necessary.
- [ ] Move test/smoke runners into `Testing/Smoke/`.
- [ ] Add a README to every new non-main workflow folder.
- [ ] Rename durable scripts to lower snake case and remove numeric ordering
  where directory structure already supplies the order.
- [ ] Update all source, command, documentation, and workflow references.
- [ ] Add a blocking allowlist/classification check for
  `R/02_Main_analyses`.

**Validation:**

- Parse every moved script.
- Verify every old path has zero active references.
- Execute each supported diagnostic/validation entry point at least to its
  configuration and input-preflight boundary.
- Run the relevant smoke workflow from its new path.
- Generate affected pipeline manifests.
- Run focused tests for path/configuration helpers.
- Run a fresh-store small representative pipeline slice.
- Run the full suite if shared runner or path helpers change.
- Complete the mandatory change-review workflow before merging.

### Reorganise data-domain functions and tests

**Goal:** Give abiotic, community, trait, and time functions clear lifecycle
ownership without changing behavior.

**Domains:** `Abiotic`, `Community`, `Traits`, and `Time`.

**Per-domain tasks:**

- [ ] Perform a path-only function and mirrored-test move.
- [ ] Verify the loaded function inventory is identical.
- [ ] Rename functions and files using the approved naming map.
- [ ] Rename local objects in the functions being edited.
- [ ] Decompose coherent named nested helpers.
- [ ] Consolidate duplicated helpers only with demonstrated equivalent
  contracts.
- [ ] Remove the domain's proven dead/legacy paths.
- [ ] Update roxygen, tests, pipelines, scripts, and generated documentation.
- [ ] Turn architecture/naming checks blocking for the migrated domain.

**Validation for each domain:**

- Clean-session function-tree load and symbol comparison.
- Focused function tests and mirrored-test discovery.
- Affected pipeline manifests.
- A fresh-store small pipeline slice that exercises the domain.
- Old-path and old-symbol reference checks.
- Full suite for shared helpers or broad call graphs.
- Mandatory change review before merging each domain batch.

### Reorganise modelling functions outside cross-validation

**Goal:** Clarify model input, fitting, spatial effect, evaluation,
decomposition, tuning, and variance-partitioning ownership.

**Tasks:**

- [ ] Migrate `Fit_inputs`, `Fitting`, `Spatial_effects`, `Evaluation`,
  `Decomposition_diagnostics`, `Diagnostics`, `Tuning`, and
  `Variance_partitioning` in separate domain-sized batches.
- [ ] Separate reusable modelling logic from diagnostic or scientific-reference
  logic.
- [ ] Rename functions/files and local objects using the approved maps.
- [ ] Extract coherent named nested helpers.
- [ ] Replace the `Utility`-style cross-domain ownership that belongs to
  modelling.
- [ ] Remove proven dead/legacy modelling paths inside their owning batch.
- [ ] Update tests, manifests, runners, and generated documentation.

**Validation for each batch:**

- Clean-session source and symbol comparison.
- Focused tests.
- Affected spatial, temporal, paleo, modern, tier, and sensitivity manifests.
- A fresh-store representative model-input or model-evaluation pipeline slice.
- Contract comparison for any persisted artifact.
- Full suite for shared modelling infrastructure.
- Mandatory change review before merging.

### Reorganise pipeline, prediction, visualisation, and presentation helpers

**Goal:** Remove catch-all utility ownership and align remaining helpers with
their consumers and side effects.

**Tasks:**

- [ ] Move configuration, path/store, and orchestration helpers from `Utility`
  into explicit pipeline or infrastructure capabilities.
- [ ] Reorganise prediction helpers by inputs, inference, scaling, and
  summaries.
- [ ] Reorganise visualisation helpers by returned plot or prepared-data
  contract.
- [ ] Decide from active callers whether IAVS presentation helpers remain
  project-wide reusable functions or move beside the presentation workflow.
- [ ] Apply function/file/local-object renames inside each owned batch.
- [ ] Separate `plot_`, `save_`, and `render_` side-effect contracts.
- [ ] Remove proven dead/legacy paths and update generated documentation.
- [ ] Make architecture checks blocking for each migrated capability.

**Validation for each capability:**

- Clean-session source and symbol comparison.
- Focused tests, including file-side-effect tests in temporary directories.
- Affected manifests and render/plot smoke checks.
- Old-path and old-symbol reference checks.
- Full suite when pipeline/store helpers change.
- Mandatory change review before merging.

### Migrate persisted internal targets and artifacts

**Goal:** Standardise internal persisted names without breaking frozen public
contracts or silently invalidating stores.

**Tasks:**

- [ ] Exclude Issue #141 public target names and artifact fields by default.
- [ ] For each proposed internal target rename, record consumers, store
  invalidation, restart impact, and compatibility requirements.
- [ ] Prefer leaving a persisted name unchanged when the clarity gain does not
  justify invalidating expensive stores.
- [ ] Require explicit user approval for any public/frozen migration.
- [ ] Add compatibility tests before an approved artifact/schema migration.
- [ ] Rename private targets only inside the pipeline batch that owns them.
- [ ] Record which stores need a clean rebuild and which can resume.
- [ ] Remove old internal names only after every consumer and generated document
  is migrated.

**Validation for each migration:**

- Before/after `tar_manifest()` comparison.
- Public target-name inventory equality.
- Artifact schema/status/provenance comparison.
- Fresh-store small execution plus documented resume check.
- Target-store invalidation check.
- Focused tests and full suite for shared artifacts.
- Applicable Issue #139 correctness references.
- Mandatory change review before merging.

### Enforce the completed architecture

**Goal:** Convert the report-only safeguards into durable blocking checks and
publish an accurate architecture map.

This workstream adds maintained tooling and documentation; it is not a deferred
cleanup or validation-only phase.

**Tasks:**

- [ ] Make duplicate-symbol, file/function mismatch, one-function-per-file,
  stale-path, folder-placement, and migrated-domain naming checks blocking.
- [ ] Add explicit exceptions only with owner, rationale, and review date.
- [ ] Generate the final R architecture and dependency map.
- [ ] Regenerate function documentation and coverage reports.
- [ ] Verify README completeness for every non-main workflow folder.
- [ ] Update repository instructions to describe the new structure and naming
  contracts.
- [ ] Close the umbrella only when every deferred exception has an accepted
  follow-up issue.

**Validation:**

- Run the architecture checks from a clean checkout/session.
- Parse all R and Quarto source.
- Run the full test suite.
- Generate every pipeline manifest.
- Run the documented small end-to-end smoke workflows.
- Render affected generated/function documentation.
- Complete the mandatory change-review workflow before umbrella closure.

---

## Risks and mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| A mass move obscures behavioral changes | High | Separate path-only moves from semantic renames and decomposition within each domain. |
| Recursive loading hides duplicate functions or source-order assumptions | High | Harden the loader and test clean-session loading before deeper nesting. |
| Public CV contracts change accidentally | High | Keep #141 bounded; compare frozen names, hashes, schemas, statuses, and correctness references. |
| Refactoring regresses staged CV performance | Medium | Run the exact Issue #138 protocol after shared/performance-sensitive changes and at #141 closure. |
| Generated `config.yml` drifts from its sources | High | Track the generated artifact and fail a regeneration comparison in repository checks. |
| Configuration inheritance becomes harder to understand | Medium | Limit inheritance depth, reject cycles, and generate a resolved profile catalog. |
| A reference or one-time profile is used by a main runner | High | Enforce role and selectability metadata at the canonical runner boundary. |
| Structural configuration changes alter parameter values | High | Deep-compare all 26 resolved profiles against a versioned pre-migration reference. |
| Target renames invalidate expensive stores | High | Classify persisted contracts, quantify invalidation, and require explicit migration approval. |
| Local-variable cleanup creates unreviewable diffs | High | Rename locals only in the function/domain batch already changing that code. |
| Test discovery misses nested tests | Medium | Add an executable nested-discovery fixture before mirroring the test tree. |
| Windows case-only moves behave inconsistently | Medium | Avoid case-only steps; use explicit temporary paths when implementation requires a case change. |
| Generated documentation retains stale paths | High | Track generated consumers in inventories and regenerate within each owning batch. |
| One-time scripts become unexplained permanent code | Medium | Require README status, exact command, regeneration policy, and retirement criteria. |
| Multiple long-lived branches drift from main | Medium | Merge sequential domain issues from updated `main`; use disjoint ownership only for safe parallel work. |
| A final cleanup bucket accumulates deferred work | Medium | Remove dead paths and enable blocking checks inside each domain closure gate. |

---

## Open decisions

- Whether a later, separately approved migration should rename the four
  top-level R roots after their contents are stable. This plan assumes they
  remain unchanged initially.
- Whether IAVS presentation helpers still have active project-wide consumers or
  should live beside the presentation.
- Which persisted internal target names provide enough clarity benefit to
  justify clean-store invalidation.
- Whether a later behavior migration should rename configuration profile IDs.
  This plan preserves every current ID during the structural migration.
- Whether to create the proposed GitHub umbrella and child issues now.

These decisions do not block the standards/inventory/loader workstream.

---

## GitHub issues scaffold

### Existing Issue #141

Keep
[#141](https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/141)
as a child of #140. Update its body only through an explicitly approved GitHub
write after the path/function inventories identify its exact owned files. Add
the existing `🏗️refactor` label if the user approves; preserve its existing
labels and metadata.

### Umbrella issue #149

**Title:** Refactor R code architecture and naming contracts

**Suggested existing labels:** `💻code`, `🏗️refactor`, `🔀pipeline`

**Body:**

```markdown
## Background

The R codebase has outgrown its current folder and naming structure. Main
analysis folders mix production workflows with diagnostics, benchmarks,
reference generators, and issue-specific runners. Reusable functions use many
overlapping verbs and several capability folders are too large to navigate.
The flat `config.yml` also mixes main pipelines, smoke profiles, scientific
references, and one-time issue profiles without explicit roles.

Issue #141 separately owns simplification of the optimised cross-validation
architecture under frozen scientific, public-artifact, store, and performance
contracts. This umbrella coordinates the broader repository refactor without
reparenting or weakening #141.

## Goal

Make every active R script, function, test, target, and generated document easy
to locate and name consistently, while keeping affected pipelines runnable
after every mergeable batch.

## Approach

- Define versioned path, function, contract, and naming inventories first.
- Harden recursive function loading before deepening the hierarchy.
- Keep `{config}`, but author categorized fragments under `Configuration/` and
  generate the tracked root `config.yml`.
- Give profiles explicit role, lifecycle, and selectability metadata.
- Keep #141 bounded to CV-owned architecture and files.
- Move and rename code in domain-sized batches.
- Rename local objects only inside their owning domain changes.
- Migrate persisted names only with explicit invalidation and compatibility
  decisions.
- Introduce architecture checks in report-only mode, then make them blocking as
  domains migrate.

## Acceptance criteria

- [ ] `R/02_Main_analyses` contains only stable main analyses.
- [ ] Every non-main diagnostic, validation, experiment, benchmark, or one-time
      folder has a standard README.
- [ ] The function and test trees follow the approved hierarchy.
- [ ] Function names follow documented semantic verb contracts.
- [ ] `config.yml` is generated deterministically from categorized,
      human-authored sources.
- [ ] All 26 existing profiles retain their IDs and resolved values in the
      structural migration.
- [ ] Main runners reject reference, archived, base, and one-time profiles.
- [ ] No vague `simple`, `basic`, `new`, `old`, or `final` variant remains
      without an explicit domain meaning.
- [ ] No duplicate function symbols, filename/function mismatches, or
      unexplained nested named helpers remain.
- [ ] Public/frozen CV targets and artifacts remain compatible.
- [ ] Each child owns its validation and mandatory review closure.
- [ ] Blocking architecture checks and current architecture documentation are
      in place.

## Related required work

- #141 Simplify the optimized cross-validation architecture

## Sub-issues

- [ ] Define R naming inventories and harden function loading
- [ ] Modularise and type pipeline configuration profiles
- [ ] Separate main analyses from supplementary workflows
- [ ] Reorganise data-domain functions and tests
- [ ] Reorganise modelling functions outside cross-validation
- [ ] Reorganise pipeline, prediction, visualisation, and presentation helpers
- [ ] Migrate persisted internal target and artifact names
- [ ] Enforce R architecture contracts and publish the final map
```

### Child issue #150: Define R naming inventories and harden function loading

**Body:**

```markdown
## Context

Deeper nesting and large renames are unsafe until every file and persisted
contract has an owner and recursive loading rejects ambiguous definitions.

## Tasks

- Create versioned script-path, function-name, contract, and naming-decision
  inventories.
- Define semantic verb and object-name contracts.
- Sort function source paths deterministically.
- Reject duplicate symbols/basenames, basename mismatches, multiple top-level
  declarations, and unapproved top-level executable code.
- Add report-only placement, naming, and stale-reference checks.

## Validation

- Parse every active R file.
- Source the full function tree in a clean session.
- Compare loaded symbol inventories.
- Run loader tests, all manifests, a fresh small CZ slice, and the full suite.
- Complete the mandatory change review before closure.

## Links

- Part of: Refactor R code architecture and naming contracts
- Enables: #141 and all repository domain migrations
```

### Child issue #151: Modularise and type pipeline configuration profiles

**Body:**

```markdown
## Context

The flat `config.yml` mixes main pipelines, smoke workflows, scientific
references, and issue-specific one-time profiles. The repository should retain
the proven `{config}` runtime behavior while making configuration authoring and
profile selection navigable and safe.

This is a structural migration. Existing profile IDs and resolved values,
including the frozen Issue #141 profiles, must remain unchanged.

## Tasks

- Create `Configuration/` with default, base, main, validation, reference, and
  one-time issue source folders, plus a README and ordering manifest.
- Inventory all 26 current profiles, their consumers, stores, roles, lifecycle,
  inheritance, and issue ownership.
- Create a versioned semantic reference of every resolved profile.
- Add `_profile` role, status, selectability, pipeline, issue, and retirement
  metadata.
- Build deterministic generation of the tracked root `config.yml` and a
  searchable profile catalog.
- Preserve `{config}` expressions and comments and keep inheritance shallow.
- Rename `get_active_config()` to `load_active_config()`, update all callers,
  and centralise runtime access.
- Make production runners reject base, reference, archived, and one-time
  profiles unless a dedicated runner explicitly authorises them.
- Add backstory and retirement documentation for issue-profile folders.
- Add a blocking generated-file drift check.

## Validation

- Deep-compare and hash all 26 old/new resolved profiles.
- Reject duplicate keys, missing or duplicated manifest fragments, multiple
  defaults, incomplete metadata, unknown parents, cycles, and excessive
  inheritance depth.
- Resolve every selectable profile through the generated file.
- Verify direct `config::get()` calls are limited to the canonical loader,
  generator/equivalence tooling, and tests.
- Regenerate in a temporary location and compare the tracked output and catalog.
- Generate affected manifests and run fresh CZ paleo and modern smoke workflows.
- Verify exact Issue #141 profile IDs and resolved values; any difference
  requires separate approval and the full Issue #138 paired benchmark.
- Run focused tests, the full suite, and the mandatory change review.

## Links

- Part of: Refactor R code architecture and naming contracts
- Related: #141 for frozen CV-profile validation
```

### Child issue #152: Separate main analyses from supplementary workflows

**Body:**

```markdown
## Context

`R/02_Main_analyses` currently mixes stable analyses with diagnostics,
sensitivity work, repair scripts, tests, and issue-specific evidence. CV-owned
files remain owned by #141; this issue owns the remaining classified scripts.

## Tasks

- Move diagnostics, sensitivity studies, repair scripts, and smoke tests to the
  approved supplementary tree.
- Rename durable scripts consistently and update every active reference.
- Add standard READMEs with commands, outputs, interpretation, regeneration,
  and retirement policy.
- Make the main-analysis placement check blocking.

## Validation

- Parse and preflight every moved entry point.
- Verify zero active references to old paths.
- Run relevant smoke workflows, affected manifests, and a fresh small pipeline
  slice.
- Run the full suite when shared path/runner helpers change.
- Complete the mandatory change review before closure.

## Links

- Part of: Refactor R code architecture and naming contracts
- Related: #141 for CV-owned script moves
```

### Child issue #153: Reorganise data-domain functions and tests

**Body:**

```markdown
## Context

Abiotic, community, trait, and time functions need explicit ingest,
transformation, classification, quality-control, and validation ownership.

## Tasks

- Migrate one data domain at a time.
- Separate path-only moves from semantic renames.
- Mirror tests, rename local objects in touched functions, and extract coherent
  nested helpers.
- Remove proven dead paths and make checks blocking for each migrated domain.

## Validation

- For every domain: clean-session source and symbol comparison, focused tests,
  affected manifests, a fresh small exercising pipeline slice, and old-reference
  checks.
- Run the full suite for shared helpers.
- Complete the mandatory change review before each domain merge.

## Links

- Part of: Refactor R code architecture and naming contracts
```

### Child issue #154: Reorganise modelling functions outside cross-validation

**Body:**

```markdown
## Context

Model inputs, fitting, spatial effects, evaluation, decomposition, tuning, and
variance partitioning need explicit ownership. Cross-validation remains owned
by #141.

## Tasks

- Migrate each modelling capability in its own reviewable batch.
- Separate reusable modelling logic from diagnostic/reference logic.
- Apply approved function/file/local-object names and extract coherent helpers.
- Remove proven dead/legacy paths inside their owning batch.

## Validation

- Run clean-session source checks, focused tests, affected manifests, and a
  fresh representative modelling slice per capability.
- Compare persisted artifact contracts where applicable.
- Run the full suite for shared modelling infrastructure.
- Complete the mandatory change review before each merge.

## Links

- Part of: Refactor R code architecture and naming contracts
- Related: #141
```

### Child issue #155: Reorganise pipeline, prediction, visualisation, and presentation helpers

**Body:**

```markdown
## Context

Remaining utility, pipeline, prediction, visualisation, and presentation helpers
mix configuration, orchestration, inference, plot construction, and side
effects.

## Tasks

- Replace catch-all utility ownership with explicit configuration, path/store,
  and orchestration capabilities.
- Reorganise prediction and visualisation helpers by contract.
- Decide the active ownership of IAVS presentation helpers.
- Distinguish plot-return, save, and render functions.
- Apply approved function/file/local-object names and remove proven dead paths.

## Validation

- Run clean-session source checks, focused and side-effect tests, affected
  manifests, and relevant render/plot smoke checks.
- Run the full suite when shared pipeline/store helpers change.
- Complete the mandatory change review before each capability merge.

## Links

- Part of: Refactor R code architecture and naming contracts
```

### Child issue #156: Migrate persisted internal target and artifact names

**Body:**

```markdown
## Context

Persisted internal names cannot be treated like local variables because renames
may invalidate expensive target stores or require compatibility migrations.
Issue #141 public targets and artifact fields are frozen by default.

## Tasks

- Inventory consumers, invalidation, resume, and compatibility effects for each
  proposed persisted rename.
- Leave low-value persisted names unchanged.
- Obtain explicit approval for any public/frozen migration.
- Add compatibility tests before approved schema changes.
- Document clean rebuild and resume consequences.

## Validation

- Compare manifests and public target inventories before/after.
- Compare schemas, statuses, and provenance.
- Run fresh-store small executions and documented resume checks.
- Run focused tests, the full suite for shared artifacts, and applicable Issue
  #139 correctness references.
- Complete the mandatory change review before closure.

## Links

- Part of: Refactor R code architecture and naming contracts
- Blocked by the owning domain migrations
```

### Child issue #157: Enforce R architecture contracts and publish the final map

**Body:**

```markdown
## Context

Report-only safeguards must become maintained blocking checks as migrated
domains reach their approved structure.

## Tasks

- Make duplicate-symbol, file/function mismatch, one-function-per-file,
  stale-path, placement, and naming checks blocking.
- Maintain explicit, owned, time-bounded exceptions.
- Publish the final architecture/dependency map.
- Regenerate function documentation and coverage reports.
- Verify README completeness and update repository guidance.

## Validation

- Run checks from a clean session, parse all R/Quarto source, run the full
  suite, generate every manifest, run documented smoke workflows, and render
  affected documentation.
- Complete the mandatory change review before umbrella closure.

## Links

- Part of: Refactor R code architecture and naming contracts
- Blocked by all domain migrations
```

---

## Recommended next action

Begin #150 and the inventory/reference portion of #151 from updated `main`.
Implement and validate the configuration generator before mass script moves or
configuration edits. Do not begin mass moves or renames until the inventories,
loader checks, and structural configuration equivalence gates are accepted.
