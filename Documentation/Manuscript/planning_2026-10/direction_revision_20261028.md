# Direction revision — 28 October 2026

Supersedes the four-axis layout of `STATUS_AND_PLAN.md` Part 2 and the issue priorities in `ISSUE_PLAN.md` §3. The issue bodies on GitHub remain the operative specification; this document records the decision and lists the edits to make to them. Written before the Round 0 briefing ([#197]) is sent, so that the briefing presents this layout.

## 1. Decision

The project measures how far the residual association structure of fitted `{sjSDM}` models persists. **Time is the backbone.** Every other comparison is a test of how robust the temporal result is to the way the structure is observed, aggregated or nested in space:

| Rank | Axis | What it becomes | Issues |
|---|---|---|---|
| Backbone | Time | Half-life, pace, residual versus raw co-occurrence, cross-continent recurrence of long-lag pairs | [#181] [#182] [#183] [#184] [#185] [#186] [#190] [#194] |
| Robustness: observation system | Fossil pollen versus modern plots, same grid cell | Local and regional tiers at genus level; continental tier at functional-type level, where the two systems have matching matrix sizes | [#189] |
| Robustness: aggregation | Genus → family → functional type | Rerun the temporal models at family and functional-type level and compare the half-lives | [#202] (§6) |
| Robustness: nested extent | Local units within regions, regions within continents | Paired test: is a local matrix closer to its own region's matrix than to other regions' matrices (and regional to its own continent)? Replaces the half-distance | [#187] (rewritten) |
| Prerequisite | Functional-type classification | Stays on the critical path, with a usability constraint: enough groups, balanced, applied identically to paleo and modern data | [#179] |
| Supplement | Genus → family projection within a unit | Kept as a check of the projection idea, taxon-label null only | [#188] (reduced) |
| Supplement | Legacy temporal results | Network-metric rarefaction | [#192] |
| Fallback core | Held-out component removal on 20–30 units | Cheap on GPU and the core of the methods paper if the ceiling is low | [#193] |
| Corroboration | Rate of change with `{RRatepol}` | Offered to a co-author or kept supplementary | [#191] |
| Conditional | Refit spatial units at matched taxon number | Unchanged | [#195] |

Dropped: the spatial half-distance within a tier, and any structure comparison on local or regional functional-type models (5–8 groups).

The opener of the paper stays the matrix-size effect: the association share of explained variance tracks the number of taxa in the model, so the amount of residual structure cannot be compared between models.

## 2. Facts that drove the decision

### Taxa per model (unit tables of 2026-10-23, `Outputs/Tables/Visualisation/*_variance_partitioning_unit_2026-10-23.csv`, component `Associations`)

| Model family | Resolution | Local (median taxa; units; share with ≥ 10 taxa) | Regional | Continental |
|---|---|---|---|---|
| Paleo spatial | genus | America 11 (23; 61 %), Europe 12 (35; 63 %) | America 18 (9; 78 %), Europe 14.5 (8; 88 %) | America 54, Europe 56, Asia 8 |
| Paleo spatial | family | 6 and 7.5 (12–18 % with ≥ 10) | 14 and 10 (57–62 %) | 31 and 33 |
| Paleo spatial | functional type | 5 and 5.5 (0–8 %) | 8 and 7.5 (0–38 %) | America 20, Europe 16, Asia 5 |
| Modern spatial | genus | 11.5, 14, 21 | 26, 39.5, 88 | 310, 121, 308 |
| Modern spatial | family | 8, 11, 14 | 17, 24.5, 44 | 111, 47, 83 |
| Modern spatial | functional type | 3–4.5 | 4.5–6.5 | 5–8 |
| Paleo temporal | genus only (`taxonomic_resolution: "genus"` in `Configuration/Profiles/Main/Paleo/temporal.yml`); continental extent | Europe 6 ka: 46 taxa, 535 samples | | |

Consequences:

- A similarity needs at least 10 shared taxa ([#183]), that is 45 estimated off-diagonal elements in common. About 40 % of local genus units fall under that before any pairing, and the regional tier has 8–9 units per continent, that is 28–36 non-independent pairs. A spatial half-distance would rest on that, and shared taxa fall with distance, so distant pairs would be compared on the widespread generalists only. In time, within one continent, the shared set is large (about 50 of 56 genera) and nearly constant.
- Functional-type matrices at local and regional level have 10–28 off-diagonal elements, too few for a structure comparison whatever classification is used. At continental extent the paleo functional-type models hold 16–20 groups (120–190 elements), which is workable, and the temporal models are continental in extent.
- The modern functional-type models hold only 5–8 groups at every tier, so today no fossil–modern comparison is possible at functional-type level. With one classification of about 20 groups applied to both data sources, the continental tier becomes the one place where fossil and modern matrices have matching sizes (today 56 versus 308 genera, 33 versus 83 families).
- Functional types are shared across continents by construction, unlike genera (32 shared between the European and North American temporal models), so the cross-continent recurrence test ([#194]) gains full overlap at functional-type level.

### Compute (Europe temporal store, `Data/targets/paleo_temporal_europe/pipeline_paleo_temporal/meta/meta`, recorded seconds per target)

| Step | Targets | Total |
|---|---|---|
| Community interpolation (`data_community_interpolated_dataset`) | 1 (dynamic over datasets) | 8.5 h |
| `model_anova_timeslice_*` | 41 | 0.9 h |
| `data_network_metrics_timeslice_*` | 41 | 0.8 h |
| `model_jsdm_timeslice_*` | 41 | 0.2 h |
| `data_cross_validation_grid_calibration_timeslice_*` | 41 | 0.2 h |

Interpolation runs **before** `classify_taxonomic_resolution()` in `R/Pipelines/_pipes/pipe_segment_community_prepare_paleo.R`, so a family- or functional-type-level run reuses the interpolated data when it shares the prebuilt interpolation (`run_pipeline_interpolation_prebuild.R`), and otherwise costs about one day per continent. The model fits themselves are cheap. Rerunning the temporal pipeline at coarser levels is therefore the cheapest way to add an aggregation axis, and it puts that axis in the same units as the main result. The functional-type rerun must wait for the classification from [#179]; the family rerun can start as soon as [#181] is done.

### The similarity statistic: union with zeros as the default

Decided 28 October 2026. The preliminary results compared two matrices on the intersection of their taxa (Spearman correlation of the off-diagonal elements). That ignores the turnover of taxa between the two models, which is exactly what worried us about the spatial comparisons. The default is now the community-ecology convention: both matrices are placed on the **union** of their taxa, every pair not estimated in a model (at least one taxon absent from that model) is set to **0**, as an absent species has zero abundance in a community dissimilarity, and the Pearson correlation of the off-diagonal elements is taken (`union_zero`). Pearson, not Spearman, because the zeros produce heavy ties. This is the whole-network dissimilarity of Poisot et al. 2012 (*Ecol. Lett.*, `10.1111/ele.12002`), which splits into a rewiring part among shared taxa and a species-turnover part.

Two supporting statistics isolate the rewiring part and are reported wherever a decay is fitted: `shared` (the preliminary statistic: Spearman on the intersection) and `rarefied` (`shared` on repeated random subsets of a fixed number of shared taxa). The difference between `union_zero` and `shared` is the turnover contribution. Every pair also carries its turnover share `1 − n_shared / n_union`, used as a covariate for `union_zero`. The permutation null permutes taxon labels among the taxa present in each model, so the zero pattern stays fixed and the null tests rewiring given turnover. A pair still needs a minimum number of shared taxa (for example 10) to be compared at all.

Caveat to state in the manuscript: a taxon is absent from a model mostly because it fell under the community filters, not because it vanished, so the turnover part carries sampling. The gate rules are unaffected: seed replicates and taxon-subset refits compare matrices with identical or nested taxon sets, where `union_zero` and the shared statistic coincide on the compared pairs.

### Matrix size and the similarity estimator

Whichever statistic is used, the values compared are the pairs estimated in both models. Dropping taxa does not change the true marginal correlations among the taxa that remain. But `{sjSDM}` estimates the covariance with an elastic-net penalty and a low-rank latent structure, both of which act on the whole matrix, so the same taxon pair can be estimated differently in a 46-taxon model and a 20-taxon model. Old temporal slices have fewer taxa and fewer sites, so matrix size is correlated with lag in the same way site count is. The nested-extent test compares matrices of different sizes by design (local 12 versus regional 15 versus continental 55 genera). The sentence in the Round 0 report that similarity "is not inflated by matrix size in the way a variance share is" is an assumption until tested. The test belongs in the gate (§4).

## 3. The questions, revised

| Axis | Question | Status |
|---|---|---|
| Q1 premise | Can the strength of residual structure be compared across models? | Answered: not as a variance share (matrix-size effect) |
| Q2 time | Over how much time does the structure stay recognisable? | Preliminary half-life ≈ 2 kyr; backbone |
| Q6 pace | Did the rate of rewiring change while compositional change accelerated? | Preliminary: no acceleration; backbone |
| Q5 observation system | Does fossil pollen give the same structure as modern plots for the same cell? | Local and regional at genus; continental at functional type |
| Q4 aggregation | Does the half-life change from genus to family to functional type? | Temporal reruns at family and functional-type level |
| Q3 nested extent | Is a local structure closer to its own region's structure than to other regions', and a regional structure to its own continent's? | Paired test on the spatial grid, paleo and modern |

## 4. Decision gate, revised

Four checks, rules frozen before any result is inspected:

| Check | Issue | Rule (proposed) |
|---|---|---|
| Reproducibility ceiling | [#184] | Median replicate similarity ≥ 0.85 sound; 0.65–0.85 usable with mandatory ceiling correction; ≤ 0.65 pivot to the methods paper |
| Matrix-size dependence of the estimator | [#184], new arm | For the retained taxon pairs, the similarity between a full fit and a fit on a random 50 % or 75 % taxon subset lies within 0.05 of the seed-replicate ceiling of that slice: the estimator does not depend on size. If it lies more than 0.05 below, log(minimum taxa of the pair) is a mandatory covariate on every axis, and the nested-extent and fossil–modern tests are restricted to pairs within a factor of 2 in taxon number or report the subset-corrected similarity |
| Raw co-occurrence control | [#185] | Residual minus input-derived (φ) half-life with a 95 % bootstrap interval over slices, per continent. Excludes 0 on both continents: residual structure has its own dynamics. Includes 0 and the half-life ratio lies within 0.8–1.25: residual tracks composition. Otherwise inconclusive, conservative framing |
| Site overlap, shrinkage and matrix size | [#186] | Under the joint model the log(lag) coefficient keeps its sign, retains ≥ 50 % of its uncontrolled size and its 95 % interval excludes 0 on both continents |

Mapping to the three papers stays as in [#180]. The matrix-size arm adds about 24 fits (4 slices × 2 subset fractions × 3 replicates) to the ~70 of [#184], on the same pipeline and GPU budget.

## 5. Issue updates

Edits only; no issue is closed. Each row gives the action, the milestone and the text to add or change. Umbrella first, then the gate, then the axes.

### [#180] Umbrella

- Replace "width artefact" and "matrix width" with "matrix-size effect" and "matrix size" (Context, Q1 row, outcome table).
- Replace the Goal table with the table in §3 above and add after it: "Time is the backbone. The observation-system comparison ([#189]), the family- and functional-type-level temporal reruns ([#202]) and the nested-extent test ([#187]) test how robust the temporal result is to the way the structure is observed, aggregated and nested in space. Decided 28 October 2026 (`Documentation/Manuscript/planning_2026-10/direction_revision_20261028.md`)."
- Decision gate: add the matrix-size check as a fourth row and note it is run inside [#184].
- Scope: add `- [ ] #202` under Questions; move `#188` and `#192` under Supporting analyses; change the [#179] line to "`- [ ] #179 (functional-type classification; blocks the functional-type arms of #202, #189 and #194; must satisfy the usability constraint recorded there)`".
- Decision record: add "subset-refit similarity relative to the ceiling, per slice".

### [#184] Reproducibility ceiling (gate)

- Context, add a paragraph: "A second question rides on the same fits. The covariance penalty and the low-rank latent structure act on the whole matrix, so the estimate for one taxon pair may depend on how many other taxa the model contains. Old slices have fewer taxa, so matrix size is correlated with lag like site count is, and the nested-extent and fossil–modern tests compare matrices of different sizes by design. Whether the estimator depends on matrix size decides whether those comparisons are admissible without correction."
- Decision rule table, add the matrix-size rule from §4.
- Design, add: "**Taxon-subset replicates:** for the same four temporal slices, refit on random subsets of 50 % and 75 % of the taxa, 3 replicates each, identical data otherwise (about 24 fits). Compare the full fit and each subset fit on the retained taxa with the shared similarity function, and report the result next to the seed-replicate ceiling of that slice."
- Scope, add: `- [ ] Taxon-subset replicates and their similarity to the full fit, per slice and subset fraction.`
- Acceptance criteria, add: `- [ ] The matrix-size rule was frozen before results were inspected and its outcome is in the decision record.`

### [#186] Site overlap and shrinkage (gate)

- Title: "Control the temporal decay for site overlap, covariance shrinkage and matrix size".
- Context, add a third confound: "3. **Matrix size.** The number of taxa differs between slices and falls with age. Through the penalty and the latent rank it can change the estimate of each pair mechanically (see [#184])."
- Scope, add: `- [ ] Matrix size per pair: log of the smaller taxon count and the absolute log ratio; add them to the covariate regression one at a time and jointly, as for shrinkage.`
- Acceptance criteria: extend the first line to "with and without each control (site overlap, shrinkage, matrix size)".
- Add the frozen decision rule from §4 under a "Decision rule" heading.

### [#185] Raw co-occurrence control (gate)

- Add the frozen decision rule from §4 under a "Decision rule" heading. No other change.

### [#179] Functional-type classification (prerequisite)

- Add a section "### Usability constraint for the persistence analyses (added 28 October 2026)": "The classification feeds three structure comparisons: the functional-type-level temporal rerun ([#202]), the continental fossil–modern comparison ([#189]) and the cross-continent recurrence test ([#194]). All three compare taxon × taxon correlation matrices on shared groups and need at least 10 shared groups per pair (45 off-diagonal elements), preferably 15 or more. Add to the pre-registered selection rule, and reject candidates that fail it: (1) at least 15 groups retained after the community-filter chain in every continental paleo and continental modern unit of Europe and North America, and in every 500-year temporal slice with at least 10 samples; (2) the largest group holds at most 25 % of eligible taxa; (3) the effective number of groups is at least 10; (4) one mapping applied to paleo and modern taxa alike, so that the same groups exist on both sides. Report these four numbers for every candidate, including the current production classification and the simple baselines, in the benchmark table."
- Cost of adoption: add "The temporal pipeline is rerun at functional-type level after adoption ([#202]); the fits are cheap, the interpolation is reused."
- Milestone stays 1️⃣. Relationships: add "Blocks [#202] (functional-type arm), [#189] (continental arm), [#194] (functional-type arm)".

### [#187] Spatial axis (rewrite)

- Title: "Test whether residual association structure is consistent across nested spatial extents".
- Context, replace the second paragraph with: "The spatial half-distance within a tier was withdrawn on 28 October 2026 (`direction_revision_20261028.md`): shared taxa fall with distance, so distant pairs would be compared on widespread taxa only; 40 % of local genus units have fewer than 10 taxa; the regional tier has 8–9 units per continent. The spatial grid supports a cleaner, paired question instead. Every local unit sits inside one region and every region inside one continent (`Data/Input/spatial_grid.csv`, `parent_id`), and each level is fitted separately. If the residual structure is a property of the place rather than of the extent at which it is modelled, the matrix of a local unit should be closer to its own region's matrix than to the matrices of other regions on the same continent, and a regional matrix closer to its own continent's than to the other continent's."
- Goal: "Test, per tier transition (local → region, region → continent), whether a unit's structure is more similar to its parent's than to non-parents', on paleo and modern grids."
- Scope, replace with: `- [ ] For every fitted local unit (genus; paleo and modern separately), compute similarity on shared taxa with its parent regional matrix and with every other regional matrix of the same continent; report the shared-taxon count for each pair.` `- [ ] For every fitted regional unit, the same against its own and the other continental matrix (shared genera between continents are few; report the count and skip pairs under the minimum).` `- [ ] Statistic: own-parent similarity minus the mean non-parent similarity, per unit; test with a permutation of parent labels within continent; summarise per tier transition, continent and data source.` `- [ ] Covariates and restriction from the #184 matrix-size rule (parent and child matrices differ in size by design: 12 versus 15 versus 55 genera).` `- [ ] Apply the reproducibility ceiling where measured (#184 fits one local, one regional and one continental paleo unit).` `- [ ] Figure: own-parent against non-parent similarity per tier transition, paleo and modern.`
- Null result: "A unit's structure is no closer to its parent's than to other parents'."
- Milestone stays 1️⃣. Relationships: add "Blocked by [#184] (matrix-size rule)".

### [#189] Fossil versus modern, same cell

- Context, add: "Matrix sizes differ between the two observation systems at genus level: continental models hold 121–310 modern genera against 8–56 paleo ones, so the continental genus comparison is excluded; local (11–21 versus 11–12 median genera) and regional (26–88 versus 14–18) tiers are compared. At functional-type level the picture inverts: with one classification applied to both data sources ([#179] usability constraint), the continental tier is the one place where fossil and modern matrices hold the same groups at the same size (about 15–20), and functional types are shared across continents, so the other-continent pairs serve as the null. The different-cell null always uses pairs of the same two model families, so it carries the same size difference as the same-cell pairs."
- Scope, add: `- [ ] Genus level: local and regional tiers only; report the taxon counts of both models for every pair; apply the matrix-size outcome of #184.` `- [ ] Functional-type level, continental tier, after the #179 refits: same-continent fossil–modern similarity against other-continent fossil–modern similarity (3 same, 6 other), with the taxon-label permutation null per pair.`
- Relationships, add: `- Blocked by #184 (matrix-size rule)` and `- Blocked by #179 (functional-type arm only)`.
- Milestone stays 1️⃣ (genus arms); the functional-type arm follows the [#179] refits.

### [#188] Aggregation by projection (reduce)

- Title: "Test whether genus-level association structure projects onto fitted family-level structure".
- Context, add after the FT paragraph: "**Reduced to a supplementary check (28 October 2026).** The aggregation axis is carried by the family- and functional-type-level temporal reruns ([#202]), which compare half-lives in the same units as the main result. Local and regional functional-type models hold 5–8 groups, too few for any structure comparison, so the functional-type arm here is withdrawn. This issue keeps only the genus → family projection within spatial units as a check of whether a fitted coarse matrix resembles the projected fine one."
- Definitions, replace the random-grouping null: "**Null.** Taxon-label permutation of the projected matrix. A random-grouping null would need coarse models refitted on random partitions, which is out of scope; state this limitation."
- Scope: remove the FT arm and the functional-versus-taxonomic comparison; keep the genus → family arm.
- Relationships: remove "Blocked by [#179]"; add "Related to [#202]".
- Milestone: move to 2️⃣.

### [#194] Cross-continent recurrence

- Scope, add: `- [ ] Repeat at functional-type level from the #202 temporal reruns, where every group is shared between continents by construction; compare the agreement statistic at genus and functional-type level.`
- Relationships, add: "Related to [#202] (functional-type arm)". Consider moving to 1️⃣: it is backbone and cheap at genus level.

### [#183] Similarity engine

- Definitions: `union_zero` (Pearson on the union with zeros) becomes the default similarity; `shared` (Spearman on the intersection, the preliminary statistic) and `rarefied` (fixed number of shared taxa) are sensitivity modes; every pair carries union and shared counts and the turnover share; the permutation null permutes labels among the taxa present in each model. `compute_association_similarity()` gets a `method` argument. The temporal application reports all three modes side by side, with the turnover share as a covariate for `union_zero`, and reproduces the preliminary table in `shared` mode first. Fixtures: identical taxon sets give the same `union_zero` and Pearson-on-shared value; an absent taxon gives a zero row and column in that model's union matrix.
- Add log(minimum taxa) to the covariate-model definition so the engine supports [#186].
- Every issue that uses the similarity ([#184], [#185], [#186], [#187], [#189], [#190], [#194], [#202]) gets a "Similarity statistic" note before its Goal: the default is `union_zero`, `shared` and `rarefied` are sensitivity analyses, and the preliminary numbers quoted were computed on shared taxa.

### [#190] Pace, [#182] Extraction, [#181] Slice errors

- No change in content. [#182]: records must carry `resolution` for the temporal family and functional-type stores. [#181] stays first in the order of work.

### [#191] RRatepol, [#192] Network rarefaction, [#193] Component removal, [#195] Matched-size refit

- [#191]: add "Candidate task for a co-author with rate-of-change expertise; ask in Round 0." [#192]: no change (2️⃣). [#193]: add "About 5 minutes per unit on GPU (reference run); 20–30 units are 2–3 hours; run before 31 December 2026 regardless of the gate outcome." [#195]: replace "width" with "matrix size"; stays conditional.

### [#197] Round 0 briefing

- Scope, change "the new question and its four axes" to "the new question, with time as the backbone and the observation-system, aggregation and nested-extent comparisons as robustness tests (28 October 2026 revision)".
- Replace "width-artefact figure" with "matrix-size figure".
- Questions, add: "whether the usability constraint on the functional-type classification (at least 15 balanced groups on both data sources) is acceptable to the trait co-authors".

### [#196], [#198], [#199], [#200] Writing and rounds

- [#196] and [#198]: replace "time, space, taxonomic resolution and observation system" with "time, with the observation-system, aggregation and nested-extent comparisons as robustness tests"; replace "width artefact" with "matrix-size effect". No change to dates.

## 6. New issue: family- and functional-type-level temporal reruns

**Title:** Rerun the paleo temporal models at family and functional-type level and compare the half-lives with genus level

**Labels:** 🧮Modelling, 🔀pipeline, 🌿taxonomy, 🏵️Traits and functional groups

**Milestone:** 1️⃣ Co-author round · Results skeleton (family fits before 31 December 2026 on GPU; functional-type fits as soon as [#179] adopts a classification, also before 31 December 2026 if possible; analysis in January 2027)

**Body:**

## Context

The paleo temporal models (`R/Pipelines/pipeline_paleo_temporal.R`; profiles `project_paleo_temporal_{europe,america,asia}` in `Configuration/Profiles/Main/Paleo/temporal.yml`) are fitted at genus level only (`data_processing: taxonomic_resolution: "genus"`) at continental extent. Between 500-year slices the residual association structure (`sjSDM::getCor()` matrices compared on shared taxa) decays with a half-life of about 2.1 kyr (North America) and 2.2 kyr (Europe).

The manuscript asks whether that persistence depends on the level of biological organisation. The spatial models exist at genus, family and functional-type level, but their matrices are small at local and regional extent (median 11–12 genera, 6–8 families, 5–8 functional types locally), and comparing a genus matrix with a family matrix requires a projection whose validity is uncertain ([#188]). Rerunning the temporal pipeline at coarser levels avoids both problems: the comparison is between decay curves estimated the same way, and the aggregation axis is expressed in the same units as the main result (a half-life). At continental extent the paleo functional-type models hold 16–20 groups with the current classification; the classification adopted in [#179] must satisfy the usability constraint recorded there (at least 15 balanced groups on both data sources), so that every slice pair shares at least 10 groups.

The expensive step of the temporal pipeline is community interpolation (8.5 h for Europe, `data_community_interpolated_dataset`), which runs before `classify_taxonomic_resolution()` in `R/Pipelines/_pipes/pipe_segment_community_prepare_paleo.R` and does not depend on the resolution. The 41 Europe slice fits took 0.2 h in total; cross-validated regularisation calibration 0.2 h; ANOVA 0.9 h. A rerun per continent and level therefore costs hours of fitting if the interpolation is reused, or about one day if it is rebuilt.

## Goal

Family-level and functional-type-level association matrices for every 500-year slice of Europe and North America (Asia if the genus-level run is retained), and a formal comparison of the half-lives across the three levels.

## Scope

- [ ] Add profiles `project_paleo_temporal_{europe,america}_{family,functional_type}` to `Configuration/Profiles/Main/Paleo/temporal.yml` with the matching `taxonomic_resolution`, separate `target_store` paths (for example `Data/targets/paleo_temporal_europe_family`) and `supported_runners` entries; regenerate `config.yml` through the documented generator, never by hand. Reuse the prebuilt interpolation (`R/Functions/Pipeline/Orchestration/Execution/run_pipeline_interpolation_prebuild.R`) if the store layout allows it; otherwise accept the rebuild.
- [ ] Add preparation and fitting runners under `R/02_Main_analyses/01_Preparation/_components/` and `R/02_Main_analyses/03_Model_fitting/_components/`, registered in their `Run_*.R` files and the runner allowlist.
- [ ] Fit with the production settings (cross-validated regularisation, `min_n_samples: 10`). Record the selected regularisation per slice. Production genus-level stores are never modified.
- [ ] Functional-type runs use the classification adopted in [#179] and start only after it is frozen; until then, the family runs proceed.
- [ ] Extend the association extraction ([#182]) and the similarity engine ([#183]) to the new stores; the records carry `resolution`.
- [ ] Decay analysis identical to the genus-level one ([#183]) per level: all slice pairs, similarity in the default `union_zero` mode with `shared` and `rarefied` as sensitivity, label permutation null, exponential-plus-floor fit on lags ≥ 2 kyr, bootstrap over slices, covariate regression with log(lag), log(minimum site count), log(shared groups), log(minimum groups).
- [ ] Contrasts: family minus genus and functional type minus genus half-life with 95 % bootstrap intervals over slices, per continent. Report floors and exceedance fractions side by side.
- [ ] Apply the reproducibility ceiling of [#184] to each level; if a level's ceiling is not measured, state that the comparison is uncorrected.
- [ ] Figure: decay curves at the three levels per continent on the same axes.

## Tests and validation

- [ ] `targets::tar_manifest()` for the new profiles; smoke run on two slices per continent and level.
- [ ] Confirm that the genus-level stores are unchanged (metadata timestamps).
- [ ] Tests for any new function; full suite and the architecture validator (`R/03_Supplementary_analyses/Validation/Architecture/README.md`).

## Acceptance criteria

- [ ] Family-level and functional-type-level matrices for every available slice of Europe and North America, with explicit status for infeasible slices.
- [ ] Half-life per level and continent with intervals, and the two stated contrasts.
- [ ] Figure produced by a committed script.
- [ ] Family fits finished on GPU before 31 December 2026; functional-type fits as soon as [#179] is adopted.

## Relationships

- Blocked by [#181] (slice status), [#182] (extraction), [#183] (similarity engine)
- Blocked by [#179] (functional-type arm only)
- Related to [#184] (ceiling), [#188] (projection check), [#189] and [#194] (functional-type arms)
- Part of [#180]

## 7. Changes to the Round 0 report ([#197])

In `Documentation/Reports/Third_report/_Project_status_and_direction.qmd`:

- Section "The new direction": explain the similarity statistic (union with zeros as the default, shared and rarefied as supports, their difference as the turnover contribution) and mark the preliminary numbers as shared-taxa values.
- Section "The new direction": replace the four equal axes with the §3 table and one paragraph saying that time is the backbone, that the other three comparisons test its robustness, and why the spatial half-distance was replaced by the nested-extent test (species-pool turnover, 8–9 regional units per continent, local matrices of 11 taxa).
- Add the family- and functional-type-level temporal reruns as the aggregation test, with the compute facts (fits are cheap; interpolation is the cost) and the dependency on the new classification.
- Say where functional types now carry weight: continental extent (temporal reruns, fossil–modern at continental tier, cross-continent recurrence), not local or regional units; and state the usability constraint on the classification.
- Soften the sentence that similarity "is not inflated by matrix size in the way a variance share is" to "is computed on the taxa the two models share; whether the estimate itself depends on matrix size is one of the checks below".
- Section "Three checks": becomes "Four checks" with the matrix-size rule.
- Co-author questions: add "Is the usability constraint on the functional-type classification (at least 15 balanced groups, same mapping for pollen and plots) acceptable, and which traits should drive it?" and "Would anyone take on the rate-of-change corroboration ([#191])?"
- Plan: the family fits, the [#184] and [#193] fits and, if [#179] lands in time, the functional-type fits all run on GPU before 31 December 2026.

Update `Coauthor_feedback/Round_0/README.md`, `response_table.md` and `Private/cover_email.md` with the added questions.

## 8. Order of work and GPU budget

GPU work that must finish before 31 December 2026, in start order:

1. [#181] slice errors (unblocks 0 ka and the reruns).
2. [#184] seed replicates and taxon-subset replicates (~95 fits; can start now, results not inspected before the rules are frozen after Round 0).
3. [#193] component removal on 20–30 units (2–3 h).
4. Family-level temporal rerun, Europe and North America (hours to a day per continent).
5. [#179] adoption decision, then the functional-type refits it triggers (spatial, paleo and modern, all tiers) and the functional-type temporal rerun. If [#179] cannot be adopted before mid-December, the functional-type arms move to the full-draft milestone and the manuscript reports genus and family only in the skeleton.

CPU work in parallel: [#182] extraction, [#183] engine, then [#185], [#186], [#190], [#194] on the genus-level artifact; [#187] and [#189] once [#184] reports the matrix-size rule; the family-level decay once its fits are in.

Writing milestones are unchanged: gate update about 4 December 2026, results skeleton 11 January 2027, full draft 15 March 2027, submission check 3 May 2027. These dates were superseded on 10 November 2026; the current calendar is in `ISSUE_PLAN.md`.

## 9. Applying the edits

Issue edits need the maintainer's authorisation. Suggested sequence, one command per issue, with the bodies prepared as files in a git-ignored folder:

```powershell
gh issue create --title "<title from §6>" --label "🧮Modelling" --label "🔀pipeline" --label "🌿taxonomy" --label "🏵️Traits and functional groups" --milestone "1️⃣ Co-author round · Results skeleton" --body-file <path>
gh issue edit 180 --body-file <path>
gh issue edit 184 --body-file <path>
gh issue edit 186 --title "Control the temporal decay for site overlap, covariance shrinkage and matrix size" --body-file <path>
gh issue edit 187 --title "Test whether residual association structure is consistent across nested spatial extents" --body-file <path>
gh issue edit 188 --title "Test whether genus-level association structure projects onto fitted family-level structure" --milestone "2️⃣ Co-author round · Full draft" --body-file <path>
gh issue edit 179 --body-file <path>
gh issue edit 185 --body-file <path>
gh issue edit 189 --body-file <path>
gh issue edit 194 --body-file <path>
gh issue edit 191 --body-file <path>
gh issue edit 193 --body-file <path>
gh issue edit 195 --body-file <path>
gh issue edit 197 --body-file <path>
gh issue edit 196 --body-file <path>
gh issue edit 198 --body-file <path>
```

Create the new issue first so that its number can replace `#202` in the other bodies.

<!-- Issue and pull-request links -->

[#179]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/179
[#180]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/180
[#181]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/181
[#182]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/182
[#183]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/183
[#184]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/184
[#185]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/185
[#186]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/186
[#187]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/187
[#188]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/188
[#189]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/189
[#190]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/190
[#191]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/191
[#192]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/192
[#193]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/193
[#194]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/194
[#195]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/195
[#196]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/196
[#197]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/197
[#198]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/198
[#199]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/199
[#200]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/200
[#202]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/202
