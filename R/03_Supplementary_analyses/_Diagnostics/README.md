# Legacy-labelled diagnostics

## Purpose and backstory

This root retains diagnostics whose public output labels predate the current `Diagnostics/` hierarchy. The leading underscore is provenance, not a signal that the scripts are generated or safe to ignore.

## Status and entry point

Status: active diagnostic provenance. Use the README in each child workflow; currently `age_scalling/README.md` is the supported entry point.

## Prerequisites and configuration

Run from the repository root with the profile and target store documented by the child workflow. Never substitute a production store for a diagnostic one.

## Outputs and interpretation

Outputs are diagnostic evidence under `Documentation/Reports/Diagnostics/`. They do not change the scientific production contract.

## Regeneration and retirement

Regenerate only when reproducing the named investigation. Rename or retire the root only together with its public report links and inventory records.
