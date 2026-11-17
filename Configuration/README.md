# Project configuration

`Configuration/` is the human-authored source for the repository's runtime configuration. The root `config.yml` remains tracked because `{config}` reads that conventional location, but it is generated and must not be edited directly.

## Structure

- `Defaults/` contains the single shared `default` profile.
- `Bases/` is reserved for proven-equivalent, non-selectable shared profiles.
- `Profiles/Main/` contains supported production profiles.
- `Profiles/Validation/` contains small smoke profiles.
- `Profiles/References/` contains frozen scientific or implementation references used by dedicated runners.
- `Profiles/One_time/Issues/` contains historical issue-specific profiles and their retirement context.
- `Generated/` contains the searchable generated profile catalog.
- `manifest.yml` is the only fragment-ordering authority.

Every profile has a complete `_profile` block describing its role, lifecycle, selectability, owning pipeline, purpose, related issue, retirement criterion, and supported runner.

## Authoring workflow

From the repository root:

```powershell
Rscript R/03_Supplementary_analyses/Validation/Configuration/Generate_configuration.R
Rscript R/03_Supplementary_analyses/Validation/Configuration/Check_configuration.R
```

The generation command validates the manifest and fragments, compares all resolved legacy fields with the version-one semantic reference, then writes `config.yml` and `Configuration/Generated/profile_catalog.md`.

The check command regenerates both artifacts in a temporary directory and fails if either tracked artifact is stale.

Commit the edited fragments, generated root file, generated catalog, and any affected tests together.

## Profile-selection policy

Normal production runners accept only `main` and `smoke` roles. Frozen `reference` and `one_time` profiles require a dedicated runner to authorize their role explicitly. `base` and `archived` profiles cannot be run.

The initial issue #151 migration is structural. Existing profile identifiers and legacy resolved values are frozen by `Documentation/Implementation_inventories/Configuration/configuration_profile_reference_v1.rds`.

Intended changes to resolved profiles update the reference only through `R/03_Supplementary_analyses/Validation/Configuration/Update_configuration_reference.R`. Each changed key path is first declared, with its issue and rationale, in `Documentation/Implementation_inventories/Configuration/configuration_reference_changes.csv` (`profile_id` may be `*` for every profile, and `<path>[order]` declares a change of key order). The update aborts on any undeclared difference, recomputes the semantic hashes, and appends the applied changes to the reference's `revision_changes`. Generation also checks that every spatial-grid continent has an entry in `spatial_crs_by_continent`, that no continent outside Europe uses EPSG:3035, and that every main temporal profile sets `continent_id`.

The independently validated `model_fitting.cross_validation.grouped_fold_ladder` is an approved post-reference policy extension. It defaults to 5, 10, 20, and 50 folds: retain the existing initial design when feasible, otherwise test larger grouped designs before leave-one-location-out. Every training partition and configured repeat must pass existing feasibility checks. The policy is loaded through a CV-only target and excluded from general model configuration, preventing this setting alone from invalidating interpolation or other heavy preparation. Existing fit-budget extensions and this ladder are excluded only from the frozen legacy-field comparison, not from runtime CV evidence or configuration validation.
