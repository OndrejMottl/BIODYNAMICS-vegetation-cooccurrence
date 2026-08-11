# Issue 143 shared-MEM validation runner

## Purpose and backstory

This one-time runner reproduces the modern continental shared-MEM validation from issue #143. Issue #141 still uses it to compare shared spatial predictors within the cross-validation refactor.

It was moved from `R/02_Main_analyses` by issue #152 because it records issue-specific validation evidence rather than a supported production analysis.

## Status and entry point

Status: retained one-time validation evidence. The script in this folder is the only entry point.

## Prerequisites and configuration

The runner activates the frozen profile in `Configuration/Profiles/One_time/Issues/issue_143.yml` and writes to the isolated `Data/targets/issue143_validation/modern_continental_europe` store. Keep that output separate from production target stores.

## Outputs and interpretation

The isolated store is shared-MEM validation evidence for Issues #143 and #141; it is not a production model result.

## Regeneration and retirement

Regenerate only with the frozen profile. Retire after Issue #141 no longer depends on this evidence and the comparison provenance is preserved elsewhere.
