# Stage 02: model calibration

Run `01_run_model_calibration.R` after stage 01. It builds the current preparation inventory, selects representatives, calibrates every representative sequentially on the GPU, publishes accepted CV budgets, regenerates `config.yml`, and verifies the generated configuration.

No representative identifiers need to be set manually. The calibration screens all eight candidates on three folds at sampling 100, then confirms the leading two on five folds and two repeats at production sampling 200. Only the most complex eligible unit in each analysis, tier, and resolution across continents and the most complex eligible time slice in each temporal profile are calibrated. Other spatial units and temporal profiles without eligible five-fold CV inherit the conservative accepted budget from the same analysis, tier, and resolution. Production tuning remains eight candidates, five folds, three repeats, and sampling 200.

Accepted results, rung checkpoints, and candidate-fold work checkpoints under `Data/Temp/Sjsdm_cv_calibration/` are reused after interruption when they match the current adaptive-calibration contract. Compatible version-2 fit evidence is migrated without refitting. Repeat 2 confirms the repeat-1 candidate when it is the exact winner or its normalized loss is within 2% of the repeat-2 minimum. Independent representatives continue after an individual failure, but budget publication is blocked until all required evidence is accepted.

The scripts under `_components/` are implementation and recovery entry points. The master runner supplies their registered identifiers automatically.
