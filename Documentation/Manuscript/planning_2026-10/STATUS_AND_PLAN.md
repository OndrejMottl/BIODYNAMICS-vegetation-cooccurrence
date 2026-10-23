# BIODYNAMICS — where the project stands and what to do next

23 October 2026. This is the readable summary. The blow-by-blow reasoning,
including abandoned directions, is in `direction_review_20261023.md` and the
other files in this folder.

---

## Part 1 — Where the project stands

### What has been built

A single modelling pipeline, applied consistently across three axes:

- **Space** — 229 fossil-pollen models and 274 modern-vegetation models, each a
  unit × taxonomic-resolution combination, at three nested extents (local,
  regional, continental) on three continents.
- **Time** — 97 models, one per 500-year slice: 40 for North America (19.5–0 ka),
  36 for Europe (17.5–0 ka), 21 for northern Asia (10.5–0 ka).
- **Biological organisation** — every unit fitted at genus, family and
  functional-type level, the functional types derived from trait data.

Each model separates community composition into a climate component, a spatial
component, and a residual: the co-occurrence that climate and space do not
explain. The residual is the project's subject.

### The problem that emerged

The project was designed around comparing **how much** residual there is across
scales. That comparison does not work.

The residual share of explained variance scales with the **number of taxa in the
model**. Regressing it on log(number of taxa) across the 229 fossil models gives
R² = 0.675, and taxon number accounts for η² = 0.516 of the variation against
0.046 for taxonomic resolution. Because continental units carry more taxa than
local ones (median 25 vs 7), the raw numbers suggest the residual *increases*
with spatial extent. Matching taxon number reverses that: local 27.1 %,
regional 24.9 %, continental 18.6 %.

So the headline quantity is substantially a property of matrix width, not of
ecology. No published work reports this, which makes it a result in its own
right — but it means the original comparison has to be replaced.

### The replacement

Instead of asking how *much* residual structure there is, compare the residual
structure **itself**, and measure how similar two such structures are.

**Which matrix, precisely.** This is the model's **output**, not its input. Each
fitted jSDM estimates a residual covariance among taxa — the part of their
co-occurrence left once the climate and spatial components have taken their
share. `sjSDM::getCor()` returns that as a taxon × taxon correlation matrix, and
that is what was exported and analysed. It is a fitted parameter of the model.
It is *not* the site × taxon community data, and *not* a prediction of where
taxa occur.

The distinction matters because the **input**-derived matrix is a different
object with a different job:

| | What it is | What it contains |
|---|---|---|
| **Input-derived** co-occurrence | taxon × taxon Jaccard or φ computed directly from the binarised site × taxon data | everything: shared climate responses, shared spatial structure, and whatever is left |
| **Output** residual correlation (used here) | `sjSDM::getCor()` on the fitted model | only what climate and space did not explain |

The analysis uses the output. The input-derived matrix is the **control** in
Step 0b: if the raw co-occurrence structure decays at the same rate as the
residual structure, then the residual is tracking composition and is not telling
us anything on its own.

One consequence of using a fitted parameter: it carries estimation error, and
sjSDM shrinks it through the elastic-net penalty on the covariance. Two fits of
the same data will not give the same matrix. That is precisely why Step 0a
exists.

Similarity between structures is not inflated by matrix width the way a variance
share is, and it can be computed between any two models — separated in time, in
space, in taxonomic resolution, or by observation system.

That one change turns every axis of the project into a measurable decay
constant, and it is the basis of everything below.

### What has already been found with it

Comparing association matrices across time, on shared taxa, against a
label-permutation null:

- Structure decays with a **half-life of about 2,100 years in North America and
  2,200 years in Europe**.
- The decay is **not** a sampling artefact. Controlling for the sparser slice's
  site count and the number of shared taxa, the lag effect holds with almost
  the same coefficient on both continents (−0.109 and −0.116 per log unit of
  lag, p < 10⁻⁹⁹).
- There is **no strong conserved core**. At the longest lags, average similarity
  falls to the permutation null, though 50 % (America) and 31 % (Europe) of
  slice pairs still individually exceed their own null, against 2.5 % expected
  by chance.
- The rate of rewiring **did not accelerate** toward the present. North America
  slowed through the Holocene; Europe is flat.

That last point matters because compositional change did the opposite. This is
not a single-study claim:

- **Mottl et al. 2021**, *Science* (`10.1126/science.abg1685`) — global
  acceleration in rates of vegetation change over the past 18,000 years.
- **Gordon, Fagan, Milner & Thomas 2024**, *Nature Ecology & Evolution*
  (`10.1038/s41559-024-02457-x`) — 64,305 pollen samples from 1,763 records;
  turnover and diversity fell through the early Holocene and then generally
  increased from roughly 6,000–1,000 years ago, with timings, magnitudes and
  sometimes directions differing among continents, biomes and sites, and most
  metrics associated with anthropogenic land-cover change over the last
  8,000 years.

Three consequences for this project:

1. **The accelerating half of the contrast is established literature.** The
   novelty sits entirely in the other half — that the *structure* did not speed
   up with it. That puts more weight on the validity checks in Step 0, not less.
2. **Regional heterogeneity is the expected pattern, not an anomaly.** Gordon
   et al. find turnover responses differing among continents and biomes. Our
   Europe-versus-North-America difference in rewiring rate sits naturally
   alongside that rather than needing special pleading.
3. **This topic clears *Nature Ecology & Evolution*.** A pollen-based,
   continental-scale Holocene turnover paper was published there in 2024, which
   is a useful calibration for venue choice.

### Honest status of the other findings

| Finding | Status |
|---|---|
| Residual share is stable through 20 kyr, and not driven by sampling effort | Solid |
| Fossil and modern windows give different partitions (climate 69 % vs 48 %; space 41 % vs 52 %, continental tier) | Solid, continental tier only |
| Europe's co-occurrence network loses modularity through the deglacial; North America's does not | Confounded with rising site counts; needs rarefaction |
| Europe shifts from spatial to climatic control through time | Same confound |
| Removing the residual block costs held-out performance in calibration but not ranking | Demonstrated on one unit only |
| Fitted variance fractions are not additive (one three-way fraction is −6.85) | Solid, and worth reporting as a caution |

---

## Part 2 — The questions

One question per axis, in the same units, all answerable the same way.

**Q1 — Can the strength of residual structure be compared across models at all?**
Already answered: not as a variance share. This is the methodological premise
and the motivation for everything else.

**Q2 — Over how much *time* does residual structure stay recognisable?**
Answered: a half-life of about two thousand years, on two continents, robust to
the obvious confounds.

**Q3 — Over how much *distance* does it stay recognisable?**
Not yet asked. The spatial equivalent of Q2: compare units separated by
increasing distance within a tier, and estimate a half-distance.

**Q4 — Does it survive *aggregation*?**
Not yet asked. Compare the same unit modelled at genus, family and
functional-type level. Does the structure at coarse resolution preserve the
structure at fine resolution — and does grouping by function preserve more than
grouping by taxonomy?

**Q5 — Does it depend on *how you look*?**
Not yet asked, and the strongest available test. The fossil and modern spatial
grids use the same unit identifiers: 264 shared local units and 30 shared
regional units. For the same geographic cell, does the structure inferred from
pollen match the structure inferred from vegetation plots?

**Q6 — Did the *pace* of change shift?**
Partly answered: no acceleration, with North America slowing. Needs the controls
in Part 3 before it is claimed.

Together these ask one thing: **over what separation — in time, in space, across
levels of biological organisation, and between ways of observing — does the
residual co-occurrence structure of plant communities remain recognisable?**
That is a question about the characteristic scales of community organisation,
and it is a direct answer to the grant's second objective.

---

## Part 3 — How to answer them

### Step 0 — Three validity checks, before anything else

These decide whether the measurement means what we think. All are cheap, and all
serve every axis at once.

**0a. The reproducibility ceiling.** Two independent fits of the *same* data will
not produce identical association matrices. Extrapolating the temporal decay to
zero lag gives similarity around 0.59 (America) and 0.50 (Europe) rather than 1,
so an unknown share of what we are calling "change" may be estimation noise.
*Do:* refit one slice about ten times with different seeds, per continent, and
measure similarity among the replicates. *If* replicate similarity is around
0.9, the measurement is sound. *If* it is around 0.6, the decay is largely noise
and the project should pivot to the methodological paper.

**0b. Raw co-occurrence as a control.** Compute the identical similarity
statistic on the **input**-derived matrix — taxon × taxon Jaccard or φ from the
same binarised site × taxon data the models were fitted to — and compare its
decay with that of the model's residual correlation. Same data, same slices,
same taxa, same statistic; the only difference is whether climate and space have
been removed. If the two decay at the same rate, the residual is tracking
composition and adds nothing of its own. *Do:* export the binarised slice
community matrices and repeat the analysis.

**0c. Site overlap, not just site count.** Two slices drawn from partly
different sets of cores may differ for geographic rather than temporal reasons.
Site count is controlled; site identity is not. *Do:* add site identifiers to
the export and include pairwise site overlap as a covariate.

### Step 1 — Extend the export to the spatial stores

The association matrices for the temporal models are already exported. The
spatial stores are organised one directory per unit
(`<store>/<unit_id>/pipeline_*/objects`) with resolution-suffixed target names,
so the existing export script generalises with a path change and a loop over
unit directories.

The fossil spatial stores have been untouched for 9–13 days and can be read now.
The modern spatial stores were being written during the cross-validation rerun,
so those should wait until it finishes.

This single export unlocks Q3, Q4 and Q5.

### Step 2 — Answer the three open questions

| Question | Procedure | What would make it a null result |
|---|---|---|
| **Q3 distance** | Within a tier, compute similarity between every pair of units on their shared taxa; regress on geographic distance between unit centroids, controlling for site count and shared taxa as in the temporal analysis; fit the same exponential-plus-floor | Similarity is flat with distance, or indistinguishable from the permutation null at all distances |
| **Q4 aggregation** | For each unit, project the genus matrix to family and to functional-type level using the existing harmonisation and FT tables, and compare each projection with the matrix actually fitted at that level | The fitted coarse matrix bears no more resemblance to the projected fine matrix than to a permuted one |
| **Q5 observation system** | For each of the 264 paired local and 30 paired regional units, compute similarity between the fossil and modern matrices on shared taxa, against the same null | Fossil and modern matrices for the same cell are no more similar than fossil and modern matrices for different cells |

### Step 3 — The supporting analyses already planned

- Per-slice rarefaction of the network metrics, to resolve the Europe modularity
  result.
- Multi-unit component removal (about 20–30 units) to generalise the predictive
  result beyond one unit.
- Rate of change recomputed with `RRatepol` in its native per-sequence design,
  as corroboration for the pace result — not as a direct comparator, because it
  measures a different kind of thing.

---

## Part 4 — What the answers would mean

| Outcome | The paper |
|---|---|
| Structure decays on every axis with measurable constants, and the checks in Step 0 pass | The characteristic scales of plant community organisation: a ~2 kyr clock, a measured half-distance, a survival profile across levels of organisation, and an agreement between fossil and modern views of the same ground. A claim about nature, with numbers, replicated on two continents and two observation systems. |
| The checks pass but the decays are flat on the spatial and taxonomic axes | A narrower paper: structure is temporally labile but spatially and taxonomically robust. Still publishable, less striking. |
| The reproducibility ceiling is low | A methodological paper: the variance share is a width artefact, fitted fractions are non-additive, association matrices are weakly reproducible, and only held-out component removal measures anything real. Four novel results on 500+ models — probably the most-cited thing the project would produce. |

The decision point is Step 0a, and it costs about ten model fits.
