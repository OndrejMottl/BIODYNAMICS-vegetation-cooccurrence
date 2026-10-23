# Direction review — 23 October 2026

Written after re-interrogating the exported association matrices rather than
re-reading the plan. Two new analyses changed my recommendation.

---

## 1. What I tested, and what came back

### (a) Is the decay a precision artefact?

The worry: long lags necessarily involve old slices, old slices have fewer
sites, sparse slices give noisier association matrices, and noisy matrices
resemble nothing. If so, the "half-life" would be a sampling curve.

Regressing similarity on lag, the sparser slice's site count, and the number of
shared taxa:

| Continent | log(lag) | log(min sites) | log(shared taxa) | R² |
|---|---|---|---|---|
| America (n = 741) | **−0.109**, p = 1.1 × 10⁻⁹⁹ | +0.098, p = 2.9 × 10⁻²⁰ | −0.134, p = 2.2 × 10⁻⁴ | 0.660 |
| Europe (n = 595) | **−0.116**, p = 5.3 × 10⁻¹⁰⁸ | +0.073, p = 7.5 × 10⁻¹⁵ | −0.195, p = 2.0 × 10⁻⁶ | 0.685 |

**The lag effect survives, and the two continents give almost the same
coefficient.** Site count has a real, independent, positive effect on similarity
— worth reporting in its own right — but it does not generate the decay.

### (b) Did rewiring accelerate toward the present?

Adding the midpoint age of each slice pair to the same model:

| | all pairs | adjacent pairs only (lag ≤ 1 kyr) |
|---|---|---|
| America | mid-age β = −0.0356, p = 7.1 × 10⁻⁹⁴ | −0.0251, p = 7.5 × 10⁻⁷ |
| Europe | −0.0129, p = 3.3 × 10⁻⁷ | **+0.0177, p = 0.059** |

Negative means older pairs are *less* similar, i.e. faster rewiring in the past.
So **North America rewired faster during the deglacial and slowed through the
Holocene; Europe is flat, with a marginal, non-significant trend the other way.**
Neither continent shows accelerating rewiring toward the present.

An earlier apparent anomaly — slice pairs involving the last 1 kyr sitting
+0.105 above the decay curve in America (p = 3 × 10⁻²⁰) — is explained by site
count, not by ecology. Recent slices are better estimated, so they resemble
everything more. Worth knowing before someone else finds it.

---

## 2. What this changes

> **Superseded by §6.** The three-act structure below uses only the temporal
> arm. §6 generalises it so the spatial, taxonomic and modern axes do first-class
> work rather than appearing as caveats.

The project has been circling three framings — the *amount* of residual
structure (invariance), *which pairs* recur (Clements–Gleason), and the
measurement correction. The first is a null about a technical estimand, the
second lost its best version when the conserved core failed to appear, and the
third is a methods paper.

The new results point at a fourth, which I think is clearly the strongest:

> **The paper is about a rate, not a fraction.**

Rates are intuitive. "The co-occurrence structure of plant communities is
rewritten on a two-thousand-year timescale" needs no methodological preamble;
"the association component accounts for 24 % of Nagelkerke R²" does. That single
change fixes the problem I flagged earlier — that the invariance framing asks
the reader to care about an estimand before the result can land.

### The three-act structure

1. **You cannot compare the amount across models.** The association share scales
   with model width (R² = 0.675 on log taxa; η² = 0.516 against 0.046 for
   taxonomic resolution), which reverses the apparent spatial gradient. So stop
   comparing fractions and measure a rate instead. The methodological result
   becomes the *motivation* rather than a caveat.
2. **The rate is conserved.** Half-life ≈ 2.1 kyr (America) and 2.2 kyr
   (Europe), with near-identical lag coefficients after controlling for site
   count, shared taxa and estimation precision — two continents with different
   floras, different glacial histories and different sampling, agreeing to
   within a tenth of a millennium.
3. **The rate did not accelerate.** Compositional change reached unprecedented
   late-Holocene rates (Mottl et al. 2021, *Science*); structural rewiring did
   not. In North America it slowed. The recent acceleration is taxa
   redistributing within a relational structure whose own clock did not speed up.

### Why this is the strongest available direction

- It is a claim about vegetation, with a number, replicated on two continents.
- It is not pre-empted. Liu et al. 2026 concerns the *direction* of inferred
  interactions in nine Arctic lakes; nobody has measured the *pace* of
  structural turnover.
- It converts the author's own 2021 paper from a possible "incremental"
  objection into the setup, and supplies the contemporary hook the other
  framings lacked.
- Every asset has a job: the spatial grid becomes replication for the rate, the
  modern arm the present-day endpoint, the component-removal experiment the
  licence to treat the residual as signal, and the width artefact the opening
  argument.
- Both outcomes of the remaining controls are publishable — see §4.

---

## 3. The three experiments that decide it

All cheap. All should run before another word of Introduction.

### (i) The reproducibility ceiling — **the biggest single risk, and not yet flagged anywhere**

Two independent fits of the *same* slice will not give identical association
matrices. Extrapolating the decay fit to zero lag gives similarity ≈ 0.59
(America) and 0.50 (Europe), not 1 — so a large part of the dissimilarity
between any two slices may be estimation noise rather than change.

Refit one slice 10 times with different seeds, per continent, and compute
similarity among replicates. That gives the ceiling. The half-life should then
be re-expressed relative to it. If replicate similarity is ≈ 0.9, the clock is
real and the half-life is roughly right. **If replicate similarity is ≈ 0.6, the
"decay" is largely noise turnover and the centrepiece collapses.**
Cost: ~10 model fits.

### (ii) Raw co-occurrence as the internal control

Compute the identical statistic on the raw taxon × taxon co-occurrence matrix
from the same binarised slice matrices. If raw co-occurrence turns over at the
same rate, the clock is compositional, not relational, and the paper is about
something less interesting. If the residual turns over faster or slower, the
contrast is the result. Cost: one export plus an afternoon.

### (iii) Site overlap, not just site count

Slices drawn from partly different sets of cores will differ for geographic
rather than temporal reasons. Site count is controlled; site *identity* is not.
Recompute with pairwise site overlap as a covariate. Cost: hours, needs the site
IDs added to the export.

---

## 4. What happens under each outcome

| Outcome | Paper | Venue |
|---|---|---|
| Ceiling high, raw co-occurrence turns over differently, overlap controlled | The rate paper as above: a conserved two-millennium clock that did not accelerate | *Nature Ecology & Evolution* / *PNAS* plausible |
| Ceiling high, raw co-occurrence turns over at the same rate | The clock is compositional; reframe as "association structure tracks composition with no independent dynamics" — still a clean negative with the width artefact attached | *Ecology Letters* / *GEB* |
| Ceiling low (≈ 0.6) | The decay is largely estimation noise. Pivot to the methods paper: width artefact + non-additive ANOVA fractions + poor reproducibility + predictive component removal — four results, all novel, all useful | *Methods in Ecology and Evolution*, strong |

Note that the third row is not a failure. A demonstration that jSDM association
matrices are weakly reproducible, that their variance share is a dimensionality
artefact, and that fitted fractions do not predict held-out contribution, built
on 500+ models, would be the most-cited thing the project produces.

---

## 5. Recommendation

Run (i), (ii) and (iii) — days of work, no new methodology — and let them pick
the framing. Do not write the Introduction first; the three outcomes above need
different ones.

If forced to commit today, I would commit to the rate framing, because the lag
coefficient survived the hardest control I could throw at it and the two
continents agree closely — −0.109 and −0.116, a difference of about 6 % —
despite sharing almost nothing else. That is the most robust thing in the
project.

---

## 6. Correction: the rate generalises to every axis

§2 was too narrow. As written, the rate paper uses the 97 temporal slices and
relegates the 229 paleo spatial models, the 274 modern models, the three
taxonomic resolutions and the trait/functional-type work to a methodological
warning in Act 1. That under-uses the project badly, and it is not what the
grant set out to answer.

The error was in the application, not the idea. **Similarity between association
matrices is a general operation**, and the project's design axes are exactly the
axes along which to apply it:

| Axis | Comparison | Question | Material |
|---|---|---|---|
| **Time** | slices separated by Δt | over how long does structure stay recognisable? | 97 slices — **done**, half-life ≈ 2 kyr |
| **Space** | units separated by distance, within a tier | over what distance does structure stay recognisable? | 229 paleo models at three nested extents |
| **Taxonomic resolution** | same unit, genus vs family vs functional type | does structure survive aggregation, and does functional grouping preserve more of it than taxonomic grouping? | the FT classification and trait work |
| **Observation system** | same unit, fossil vs modern | does structure inferred from pollen match structure inferred from plots **in the same place**? | **264 paired local units and 30 paired regional units** — the grids are identical by construction |

That last row is the one I had not appreciated. `paleo_spatial_local` and
`modern_spatial_local` contain the *same 264 unit identifiers*, and the regional
tiers share all 30. These are paired fossil/modern models of the same
geographic cells. Nothing else in the literature has that.

### The unifying question

> **Over what separation — in time, in space, across levels of biological
> organisation, and between observation systems — does the residual
> co-occurrence structure of plant communities remain recognisable?**

That is a question about the characteristic scales of community organisation,
answered in the same units on every axis. It is also a direct answer to the
grant's objective 2 — how biotic structure scales across space, time and
taxonomy — and a far more literal one than any variance-fraction version.

### Revised act structure

1. **You cannot compare the amount across models.** The association share scales
   with model width, which reverses the apparent spatial gradient. Therefore
   compare *structures*, not fractions. (Uses the full 229 + 274 grid.)
2. **Structure decays along every axis, and the decay constants are the
   result.** A temporal half-life of ~2 kyr; a spatial half-distance; a
   taxonomic survival profile; a fossil-versus-modern agreement for the same
   cells. Each is a characteristic scale, each is measured identically, and the
   continents replicate.
3. **The temporal rate did not accelerate** even as compositional change reached
   unprecedented late-Holocene rates — the contemporary implication.

### What this needs beyond what is already planned

Only one new thing: export association matrices from the spatial stores as well
as the temporal ones. The stores are organised per unit
(`<store>/<unit_id>/pipeline_*/objects`) with resolution-suffixed targets, so
the existing script generalises with a path change and a loop over unit
directories. Everything else — the reproducibility ceiling, the raw-co-occurrence
control, the site-overlap control — applies unchanged and serves all four axes
at once.

The modern spatial stores were being written during the cross-validation rerun,
so those exports should wait until that finishes; the paleo spatial stores have
been cold for ~9–13 days and can be read now.
