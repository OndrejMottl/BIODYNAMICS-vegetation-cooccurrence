# Issue 143 shared-MEM validation runner

## Purpose and backstory

This one-time runner reproduces the modern continental shared-MEM validation
from issue #143. Issue #141 still uses it to compare shared spatial predictors
within the cross-validation refactor.

It was moved from `R/02_Main_analyses` by issue #152 because it records
issue-specific validation evidence rather than a supported production
analysis.

## Usage

The runner activates the frozen profile in
`Configuration/Profiles/One_time/Issues/issue_143.yml` and writes to the
isolated `Data/targets/issue143_validation/modern_continental_europe` store.
Keep that output separate from production target stores.
