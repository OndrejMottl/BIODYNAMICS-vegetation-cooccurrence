# Implementation plan as GitHub issues — October 2026

23 October 2026. Turns `STATUS_AND_PLAN.md` (newest, takes precedence), `direction_review_20261023.md` §3–§6 and the run lists in `../manuscript_rework_skeleton_20261021.md` §7 and §9 into a set of issues. **Created on GitHub on 23 October 2026** with milestones 0️⃣–3️⃣ (milestone numbers 6–9):

| Plan ID | Issue | Plan ID | Issue | Plan ID | Issue |
|---|---|---|---|---|---|
| P0 | #180 | P7 | #187 | P14 | #194 |
| P1 | #181 | P8 | #188 | P15 | #195 |
| P2 | #182 | P9 | #189 | P16 | #196 |
| P3 | #183 | P10 | #190 | C0 | #197 |
| P4 | #184 | P11 | #191 | C1 | #198 |
| P5 | #185 | P12 | #192 | C2 | #199 |
| P6 | #186 | P13 | #193 | C3 | #200 |

The issue bodies on GitHub are self-contained and take precedence over the descriptions below, which they refine. In particular, component removal uses `R/Pipelines/pipeline_paleo_local_cv_decomposition_reference.R`, not the CZ component pipeline.

---

## 1. Facts checked against the repository that change the plan

| # | What the planning docs say | What the repository shows | Consequence |
|---|---|---|---|
| 1 | Q5 has 264 paired local and 30 paired regional fossil/modern units | Those are shared grid identifiers. Fitted, matched genus pairs are **46 local, 14 regional, 3 continental** (family 46/14/2, FT 28/7/3) in `Documentation/Reports/Model_evaluation/publication_products_2026-10-22/matched_unit_counts.csv` | Q5 is still feasible but its *n* is about 60, not about 300. State the real *n* in the issue and in the manuscript. |
| 2 | 97 temporal models (40 / 36 / 21) | 39 / 35 / 21 available; 28 slices `unexpected_error` (`temporal_slice_status_counts.csv`). The **0 ka slice is errored on all three continents**; Europe 18–20 ka and America 20 ka also fail; Asia 11–20 ka fail | Q6 ("pace toward the present") currently has no present-day slice. The Asia failures are probably outside its 10.5–0 ka design window and should be reclassified, not fixed. Needs its own issue (P1) before the decay numbers are frozen. |
| 3 | Modern spatial stores must wait for the CV rerun | Modern spatial completion (2026-10-20), sensitivity verification and the Stage 04/05 publication run (2026-10-22) are all done | Spatial and modern export is unblocked now. |
| 4 | `scripts/export_association_matrices_v2.R` does the export | It is a one-off script: base R, writes only to `Data/Temp/assoc_export`, and no `R/Functions/` helper extracts `sjSDM::getCor()` today | Committed analyses must not depend on `Data/Temp`, so the export must be rebuilt as tested functions (P2). |
| 5 | Skeleton §8 says item 1 (H2d, cross-continental pairs) is the decision point | `STATUS_AND_PLAN.md` says Step 0a (reproducibility ceiling) is the decision point and drops the recurrence framing | The newer document wins: P4 is the gate; H2d becomes optional (P14). |

---

## 2. Existing open issues — what to do with each

| Issue | Recommendation | Why |
|---|---|---|
| #171 Regenerate CV-backed model results and update the manuscript and website | **Keep and rescope.** Keep the freeze/provenance/results-inventory and website parts. Move "Update manuscript Results/Discussion" to P16 and link it there. Make P1 a sub-issue of #171. | #140 is closed and #177/#178 already regenerated most model outputs. Its manuscript tasks assume the old pipeline-shaped Results section. |
| #179 Evaluate deep sequential clustering for FT groups | **Keep, promote to the critical path.** Make it a sub-issue of P0 and a blocker of P8. Suggested additions to its body below. | The current FT classification is degenerate: one huge group holding most taxa plus a few highly specialised rare groups. Q4 compares functional with taxonomic and random grouping, and such a split cannot answer that, because the giant group behaves like "everything" and the small ones like noise. |
| #136 Add future diversity prediction workflow for CMIP6 | **Park.** Not part of this paper. | Off the critical path; competes for GPU time. |
| #26 Change the binomial model to a hurdle model | **Suggest closing as not planned** (your decision). | Changing the likelihood would invalidate every fitted model the new direction relies on. |
| #166 Modularise the R architecture diagnostics engine | **Independent.** No change. | Tooling, unrelated to the science. |

Milestones: one per co-author round rather than one for the whole manuscript. See §5–§6.

### Suggested additions to #179 (edit, not a new issue)

- **A cheap baseline benchmark first.** The fallback uses average linkage with silhouette selection over 5–30 groups. Average linkage on Gower distances is prone to chaining, which produces exactly one giant cluster plus outlier singletons, and silhouette can reward that split. Benchmark Ward linkage and PAM (k-medoids) on the same Gower matrix next to the autoencoder variants. If a simple method already gives balanced, coherent groups, the deep-clustering variant has to beat it to be adopted.
- **Group-balance criteria in the acceptance rule:** largest-group share, effective number of groups (exp of Shannon entropy over group sizes), and the minimum number of usable groups after the community-filter chain. Silhouette alone should not decide.
- **A criterion tied to Q4:** groups must be usable in a random-grouping null with the same size distribution, so that P8 can compare functional, taxonomic and random grouping on equal terms.
- **The cost of switching:** adopting a new classification means refitting every FT model (paleo and modern spatial, all tiers) and rerunning the FT variance-partitioning outputs. Estimate GPU time in the issue, and run the refits once for both the existing FT results and P8.

---

## 3. New issues

Labels use the repository's existing set. "Done when" lines become the acceptance criteria.

### P0 — Umbrella

**Title:** Measure how far residual co-occurrence structure persists across time, space, resolution and observation system
**Labels:** 📜manuscript, 🧮Modelling
**Body:** The question, the four axes, the decision table from `STATUS_AND_PLAN.md` Part 4, links to the planning folder, and a checklist of P1–P16 plus the existing #179 as sub-issues. Includes a **decision record** section filled in after P4–P6: which of the three outcome rows applies, and therefore which framing P16 writes.
**Done when:** all non-conditional sub-issues are closed and the decision record is filled in.

### Foundation

#### P1 — Resolve unexpected errors in cached paleo temporal slices

**Labels:** 🐛 bug, 🔀pipeline, 🧮Modelling — sub-issue of #171
**Scope:** Classify each of the 28 `unexpected_error` slices in `temporal_cached_error_rows.csv`. Reclassify Asia 11–20 ka as expected limitations if they fall outside the configured window. Reproduce and correct the 0 ka failures (all three continents) and the Europe 18–20 ka / America 20 ka failures, following `.ai/debugging.md` (`data_sample_ids must be a data frame`, `ZeroDivisionError`). Refit only the affected slices.
**Done when:** every slice is either available or has a documented expected status; the 0 ka slice exists for Europe and America; the temporal synthesis reruns without unexpected errors.
**Depends on:** nothing. **Blocks:** final numbers in P3, P10.

#### P2 — Extract residual association and community matrices from fitted model stores

**Labels:** 💻code, 🔀pipeline, 🗂️data, 🀄Tests
**Scope:** Tested functions (one per file, names checked against `r_naming_decisions_v1.md`) that, for any fitted unit, return: the residual correlation matrix from `sjSDM::getCor()`; the binarised site × taxon matrix it was fitted to; site identifiers and coordinates; unit centroid; number of sites and taxa; tuned regularisation (`lambda_cov`, `alpha_cov`) and latent dimension; seed and store hash. A read-only runner loops over the temporal, paleo spatial and modern spatial stores (`<store>/<unit_id>/pipeline_*/objects`), never calls `tar_make()`, and writes a versioned artifact to `Data/Processed` or `Outputs/Data`, not `Data/Temp`. Replaces `scripts/export_association_matrices_v2.R`.
**Done when:** all available temporal and spatial units (genus, family, FT) are exported; site IDs and regularisation are present; the temporal matrices reproduce `data/lag_similarity.csv` observed values; tests and the architecture validator pass.
**Depends on:** nothing (P1 adds slices later). **Blocks:** P3–P14.

#### P3 — Build the association-similarity engine and reproduce the temporal half-life

**Labels:** 💻code, 🧮Modelling, 🀄Tests, 🖼️visualisation
**Scope:** Axis-agnostic functions that take any table of matrix pairs plus a separation (lag, distance, resolution step, observation system) and compute: Spearman similarity of off-diagonal values on shared taxa; a taxon-label permutation null (mean and 97.5th percentile); per-pair exceedance; the exponential-plus-floor fit on lags ≥ 2 kyr with half-life and interval; and the regression of similarity on log separation, log minimum site count and log shared taxa. Reproduce Fig 4a–b. The same code serves P5–P9.
**Done when:** the pipeline reproduces half-lives of about 2.1 kyr (America) and 2.2 kyr (Europe) and lag coefficients of about −0.109 / −0.116 from the P2 artifact; differences from the planning numbers are explained; Fig 4a–b is produced by a committed script.
**Depends on:** P2.

### Validity gate (Step 0) — decides the framing

#### P4 — Measure the reproducibility ceiling of fitted association matrices

**Labels:** 🧮Modelling, 🔀pipeline, 🔁Cross-validation
**Scope:** A supplementary seed-replicate sensitivity pipeline (modelled on `pipeline_sjsdm_common_regularization_sensitivity.R`): refit one temporal slice per continent (Europe, America) about 10 times with different seeds at the selected hyperparameters, plus one paleo spatial unit per tier so the spatial axes have a ceiling too. Compute replicate-to-replicate similarity with the P3 engine. Re-express the half-life relative to the ceiling. **Write the decision rule into the issue before running** (≈0.9 → measurement sound; ≈0.6 → pivot to the methods paper).
**Done when:** ceilings per continent and tier are reported with spread; the ceiling-corrected half-life is computed; the P0 decision record is updated.
**Depends on:** nothing to start the fits (GPU, can run immediately alongside P2); P3 for the similarity numbers.

#### P5 — Compare residual decay with raw co-occurrence and compositional turnover

**Labels:** 🧮Modelling, 💻code
**Scope:** From the P2 binarised matrices, compute the input-derived taxon × taxon matrix (φ and Jaccard) and between-slice compositional turnover on shared taxa. Run the identical similarity statistic and decay fit on all three. Test whether residual half-life differs from raw co-occurrence half-life (bootstrap over slices). Covers Step 0b and skeleton items 9 and 10.
**Done when:** three decay curves per continent on the same axes; a stated contrast with interval; the P0 decision record is updated.
**Depends on:** P2, P3.

#### P6 — Control the temporal decay for site overlap and covariance shrinkage

**Labels:** 🧮Modelling
**Scope:** Add pairwise site overlap (Jaccard of site IDs between slices) and tuned regularisation strength as covariates to the P3 regression; report how the lag coefficient changes. Covers Step 0c and skeleton item 7.
**Done when:** the lag effect is reported with and without each control on both continents.
**Depends on:** P2, P3.

> **Decision point.** After P4, P5 and P6, fill in the P0 decision record. P7–P10 assume the "ceiling high" rows; if the ceiling is low, P7–P10 are deprioritised and P13 plus the width artefact become the paper.

### The open questions

#### P7 — Estimate the spatial half-distance of residual association structure (Q3)

**Labels:** 🧮Modelling, 🖼️visualisation
**Scope:** Within each tier and resolution of the paleo spatial grid, compute similarity between every unit pair on shared taxa against centroid distance, with the P3/P6 covariates; fit exponential-plus-floor; use a unit-level permutation or bootstrap that respects spatial non-independence. Repeat on the modern grid as replication. Covers skeleton item 8 (Fig 4d).
**Done when:** half-distance per tier and continent with intervals, or a documented null; figure panel produced.
**Depends on:** P2, P3; interpretation uses P4.

#### P8 — Test whether association structure survives taxonomic and functional aggregation (Q4)

**Labels:** 🧮Modelling, 🏵️Traits and functional groups, 🌿taxonomy
**Scope:** For each unit, project the genus matrix to family and to FT level using the existing harmonisation and frozen FT tables, and compare with the matrix fitted at that level. Define the projection explicitly (for example the mean member-pair correlation) and justify it, since presence aggregation is a union rather than a sum. Null: random groupings with the same group-size distribution (skeleton item 4, H1b), so the result can say whether functional grouping preserves more than taxonomic or random grouping.
**Done when:** survival profile genus → family → FT against the random-grouping null, per tier, using the FT classification adopted in #179.
**Depends on:** P2, P3, **#179 and the FT refits that follow from it**. The genus → family arm can run before #179 closes; the FT arm must wait. Results from the current FT classification may be shown only as a diagnostic of why it was replaced.

#### P9 — Compare fossil and modern association structure in the same grid cells (Q5)

**Labels:** 🧮Modelling, 🖼️visualisation
**Scope:** For every matched fossil/modern unit (currently 46 local, 14 regional, 3 continental at genus level; confirm from P2), compute similarity on shared harmonised taxa. Null: fossil and modern matrices from *different* cells in the same tier. Report the real *n* per tier and resolution.
**Done when:** same-cell versus different-cell similarity per tier with a permutation test.
**Depends on:** P2, P3.

#### P10 — Model the pace of association rewiring against age and sampling (Q6)

**Labels:** 🧮Modelling
**Scope:** Adjacent-slice rewiring (1 − similarity) modelled jointly against midpoint age, shared-taxon count, minimum site count and site overlap; repeat after rarefying to a fixed number of shared taxa. Covers skeleton item 12 and the America shared-taxon caveat.
**Done when:** the deceleration (America) and flat trend (Europe) are confirmed or withdrawn under the joint model, including the 0 ka slice.
**Depends on:** P1, P3, P6.

#### P11 — Recompute rate of change per continent with RRatepol

**Labels:** 💻code, 🧮Modelling, 🖼️visualisation
**Scope:** `RRatepol` in its native per-sequence design, with age-model iterations and count rarefaction, summarised per continent in 500-year bins. Builds the three-row figure (raw co-occurrence turnover from P5, residual rewiring from P10, RoC) on a shared age axis. Corroboration, not the comparator. Covers skeleton item 11.
**Done when:** per-continent RoC curves with uncertainty; the three-row figure is produced by a committed script.
**Depends on:** core-level data only; the figure needs P5 and P10.

### Supporting analyses

#### P12 — Rarefy network metrics per temporal slice

**Labels:** 🧮Modelling, 🖼️visualisation
**Scope:** Repeatedly subsample sites to the smallest per-slice count and recompute `compute_network_metrics()` (modularity, connectance, nestedness) for Europe and America. Settles H3b and Fig 5a. H3c (spatial-to-climatic shift) would need refits and is out of scope; record that in the issue.
**Done when:** rarefied modularity per slice with intervals; Europe's de-modularisation either survives or is withdrawn.
**Depends on:** P2 (binarised matrices) or the existing `data_to_fit` targets.

#### P13 — Generalise component-removal cross-validation to multiple spatial units

**Labels:** 🔁Cross-validation, 🧮Modelling, 🔀pipeline
**Scope:** Extend `pipeline_cz_paleo_cv_component_reference.R` to about 20–30 units stratified by tier, continent and resolution (about 5 min per unit on GPU). Report Δ log loss, Brier, Tjur R² and AUC for removing each block, and fitted ANOVA share against held-out effect per unit. Covers H4a–b and Fig 6; central to the methods-paper fallback.
**Done when:** per-unit component effects and the ANOVA-versus-held-out comparison exist for at least 20 units.
**Depends on:** nothing; can run whenever the GPU is free.

#### P14 — Test whether long-lag associations recur between continents (optional)

**Labels:** 🧮Modelling
**Scope:** For the 32 genera shared between the European and North American temporal models (9 present in every slice), test sign and rank agreement of pair associations between continents, with a null built from the observed sign distribution rather than 50/50. Covers H2d and Fig 4c.
**Done when:** agreement statistic with null, and a list of agreeing pairs if any.
**Depends on:** P2, P3. Low priority; a few hours.

#### P15 — Refit spatial units at matched taxon number (conditional)

**Labels:** 🧮Modelling, 🔀pipeline
**Scope:** Taxon-number-matched refits across the spatial grid to replace the regression-adjusted width correction (H1a, Fig 2b, Fig 3a–b). Heavy. Create only if co-authors or reviewers require more than the regression result.
**Depends on:** nothing technical; a decision.

### Writing

#### P16 — Rewrite the manuscript around the persistence scales of residual structure

**Labels:** 📜manuscript, 🖼️visualisation, 📝method documentation
**Scope:** Write Introduction, Results, Discussion and Abstract for the framing chosen in the P0 decision record; add Methods for the extraction, similarity engine, null models and reproducibility ceiling; replace the pipeline-shaped Results outline; all numbers as inline R; figures from committed scripts. Takes over the manuscript tasks of #171.
**Done when:** a complete draft renders with every number traceable to an artifact.
**Depends on:** P0 decision record, then P3–P13 as their sections are written.

---

## 4. Order of work

```text
Now, in parallel:   P1 (temporal errors)   P2 (extraction)   P4 fits on GPU   #179 (FT method)
Then:               P3 (engine, reproduce half-life)   FT refits once #179 picks a method
Gate:               P4 + P5 + P6  ->  P0 decision record
If ceiling high:    P7  P8 (FT arm after FT refits)  P9  P10  (+ P11, P12, P14 alongside)
Then:               P16 (manuscript)
GPU when free:      P13
Conditional:        P15
```

There are two critical paths. One is P2 → P3 → P4/P5 → decision. The other is #179 → FT refits → P8. Start #179 now: it is independent of the gate, and its refits compete for the same GPU as P4 and P13, so plan the GPU queue as P4 first, then FT refits, then P13. P1 must finish before P10 and before the half-life is quoted as final, because it adds the 0 ka slice.

---

## 5. Co-author communication

### What the co-authors last saw

| Occasion | Date | What it told them | Status now |
|---|---|---|---|
| First report and presentation (`Documentation/Reports/First_report/`) | Oct–Nov 2025 | Technical pipeline, HMSC, Czech test project; next steps included a hurdle model and validation with spOccupancy | Models are now `{sjSDM}`; hurdle model suggested for closure (#26) |
| Second presentation (`Documentation/Reports/Second_report/`) | Mar 2026 | Q1: is there scale dependence in the *amount* of unexplained variation? Q2: does including biotic interactions improve prediction? Residual co-occurrence presented as "biotic interactions", positive = facilitation, negative = competition | Q1 is answered by the width artefact: the amount cannot be compared across models, and the apparent spatial gradient reverses at matched width. "Interaction" language is dropped. Q2 survives as the component-removal experiment (P13) |
| IAVS / CSPE 2026 talks (if co-authors attended or saw the slides) | Jun / Aug 2026 | Frozen 31 Aug snapshot | Functional-type fractions moved from 5–8 % to 17–24 % after the trait correction |

Every co-author therefore holds a mental model that the manuscript now contradicts. The first manuscript round must not be the first time they see the new direction.

### Rounds

Keep the usual three rounds and add a short **Round 0** in front of them, plus one information-only update at the gate.

| Round | When | What is sent | What is asked | Window |
|---|---|---|---|---|
| **0 — Direction briefing** | Now, before the gate results | A short report in the style of the first two, `Documentation/Reports/Third_report/`, with a 30–45 min call offered. Content: what changed since March and why (the width artefact, using `figures/taxon_count_confound.png`); the new question about persistence across time, space, resolution and observation system; the preliminary half-life (`figures/assoc_decay.png`, numbers rounded and marked preliminary); the validity gate with its three possible outcomes and the decision rule written before the results; a table "numbers you may remember and what they are now" | Objections to the direction; comments on the decision rule; open decisions (one paper or a series, venue, whether Asia is main text, the functional-type method in #179); expertise for specific questions (pollen–plot taxon harmonisation for Q5, trait grouping for Q4, rate of change for P11) | 2 weeks |
| **Gate update** | When P4–P6 close | A one-page note: ceiling, raw co-occurrence contrast, which outcome row applies, and therefore which paper is being written | Objections only, no line comments | 1 week |
| **1 — Initial stage** | Core results exist: P3–P9 done, at least the genus → family arm of Q4 | Results skeleton as a line-numbered PDF: title, abstract draft, Introduction as paragraph-level claims, Results as claims with real numbers and real Figures 1–4, existing Methods, Discussion outline. Missing pieces are marked, not hidden | Is the story right? Which analysis is missing or unconvincing? Which claim would a reviewer attack first? Mostly Major comments are expected | 2–3 weeks |
| **2 — Main feedback** | Full draft: P10–P14 done, P16 written, Round 1 comments resolved | Complete manuscript with supplement and figures, plus a response table for Round 1 comments | Full line-by-line review | 3 weeks |
| **3 — Last check** | Submission package ready | Final manuscript, supplement, cover letter, author contributions (CRediT), data and code availability, list of suggested reviewers | Errors, approval to submit, and author details | 1 week |

### Co-authors and targeted asks

Provisional list (not final). Emails are kept out of the repository on purpose. The asks filled in below were confirmed on 2026-10-23; empty rows still need one.

| Co-author | Possible targeted ask in Round 0 and Round 1 |
|---|---|
| Franka Gaiser (Bayreuth) | |
| Gregor Mathes | |
| Natalie Hanusová | |
| Jonathan Gordon (York) | First author of Gordon et al. 2024 (*Nat. Ecol. Evol.*), which the paper uses as the accelerating half of the Q6 contrast: whether our compositional-turnover curve matches theirs, and the design of P11 |
| Jack W. Williams (Wisconsin) | North American pollen data and no-analogue communities: whether the half-life and the North American slowdown are plausible, and the pollen–plot comparison in Q5 |
| Manuel Steinbauer (Bayreuth) | |
| Suzette Flantua | Pollen data synthesis: site-overlap and sampling controls (P6), and what can be compared between fossil and modern data in Q5 |
| Irena Šímová | *Suggested, to confirm:* plant functional traits and their macroecology. The functional-type method in #179 (are the groups ecologically coherent, and are the six traits the right basis?) and the aggregation question Q4 (P8) |
| Name to add (co-author 9, Charles University) | |

Before Round 1, enter final names, ORCIDs and affiliations in `manuscript.qmd`, and agree CRediT roles roughly at Round 0 so that nobody is surprised at Round 3.

### Mechanics, reusing what exists

- Each round uses `Documentation/Manuscript/Coauthor_feedback/Round_N/` and `feedback_template.md` unchanged. Round 0 and the gate update are reports rather than manuscript versions, so they don't need the template; collect their replies as `Coauthor_feedback/Round_0/<Name>_feedback.md` or as notes from the call.
- Before each manuscript round, tag the commit `manuscript-round-N` (you run the tag) and render the PDF with line numbers into the round folder.
- After each round, consolidate all returned files into one response table in the round folder. Each Major comment becomes either a new issue in the next round's milestone or a reasoned reply in the table. Minor and editorial comments are handled in a single "address Round N comments" issue.
- Fill in `manuscript.qmd` co-author names and affiliations before Round 1 (they are still `TODO`).

### Calendar

The grant ends on 31 December 2026. A 12–18 month extension of the final report will be requested, which moves the report deadline to between December 2027 and June 2028. The paper should be published, or at least accepted, by then. Plan for the shorter extension: if only 12 months are granted, the paper needs to be submitted by about May 2027 to leave about seven months for review, revision and one possible resubmission elsewhere.

| Step | Send | Feedback by | Notes |
|---|---|---|---|
| Round 0: direction briefing | Fri 6 Nov 2026 | Fri 20 Nov 2026 | Call in the week of 16 Nov. Also ask co-authors about their availability from January to May 2027 and their preferred venue order |
| Gate update | about Fri 4 Dec 2026 | Fri 11 Dec 2026 | Needs P2, P3, P4–P6 |
| Round 1: initial stage | Mon 11 Jan 2027 | Mon 1 Feb 2027 | Sending in mid-December would put the feedback window over Christmas |
| Round 2: main feedback | Mon 15 Mar 2027 | Mon 5 Apr 2027 | Easter falls on 28 March 2027, inside the window; three weeks covers it |
| Round 3: last check | Mon 3 May 2027 | Mon 10 May 2027 | |
| Submission | by Fri 21 May 2027 | | |

Two consequences of the grant ending on 31 December 2026:

- **Do grant-funded work in 2026.** If GPU time, cloud compute or paid help comes from the grant, run the heavy computing before the end of December: the P4 replicate fits, the functional-type refits after #179, P13 component removal, and P15 if it is triggered. Analysis and writing can continue in 2027.
- **Round 0 doubles as extension evidence.** The briefing report, this plan and the milestone due dates are a concrete work plan to attach to the extension request.

A venue cascade agreed in Round 0 saves time later. A desk rejection costs about one to two months and a rejection after review about three to four, so with a 12-month extension there is room for one of each, not more.

---

## 6. Milestones

One milestone per round. A milestone holds the work that must be finished **before** that round is sent; its due date is the planned send date. The round's own communication issue (labelled 🗣️communication) sits in the same milestone and closes when the feedback is consolidated.

| Milestone | Due (send date) | Issues | Closes when |
|---|---|---|---|
| **0️⃣ Co-author round · Direction briefing** | 2026-11-06 | C0 Prepare and send the direction briefing; the decision rule written into P4 | The briefing has been sent and replies consolidated |
| **1️⃣ Co-author round · Results skeleton** | 2027-01-11 | P1, P2, P3, P4, P5, P6, P7, P8, P9, #179; C1 Send and consolidate Round 1 | The skeleton has been sent and Round 1 comments triaged |
| **2️⃣ Co-author round · Full draft** | 2027-03-15 | P10, P11, P12, P13, P14, P16; Round 1 follow-up issues; P15 if triggered; C2 Send and consolidate Round 2 | The full draft has been sent and Round 2 comments triaged |
| **3️⃣ Co-author round · Submission check** | 2027-05-03 | #171 (provenance, results inventory, website); figure polishing from `visual_review.csv`; submission package (cover letter, CRediT, data and code availability, code and data archive); Round 2 follow-up issues; C3 Send and consolidate Round 3 | Co-authors approve submission |

The grant-funded computing in P4, the functional-type refits and P13 (and P15 if triggered) should finish by 2026-12-31, even though P13 belongs to the Round 2 milestone.

P0 stays outside the milestones as the umbrella and holds the gate update as a checklist item ("send the gate note within a week of P6 closing"). If Q4's functional-type arm is late, move P8 alone to the Round 2 milestone rather than delaying Round 1.

### Communication issues

| ID | Title | Labels |
|---|---|---|
| C0 | Brief co-authors on the revised manuscript direction | 🗣️communication, 📜manuscript |
| C1 | Share the results skeleton with co-authors for Round 1 feedback | 🗣️communication, 📜manuscript |
| C2 | Share the full manuscript draft with co-authors for Round 2 feedback | 🗣️communication, 📜manuscript |
| C3 | Share the submission version with co-authors for final approval | 🗣️communication, 📜manuscript |

Each C issue carries the same checklist: material ready and rendered → tag `manuscript-round-N` (manuscript rounds only) → send with deadline → collect replies in the round folder → consolidated response table → Major comments filed as issues in the next milestone.
