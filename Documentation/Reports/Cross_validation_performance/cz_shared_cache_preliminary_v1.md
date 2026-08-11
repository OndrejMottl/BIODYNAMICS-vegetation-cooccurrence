# Shared tuning-prediction cache: preliminary CZ result

**Issue:** #138  
**Date:** 2026-07-20  
**Branch:** `issue138-cv-runtime`  
**Strategy:** exhaustive with selected-candidate prediction reuse

## Result

`Rscript R/03_Supplementary_analyses/Testing/Smoke/run_cz_pipelines.R` completed successfully from fresh stores in 1,991 seconds (33 minutes 11 seconds). The three stores contained 3,631 metadata rows and zero target errors. The earlier correctness-reference run took about 42 minutes 26 seconds, so this single unpaired observation is approximately 21.8 percent faster. It is preliminary: the protocol requires three paired fresh repetitions and uses their median.

All seven CZ model profiles prepared five folds, executed five tuning fits, and reused five successful selected-candidate predictions. Each profile therefore used five CV fits instead of the historical ten, a 50 percent reduction for the explicit one-candidate CZ configuration. This validates caching and prediction assembly; it does not validate the eight-candidate staged search.

The three stores occupied 176,050,464 bytes after the run. A same-protocol pre-change byte baseline was not available, so the 25 percent storage gate is not yet resolved.

## Scientific comparison note

The tuning cache uses the established deterministic candidate-specific tuning seeds. The removed selected-candidate refit used a different fold-only seed, so the cached probabilities are not numerically identical to the historical refit. Candidate selection, fold keys, statuses, prediction row counts, and evaluable-taxon counts remained stable. Some aggregate metrics moved by more than the staged-search tolerances, including the paleo-family AUC and log loss. This is recorded rather than hidden.

Those tolerances govern the required paired staged-versus-exhaustive comparison on identical assignments and tuning seeds. Production remains `exhaustive` until that comparison, the three-repeat eight-candidate reference, and the continental/temporal gates pass.

## Instrumentation evidence

The additive timing artifact contains one row per fold/candidate stage for preparation, fitting, prediction, and scoring. The additive execution artifact records strategy/version, prediction source, preparations, fits executed, successful fits, avoided refits, exhaustive/historical budgets, and reduction. No fitted sjSDM object is stored in the prediction cache.

## Decision

Accept the common cached-prediction path as the first runtime slice. Do not yet enable staged production tuning. The next slice must add explicit round-level unit/tier orchestration and candidate/fold resume boundaries before running the paired equivalence benchmarks.
