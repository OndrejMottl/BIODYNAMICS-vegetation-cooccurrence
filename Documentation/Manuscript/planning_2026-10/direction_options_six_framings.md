# BIODYNAMICS vegetation co-occurrence — options for framing the paper

Prepared 21 October 2026, after reading: `README.md`; the project page
(ondrejmottl.github.io/projects/BIODYNAMICS); the manuscript source
(`Outputs/Manuscript/manuscript.qmd` + all 11 `sections/*.qmd`); the IAVS 2026 /
CSPE 2026 deck (`index.qmd`, `script.md`, `README_figures.md`,
`RESULTS_PROVENANCE.md`) and its result PNGs; the First and Second co-author
report sources; the implementation plans (incl. the future-diversity-prediction
plan); `Documentation/Reports/Cross_validation_audit/paleo_local_cv_predictive_decomposition_v1.md`;
`Documentation/Reports/Model_evaluation/modern_spatial_completion_2026-10-20/README.md`;
and the dated tables in `Outputs/Tables/`.

---

## 1. Where the manuscript actually stands

Methods are written and detailed (~25 kB of `03_methods.qmd`, essentially
submission-ready prose). **Abstract, Introduction, Results and Discussion are
all `TODO`.** The title is `TODO`. This is the best possible position to be in
for your question: nothing argumentative is committed yet, so re-framing costs
you nothing except the keyword list (which still says "HMSC", a leftover).

So the decision is genuinely open — and it should be made now, because the
Results skeleton in `04_results.qmd` ("Data overview / Model performance /
Co-occurrence patterns / Environmental drivers") is the *pipeline's* structure,
not an argument's structure. Writing results in that order is how a paper ends
up with the framing you are worried about.

---

## 2. Asset inventory — what you can actually claim today

This matters more than taste, because each framing below is only as good as the
evidence already on disk.

| Asset | State | Where |
|---|---|---|
| Paleo spatial grid: 229 unit × resolution models (local 58/57/56, regional 18/17/15, continental 3/3/2 for genus/FT/family) | Done, 2026-10-12 snapshot | `Outputs/Tables/paleo_patterns_{unit,summary}_2026-10-12.csv` |
| Modern spatial grid: 274 fitted-and-converged unit × resolution combinations across all three tiers; 380 requested CV endpoints all validated; 6,472/6,472 fold fits successful | Fitting done and audited; **Stage 04 synthesis + Stage 05 figures not yet rebuilt** (queue stopped by you on 21 Oct) | `Model_evaluation/modern_spatial_completion_2026-10-20/` |
| Paleo temporal: 40 slices America (19.5–0 ka), 36 Europe (17.5–0 ka), 21 Asia (10.5–0 ka), each with variance components *and* model-free bipartite network metrics | Done | `Outputs/Tables/paleo_temporal_patterns_unit_2026-10-01.csv` |
| **Held-out component-removal experiment** (full vs. no-abiotic / no-spatial / no-association, matched 3×5 spatial folds, 45/45 fits) | Done for **one** unit (`eu_r005_l010`, genus) | `Cross_validation_audit/paleo_local_cv_predictive_decomposition_v1.md` |
| Functional-type classification from traits (Gower + Ward, silhouette-selected *k*, per continent) | Done; trait correction changed FT results substantially between June and September | `Outputs/Tables/functional_type_ordination_*` |
| Hindcast/projection machinery (grid build, CHELSA-TraCE21k extraction, MEM interpolation to grid, per-taxon and richness maps) | Working prototype, demonstrated for Europe at 0 ka (median AUC ≈ 0.89 shown on the slide) | `R/Functions/Prediction/*`, IAVS slide 12 |
| CMIP6 future-scenario projection (2050/2100) | **Planned only, never run** | `plan_future_diversity_prediction_2026-06-24.md` |
| Modern × paleo contrast with one identical pipeline | Continental tier comparable now; regional/local awaits the Stage 04 rebuild | `modern_patterns_summary_2026-10-01.csv` |

### Three numbers that should drive the decision

**(a) The association fraction is ordered by taxonomic resolution, not by spatial extent — and the spatial ordering runs the *wrong* way.**
Median non-shared association fraction (% of Nagelkerke R², paleo, 2026-10-12):

| Resolution | continental | regional | local |
|---|---:|---:|---:|
| Genus | 41.4 | 34.4 | 30.7 |
| Family | 28.3 | 28.5 | 22.2 |
| Functional type | 22.3 | 16.6 | 17.1 |

Stable across the 2026-09-27, -10-01 and -10-12 snapshots. The classic
expectation — interactions matter most locally, wash out continentally — is
*not* supported; if anything the gradient is inverted. The taxonomic gradient,
by contrast, is monotone and large (genus → FT roughly halves the fraction).
Note the talk currently says "no obvious change between spatial scales"; the
medians are in fact ordered, just opposite to prediction. That is a stronger
and more interesting statement than "no pattern", but continental *n* is only
2–3 units.

**(b) Europe reorganised; North America did not.** Bipartite network modularity
*Q* against age (Spearman, computed from `paleo_temporal_patterns_unit_2026-10-01.csv`):

- Europe: ρ = +0.70, p = 2.2 × 10⁻⁶ — *Q* falls from 0.375 at 17.5 ka to a
  minimum of 0.163 at 6 ka, then rebounds to 0.282 at 0 ka.
- America: ρ = −0.40, p = 0.012 — weak trend in the *opposite* direction,
  *Q* ≈ 0.22–0.29 throughout.
- Asia: ρ = −0.40, p = 0.073 — no trend (and only the last 10.5 ka).

In the same Europe series the *spatial* variance fraction collapses toward the
present (ρ = +0.70, p = 3.2 × 10⁻⁶) while the *abiotic* fraction rises
(ρ = −0.37, p = 0.027) and the *association* fraction stays flat (p = 0.39).
America shows essentially flat components. This is a real, quantified,
continent-contrasting result that nobody has to interpret as "interaction".

**(c) Residual associations carry genuine but modest out-of-sample information.**
From the one-unit component-removal experiment, removing the association block
costs (full − reduced, held-out, three repeats):

| Removed | Δ log loss | Δ Brier | Δ Tjur R² | Δ AUC |
|---|---:|---:|---:|---:|
| Abiotic | 0.0759 | 0.0304 | 0.149 | 0.225 |
| Associations | 0.0261 | 0.00432 | 0.0131 | 0.0011 (CI spans 0) |
| Spatial | 0.00372 | 0.00139 | 0.00779 | −0.0111 |

≈ 20–25 % of the positive log-loss effect. Repeatable in every repeat for
proper scores, absent for AUC. **This is the single most defensible asset in the
project** and it is currently buried in an audit report.

### Two numbers that constrain every option

- **Fitted-data ANOVA fractions are not safely interpretable as variance
  shares.** For `eu_r005_l010` the full-data genus ANOVA returns A = 0.933,
  B = 0.541, S = 0.418 with shared A∩B = 0.905, A∩S = 0.895 and a three-way
  fraction of **−6.85**. Negative fractions are currently clamped to zero in the
  pipeline. Any headline number taken straight from the ANOVA is exposed on
  exactly the point a sceptical reviewer will press.
- **Honest spatial-block CV skill at genus level is weak.** At the continental
  tier, `predictive_auc_mean` is 0.52 (America), 0.56 (Europe), 0.60 (Asia) for
  genus, against fitted AUC of 0.63–0.84. Family and FT do better (up to 0.80).
  Any "we can predict diversity" claim has to live inside those numbers.

---

## 3. Why your instinct about the interaction framing is right

Three separate problems compound:

1. **The inferential objection is live and well-known.** The
   residual-covariance-as-interaction reading has been argued down repeatedly
   (Dormann, Blanchet, Poggiato, Zurell and others); a reviewer can cite the
   critique literature without reading your results.
2. **Your own numbers argue against the interaction reading.** If the residual
   were dominated by interaction you would expect it to be strongest where
   individuals actually meet — locally, at fine taxonomic resolution. You
   observe the opposite on both axes (table (a)). The honest conclusion from
   your own data is that the residual behaves more like a *resolution artefact
   of aggregation plus unmeasured shared drivers* than like interaction.
3. **Pollen compounds it.** Presence/absence of genus-level pollen
   morphotypes at 500-yr resolution across catchment-scale source areas is
   about the weakest substrate imaginable for inferring who competes with whom.
   You cannot win that argument in review, and defending it will eat the
   discussion.

Conclusion: *don't lead with interactions*. The question is what to lead with
instead. The options below are ordered roughly from "least new compute" to
"most new compute".

---

## 4. The options

### Option A — The residual is taxonomic, not spatial
*"What the unexplained fraction of community structure is a fraction of"*

**Headline.** Across 229 paleo models spanning three continents, three spatial
extents and three levels of biological organisation, the unexplained
(residual-association) fraction of community structure is essentially invariant
to spatial extent — or weakly *increases* with it — but falls by roughly half
from genus to functional type. The component of co-occurrence that resists
climate and space is therefore a property of the taxonomic lens, not of
geographic grain.

**Evidence in hand.** Table (a), fully. The modern grid replicates it
independently once Stage 04 is rebuilt (continental modern already shows the
same FT collapse: 5.5 % at FT vs 34–35 % at genus/family).

**Still to run.** Stage 04/05 rebuild for modern. Ideally one aggregation
simulation: take the genus matrices, aggregate at random to FT-sized groups,
show the fraction falls the same way — which separates "functional coherence"
from "any aggregation reduces residual covariance". Without that control the
reviewer writes it for you.

**Target.** *Ecology Letters*, *Global Ecology and Biogeography*, *Ecography*.

**Pros**
- Uses the data you already have, as its own headline rather than as a caveat.
- Reframes the inference problem as the finding, so the co-occurrence critique
  becomes your discussion rather than your weakness.
- A genuinely counter-intuitive result; the inverted spatial gradient is the
  kind of thing people cite.
- Directly answers grant objective 2 (the scale question) without needing
  objective 3.

**Cons**
- Fundamentally a negative/deflationary result; some editors read that as
  "methods paper in ecology clothing".
- Continental tier has *n* = 2–3 units, so the top of the spatial gradient is
  thin; the inverted ordering rests largely on those few models.
- The aggregation control is a real new analysis, and it could kill the
  functional interpretation (if random aggregation does the same thing, the
  taxonomic gradient is pure statistics).
- The headline quantity is the ANOVA fraction — i.e. the quantity with the
  −6.85 shared-fraction problem. You would need to show the result survives in
  predictive terms too.

---

### Option B — Assembly since the LGM: reorganisation without a change in rules
*"Europe rewired, North America did not"*

**Headline.** Through 20 kyr of deglacial and Holocene climate change the
*relative* contributions of climate, space and residual association to community
structure stay remarkably constant — but the co-occurrence network itself
restructures, and only in Europe. European assembly shifts from
spatially-structured to climate-structured as *Q* halves between 17.5 and 6 ka;
North America holds steady on both counts. The composition changed; the rules
that generated it did not.

**Evidence in hand.** All of (b), from saved tables. 40/36/21 time slices with
both model-based components and model-free network metrics — the decoupling of
the two is the argument, and it is already computed.

**Still to run.** Little, strictly. Worth adding: sample-size and taxon-richness
controls per slice (modularity is sensitive to both, and the Europe trend
tracks the deglacial rise in core count — this is the first thing a reviewer
will ask); a change-point or GAM fit rather than Spearman; and the obvious
mechanistic overlay (ice-sheet retreat, refugial structure, the 8.2 ka and
late-Holocene land-use horizons).

**Target.** *Nature Ecology & Evolution* / *PNAS* for the ambitious version;
*Global Change Biology*, *Journal of Ecology*, *Journal of Biogeography* for the
safe version.

**Pros**
- This is the paleoecological result — the thing only your data can produce.
  Modern plot data cannot say it at all.
- The continental contrast maps onto a classic, well-loved biogeographic story
  (European E–W barriers, Pleistocene extinction filter, refugial compression)
  and gives it a community-structure measurement rather than a range-shift one.
- The model-free network metrics are independent of the jSDM, so the central
  claim survives even if a reviewer rejects the variance decomposition wholesale.
  That is a strong structural position.
- Stability of the partition under enormous climate change is itself a quotable
  result, and it reframes the flat association fraction as *robustness* rather
  than *absence of signal*.
- Closest to what you said you find cool, and the cheapest to reach.

**Cons**
- Sampling-density confounding is the whole fight. European core counts rise
  steeply through the deglacial; modularity falls. You must kill that
  alternative explanation convincingly (rarefaction to constant site and taxon
  number per slice, ideally constant geographic extent too).
- Asia contributes only the last 10.5 ka and will look like a half-finished
  panel; you may have to demote it to supplementary.
- Three continents is *n* = 3 for the "continental contrast" claim.
- Interpolation to a 500-yr grid plus age-model uncertainty is a genuine
  smoothing concern for time-resolved network metrics; the supplementary
  interpolation-uncertainty figures exist but will need to be front-line.
- "No change in the partition" could also mean the partition is insensitive —
  you need the network result to carry the paper, which it can.

---

### Option C — Does residual co-occurrence actually help you predict?
*"Partitioning fitted variance tells you less than removing a block and testing"*

**Headline.** Take the question out of the inference war and into
decision-relevant terms: when you hold out space and predict unseen locations,
how much does the residual-association block buy you? Answer, so far: a small
but completely repeatable improvement in calibration (log loss, Brier, Tjur R²)
and nothing in ranking (AUC); climate dominates; space is marginal. And the
fitted-data ANOVA that everybody reports does *not* reproduce those magnitudes —
only their ordering.

**Evidence in hand.** The full `eu_r005_l010` experiment (table (c)), plus the
explicit ANOVA-vs-prediction comparison including the −6.85 three-way fraction.
The CV architecture already runs at scale (6,472 fold fits on the modern side
alone), so the machinery is not the obstacle.

**Still to run.** Scale the component-removal design from 1 unit to a
representative sample — say 20–30 units spanning all three tiers, all three
resolutions, and both data sources. That is 4 fits × 15 folds × N units; at the
~5 min/unit GPU figure recorded for the reference run, this is days of compute,
not months, and needs no new methods.

**Target.** *Methods in Ecology and Evolution*, *Ecography*, *Global Ecology and
Biogeography*.

**Pros**
- Methodologically unassailable. There is no inferential leap to attack: you
  measure predictive contribution, you report predictive contribution.
- Pre-empts the exact criticism you are worried about by making it the subject.
- Genuinely useful to a large community — every jSDM paper reports variance
  fractions, and you would be the one showing what they do and don't mean.
- Sets up every later paper: once this exists you can cite it and use the
  association fraction descriptively without re-litigating.
- Your reproducibility infrastructure (targets, renv, ~full test coverage) is a
  real asset in a methods venue and dead weight in an ecology venue.

**Cons**
- It is a methods paper. If BIODYNAMICS needs a flagship ecology output, this is
  not it.
- "Climate dominates, associations add a little, space adds almost nothing" is
  not surprising to anyone; the novelty is the rigour and the scale, not the
  direction.
- Needs the new multi-unit run before it says anything general — one unit is an
  anecdote.
- Risk of overlap with the existing jSDM-evaluation literature (Norberg et al.
  2019 and successors); you need to be clear what the component-removal design
  adds beyond published cross-comparisons.

---

### Option D — Paleo vs modern through one pipeline
*"What you conclude about biotic structure depends on the observational window"*

**Headline.** Run the identical model on fossil pollen and on contemporary
vegetation plots and the partition changes systematically: at the continental
tier, climate explains ~69 % (predictor-inclusive) in paleo vs ~48 % in modern
genus-level models, while space goes the other way (41 % → 52 %) and the
association fraction stays similar (~54 % → ~50 %). The inference you draw about
the unexplained fraction is partly a property of *how you looked*.

**Evidence in hand.** Continental tier for both arms. The modern regional and
local tiers are fitted and audited but their synthesis tables and figures are
not yet rebuilt.

**Still to run.** Stage 04 + Stage 05 (the queue you stopped on 21 Oct). Then a
careful treatment of what differs besides age — taxonomic resolution,
abundance definition, grain, source area, sampling design — because the
comparison is only interesting if it is not just confounding.

**Target.** *Global Ecology and Biogeography*, *Ecography*, *Journal of
Vegetation Science*, *Frontiers of Biogeography*.

**Pros**
- Only VegVault makes it possible; it is the direct payoff of grant objective 1
  and an argument for the database's existence.
- Methodologically honest in a way reviewers like: you are measuring your own
  observational bias rather than assuming it away.
- Useful to two communities at once (paleo people who want to know if their
  inferences transfer; neo people who want to know what deep time adds).
- The modern arm is already fitted — the remaining cost is the synthesis
  rebuild, which you were going to do anyway.

**Cons**
- The confound list is brutal and partly irreducible: pollen source area vs plot
  area, morphotype vs species, relative pollen percentage vs cover, opportunistic
  coring vs designed plot networks. A reviewer can always say the difference is
  the data, not the ecology — and they would be partly right.
- Risks reading as a data-quality note rather than an ecological finding.
- Weakest headline of the six; best as a major section of another paper (it is
  the natural robustness section for Option A).

---

### Option E — Hindcast-validated projection of diversity change
*"Use 20 kyr of observed response to test, then project"*

**Headline.** The grant's objective 3. Fit on part of the record, hindcast the
rest, show where the model is trustworthy, then drive it with CMIP6 to 2050/2100
with the association structure included and excluded.

**Evidence in hand.** Working projection machinery (per-taxon probability and
expected-richness maps for Europe, median AUC ≈ 0.89 on the slide), CHELSA-TraCE21k
hindcast extraction, MEM interpolation to grid, and a written implementation
plan.

**Still to run.** Essentially all of it — CMIP6 acquisition and harmonisation
with CHELSA baselines, scenario metadata, a defensible temporal-transfer
validation design, and the with/without-association contrast. Months.

**Target.** *Nature Ecology & Evolution*, *Nature Climate Change*, *PNAS*,
*Global Change Biology*.

**Pros**
- Highest impact ceiling by a wide margin, and the only option that closes the
  grant's headline promise.
- Deep-time hindcast validation is a real methodological advance over SDM
  projections validated only on held-out modern data — you can show transfer
  across genuinely non-analogue climates, which nobody else can.
- The with/without-association contrast makes the association block
  *consequential* rather than merely present, which is the strongest possible
  answer to the "is it interaction?" objection: it stops mattering.

**Cons**
- Your own CV numbers currently argue against it. Spatial-block out-of-sample
  AUC at the continental genus tier is 0.52–0.60. Projecting to 2100 from models
  that barely beat chance when moved across space inside the same continent is
  hard to defend; you would have to lead with family/FT resolution, where skill
  is adequate, which weakens the taxonomic story.
- Largest new-compute burden of any option, on a machine with a known failing
  C-drive and a grant that has already been extended once.
- Non-analogue climate transfer is exactly where SDM projections are known to
  fail; reviewers who like this topic are also the ones best equipped to attack
  it.
- The association block's contribution is to *calibration*, not ranking — which
  is the honest framing but much less saleable than "interactions change the
  forecast".

---

### Option F — Split it: a short series rather than one paper
*"Stop trying to make one paper carry three axes, two data sources and a forecast"*

A plausible sequence, each paper standing alone and citing the previous:

1. **Paper 1 (methods, ~3 months):** Option C. Multi-unit component-removal,
   ANOVA-vs-prediction discrepancy, the pipeline. Establishes the measurement.
2. **Paper 2 (flagship ecology, ~4–6 months):** Option B, with Option A's
   taxonomic result as its second axis and Option D's modern comparison as the
   robustness section. Cites paper 1 for why the association fraction means what
   you say it means.
3. **Paper 3 (ambitious, open-ended):** Option E, built on the validated
   machinery, with paper 2's temporal results as the empirical justification for
   the transfer design.

**Pros**
- Each paper has one defensible headline instead of one paper with four hedged
  ones — which is the failure mode the current Results outline is heading for.
- Paper 1 derisks papers 2 and 3 by settling the inference argument once, in the
  venue where that argument belongs.
- Matches the actual state of the compute: paper 1 needs a modest new run,
  paper 2 needs almost none, paper 3 needs everything.
- Three outputs is a better grant report than one.

**Cons**
- Slowest route to the first high-profile paper, and the grant is already in
  extension.
- Salami-slicing risk: reviewers of paper 2 may ask why the modern data and the
  predictive validation are elsewhere.
- Three papers means three rounds of co-author coordination and three
  manuscripts to maintain against a pipeline that is still being rerun.
- The methods paper has to actually land first, or paper 2 loses its foundation
  and you are back to defending the ANOVA fractions.

---

## 5. Recommendation

If you want one paper: **Option B as the spine, Option A as the second axis**,
with the interaction language removed entirely and replaced by "residual
association" / "unexplained co-occurrence structure" throughout. Title in the
register of *"Vegetation reorganised without changing its assembly rules since
the Last Glacial Maximum"*. Reasons: it is the result only you can produce, it
is almost fully computed, the network metrics give it a jSDM-independent
backbone, and the continental contrast gives it a story rather than a
partition table.

If you want the safest path to a first paper: **Option C**, because the
experiment design is already validated and the result is unattackable.

The thing I would not do is lead with the spatial-scale question as currently
framed in the talk ("is the association signal scale-dependent?"). The honest
answer from your own tables is "yes, but on the taxonomic axis and in the
direction opposite to the one the question presumes" — which is a fine *finding*
and a poor *frame*, because the frame invites the reader to evaluate it as an
interaction study.

## 6. Caveats that apply whichever way you go

- **Decide now whether the headline number is an ANOVA fraction or a predictive
  effect.** The −6.85 three-way fraction and the negative-to-zero clamping are
  discoverable by any reviewer who reads the methods. Options A, B and D
  currently rest on the clamped ANOVA; Option C replaces it.
- **The frozen 31 Aug snapshot in the conference decks is not the 12 Oct
  snapshot.** Functional-type fractions moved from 5–8 % to 17–24 % after the
  trait correction. Any co-author who remembers numbers from the talk will
  remember the old ones.
- **Asia is a 10.5 ka record, not a 20 ka one.** Decide early whether it is a
  main-text panel or supplementary.
- **Sampling density is the first reviewer question on every temporal figure.**
  Rarefaction per slice is not optional for Option B.
- **The modern Stage 04/05 rebuild is an unfinished dependency** for anything
  that quotes modern regional or local results.
- Keywords in `manuscript.qmd` still list HMSC; the models are `{sjSDM}`.

## 7. What I would want to decide before writing a word of Introduction

1. One paper or a series (§4F)?
2. Headline quantity: fitted-data variance fraction, or held-out predictive
   contribution?
3. Is Asia main text or supplementary?
4. Is the modern arm a co-equal axis (Option D) or the robustness section of a
   paleo paper?
5. Target journal first, then write — the Nature-Letter vs Frontiers-of-Biogeography
   fork is still open in the manuscript comments and it determines how much of
   the methods can stay.
