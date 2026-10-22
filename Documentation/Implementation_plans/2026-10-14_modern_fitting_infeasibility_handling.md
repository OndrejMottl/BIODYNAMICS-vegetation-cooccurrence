# Modern fitting infeasibility handling

## Approved scope

Implement the handling/reporting fix approved after stopping modern regional fitting and the queued modern-local continuation. Preserve all completed analytical targets, calibration results, fitting budgets, configuration, and unrelated dirty-worktree changes. Do not restart production or the queue, install legacy `qs`, reset stores, or change data thresholds.

## Implementation

1. Revalidate registered preparation failures through narrowly requested root targets before modern regional/local fitting. Normal targets dependency checks prove that a repeated failure uses current inputs; a root that now succeeds requires refreshed preparation/calibration evidence.
2. Return one explicit unit-resolution status. Exclude shared failures at unit level and resolution-specific failures only at the affected resolution. Preserve all other eligible model requests.
3. Use identical per-unit eligibility for candidate tuning, tier pooling, and final fitting. Persist the exact tier store-target request pairs outside targets internals and retain timestamped preflight/final status tables.
4. Distinguish absent objects after upstream failure from existing unreadable caches. Preserve a registered current data root when targets additionally throws an empty-branch dependency exception; do not reclassify unrelated subprocess failures.
5. Continue independent units, but block tier selection for unexplained failures or incomplete eligible tuning evidence.

## Validation

Use focused tests for shared/partial infeasibility, stale exclusions, missing folds, reader-fallback diagnostics, request maps, tier pooling, and strict failures. Exercise actual cold/warm isolated targets stores, proving that healthy cached final objects remain unchanged and changed inputs invalidate an old exclusion. Regenerate function documentation and architecture inventories, run the blocking architecture validator, the complete test suite, and warm canonical paleo/modern CZ smoke checks. Production remains stopped throughout.

## Cache impact

No analytical preparation/fitting command or scientific setting is changed. New helpers belong to orchestration; the tier summary reader changes only the tier pooling contract. It remains always-cued, and changed pooled rows invalidate descendants via the ordinary summary content hash. No target names or store paths are renamed and no target objects or metadata are edited directly.
