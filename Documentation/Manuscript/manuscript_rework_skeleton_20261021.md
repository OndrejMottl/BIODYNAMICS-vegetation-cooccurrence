# BIODYNAMICS manuscript plan — consolidated

Supersedes the earlier skeleton. Rewritten after the association-decay result of 21 October 2026, which changed the spine of the paper.

**Status key:** ✅ established from the current data · ⚠ established but confounded, needs a control · ⏳ not yet run.

---

## 1. The claim

> Plant communities hold a **constant amount** of structure that climate and
> space cannot explain — across 20,000 years, three continents, four orders of
> magnitude of spatial extent and two independent observation systems — while
> **continuously rewiring what that structure consists of**, with a half-life of
> about two thousand years. The scale-dependence previously reported for this
> quantity is an artefact of how it is measured.

Constant magnitude, continuous turnover. That pairing is the paper.

### Title

**Working title (user's preference):** *Conserved assembly rules behind 20,000 years of vegetation reorganisation.*

It fits the results, on one condition: "conserved" must be scoped in the abstract to the **partition and the pace of rewiring**, not to the identity of species pairs — which demonstrably is *not* conserved (half-life ≈ 2 kyr). With rate-of-change added (§9) the title becomes tighter still, because "reorganisation" acquires a measured quantity rather than a vague one.

Alternatives kept on the shelf: *A two-thousand-year half-life for plant species associations*; *Vegetation changed ever faster without rewiring any faster*.

---

## 2. Research questions

| # | Question | Role |
|---|---|---|
| **Q0** | Is the residual-association share comparable between models of different width? | Methodological premise; everything downstream depends on it |
| **Q1** | Does the *amount* of residual structure depend on spatial extent, taxonomic resolution, observation system, or time? | The invariance result |
| **Q2** | Does the *identity* of residual associations persist through time? | The turnover result — the centrepiece |
| **Q3** | Do continents differ in how fast they rewire? | The divergence result |
| **Q4** | Does the residual carry transferable predictive information at all? | Licenses treating it as signal rather than noise |

---

## 3. Hypotheses

| ID | Hypothesis | Current evidence | Status |
|---|---|---|---|
| **H0** | The association share is not comparable across models of different width | log(n taxa) alone: R² = 0.675, slope +12.1 pp per e-fold, p = 2.5 × 10⁻⁵⁷; η² = 0.516 vs 0.046 for taxonomic resolution | ✅ |
| **H1a** | Residual share is higher at fine spatial extent | Raw medians 30.7 / 34.4 / 41.4 (local/regional/continental) **reverse** to 27.1 / 24.9 / 18.6 at matched taxon number | ⚠ regression-adjusted; needs rarefied refits |
| **H1b** | Functional aggregation removes structure beyond the width effect | — | ⏳ random-aggregation null |
| **H1c** | Fossil and modern windows give different partitions | Continental genus, predictor-inclusive: climate 69 % (pollen) vs 48 % (plots); space 41 % vs 52 %; association 54 % vs 50 % | ✅ continental tier only |
| **H1d** | The residual share is stable through 20 kyr | Flat in all three continents, and **uncorrelated with sampling effort** (Europe p = 0.66, Asia p = 0.98; America weak, p = 0.032) | ✅ |
| **H2a** | Association identity persists through time | Exponential-plus-floor fit on lags ≥ 2 kyr: **half-life 2.1 kyr (America), 2.2 kyr (Europe)** | ✅ |
| **H2b** | A conserved core survives the full glacial–interglacial span | Floor +0.116 [0.095, 0.131] America vs null 97.5 = 0.095; +0.096 [0.067, 0.115] Europe vs null = 0.116 | ❌ **rejected on the mean** — no strong conserved core |
| **H2c** | Some pair identity nonetheless survives the longest lags | At 13.5–20 kyr, 50 % (America) and 31 % (Europe) of slice pairs exceed their **own** null 97.5th percentile, vs 2.5 % by chance | ✅ |
| **H2d** | The surviving long-lag pairs are the *same* pairs in both continents | 32 genera shared between EU and AM models; 9 present in every slice of both | ⏳ **the decisive untested question** |
| **H3a** | Europe rewires faster than North America | 31 % vs 50 % exceedance at the longest lags, under near-identical sampling trajectories (ρ(age, sites) = −0.95 / −0.99) | ✅ |
| **H3b** | Europe's co-occurrence network also de-modularises | Modularity Q 0.375 (17.5 ka) → 0.163 (6 ka) → 0.282 (0 ka); ρ vs age = +0.699, p = 2.2 × 10⁻⁶; America flat | ⚠ confounded with site count (ρ = −0.83); needs per-slice rarefaction |
| **H3c** | Europe's assembly shifts from spatial to climatic control | Spatial share ρ = +0.70 (p = 3.2 × 10⁻⁶), abiotic ρ = −0.37 (p = 0.027), association flat (p = 0.39); America flat | ⚠ spatial term correlates with site count (ρ = −0.68) |
| **H4a** | Removing the residual block costs held-out performance | Δ log loss 0.0261, Δ Brier 0.0043, Δ Tjur R² 0.0131, Δ AUC ≈ 0 (CI spans zero); climate costs 0.076 / 0.030 / 0.149 / 0.225 | ✅ **one unit only** |
| **H4b** | Fitted variance fractions misstate predictive magnitude | Same unit's ANOVA: A 0.933, B 0.541, S 0.418, three-way shared **−6.85** | ✅ one unit only |

Two hypotheses carry the paper's risk: **H2d**, which decides whether there is a recurrence story at all, and **H3b**, which decides whether Figure 5 survives. Both are cheap.

---

## 4. Figures

### Fig 1 — Design and coverage
*One framework, two observation systems, 20 kyr, three continents.*

| Panel | Content | Status |
|---|---|---|
| a | Northern-hemisphere map: fossil cores and modern plots, continental boxes | drafted |
| b | Samples per 500-yr slice per continent | ✅ data ready |
| c | The three analysis axes | drafted |
| d | Model structure: climate + spatial eigenvectors + latent covariance | drafted |

### Fig 2 — The measurement correction
*The association share scales with model width; matching width reverses the spatial gradient.*

| Panel | Content | Status |
|---|---|---|
| a | Association share vs number of modelled taxa, by resolution | ✅ computed |
| b | Raw vs width-matched spatial gradient | ⚠ regression-adjusted → ⏳ rarefied |
| c | Functional types vs random groups of equal size | ⏳ |
| d | The `eu_r005_l010` ANOVA fractions, including −6.85 | ✅ |

This leads, not because it is the most interesting result but because every number after it depends on it being handled.

### Fig 3 — Constant magnitude
*The amount of residual structure barely moves on any axis.*

| Panel | Content | Status |
|---|---|---|
| a | Three components × three extents, paleo, width-matched | ⏳ rarefied refits |
| b | Same for modern | ⏳ Stage 04/05 rebuild |
| c | Pollen vs plots at the continental tier | ✅ |
| d | The three shares per 500-yr slice, three continents — flat | ✅ |

### Fig 4 — Millennial turnover *(centrepiece)*
*What the structure consists of is replaced with a half-life of ~2 kyr.*

| Panel | Content | Status |
|---|---|---|
| a | Association similarity vs time lag, Europe and America, with permutation-null envelope and fitted decay | ✅ **done** |
| b | Fraction of slice pairs exceeding their own null, by lag bin | ✅ **done** |
| c | The conserved pairs that do survive the longest lags — named, and tested for continental agreement | ⏳ H2d |
| d | Recurrence across independent spatial units at one scale (replication in space rather than time) | ⏳ |

### Fig 5 — Continental divergence
*Europe rewires faster and de-modularises; North America does neither, under the same sampling trajectory.*

| Panel | Content | Status |
|---|---|---|
| a | Rarefied modularity Q per slice, three continents | ⚠ → ⏳ rarefaction |
| b | Spatial and climatic shares through time, Europe vs America | ⚠ |
| c | Sites per slice — the sampling rebuttal, kept in the main figure | ✅ |

### Fig 6 — What the residual is worth *(or Extended Data)*
*The residual block improves calibration, not ranking; fitted fractions do not predict that.*

| Panel | Content | Status |
|---|---|---|
| a | Δ log loss / Brier / Tjur R² / AUC for removing each block, across units | ⏳ multi-unit run |
| b | Fitted ANOVA share vs held-out effect, one point per unit-component | ⏳ |

If the journal caps main figures at five, this becomes Extended Data with one sentence in Results — but the argument needs it somewhere.

---

## 5. Section plan

**Introduction** — five paragraphs: (1) composition is partitioned between abiotic control, spatial processes and residual co-occurrence; (2) the residual is assumed scale-dependent, rarely tested on matched models — cite König et al. 2021 and Mod et al. 2020 here, not in the Discussion; (3) deep time is the only way to ask whether the balance is a constant or a function of climate state; (4) VegVault makes observation system a testable axis rather than a caveat; (5) what we do. **Do not use the word "interaction" in this section.**

**Results** — in figure order: the measurement correction; constant magnitude; millennial turnover; continental divergence; predictive worth. Data overview and model performance go to Table 1 and Extended Data, not a leading subsection.

**Discussion** — (1) constant magnitude with continuous turnover, and what that implies about assembly; (2) the measurement correction and the existing scale-dependence literature; (3) why Europe and not North America — barriers, refugial compression, extinction filter; (4) what cannot be concluded: residual covariance is not interaction, pollen integrates catchments and centuries, three continents is three replicates; (5) forecasting — projecting occurrence and projecting co-occurrence have different error budgets, and the ~2 kyr half-life is the first empirical bound on how fast co-occurrence information decays.

---

## 6. Prior art to position against

| Work | What it establishes | Your relation to it |
|---|---|---|
| König, Wüest & Graham 2021, *J. Biogeogr.* `10.1111/jbi.14106` | jSDM associations shift with grain (125–1000 m), switch sign across scales, correlate with functional similarity | Your width artefact offers a mechanism for their instability |
| Mod, Chevalier & Luoto 2020, *J. Ecol.* `10.1111/1365-2745.13434` | Biotic-interaction strength does not vary consistently across plot sizes 0.04–64 m² | Your invariance extends theirs to continental extent and explains why |
| Liu, Jia & Liu et al. 2026, *Nat. Commun.* `10.1038/s41467-026-77801-9` | Arctic sedaDNA, 9 lakes, 24 ka: plant interactions shifted positive → negative with woody encroachment | **Direct competitor, opposite conclusion.** Engage in the Discussion; do not let a reviewer introduce it |
| Zurell, Pollock & Thuiller 2018, *Ecography* `10.1111/ecog.03315` | jSDMs do not reliably recover known interactions | The reason you never say "interaction" |
| Vallé, Poggiato & Thuiller 2023, *J. Biogeogr.* `10.1111/jbi.14752` | Data type, resolution and sampling size affect residual associations | Width is the axis they did not test |
| Schulz, Saastamoinen & Vanhatalo 2025, *Ecol. Monogr.* `10.1002/ecm.1646` | Variance partitioning is interpretable only under stated conditions | General frame for your specific mechanism |
| Hui, Vu & Hooten 2024, *MEE* `10.1111/2041-210x.14420` | Spatial random effects and species associations are mutually confounded | Must be cited in Methods for the MEM component |

Genuinely unclaimed, as far as the OpenAlex scan found: the width dependence of jSDM variance fractions; jSDMs on fossil pollen; network metrics on pollen assemblages through time; the matched fossil-modern comparison; and the persistence timescale of residual community structure.

---

## 7. What still has to be run

| # | Work | Unblocks | Cost |
|---|---|---|---|
| 1 | **Do the surviving long-lag pairs match between continents?** | H2d, Fig 4c — decides whether there is a recurrence story | hours, data already exported |
| 2 | Per-slice rarefaction of network metrics | H3b, Fig 5a | days, no refitting |
| 3 | Taxon-number-matched refits across the spatial grid | H1a, Fig 2b, Fig 3a–b | the binding constraint; refits of existing units |
| 4 | Random-aggregation null | H1b, Fig 2c | days, no refitting |
| 5 | Multi-unit component removal (~20–30 units) | H4a–b, Fig 6 | ≈5 min/unit on GPU |
| 6 | Modern Stage 04 + Stage 05 rebuild | Fig 3b | already scoped |
| 7 | Shrinkage control (`lambda_cov`) on the decay analysis | Fig 4 robustness | hours |
| 8 | Spatial-replicate version of the decay test | Fig 4d | hours |

Items 1, 2, 4, 7 and 8 are days of work in total and settle every open hypothesis except H1a and H4. Item 3 remains the only genuinely heavy one.

---

## 8. Honest venue read

With items 1–8 done this is a credible *Nature Ecology & Evolution* or *PNAS* submission **if** item 1 returns continental agreement — a named, cross-continental conserved set plus a two-thousand-year half-life is a paper with both a number and a story. If item 1 returns nothing, the half-life still stands on its own and the natural homes are *Ecology Letters* or *Global Ecology and Biogeography*, where it would be well received.

The decision point is item 1, and it costs hours.

---

## 9. Rate of change as the compositional yardstick

### Why it belongs in this paper

The single most dangerous reviewer question about the ~2 kyr half-life is: *"isn't that just compositional turnover?"* If the taxa present at 15 ka and 10 ka differ, their associations will differ too, and the decay would be a restatement of community turnover rather than a separate phenomenon. Restricting each comparison to shared taxa (as done) controls taxon identity but not prevalence structure, sampling, or the pace of compositional change itself.

Rate of change (RoC) from `RRatepol` is the natural yardstick, and the comparison is already informative.

### What the current data show

Adjacent-slice rewiring, measured as 1 − association similarity against the midpoint age of each slice pair:

| Continent | lag 500 yr | lag 1000 yr | mean rewiring >10 ka | <5 ka |
|---|---|---|---|---|
| America | ρ = +0.39, p = 0.016 | ρ = +0.66, p = 9.4 × 10⁻⁶ | 0.623 | 0.422 |
| Europe | ρ = −0.17, p = 0.34 | ρ = +0.25, p = 0.17 | 0.633 | 0.587 |

(positive ρ against age means rewiring was *faster in the past*)

So association rewiring is **flat in Europe and decelerating in North America** toward the present. Mottl et al. 2021 (*Science* `10.1126/science.abg1685`) showed the opposite for composition: RoC **accelerated**, with recent rates exceeding anything since the LGM.

If both hold under proper controls, the paper gains its sharpest claim:

> **Vegetation composition has been changing faster and faster, while the
> co-occurrence structure has not been rewiring any faster.** The recent
> acceleration is taxa redistributing within a relational structure whose pace
> of change has not increased.

That is a timely, mechanistic statement with an obvious forward-looking implication, and it converts the author's own *Science* paper from a potential "incremental" objection into the setup.

### Caveat that must be handled first

In America, rewiring correlates with the number of shared taxa between slices (ρ = −0.44, p = 0.005), and shared-taxon count rises toward the present with sampling. The apparent deceleration may therefore be partly an artefact. Rewiring must be modelled against age **and** shared-taxon count (and ideally rarefied to a fixed number of shared taxa) before the deceleration is claimed. Europe shows no such correlation (ρ = +0.21, p = 0.24).

### The comparability problem

`RRatepol` and the association analysis do not measure the same kind of thing, and forcing them onto one axis would be a methodological soft spot:

| | Rate of change | Association rewiring |
|---|---|---|
| Unit of analysis | One pollen sequence; consecutive samples within a core | One continent; a structure estimated *across* sites per 500-yr slice |
| What it measures | How fast the assemblage at a *place* changes | How fast the cross-site covariance structure changes |
| Standardisation | Count rarefaction; age uncertainty propagated over age-model iterations | Interpolated point ages; binarised at a 1 % filter; no age uncertainty |
| Spatial scale | Local | Regional to continental |
| Units | Dissimilarity per unit time | 1 − Spearman per unit lag |

Only the *shape* of the two curves could be compared, never their magnitudes — and a reviewer could attribute any divergence in shape to the difference in estimator rather than to ecology. That is too much weight for the paper's sharpest claim to rest on.

### Better: make the control internal, and let RoC corroborate

Three nested controls, in order of how tightly they bind:

1. **Raw co-occurrence turnover vs residual association turnover.** Compute the *identical* statistic — Spearman between off-diagonal vectors across shared taxa — on the raw taxon × taxon co-occurrence matrix (Jaccard or φ) derived from the same binarised slice matrices the models were fitted to. Same data, same slices, same taxa, same filters, same statistic. This isolates exactly what climate and space have already removed, and it is immune to the estimator objection. **This is the control the claim actually needs.**
2. **Compositional turnover between slices.** Between-slice dissimilarity in taxon composition/prevalence on the same matrices, again on shared taxa. Tells you whether association rewiring outpaces or lags plain compositional change.
3. **`RRatepol` rate of change.** External, differently standardised, and published — enters as corroboration, not as the comparator.

### What RoC uniquely contributes

Three things nothing else in the project provides, and they are the reason to include it despite the mismatch:

- **Age-uncertainty propagation.** The jSDM pipeline uses interpolated point ages and carries no chronological error. RoC's age-model iterations are the only available test of whether chronological uncertainty alone could generate a rewiring signal of the observed size.
- **Count rarefaction.** Directly relevant to the shared-taxon confound found in the American rewiring series — RoC standardises the richness/count problem in a way the association analysis currently does not.
- **A published, continentally resolved pattern** to anchor the internal compositional curve against, with the 2021 paper cited for the method and the global result.

### Scope

One figure, three rows on a shared age axis per continent: raw co-occurrence turnover, residual association rewiring, and RoC. The claim lives in rows 1–2, which are exactly comparable; row 3 shows that the internal compositional measure reproduces the known accelerating pattern. If the upscaling redo changes the 2021 picture, that is a separate paper, not a panel here.

### Added to the run list

| # | Work | Unblocks |
|---|---|---|
| 9 | **Export the binarised slice community matrices** and compute raw co-occurrence turnover with the identical statistic | the internal control — do this before anything else in §9 |
| 10 | Between-slice compositional turnover on the same matrices | control 2 |
| 11 | Recompute RoC per continent (`RRatepol`, native per-sequence design) | corroboration row; age-uncertainty and rarefaction checks |
| 12 | Model rewiring rate against age **and** shared-taxon count; rarefy to fixed shared taxa | the America deceleration claim |
