# Granular cross-validation resume evidence

**Issue:** #138  
**Date:** 2026-07-20  
**Branch:** `issue138-cv-runtime`

The shared direct and mapped CV pipes now materialize one dynamic target branch per repeat, fold, and candidate. Fold-local response, abiotic, and MEM inputs are prepared once in a separate upstream target. Every work-item identifier is a deterministic digest of strategy version, seed, repeat, fold, candidate parameters, held-out locations, and held-out row membership.

The real `project_cz_paleo` core tuning target produced five work-item branches. An immediate second invocation reused all five branches and emitted no model-fit messages. A controlled test then invalidated one branch. The resumed invocation reran exactly that branch in 4.2 seconds; the other four branch timestamps were unchanged. The recombined public tuning and execution-provenance targets completed successfully.

The invalidated branch's target-data hash changed because elapsed fit, prediction, and scoring timings are deliberately part of its additive internal artifact. Deterministic scientific equivalence is tested separately: granular and monolithic fixture runs produce identical tuning rows, seeds, metrics, and cached probability matrices.

This establishes restart at candidate/fold fit boundaries for the exhaustive engine. Tier-wide staged round boundaries remain a separate orchestration slice; staged production tuning is still disabled.

The mandatory fresh `run_cz_pipelines.R` workflow then completed in 1,953 seconds (32 minutes 33 seconds). It materialized 35 independent tuning work-item branches across the seven CZ profiles, and all 3,699 target metadata rows had zero errors. Every profile reported five materialized work items, five executed fits, and five selected-candidate refits avoided. This single run is about 1.9 percent faster than the preceding cache-only implementation run and 23.3 percent faster than the historical 42 minute 26 second reference. Repeated paired runs are still required for the formal median gate.
