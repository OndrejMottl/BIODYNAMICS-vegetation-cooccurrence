# Supplementary analyses

## Purpose and backstory

This tree contains supported workflows that are not production analysis entry points: diagnostics, validation, tests, documentation generation, scientific references, sensitivity analyses, and one-time provenance.

## Status and entry point

Status: active workflow collection. Enter through the README in the relevant workflow root; do not run the directory as a sequential pipeline.

## Prerequisites and configuration

Run scripts from the repository root after `R/___setup_project___.R` has restored the project environment. Use only the configuration profile named by the selected workflow README.

## Outputs and interpretation

Each workflow owns its output location and interpretation contract. Outputs from diagnostics, reference runs, and one-time scripts are not production results unless their README explicitly says otherwise.

## Regeneration and retirement

Regenerate an output only through its documented entry point. Remove or retire a workflow only with its provenance, consumers, and inventory record reviewed.
