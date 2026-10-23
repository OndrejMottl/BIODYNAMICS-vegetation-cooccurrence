# Paleo spatial audit recovery and modern continuation

## Approved scope

Stop the verified active modern Stage 03 process tree, preserve all completed targets, fix the October paleo audit findings, validate and recover only affected paleo results, and resume the remaining modern components. Do not reset stores, change the MEM specification, alter budgets or tuning grids, or commit/push.

## Findings and implementation

1. The exact sjSDM MEM engine fails while naming columns when the coordinate geometry provides zero positive eigenvectors. Reproduce its calculation without dropping matrix dimensions, classify only the verified zero-vector case as expected spatial infeasibility, and preserve unrelated engine errors and ordinary exact results.
2. Two paleo-local stores (`am_r007_l004`, `am_r007_l006`) retained historical models behind that failed shared basis. Recover their preparation classification and exclude those models from synthesis. A fold in `eu_r009_l002` has the same geometric limitation; refresh its affected fold evidence and distinguish unavailable held-out evaluation from a valid full-data model.
3. A repeated target failure can retain its earlier metadata timestamp. Pipeline status must inspect failures from the current execution, not only metadata changes, so unchanged errors cannot be reported as success. Selected-target runs must not be blocked by unrelated historical errors.
4. Spatial synthesis must reject stale model descendants of a failed shared basis or resolution-specific preparation/fitting target rather than accepting an ANOVA file merely because it is readable.

## Recovery and acceptance

Add regression tests before implementation. Run focused tests, syntax/80-column checks, generated documentation/architecture validation, the full suite, and paleo/modern CZ smoke pipelines. Record affected-store metadata before and after recovery, retain completed interpolation/community targets, and verify calibration evidence compatibility. Re-audit the affected units and regenerate current paleo synthesis/association-summary outputs only from admissible results. Preserve the September snapshot.

Resume the modern continental, regional, and local component runners sequentially using their registered production paths and new execution logs; do not rerun completed paleo master components. Record the stopped process tree, recovery outcomes, resume PID, and source commit (`6483905b`) under `Data/Temp/Paleo_recovery_20261012/`, with a durable report in `Documentation/Reports/Model_evaluation/`.
