# Project configuration

`Configuration/` is the human-authored source for the repository's runtime
configuration. The root `config.yml` remains tracked because `{config}` reads
that conventional location, but it is generated and must not be edited
directly.

## Structure

- `Defaults/` contains the single shared `default` profile.
- `Bases/` is reserved for proven-equivalent, non-selectable shared profiles.
- `Profiles/Main/` contains supported production profiles.
- `Profiles/Validation/` contains small smoke profiles.
- `Profiles/References/` contains frozen scientific or implementation
  references used by dedicated runners.
- `Profiles/One_time/Issues/` contains historical issue-specific profiles and
  their retirement context.
- `Generated/` contains the searchable generated profile catalog.
- `manifest.yml` is the only fragment-ordering authority.

Every profile has a complete `_profile` block describing its role, lifecycle,
selectability, owning pipeline, purpose, related issue, retirement criterion,
and supported runner.

## Authoring workflow

From the repository root:

```powershell
Rscript R/03_Supplementary_analyses/Validation/Configuration/Generate_configuration.R
Rscript R/03_Supplementary_analyses/Validation/Configuration/Check_configuration.R
```

The generation command validates the manifest and fragments, compares all
resolved legacy fields with the version-one semantic reference, then writes
`config.yml` and `Configuration/Generated/profile_catalog.md`.

The check command regenerates both artifacts in a temporary directory and
fails if either tracked artifact is stale.

Commit the edited fragments, generated root file, generated catalog, and any
affected tests together.

## Profile-selection policy

Normal production runners accept only `main` and `smoke` roles. Frozen
`reference` and `one_time` profiles require a dedicated runner to authorize
their role explicitly. `base` and `archived` profiles cannot be run.

The initial issue #151 migration is structural. Existing profile identifiers
and legacy resolved values are frozen by
`Documentation/Implementation_inventories/Configuration/configuration_profile_reference_v1.rds`.
