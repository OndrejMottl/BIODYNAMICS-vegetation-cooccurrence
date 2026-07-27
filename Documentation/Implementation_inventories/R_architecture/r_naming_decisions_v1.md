# R naming decisions, version 1

## Status

Approved baseline for issues #149 and #150. Domain-specific renames remain
owned by their migration issues and must update
`r_function_inventory_v1.csv` before implementation.

## Function-name contract

Function names use lower snake case, begin with a verb, and describe the
returned value or material side effect. Internal functions may begin with one
leading dot. The basename of a function file must equal its function name after
removing that internal leading dot.

| Verb | Contract |
|---|---|
| `load_` | Retrieve an existing persistent object from a file, URL, database, target store, or configuration source. |
| `save_` | Persist an object or artifact. |
| `build_` | Construct a new structured object from supplied in-memory inputs without persistent input/output. |
| `prepare_` | Transform data into a documented workflow-ready or model-ready contract. |
| `validate_` | Enforce a contract and abort when it is violated. |
| `diagnose_` | Return explanatory findings without defining model performance. |
| `is_`, `has_` | Return a scalar or explicitly shape-documented logical predicate. |
| `resolve_` | Apply a deterministic policy or fallback to choose one operational value or status. |
| `compute_` | Return a mathematical or algorithmic result without evaluative judgement. |
| `aggregate_` | Combine observations or evidence into grouped domain records. |
| `summarise_` | Reduce data to summary statistics or a reporting table. |
| `fit_` | Fit a statistical or machine-learning model. |
| `predict_` | Generate predictions from a fitted model or predictive artifact. |
| `score_` | Compute a documented metric set for one prediction or evidence contract. |
| `evaluate_` | Produce a standardised performance or quality assessment. |
| `select_` | Choose rows, variables, candidates, or a winning model using a documented rule. |
| `run_` | Orchestrate a multi-step workflow with material side effects or pipeline execution. |
| `plot_` | Return a plot object without saving it. |
| `render_` | Materialise a document or multi-file rendered output. |

Precise domain verbs are allowed when they remove ambiguity. Initially approved
domain verbs include `filter_`, `classify_`, `interpolate_`, `scale_`,
`project_`, `cluster_`, `deduplicate_`, and `normalise_`.

## Synonym decisions

These mappings identify the required semantic review. They do not authorise a
blind mechanical rename.

| Existing verb | Required decision |
|---|---|
| `get_` | Use `load_` for persistent retrieval, `select_` for policy-based choice, or `extract_` for an in-memory component. |
| `read_` | Use `load_` for project-level persistent retrieval. |
| `make_`, `assemble_`, `generate_` | Use `build_` when constructing a new object. |
| `check_`, `verify_` | Use `validate_` for enforcement, `diagnose_` for findings, or `is_`/`has_` for predicates. |
| `assess_` | Use `evaluate_`, `diagnose_`, or `resolve_` according to the returned contract. |
| `adapt_`, `calibrate_`, `configure_` | Use `resolve_` when applying an operational policy; retain a precise domain verb only when it names a distinct algorithm. |
| `collect_`, `combine_` | Use `load_`, `build_`, or `aggregate_` according to input/output behavior. |
| `compare_` | Use `evaluate_` for a standard assessment or a precise domain verb when the comparison itself is the returned scientific object. |

`extract_` is reserved for selecting a component from an object already in
memory. It must not read persistent data.

## Variant decisions

Do not create `xxx()` together with `xxx_simple()` or `xxx_basic()`. Also avoid
`new`, `old`, `final`, and `temp` as semantic variants.

Use:

1. a strategy-specific suffix such as `_grouped`, `_pooled`,
   `_from_shared_inputs`, `_without_spatial_effect`, or
   `_for_reference_profile`;
2. a documented `method` or `strategy` argument when input and output contracts
   are identical; or
3. separate domain names when contracts genuinely differ.

## Object-name contract

Use type- and role-explicit prefixes when the type remains stable:

- `data_`, `table_`, `list_`, `vec_`, `mat_`, `mod_`, and `plot_`;
- `path_`, `file_`, `dir_`, and `store_`;
- `config_`, `flag_`, `seed_`, `index_`, `formula_`, and `n_`;
- `res_` only for a function's explicit return object.

Use state suffixes such as `_raw`, `_validated`, `_aligned`, `_filtered`,
`_prepared`, `_selected`, and `_summary`. Do not overwrite an object with a
transformed state under the same name.

Persisted targets, artifact fields, stores, and configuration keys are not local
objects. Their renames require the contract inventory, invalidation analysis,
and approval described by issues #156 and #141.

## Loader decisions

- Active function paths are sorted case-insensitively with a stable radix
  tiebreak before sourcing.
- Every active function file contains exactly one top-level function declaration
  and no executable top-level expressions.
- Duplicate symbols and case-insensitive duplicate basenames are errors.
- A leading dot in an internal function is ignored only for the file-basename
  comparison.
- Legacy exclusions use exact directory-component names. Setting
  `vec_excluded_directory_names = "_legacy"` excludes every function below a
  directory named exactly `_legacy`, while names such as `not_legacy` remain
  active.
- The complete tree is validated before any file is sourced, preventing partial
  loads after an architecture error.

## Baseline interpretation

`r_function_inventory_v1.csv` records current symbols and paths without
authorising immediate repository-wide renames. `review_in_owning_issue` means
the owning domain must inspect behavior, callers, tests, persisted consequences,
and generated documentation before recording an intended replacement.
