# Configuration generation and validation

## Purpose and backstory

These scripts enforce issue #151's modular configuration contract. Human
maintainers edit fragments under `Configuration/`; the root `config.yml` and
profile catalog are generated compatibility artifacts.

The generator validates every source and proves that all legacy resolved
values remain identical to the version-one pre-migration reference before
writing either artifact.

## Entry points

Generate tracked artifacts:

```powershell
Rscript R/03_Supplementary_analyses/Validation/Configuration/Generate_configuration.R
```

Check for generated-file drift without modifying tracked artifacts:

```powershell
Rscript R/03_Supplementary_analyses/Validation/Configuration/Check_configuration.R
```

## Outputs

- `config.yml`
- `Configuration/Generated/profile_catalog.md`

The versioned source inventory and semantic reference live under
`Documentation/Implementation_inventories/Configuration/`.

## Interpretation and retirement

A successful generation means source structure, metadata, inheritance, and
legacy semantic values satisfy the issue #151 contract. It does not establish
scientific validity beyond the frozen reference.

These checks remain active while `{config}` and the modular source architecture
are used. They should not be retired merely because issue #151 closes.
