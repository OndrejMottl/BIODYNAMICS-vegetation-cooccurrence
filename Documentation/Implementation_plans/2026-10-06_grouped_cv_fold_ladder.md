# Higher-fold grouped cross-validation before leave-one-location-out

## Approved implementation

Apply the same fallback to paleo spatial, modern spatial, and paleo temporal workflows. Preserve initial assignments when feasible; otherwise try increasing grouped fold counts from the configured ladder (5, 10, 20, 50), then retain the existing leave-one-location-out fallback and infeasibility classification. All folds and repeats must meet the existing training sample, taxon, location, MEM, coverage, and balance requirements. Do not relax filters, search seeds, subsample folds, or change fitting budgets, candidate grids, or workers.

Expose the ladder through authored configuration and a CV-only configuration target, excluding it from configuration consumed by heavy preparation. Recalibrate branch-specific spatial grids for alternative fold counts. Publish explicit attempt diagnostics and selected-design provenance separately from prepared-fold content. Preserve direct and shared assignment routes.

## Migration and operational gates

Stop the current modern completion batch before changing the modelling contract, verify its processes are stopped, and snapshot affected metadata. Audit cached designs without GPU fitting. Let targets invalidate dependent work naturally; never rewrite hashes to force old evidence current. Preserve heavy upstream preparation and completed CV/models whose analytical inputs remain compatible. Changed prepared folds require calibration compatibility checks and recalibration of affected required representatives before production fitting. Refresh dependent tier and downstream summaries.

Validate configuration, direct/shared contracts, deterministic assignments, smallest-feasible selection, all-failed fallback, small data, infeasibility, unexpected errors, and scoped invalidation. Run focused and full tests, architecture/configuration generation and validation, CZ smoke pipelines, and a bounded GPU check before resuming modern local. Report any other completed results requiring reruns; do not launch unrelated production reruns silently. No commit or push is authorized.

## Expected costs

The existing staged 8/4/2 candidate schedule costs 14 times the selected grouped fold count: 140, 280, or 700 candidate-fold tasks for 10, 20, or 50 folds. LOO remains exhaustive, one repeat, eight candidates per held-out location. These counts exclude convergence escalation and subsequent evaluation.
