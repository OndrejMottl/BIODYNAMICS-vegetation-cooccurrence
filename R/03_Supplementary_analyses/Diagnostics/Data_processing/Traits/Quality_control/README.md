# Trait quality-control review workflow

## Purpose and backstory

This folder contains the human-review workflow for trait quality-control diagnostics. It was moved from the former `_Trait_qc` catch-all folder during Issue #153 so the reusable functions, automated tests, and analyst-facing review scripts have separate homes.

## Status and entry point

Status: active human-review workflow. Use the three entry points below for interactive review, parameterised report source, and batch rendering.

## Prerequisites and configuration

Run the traits reference pipeline before using these scripts. The pipeline writes the dated `trait_quality_control_report_*.csv` summary and creates the manual corrections template when it is absent.

The files serve different review modes:

- `review_trait_quality_control.R` is an interactive, one-taxon-at-a-time diagnostic and correction workflow.
- `trait_quality_control_report.qmd` is the parameterised source for batch PDF review reports.
- `render_trait_quality_control_reports.R` renders either one PDF per flagged trait domain or one combined report.

## Outputs and interpretation

Generated CSV files remain in `Data/Temp/`, reviewed correction inputs remain in `Data/Input/`, and rendered PDFs are written to `Outputs/Reports/`. These artifact locations are intentionally unchanged by the folder refactor.

## Regeneration and retirement

Regenerate reports after trait inputs or manual corrections change. Keep this workflow while trait-quality decisions require human review and an auditable report trail.
