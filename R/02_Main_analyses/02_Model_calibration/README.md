# Stage 02: model calibration

Run `01_run_model_calibration.R` after stage 01. It builds the current preparation inventory, selects representatives, calibrates every representative sequentially on the GPU, publishes accepted CV budgets, regenerates `config.yml`, and verifies the generated configuration.

No representative identifiers need to be set manually. Accepted calibration results under `Data/Temp/Sjsdm_cv_calibration/` are reused after interruption. Independent representatives continue after an individual failure, but budget publication is blocked until all required evidence is accepted.

The scripts under `_components/` are implementation and recovery entry points. The master runner supplies their registered identifiers automatically.
