# Supplementary classification workflows

## Purpose and backstory

These scripts build or extend auxiliary taxonomic classification inputs that support the main community-data pipeline.

## Status and entry point

Status: maintained supplementary data preparation. Review `Make_auxiliary_classification_table.R` before running it; `classification_extra.r` records the associated exploratory additions.

## Prerequisites and configuration

Run from the repository root after project setup. Confirm the tracked input tables and intended taxonomic scope before writing any auxiliary table.

## Outputs and interpretation

Outputs are classification inputs or review artifacts. They are not model results and must be inspected before use by production pipelines.

## Regeneration and retirement

Regenerate when classification sources or approved manual decisions change. Retire scripts only after their generated inputs have another documented owner.
