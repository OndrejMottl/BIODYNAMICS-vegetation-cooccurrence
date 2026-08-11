# Documentation workflows

## Purpose and backstory

This root owns generated function documentation, the website, manuscript rendering, and progress visualisations.

## Status and entry point

Status: active generated-artifact workflow. Use `Document_functions.R` for function pages, `Render_website.R` for the website, and the matching renderer for manuscript or progress artifacts.

## Prerequisites and configuration

Run from the repository root with the restored R environment, Quarto, and the document-rendering dependencies required by the selected entry point.

## Outputs and interpretation

Function HTML, TXT, and PDF files are written under `Documentation/Functions/`; website sources live under `Documentation/Website/` and published pages under `docs/`.

## Regeneration and retirement

Generated function artifacts must exactly match the active function set. Regenerate after function changes and remove pages only for functions retired or excluded by the exact `_legacy` rule.
