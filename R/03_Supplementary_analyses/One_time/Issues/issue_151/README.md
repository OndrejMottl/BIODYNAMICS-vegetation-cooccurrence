# Issue 151 configuration-source bootstrap

## Purpose and backstory

This folder records the one-time structural split of the former flat root `config.yml` into categorized human-authored fragments under `Configuration/`. It exists so the source of the initial fragments and their profile metadata is reviewable rather than hidden in a manual copy operation.

## Status and entry point

Status: historical bootstrap for issue #151.

`create_configuration_profile_reference.R` records the exact pre-migration resolved values. `bootstrap_configuration_sources.R` accepts only that frozen `config.yml` and aborts after the source changes. `create_configuration_profile_inventory.R` records profile ownership and consumers after the target fragments are established.

Run from the repository root:

```powershell
Rscript R/03_Supplementary_analyses/One_time/Issues/issue_151/create_configuration_profile_reference.R
Rscript R/03_Supplementary_analyses/One_time/Issues/issue_151/bootstrap_configuration_sources.R
Rscript R/03_Supplementary_analyses/One_time/Issues/issue_151/create_configuration_profile_inventory.R
```

## Prerequisites and configuration

Reproduction requires the frozen pre-migration root `config.yml`. Do not run the bootstrap against the modular generated configuration.

## Outputs and interpretation

The script creates the initial YAML fragments under `Configuration/`. Those fragments become human-authored sources after bootstrap. The script does not regenerate or overwrite them during normal configuration maintenance.

Use the regular configuration generator and drift checker documented in `Configuration/README.md` after the initial split.

## Regeneration and retirement

Keep this folder as provenance while issue #151 or the repository-wide architecture refactor remains under review. It may be archived after the generated configuration workflow and version-one semantic reference are accepted and no longer need bootstrap-level auditability.
