# Stage 03: model fitting

Run `01_run_model_fitting.R` after stage 02. It executes paleo spatial, modern spatial, and paleo temporal tuning and final fitting in dependency order. The component scripts do not contain a preparation mode and cannot be switched into one with an environment variable.

Existing target stores are reused. A genuine upstream content change may make preprocessing outdated through normal `{targets}` dependency tracking; a runner-path or profile-authorization change alone must not do so.
