# Plan: Separate cross-validation and final-model fitting budgets

**Date:** 2026-09-03
**Author:** Codex
**Status:** In progress

---

## Runner architecture correction

Required preprocessing and prepared-fold construction are owned by the existing allowlisted main-analysis runners. Setting `SJSMD_PREPARE_CV_FOLDS_ONLY=true` makes those runners stop before tuning, final fitting, ANOVA, and sensitivity while retaining their normal production stores. Supplementary calibration scripts only inspect cached inputs, benchmark budgets, publish accepted settings, audit results, or build invalidation manifests; they do not invoke production pipelines. The earlier cross-profile supplementary preparation driver was removed on 2026-09-03 before further production work.

---

## Goal

Separate the computational budgets used for cross-validation fits from those used for final full-data sjSDM models. Cross-validation will use explicit, validated, convergence-aware budgets calibrated from cached prepared folds, while existing final-model settings remain unchanged. The change must preserve completed preprocessing and make budget choices, escalation attempts, convergence, retention decisions, and reruns reproducible.

---

## Starting provenance

- Repository commit at implementation start: `16156f11` on branch `rerun_all`.
- Production paleo regional runner was stopped before implementation; no production runner may restart until calibration, validation, and the continental audit are complete.
- The clean-rerun archive remains `Data/targets/_archive/2026-08-31_pre_trait_cv_rerun/`.
- Existing processed trait classifications, prepared communities, fold definitions, and prepared-fold targets are inputs to preserve when current.
- Existing worktree changes in interpolation, low-taxon CV handling, runner memory control, progress artifacts, and corrected trait files are protected and outside this change unless a narrowly required integration edit is documented.

---

## Scope

### In scope

- Paleo and modern spatial tuning CSV schemas and loaders.
- Paleo temporal model-fitting configuration for all three production profiles.
- Shared cross-validation candidate, selected-fold, predictive decomposition, and cross-tier regularization-sensitivity fitting paths.
- Convergence-aware iteration escalation, attempt-level provenance, final-attempt provenance, eligibility guardrails, hashes, validators, and migration compatibility.
- A supplementary calibration workflow using cached prepared folds, deterministic representative selection, the specified iteration and sampling ladders, stability checks, and repeat-two confirmation.
- A continental retention audit and surgical invalidation of stale continental and partial paleo regional CV/model descendants.
- Focused tests, full tests, generated configuration, architecture validation, CZ smoke pipelines, and a bounded GPU calibration benchmark.

### Out of scope

- Changing existing final-model values or the regularization candidate grid.
- Rebuilding interpolation, abiotic extraction, trait classification, community preparation, fold definitions, or prepared folds when their inputs remain current.
- Restarting paleo regional or any later production runner before implementation acceptance.
- Temporal analyses other than the three paleo temporal production profiles.

---

## Contract decisions

- Spatial CSVs retain `n_iter`, `n_sampling`, `n_step_size`, `n_early_stopping`, and `n_samples_anova` as final-only fields and add `cv_n_iter_initial`, `cv_n_iter_max`, `cv_n_sampling`, `cv_n_step_size`, and `cv_n_early_stopping`.
- `load_model_tuning_parameters()` gains `fit_stage = c("final", "cross_validation")`; the backward-compatible default is `"final"`.
- Paleo temporal profiles gain `model_fitting.cross_validation.fit_budget` with the equivalent five fields.
- A distinct `config_sjsdm_cv_fitting` target exposes fitting-compatible names while retaining both initial and maximum iteration budgets. Final `mod_jsdm`, standard errors, and ANOVA remain consumers of `config_model_fitting`.
- Production configuration validation rejects missing, non-scalar, non-finite, non-positive, non-integral, or internally inconsistent CV budgets. Optional step size and early stopping retain their established `NULL` semantics; `cv_n_iter_max` must be at least `cv_n_iter_initial`.
- Every candidate-fold starts from `cv_n_iter_initial`. A successful but non-converged fit is retried with the same deterministic seed and doubled iterations, capped exactly at `cv_n_iter_max`. Fit, prediction, and scoring errors are not escalated.
- Convergence uses the existing strict criteria: absolute tail slope below `0.01` and median tail difference below `1`. A fit still non-converged at the maximum is marked ineligible.
- Attempt provenance contains candidate, repeat, fold, attempt, requested iterations, sampling, epochs run, convergence statistics, early-stopping result, runtime, and error/status fields. Final-attempt convergence and actual budgets enter tuning provenance and content hashes.
- Candidate selection requires complete converged coverage under existing fold/repeat guardrails. A unit halts clearly when no candidate remains eligible.

---

## Implementation phases

### Phase 1 — Stage-specific configuration contracts

**Tasks:**

- Add failing tests for spatial final/CV loading, required CV columns and values, backward-compatible final loading, and unchanged final ANOVA settings.
- Add failing tests for the paleo temporal nested CV budget and production configuration validation.
- Extend the loader, spatial resolution config segment, temporal config segment, and generated configuration fragments.
- Create `config_sjsdm_cv_fitting` without changing the final-model config object.
- Add the five CV fields to all six spatial tuning CSVs through a reproducible migration path; provisional values may only support tests and calibration and must be replaced by accepted calibration results before production.

**Validation:**

- Run loader/configuration test files and pipeline manifest tests.
- Regenerate `config.yml` and the profile catalogue, then verify generated fragments are synchronized.
- Parse every affected R file and confirm R source lines satisfy the repository limit.

### Phase 2 — Convergence-aware fitting and provenance

**Tasks:**

- Add failing tests for early convergence, deterministic escalation, exact max-budget capping, ordinary-error non-escalation, non-convergence failure, and attempt-table contents.
- Implement one reusable fitting orchestrator that invokes the existing candidate fitter and convergence diagnostic without introducing checkpoint assumptions.
- Route tuning candidates, selected-fold refits, predictive CV decomposition, and regularization-sensitivity fits through the CV configuration and escalation contract.
- Add attempt-level targets/artifacts and final-attempt fields to fold results, tuning summaries, validators, artifact versions, tier aggregation, and content hashes.
- Ensure non-converged evidence is excluded and no selected candidate can be produced without complete converged coverage.

**Validation:**

- Run focused fitting, convergence, selection, provenance, validator, hashing, tier, and pipeline-contract tests.
- Run affected pipeline manifests and a deterministic CPU fixture with injected fit/convergence functions.
- Run the full test suite because the shared CV infrastructure has broad reach.

### Phase 3 — Calibration workflow and budget publication

**Approved runtime revision (2026-09-10):**

- Calibrate the maximum-complexity spatial representative in each available analysis-tier-continent-resolution group; retain all three temporal profiles. Historical final-model outliers no longer receive an exhaustive independent CV ladder because final-model budgets are not evidence of CV difficulty.
- Screen all eight candidates on deterministic folds 1-3 with sampling 100. Preserve the original adjacent-rung winner, rank-correlation, loss-change, and convergence criteria.
- Confirm the screening winner and runner-up on all five folds of repeats 1 and 2 with sampling 200. Publish sampling 200 only when the same screening winner remains best and every confirmation fit converges.
- Retain production tuning at eight candidates, five folds, three repeats, and sampling 200. Production convergence-aware doubling remains the safety mechanism for unexpectedly difficult candidate-fold fits and historical outliers.
- Persist a compatible checkpoint after every completed screening or confirmation rung. Accepted representative results remain separately restart-safe.

**Tasks:**

- Add deterministic complexity measurement and representative selection for median and maximum complexity within every tier, continent, and resolution.
- Select the maximum-complexity five-fold-CV-eligible spatial unit for each analysis, tier, and resolution across continents, plus the maximum-complexity eligible time slice in each paleo temporal continental profile. Other spatial units and temporal profiles with no eligible five-fold CV inherit the conservative accepted budget from the same analysis, tier, and resolution. Historical final-budget outliers remain recorded in provenance but do not each trigger a separate exhaustive ladder.
- Screen all eight candidates on folds 1-3 of repeat one across iteration rungs `500, 1000, 2000, 4000, 8000, 16000, 32000, 64000` with sampling `100` until adjacent-rung stability is possible, then confirm the screening winner and runner-up on all five folds of repeats one and two with sampling `200`.
- When no iteration rung passes, evaluate the smallest necessary maximum-iteration rung with sampling `400, 800, 1600, 3200, 6400, 8000` and stop at the first passing value.
- Accept the smallest budget only if every fold of the winning candidate converges, the winner is unchanged at the next rung, candidate-loss Spearman rank correlation is at least `0.95`, normalized held-out loss changes by at most `1%`, and repeat two confirms it.
- Publish accepted budgets, evidence, runtimes, estimated production cost, and deterministic mapping of group budgets and outlier-specific budgets. Set maximum iterations two doubling steps above the accepted initial value, capped at `64000`.
- Populate all spatial CSV CV fields and the three temporal CV profile budgets from the published result.

**Validation:**

- Test representative selection, rung progression, stability rules, repeat confirmation, group propagation, outlier overrides, and maximum-budget calculation with fixtures.
- Run a bounded GPU benchmark from cached prepared folds and validate its schema and convergence evidence before accepting any production budget.
- Re-run configuration and focused CV tests after publishing budgets.

### Phase 4 — Continental audit and surgical invalidation

**Tasks:**

- Audit every completed continental unit-resolution combination against the accepted benchmark.
- Retain a regularization decision and final model only when the existing final model converged and the benchmark reproduces the winner under all stability criteria. Record legacy budget and accepted CV budget provenance for every retained result.
- Identify exact CV-selection and final-model descendants for continental combinations that fail retention.
- In partial paleo regional stores, identify and invalidate CV work-item results, survivor decisions, selected regularization, models, evaluations, and dependent regional tier-selection artifacts for `eu_r001` and `eu_r002`.
- Before invalidation, prove by target graph and timestamp/hash inspection that interpolation, abiotic extraction, trait classification, community preparation, folds, and prepared folds remain current and outside the invalidation set.
- Archive audit and invalidation manifests before applying changes to target metadata.

**Validation:**

- Confirm retained artifacts have explicit legacy provenance and reproduce the benchmark winner.
- Confirm stale CV/model descendants are outdated while every preserved preprocessing and prepared-fold target remains current.
- Confirm no production runner has been started.

### Phase 5 — Integrated acceptance and production handoff

**Tasks:**

- Run syntax checks, focused tests, configuration generation and semantic-reference validation, architecture inventory generators, persisted-contract generation, and the blocking architecture validator.
- Run the complete test suite and paleo/modern CZ smoke pipelines.
- Produce a compact rerun handoff recording commit, profiles, accepted budgets, archive location, validation start/end times, failures, invalidation manifest, retained continental artifacts, and resume instructions.
- Resume production only after all gates pass, beginning with paleo regional and then following the established spatial/temporal production order.

**Validation:**

- Acceptance requires no unexplained target errors, complete converged evidence for every selected candidate, final-model convergence checks, synchronized generated configuration, passing architecture checks, passing full tests and both smoke pipelines, and explicit CV/final fitting provenance.
- Verify that changing only a CV budget invalidates CV and downstream model targets while preprocessing and prepared folds remain current.

---

## Risks and mitigations

| Risk | Likelihood | Mitigation |
|---|---:|---|
| GPU calibration cost is much larger than the bounded benchmark | High | Cache every branch, run sequential GPU fits, stop at the first accepted rung, estimate the full cost from measured attempts, and do not begin production implicitly. |
| New persisted fields invalidate more of the graph than intended | Medium | Add dependency/hash tests and produce a dry-run invalidation manifest before changing target metadata. |
| Existing low-taxon or interpolation edits are overwritten | Medium | Treat current worktree changes as protected, inspect overlaps before every edit, and never restore or reset unrelated files. |
| A fit reaches the max budget without convergence | Medium | Persist all attempts, mark the evidence ineligible, require complete converged coverage, and halt the affected unit with an actionable error. |
| Historical final budgets bias CV again | Low | Keep final fields isolated, prohibit fallback in production, and populate CV fields only from accepted calibration evidence. |
| Legacy continental models cannot be retained safely | Medium | Retain only where final convergence and benchmark winner stability both pass; otherwise invalidate only that unit-resolution’s CV/model descendants. |

---

## Execution log

- 2026-09-03: Confirmed branch `rerun_all` at starting commit `16156f11`; production regional runner was already stopped.
- 2026-09-03: Inspected repository instructions, architecture/naming contracts, dirty-worktree scope, and shared fitting/CV call sites.
- 2026-09-03: Added independent spatial and temporal CV budget contracts, convergence-aware deterministic iteration escalation, attempt-level provenance, converged-evidence selection guardrails, and separate final-model provenance. Final model fitting, standard errors, and ANOVA retain their existing budgets.
- 2026-09-03: Added deterministic representative selection, the fixed iteration/sampling ladder, stability and repeat-two acceptance rules, group/outlier budget propagation, fail-closed publication, and read-only continental retention audit workflows. Repeat two is executed only after a budget passes repeat-one convergence and stability checks.
- 2026-09-03: Current-data inventory found 12 of 1767 unit-resolution inputs available and 1755 missing; archived pre-trait stores were excluded. Missing current inputs comprise all modern units, all paleo local units, most paleo regional units, and all three paleo temporal profiles. Production CV budgets remain unpublished; spatial CSV values are explicitly `NA` and fail closed.
- 2026-09-03: Bounded GPU smoke used paleo continental Europe genus, candidate 001, repeat 1, fold 1, 500 iterations, and sampling 200. It converged with early stopping at epoch 379 in 78.3 seconds; tail slope and median difference were both zero. Evidence and logs are under `Documentation/Reports/Model_calibration/sjsdm_cv_fit_budget/`.
- 2026-09-03: Read-only continental audit recorded eight available, class-valid, converged paleo models, excluded the known ineligible Asia-family case, found no current modern continental models, and stopped at the intended pending-calibration gate without invalidating targets.
- 2026-09-03: Configuration generation and drift validation passed for all 26 profiles. Focused CV/config/calibration tests and the bounded GPU smoke passed. Selective function documentation and the full published website were regenerated; the interim architecture checker passed with zero findings after registering two naming migrations.
- 2026-09-03: Regenerated the 18,650-row persisted-contract manifest and reran the architecture generator and blocking checker with zero findings. The complete test suite finished with no failed or warning test summaries; the only console warning requested database disconnection after the final test group.
- 2026-09-03: Added a dry-run-first surgical invalidation manifest for failed continental audit combinations, partial paleo regional CV/model descendants, and dependent regional tier artifacts. Prepared folds are excluded, production-store paths are allowlisted, archived stores are rejected, and application requires `SJSMD_APPLY_CV_INVALIDATION=true`. No invalidation has been applied.
- 2026-09-03: Added measured runtime provenance and expected/escalation-ceiling GPU-hour estimates for regularization tuning. Publication now fails before modifying production configuration unless the refreshed inventory contains CV strategy/effective-fold evidence and every accepted representative has finite timing evidence.
- 2026-09-03: Corrected workflow ownership and ordering after review: the five required inventory, calibration, publication, audit, and invalidation entry points now live as numbered prerequisite runners under `R/02_Main_analyses/00_Model_calibration/01_Runners/`; only the bounded GPU smoke remains supplementary under `R/03_Supplementary_analyses/Validation/Cross_validation/Smoke/`. The runners now use the project header and numbered-section structure, translate modern functional type to its persisted `ft_modern` target suffix, and register the maximum-complexity `timeslice_*` target for each temporal profile.
- 2026-09-03: Fresh CZ smoke validation resumed after an external terminal connection loss; the underlying R process survived. Paleo core, paleo resolution, and modern resolution smoke stores all completed with no errored targets. The disconnected console tee remained truncated, so target-store progress records are the authoritative completion evidence.
- 2026-09-03: Focused invalidation and runtime-provenance tests passed with nine assertions. All 84 changed R files parsed and satisfied the 80-column rule. The persisted manifest contains 18,650 profile-target rows; after generating the new function documentation and retrying one transient Windows output-file lock, the website render and blocking architecture checker completed with zero findings.
- 2026-09-10: The exhaustive calibration was stopped after measured America-family throughput showed a minimum design cost of 17,400 sequential GPU fits and an estimated runtime of four to seven days. Approved an adaptive three-fold sampling-100 screen, five-fold sampling-200 top-two confirmation, maximum-complexity representatives, and rung-level restart checkpoints. Production CV settings and convergence escalation remain unchanged.
- 2026-09-10: The adaptive inventory selected 50 five-fold-eligible representatives; paleo-temporal Asia has no eligible time slice and therefore uses the documented conservative temporal fallback. Sampling-100 smoke fits took 61.54 seconds for paleo continental Europe genus and 246.46 seconds for modern continental Europe genus. The strict minimum is 3,400 GPU fits and roughly 49 GPU-hours, with an operational estimate of two to four days if extra rungs are required. The production calibration was not launched implicitly after this cost gate.
- 2026-09-10: Approved the additional cross-continent reduction after the bounded cost gate. Spatial representatives are now selected once per analysis, tier, and resolution rather than once per continent, while production convergence escalation remains responsible for unexpected unit-specific difficulty.
- Pending: prepare missing current calibration inputs, benchmark every selected representative, publish accepted budgets, rerun the continental audit, review and apply the surgical invalidation manifest, and only then restart production.
