# Representative modern continental validation failure

**Date:** 2026-07-24  
**Issue:** #138  
**Branch:** `issue138-cv-runtime`  
**Status:** Diagnostic failure; excluded from benchmark acceptance evidence

## Run identity

- Runner: `R/03_Supplementary_analyses/One_time/Issues/issue_138/run_modern_continental_europe_staged.R`
- Strategy: `staged`
- Repetition: `113`
- Target store: `Data/targets/issue138_validation/modern_continental_europe`
- Raw diagnostics: `Data/Temp/issue138/staged/repetition_113`

## Outcome

The run did not reach cross-validation or model tuning. The shared `data_spatial_mev_core` target failed while constructing Moran eigenvector maps:

```text
Error: cannot allocate vector of size 2.9 Gb
```

The later errors for `data_spatial_mev_samples_genus`, `data_spatial_scaled_list_genus`, and `data_model_input_genus` were dependency failures after the shared MEM target failed. Their reference to a missing `qs` package is not treated as the primary cause.

No `run_summary.json` or `harness_error.txt` was produced because the observer and modelling processes ended during the interrupted session.

## Resource evidence

- Resource samples: 6,733
- Observed duration: 2.48 hours
- Peak process working set: 21.14 GiB
- Peak system-used memory: 45.70 GiB
- Peak process count: 10
- Peak GPU memory: 2,099 MiB
- GPU out-of-memory errors: none observed

The coordinate target contains 19,864 locations and 19,778 unique coordinate pairs. A single dense double-precision distance matrix at that size requires approximately 2.94 GiB. `sjSDM::generateSpatialEV()` constructs the dense distance matrix and several additional dense matrices before eigendecomposition, so the failure is structural rather than a transient shortage during model fitting.

## Interpretation

This run is diagnostic evidence for a shared spatial-predictor scalability defect. It is not evidence about staged-versus-exhaustive tuning performance, because no CV work item was executed.

The failure must be addressed in the shared MEM construction and fold-local projection path. No modern-, Europe-, or continent-specific threshold or workaround is acceptable.

## Next evidence

After the shared MEM implementation and its scientific equivalence gates pass:

1. run a diagnostic continuation to verify restart behavior where useful;
2. run a clean modern continental repetition with a new repetition identifier;
3. assess it separately from repetition 113.

