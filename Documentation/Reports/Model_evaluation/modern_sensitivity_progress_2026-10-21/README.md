# Modern sensitivity recovery: checkpoints and progress

## Scope

This recovery concerns only nine common-regularization sensitivity representatives. Production modern continental, regional, and local fits are complete and are not rerun. Synthesis and figure publication remain pending successful sensitivity completion.

## Recovery contract

Each representative has independent content-addressed `fit`, `standard_errors`, and `decomposition` RDS checkpoints inside its sensitivity target store's `sensitivity_checkpoints` directory. Completed phases are reused after interruption even though the pipeline refreshes publication timestamps. Scientific input or fitting-budget changes create different checkpoint identities. Errors are not cached. An interrupted decomposition restarts that decomposition; individual taxon likelihoods are not checkpointed.

The instrumented ANOVA adapter clones the installed sjSDM method and conditional likelihood helper into private execution environments. It does not modify the package namespace, change formulas or fitting budgets, change Monte Carlo sampling, cache predictions, or alter random-number order. It checks the dependency version and conditional-function body hash before execution. The original shared production ANOVA helper remains unchanged.

## Evidence and limitations

`likelihood_pilot.csv`, when present with `pilot_status=passed`, records a bounded test of three leave-one-taxon likelihood evaluations using the cached Europe-genus production model, its original ANOVA sampling, and its original batch size. This is not a complete decomposition, a new fitted model, or a benchmark of the saturated submodel. A fast pilot cannot rule out substantially slower reduced-model likelihoods.

The previous run remained CPU/GPU-active during its silent period. New messages identify every taxon calculation's start and completion with UTC timestamps. A single taxon call may still be quiet while its internal GPU batches run. Checkpoints improve interruption recovery; they do not make the underlying likelihood algorithm cheaper.

The bounded pilot passed on 21 October at 10:42:27 UTC using the cached 308-taxon Europe-genus model, 1,000 Monte Carlo samples, and its unchanged batch size of 1,963. The three timed taxon calls took 33.84, 31.55, and 32.02 seconds, respectively. Including the initial joint likelihood, the pilot lasted about 101 seconds. A single 308-taxon pass would therefore be roughly 2.8 hours if that rate remained stable; the eight likelihood passes of a spatial ANOVA can explain a day-scale decomposition without a deadlock. Reduced and saturated models may have different costs, and concurrent machine load matters. This is a scaling illustration, not a completion guarantee.

After the pilot and implementation, the read-only production-store check again confirmed all 1,964 monitored model, tuning, and prepared-fold metadata hashes and timestamps unchanged.

## Validation and restart

Focused tests must pass before the pilot. Architecture documentation/inventories, the blocking architecture validator, full test suite, and canonical paleo/modern CZ smoke pipelines must pass before a sensitivity-only restart. The validation/restart queue writes its component log paths and status CSV under `Data/Temp/Main_analysis_execution/modern_sensitivity_recovery_20261021/`. It must stop on failure and must not launch Stage 04 or Stage 05 automatically as part of this diagnostic recovery.

The detached queue was launched on 21 October at 10:54:30 UTC (run `20261021_125430`, parent PID recorded in `launch_receipt.csv`). Its focused tests and full test suite passed; the latter recorded 5,551 passing assertions, no test failures, and one integration skip. The standalone architecture checker reported zero findings. The persisted manifest generator completed successfully with 19,782 profile-target rows across 26 profiles; `manifest_generation_status.csv` records the actual artifact hash and observed successful exit. Canonical CZ smoke validation is the remaining long-running gate before automatic sensitivity-only execution. Subsequent status must be read live from the queue, not inferred from this dated note.

Current operational logs are under `Data/Temp/Main_analysis_execution/modern_sensitivity_recovery_20261021/20261021_125430/`. `03_canonical_cz_smoke.log` records isolated test-store preparation and smoke checks. After all gates pass, `07_modern_sensitivity_only.log` records the nine sensitivity representatives, phase checkpoint reuse, and named likelihood-pass/taxon progress. The queue is detached from VS Code. Its final provenance records success or failure and verifies preservation of the production-store baseline again after sensitivity.
