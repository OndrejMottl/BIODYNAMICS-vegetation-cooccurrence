# Stage 01: preparation

Run `01_run_preparation.R`. It executes all nine `_components/` in dependency order: paleo spatial continental, regional, and local; modern spatial continental, regional, and local; then paleo temporal Europe, America, and Asia.

This stage creates or reuses current preprocessing, feasibility evidence, fold assignments, and prepared CV folds. It cannot start tuning or final fitting. Continental spatial components run first because they publish the functional-type classifications consumed by downstream tiers.

Expected data limitations, such as too few cores, samples, taxa, viable functional-type groups, or zero spatial records, are recorded with a stable reason code and do not abort the stage. Each expected outcome must match both its validator target and its precise message contract. Unknown target, cache, dependency, and per-unit runner failures are not silently accepted: the runner attempts all remaining spatial IDs and independent components, then exits with an error that preserves the completed cache and points to the component log.

Preparation validates every requested endpoint after a component runs. A target counts as prepared only when its metadata are successful, its content hash is present, and the object can be read. This preserves and reports partial genus, family, functional-type, and temporal coverage instead of treating a whole unit as either successful or failed. Unreadable legacy `qs` objects are not accepted or hidden; the runner collects the affected endpoints, errored targets, and named dependency chain before retrying them in the current `qs2` format.

Legacy-cache recovery is skipped when current metadata already contain a registered data limitation that prevents the requested endpoint from existing. A recovery cycle also stops when an invalidation produces the same unreadable dependency set again. Refreshed cache-cascade timestamps cannot override an existing expected root, while a substantive new error still remains fatal.

For non-nested temporal stores, an unchanged historical data limitation is reused only when the current runner reports that same scientific failure. A current runner or setup failure with no fresh target error remains unexplained and blocks completion instead of allowing stale metadata to certify missing time-slice endpoints.

Known empty VegVault queries, empty community branches, and registered sample, core, or taxon limits are expected infeasibility rather than component crashes. Old downstream model errors cannot change that preparation diagnosis. If genuine unexplained failures remain, the final message reports each affected unit once and previews at most 20 units; exact target messages remain in the component log and target metadata.

Each component log is created before its subprocess starts and receives stdout and stderr while the component is running. The current log can therefore be followed under `Data/Temp/Main_analysis_execution/01_preparation/<run_id>/` instead of waiting for the component to finish.

The default resource profile is `shared`, which caps interpolation at four workers and may lower that count when little memory is available. On a machine dedicated to this project, run:

```powershell
Rscript R/02_Main_analyses/01_Preparation/01_run_preparation.R dedicated
```

The `dedicated` profile caps interpolation at eight workers. An optional second positional argument requests a deliberate custom count, for example `Rscript R/02_Main_analyses/01_Preparation/01_run_preparation.R dedicated 12`. The available-memory admission check still applies. Worker settings affect scheduling only and do not invalidate completed analytical targets.
