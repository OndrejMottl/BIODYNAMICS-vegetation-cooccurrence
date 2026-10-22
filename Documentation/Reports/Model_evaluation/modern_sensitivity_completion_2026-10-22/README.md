# Modern sensitivity: verified completion after reboot

## Result

Post-reboot verification passed. The saved common-regularization artifact passes its registered schema and content-hash validation. All nine representative fits have `fit_status=ok` and `cv_converged=TRUE`; their 27 fit, standard-error, and decomposition checkpoints are present. The saved decomposition contains all nine representative identifiers and finite estimates. No target errors are recorded in the sensitivity store.

`post_reboot_verification.csv` records the verification time, artifact content hash, checkpoint counts, decomposition coverage, and explicit confirmation that no pipeline was executed and no model was refitted. Model-level evidence is in `sensitivity_model_provenance.csv`, `sensitivity_fit_attempts.csv`, and `sensitivity_decomposition.csv`.

## Resolved operational failure

The original recovery queue correctly remains recorded as failed: its last temporary assertion expected unprefixed tier labels (`continental`, `regional`, `local`) whereas the artifact correctly contains `modern_spatial_continental`, `modern_spatial_regional`, and `modern_spatial_local`. The temporary recovery script now checks the exact modern labels. The old assertion was reproduced against the saved artifact before correction; the corrected assertion passed. Negative checks still rejected incorrect tier labels and a non-converged fit. No production function, pipeline, configuration, budget, or target contract was changed to resolve this assertion.

The failed queue was not restarted. Its saved artifact was verified directly, avoiding even a cache-only pipeline invocation. Original queue logs and the failed component status are preserved as historical evidence; this report records the successful follow-up verification separately.

## Preservation and prior validation

All 1,964 monitored production model, prepared-fold, and tuning metadata records across 294 modern stores have exactly the same hashes and timestamps as the pre-recovery baseline. Sensitivity target metadata also remained unchanged during verification. The seven fingerprinted modelling/configuration source files still match the source hashes captured before the successful focused tests, full test suite, architecture validation, and canonical CZ smoke pipelines. Those scientific checks were not rerun solely to correct an assertion in the temporary operational recovery script.

## Next analysis steps

Stage 04 synthesis and Stage 05 visualisation remain pending. Their existing numbered master runners consume the saved model outputs; they must not restart calibration or model fitting. The synthesis master also includes its existing paleo-temporal synthesis component, and the visualisation master includes the temporal figure component. Any missing cached temporal prerequisite must be reported rather than triggering temporal model fitting automatically.
