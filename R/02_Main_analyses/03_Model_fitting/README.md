# Stage 03: model fitting

Run `01_run_model_fitting.R` after stage 02. It executes paleo spatial, modern spatial, and paleo temporal tuning and final fitting in dependency order. The component scripts do not contain a preparation mode and cannot be switched into one with an environment variable.

Existing target stores are reused. A genuine upstream content change may make preprocessing outdated through normal `{targets}` dependency tracking; a runner-path or profile-authorization change alone must not do so.

When prepared CV folds need rebuilding, the preparation target compares complete current and cached analytical records. Exact equality preserves the original cached record, including its historical runtime and memory measurements, so changing those operational measurements alone does not invalidate completed tuning. Changed responses, predictors, sample identities, fold assignments, scaling, spatial strategy or other analytical fields follow normal dependency invalidation. CV-fitting budgets remain separate dependencies and are not exempt from this check. Missing or failed caches are rebuilt normally; there is no blanket cache override.

## Modern regional/local preparation checks

The modern regional and local components begin with `run_sjsdm_unit_fitting_preflight()`. It reads cached preparation evidence separately for genus, family, and modern functional types. Registered failed preparation roots are reattempted once per unit through the canonical runner, requesting only those roots; `{targets}` checks current command, configuration, and input hashes. This does not request CV candidates, final models, or a full preprocessing pass. A previously failed root that now succeeds blocks fitting with the stage 01 recovery command, because its preparation/calibration evidence must be refreshed rather than silently retaining a stale exclusion.

A shared data limitation excludes the entire unit. A resolution-specific limitation excludes only that resolution, retaining other viable models. Missing folds, unreadable evidence, unexplained root errors, and unexpected production tuning failures block tier selection. Expected exclusions are written to timestamped `modern_*_preparation_plan_*.csv` files, and final unit statuses to `modern_*_unit_status_*.csv`, under `Data/Temp/Main_analysis_execution/03_model_fitting/`.

Resolution-aware tuning requests are also saved as `sjsdm_tier_unit_requests.csv` immediately under the configured tier store root, outside the internal targets metadata/object directories. Its columns are `source_store` (absolute unit-store path) and `target_name` (eligible public tuning artifact). The always-cued tier summary target reads exactly those pairs; the summary's content hash controls downstream tier selection. The fitting orchestrator overwrites this sidecar from the verified plan on each invocation. Run the fitting component, not the tier pipeline directly, to refresh exclusions. Pipelines without a sidecar retain the complete Cartesian store-resolution contract.

Existing analytical objects are retained, not forcibly reset. Normal downstream invalidation still applies if the eligible tier evidence or selected regularization changes; retaining caches is not an instruction to reuse incompatible selections or models.

A missing-`qs` message alone is not evidence of a legacy-format cache. Endpoint diagnostics first distinguish an absent serialized object from an existing unreadable object. A reader-fallback or empty-branch cascade is expected only alongside a registered current data root; unrelated software failures remain blocking. No package installation, scientific threshold change, or blanket store reset is part of this handling.
