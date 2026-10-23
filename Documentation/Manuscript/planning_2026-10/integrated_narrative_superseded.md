# A single narrative that uses everything — and the problem that has to be fixed first

Companion to `BIODYNAMICS_paper_direction_options.md`. Written after re-analysing
the unit-level tables rather than the medians.

---

## 1. Read this part first

I tried to check the integrating claim ("the partition is invariant along every
axis except the taxonomic one") against the 229 unit-level paleo models instead
of the summary medians. It does not survive in the form the talk and the tables
present it.

**The association fraction is mostly a function of how many taxa are in the
model.**

Fitting `association_fraction ~ log(n_taxa)` on the 229 paleo models gives
R² = 0.675 (slope +12.1 percentage points per e-fold of taxa, p = 2.5 × 10⁻⁵⁷).
The correlation holds *within* every taxonomic level — genus ρ = +0.85
(p = 1 × 10⁻²²), family ρ = +0.71, functional type ρ = +0.63 — so it is not a
between-level artefact.

Type-II η² for the association fraction:

| Term | η² without taxon count | η² with log(n_taxa) in the model |
|---|---:|---:|
| log(n taxa) | — | **0.516** |
| Taxonomic resolution | 0.363 | 0.046 |
| Spatial extent | 0.042 | 0.038 |
| Continent | 0.054 | 0.007 (p = 0.14) |
| Residual (among units) | 0.541 | 0.392 |

Two consequences, both load-bearing:

1. **The taxonomic gradient is largely a width effect.** Genus models carry a
   median of 13 taxa, family 8, functional type 6. Conditioning on taxon number
   shrinks the resolution effect from η² = 0.363 to 0.046. The "genus → FT halves
   the association fraction" result — my §2(a) headline in the previous document,
   and the talk's slide 9 — is mostly the latent covariance block getting wider,
   not functional redundancy absorbing interactions.
2. **The spatial gradient reverses sign when you adjust.** Raw genus medians run
   local 30.7 < regional 34.4 < continental 41.4. At a common taxon number the
   model-adjusted means run local 27.1 > regional 24.9 > continental 18.6 —
   i.e. the *classical* expectation (biotic structure matters most at fine
   grain) is in fact supported, and the apparent inversion was continental units
   simply having more taxa (median 25.5 vs 7.0 locally).

![Association fraction vs model width, and the reversal of the spatial gradient]({{artifact:c42a1b2a-79ec-4953-8a59-3a882e4e08e5}})

This is the single most consequential thing I found. It is bad news for the
framing in the deck, good news for the paper: the corrected spatial result is
ecologically interpretable and *more* publishable than "no pattern". But
`n_taxa` is partly a consequence of extent, so regression adjustment alone is
over-controlling and will be challenged. The fix is rarefaction, not covariate
adjustment — refit a matched subset of models at a fixed taxon number (e.g.
*k* = 8 taxa drawn repeatedly from each unit) so that width is held constant by
design. That is a real but bounded run, and it is now the critical path for any
paper that quotes a variance fraction.

**The temporal arm has the same disease, partially.** Site counts rise almost
monotonically toward the present (ρ(age, n_locations) = −0.95 Europe, −0.99
America). Against site count:

| Series | Europe | America | Asia |
|---|---|---|---|
| Association fraction | ρ = +0.08 (p = 0.66) | +0.34 (p = 0.032) | +0.01 (p = 0.98) |
| Spatial fraction | −0.68 (p = 5.8 × 10⁻⁶) | −0.02 (p = 0.89) | +0.49 (p = 0.025) |
| Modularity Q | **−0.83 (p = 7.2 × 10⁻¹⁰)** | +0.38 (p = 0.018) | −0.31 (p = 0.17) |
| Connectance | −0.29 | −0.86 (p = 1.7 × 10⁻¹²) | +0.17 |
| Nestedness | +0.16 | −0.92 (p = 5.7 × 10⁻¹⁷) | −0.47 |

So: the **association fraction through time is clean** — uncorrelated with
sampling in all three continents. That invariance claim stands. The **Europe
modularity decline is confounded** — site count explains it at least as well as
age. Connectance and nestedness are unusable without rarefaction (America
ρ ≈ −0.9).

The one thing that rescues the Europe network story: America has an *identical*
sampling trajectory (ρ = −0.99) and shows *no* modularity decline — it trends
weakly the other way. Identical sampling trends with opposite responses is a
real argument, and it is the argument the paper should make, rather than the
raw trend. But per-slice rarefaction to constant site and taxon number is
non-negotiable before this goes in a figure.

---

## 2. The narrative that uses everything

With the above in hand, here is the one claim that binds the spatial grid, the
modern arm, the temporal arm and the predictive experiment into a single paper,
and is still true.

> **Pitch.** Across 20 kyr, three continents, four orders of magnitude of spatial
> extent and two independent observation systems, the share of vegetation
> community structure that climate and space cannot account for stays within a
> narrow band — even while the realised co-occurrence network reorganises
> completely. Assembly *rules* are conserved; assembly *outcomes* are not. And
> much of the scale-dependence reported for this quantity in the literature is an
> artefact of how it is measured.

Working titles:

- *Vegetation reassembles without changing its assembly rules*
- *Conserved assembly, labile communities: 20,000 years of vegetation across three continents*
- *A constant residual: what climate and space cannot explain about plant communities, from the Last Glacial Maximum to today*

The structure is **invariance + one real exception + one measurement
correction**. That is a shape high-impact journals recognise, and it converts
your three "disappointing" flat results into the finding instead of the
disappointment.

### Figure arc

**Fig 1 — What was measured.** Northern-hemisphere coverage with fossil cores
and modern plots on one map; the three analysis axes; temporal sample density;
the A/S/B partition schematic. One sentence of scope: *n* models, two
observation systems, 20 kyr. (Assets: slide 3 coverage map, slide 4 axes, slide
10 density plot, slide 6/7 schematics — all drafted.)

**Fig 2 — Invariance across extent and across observation system.** Association,
climate and spatial shares for paleo and modern, at all three extents, at matched
taxon number. The association band is narrow; the one systematic
observation-system difference is that climate takes more and space takes less in
the fossil record than in modern plots (continental genus: climate 69 % paleo vs
48 % modern; space 41 % vs 52 %, predictor-inclusive). That contrast is a result,
not a nuisance — the fossil record integrates over catchments and millennia, so
it sees climate more cleanly and local spatial texture less.
(Assets: `paleo_patterns_unit_2026-10-12.csv`, modern after Stage 04 rebuild.
**Needs the rarefaction run.**)

**Fig 3 — Why the apparent scale-dependence is not real.** Panel a: association
fraction vs model width across all 229 + 274 models. Panel b: raw vs
taxon-matched spatial gradient — the reversal. Panel c: the random-aggregation
null (aggregate genus matrices into random groups of FT size; if the fraction
falls the same way, aggregation per se explains it). This figure is the paper's
methodological spine and the reason a reviewer should believe Fig 2 and Fig 4.
(**Panels a–b exist as of today — attached. Panel c needs to be run.**)

**Fig 4 — Invariance in time, lability in the network.** Three continents ×
two rows: (i) the three variance shares per 500-yr slice, flat, with the Europe
spatial→climatic handover as the one trend; (ii) rarefied modularity, showing
Europe's decline and America's non-decline under matched sampling. The
decoupling of the two rows is the sentence: the partition does not move, the
network does.
(Assets: `paleo_temporal_patterns_unit_2026-10-01.csv`. **Needs per-slice
rarefaction.**)

**Fig 5 — What the residual is actually worth.** Multi-unit component removal:
Δlog loss, ΔBrier, ΔTjur R², ΔAUC for removing climate / space / associations,
across units and resolutions. The residual is real and transferable but buys
*calibration*, not *ranking*. This is what licenses calling the B component a
signal at all, and it closes the paper without ever claiming an interaction.
(Asset: the validated one-unit design. **Needs scaling to ~20–30 units.**)

### Discussion beats, in order

1. **Conserved rule weights, labile outcomes.** The partition is the same at
   15 ka and today, in Europe and America, in pollen and in plots. Whatever sets
   the balance of climatic, spatial and residual control over plant community
   composition is not itself a function of climate state, extent, or observation
   system.
2. **The measurement correction.** Variance fractions from jSDMs scale with
   model width; comparisons across taxonomic resolutions or spatial extents that
   do not match width are not comparing ecology. Include the `eu_r005_l010`
   example where the three-way shared ANOVA fraction is −6.85 as the concrete
   warning.
3. **Biogeographic contingency acts on networks, not on rules.** Europe's
   co-occurrence network de-modularises through the deglacial and Holocene while
   North America's does not, under identical sampling trajectories — consistent
   with Europe's E–W barriers, refugial compression and Pleistocene extinction
   filter. The reorganisation is visible in topology and invisible in the
   partition, which is exactly the point.
4. **What this means for forecasting.** If rule weights are conserved but
   realised co-occurrence is not, then projecting *where taxa will be* and
   projecting *who will be with whom* are different problems with different error
   budgets. The past gives the first empirical bound on how much reassembly to
   expect per unit of climate change. State this as the implication and the next
   paper; do not promise CMIP6 in this one.

---

## 3. Two alternative emphases of the same material

**(i) Lead with the correction instead of the invariance.** Same five figures,
reordered so Fig 3 becomes Fig 1: *"Variance partitions in joint species
distribution models scale with the number of species, and the resulting
scale-dependence is an artefact."* Pros: unassailable, immediately useful, and
you own the fix. Cons: that is a *Methods in Ecology and Evolution* paper, not
*Nature Ecology & Evolution* — the ecology becomes the demonstration.

**(ii) Lead with the continental contrast.** *"Europe reassembled, North America
did not."* Pros: a story with named places and a mechanism, which is what
high-impact editors respond to; the matched-sampling argument is genuinely
strong. Cons: *n* = 3 continents, Asia only covers 10.5 ka, and the whole paper
then rests on rarefied network metrics rather than on your 500+ models — it
leaves the spatial grid unused, which is the thing you said you did not want.

---

## 4. What has to be run

Ranked by whether the paper exists without it.

| # | Work | Why | Rough cost |
|---|---|---|---|
| 1 | **Taxon-number-matched refits** across the spatial grid (fixed *k*, repeated draws) | Without it Fig 2 and Fig 3b are regression-adjusted, and the spatial direction is contestable | The binding constraint; a bounded refit of existing units, no new methods |
| 2 | **Per-slice rarefaction** of the temporal network metrics to constant sites and taxa | Europe modularity is currently confounded at ρ = −0.83 with site count; connectance/nestedness unusable | Cheap — the matrices are already assembled, no model refitting |
| 3 | **Multi-unit component removal** (~20–30 units across tiers, resolutions, both data sources) | Fig 5; also the only evidence that is immune to the width artefact | 4 fits × 15 folds × N units; ≈5 min/unit on GPU at the recorded reference rate |
| 4 | **Random-aggregation null** for the taxonomic axis | Separates functional coherence from "any aggregation shrinks the fraction"; Fig 3c | Cheap, no model refitting for the null matrices themselves |
| 5 | **Modern Stage 04 + Stage 05 rebuild** | Fig 2's modern half; already queued and stopped | Already scoped |
| 6 | *Optional:* CMIP6 coda | Would make discussion beat 4 concrete rather than prospective | Months — keep out of this paper |

Items 2 and 4 are days. Item 5 is already planned. Items 1 and 3 are the real
work, and both are refits of models you have already specified — no new
methodology, no new data.

---

## 5. Honest assessment of the *Nature Ecology & Evolution* target

**What helps.** Genuine 20-kyr scope on three continents; two independent
observation systems through one pipeline; a counter-intuitive invariance with a
clean exception; a methodological correction with immediate reach beyond
palaeoecology; exemplary reproducibility. The decoupling of partition from
network topology is the kind of result that reads as conceptual rather than
descriptive.

**What hurts.** (a) The core claim is an invariance — editors have to be
persuaded that constancy is a finding, which requires the measurement correction
to be airtight, which is why item 1 is not optional. (b) *n* = 3 continents and
*n* = 2 observation systems, so the "generality" rests on the within-axis
replication (500+ models), not on the axes themselves. (c) Pollen presence/absence
at 500-yr resolution is a coarse substrate and will be named in every report.
(d) The honest out-of-sample skill (continental genus AUC 0.52–0.60) will come
up, and the answer has to be "this paper is about structure, not prediction",
which cuts against discussion beat 4.

**My read:** with items 1–5 done, this is a credible *Nature Ecology &
Evolution* / *PNAS* submission and a very strong *Ecology Letters* / *GEB* one.
Without item 1 it is not an NEE paper in any framing, because the headline
number would be known to be width-dependent. I would do items 2 and 4 first —
they are days of work and they tell you whether the taxonomic exception
survives at all, which determines whether the narrative above is the right one.

---

## 6. Where this leaves the previous document

`BIODYNAMICS_paper_direction_options.md` §2(a) states that the association
fraction weakly increases with spatial extent and halves from genus to
functional type, and presents both as ecological results. Both are now better
explained by model width. The options themselves still stand — Option C
(predictive component removal) is the one unaffected by this, and Option B's
association-fraction invariance through time is confirmed — but §2(a) should be
read together with §1 above, and the taxonomic headline of Option A should be
treated as unproven until the random-aggregation null is run.
