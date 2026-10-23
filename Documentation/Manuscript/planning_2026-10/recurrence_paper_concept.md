# The recurrence paper — a fuller picture

An alternative to the invariance framing, using the same models but a different
quantity: not *how much* residual association there is, but *whether the same
associations come back*.

---

## 1. The hook

Vegetation science began with an argument about whether communities are real.

Clements saw plant communities as integrated units — recurrent, repeatable
combinations of species bound together, the oak–hornbeam wood, the
spruce–feathermoss taiga. Gleason answered that each species responds to the
environment on its own, and that any apparent community is the coincidence of
overlapping individual ranges at a moment in time. Vegetation classification was
built on Clements' premise; the Quaternary pollen record has been the strongest
evidence for Gleason's. Species migrated out of their glacial refugia at
different rates and in different directions, producing assemblages with no
modern analogue — the textbook demonstration that communities disassemble and
reassemble rather than move as units.

That argument has never been given a quantitative answer, because answering it
requires something nobody has had: the same community model, fitted
consistently, to hundreds of independent floras across tens of thousands of
years, with climate and space already removed.

You have that.

> **The question.** After climate and spatial structure are accounted for, do
> the same pairs of plant taxa associate with each other, again and again,
> across different millennia, different regions, different continents, and
> different ways of observing vegetation? Or is every residual association a
> property of its own dataset?

A century after Gleason, the answer can be a number: the fraction of plant
co-occurrence structure that is **recurrent** versus **contingent**.

---

## 2. Why this is a better paper than the invariance version

| | Invariance framing | Recurrence framing |
|---|---|---|
| Unit of claim | A variance fraction | Named taxa and named partnerships |
| Result mode | Null ("nothing changes") | Positive or negative, both informative |
| Reader intuition required | Must already care about Nagelkerke partitions | Everyone understands "do oaks and hazels keep turning up together?" |
| Deep time's role | A trend axis, confounded by rising sample size | **Replication** — the confound mostly disappears |
| Vulnerability to the width artefact | Central; the headline number is width-dependent | Peripheral; sign/rank agreement between pairs is not mechanically inflated by matrix width |
| Mechanism available | None | Trait distance, phylogeny, functional type — all already computed |
| Named debate to resolve | None | Clements–Gleason, individualistic migration, no-analogue communities |
| Engages König et al. 2021 | As a caveat | **Directly tests and potentially overturns their interpretation** |

The last row is the intellectual core. König, Wüest and Graham found that
jSDM associations correlate with functional similarity, and concluded that
shared responses to unobserved predictors — not interaction — explain them. If
your *recurrent* pairs behave differently from your *contingent* pairs — if the
conserved core is **not** explained by functional similarity while the
idiosyncratic majority is — then the shared-missing-predictor explanation covers
the noise but not the signal. That is a conceptual advance, not a caveat, and it
is reachable with data you already have.

---

## 3. The four levels of independence

The design writes itself, because your three analysis axes become a ladder of
increasingly demanding tests. Each rung is harder to explain away than the one
below.

**Rung 1 — Through time, within a continent.** Do the associations estimated at
15 ka resemble those at 14.5 ka? At 10 ka? At 0 ka? This gives an *association
autocorrelation function*: similarity between association matrices as a function
of time lag. If it decays to zero, associations are purely contingent. **If it
decays to a non-zero floor, that floor is the conserved core** — and the
decay rate is the half-life of a plant partnership.
Material: 36 Europe + 40 America + 21 Asia slices.

**Rung 2 — Across space, within a continent and a time window.** Do independent
spatial units share associations? 58 local paleo units at genus level is genuine
replication across floras that never shared a model.

**Rung 3 — Across continents.** Many northern-hemisphere genera occur on both
sides of the Atlantic — *Picea*, *Pinus*, *Betula*, *Alnus*, *Salix*, *Quercus*,
*Populus*, *Fraxinus*, *Corylus*, *Abies*. For a pair present in both Europe and
North America, does it associate the same way? This rung is the strongest,
because the two continents have different climate gradients, different
topography and different glacial histories — so a shared unmeasured
environmental driver is a much weaker explanation than it is within a continent.

**Rung 4 — Across observation systems.** Does a pair that recurs in fossil
pollen also recur in modern vegetation plots? Different sampling, different
grain, different abundance currency, different taphonomy, 20,000 years apart.
Essentially nothing survives that except something real about the plants.

A pair that clears all four rungs is as close to a demonstrated assembly
constraint as co-occurrence data can get. The paper's central figure is the
count of pairs surviving each rung.

---

## 4. The mechanism layer

Once you have the conserved set, three questions make it ecological rather than
statistical:

1. **Are conserved pairs functionally similar or dissimilar?** Trait distances
   are already computed (Gower, per continent, from the TRY extraction). König's
   logic predicts that positive associations are between functionally similar
   taxa — the signature of a shared missing predictor. If the conserved subset
   breaks that pattern, the interpretation changes.
2. **Are they phylogenetically clustered?** Congeneric or confamilial pairs
   recurring together suggests shared niche; distant pairs recurring together
   suggests something else.
3. **Do negative conserved pairs look like displacement?** Mutually exclusive
   pairs that recur across all four rungs, between functionally *similar* taxa,
   are the one pattern that competition theory specifically predicts and shared
   environment does not.

And one that makes it narratively vivid: **name the pairs.** A main-text panel
listing the ten most strongly conserved positive and negative pairs, with their
recurrence scores, is the sort of figure that gets screenshotted. Readers of
*Nature Ecology & Evolution* will recognise the taxa.

---

## 5. What the paper looks like, in both outcomes

**If recurrence is substantial.** *"A conserved core in plant co-occurrence."*
A minority of pairs — say 5–15 % — associate consistently across millennia,
regions, continents and observation systems, while the majority are contingent
on time and place. The conserved core is [functionally structured / not
functionally structured], which [supports / undercuts] the shared-driver
explanation. Gleason was right about most of the flora and wrong about a
specific, identifiable minority. **This is the NEE version.**

**If recurrence is negligible.** *"Plant co-occurrence does not recur."*
Residual associations are properties of datasets, not of floras. Zurell and
colleagues showed this in simulation; here it is in 500+ fitted models across
20,000 years, four levels of independence, and two observation systems. Every
jSDM paper that interprets a residual correlation is interpreting something that
does not replicate. **This is a very strong *Ecology Letters* / *MEE* paper**,
and arguably a more useful one — it would be the empirical closing argument in a
decade-long methodological debate.

Either way you have a paper, which is not true of the invariance framing, where
the null is the only available outcome.

---

## 6. How every existing asset gets used

| Asset | Role in the recurrence paper |
|---|---|
| 229 paleo spatial models | Rung 2 replication; the association matrices are the raw material |
| 274 modern spatial models | Rung 4 — the observation-system test |
| 97 temporal slices | Rung 1 — the autocorrelation function |
| Three continents | Rung 3 — the strongest test |
| Genus / family / FT resolutions | Does recurrence strengthen at coarser resolution? A direct test of whether functional aggregation captures the conserved structure |
| Trait matrices and FT classification | The entire mechanism layer |
| Component-removal CV experiment | Methods spine — shows the residual block carries transferable information at all, which licenses asking whether it recurs |
| Width artefact | Methods spine — explains why the *scalar* fraction was the wrong quantity and motivates moving to pairwise structure |
| VegVault | The reason the paper is possible; the data-availability story writes itself |

Nothing is discarded. The two results you were most attached to — the deep-time
dimension and the paleo/modern pairing — stop being axes of a null result and
become the two hardest rungs of a positive test.

---

## 7. Figures

**Fig 1 — The question.** Clements vs Gleason as a schematic (two cartoon
landscapes: species moving as a block vs independently), the coverage map, and
the four rungs as a ladder diagram. Panel d: one example association matrix,
to show the reader what the raw material is.

**Fig 2 — The association autocorrelation function.** Matrix similarity against
time lag, one line per continent, with a null envelope. The headline is whether
the curves settle above zero. A second panel converts the decay to a half-life
in years — "the average plant partnership lasts N centuries" is a quotable
number.

**Fig 3 — The recurrence spectrum.** Distribution of per-pair recurrence scores
against a null, with the conserved tail shaded and the top pairs named. This is
the figure people will remember.

**Fig 4 — The ladder.** Number and identity of pairs surviving each rung —
time, space, continent, observation system. A funnel from thousands of pairs to
the surviving core.

**Fig 5 — Mechanism.** Conserved versus contingent pairs against trait distance,
phylogenetic distance and functional-type membership, with the König prediction
drawn as a reference line.

---

## 8. What could go wrong

**The covariance is regularised and low-rank.** `sjSDM::bioticStruct()` fits a
penalised latent-factor covariance (elastic-net `lambda_cov`, rank set by the
latent dimension), so pairwise associations are shrunk, not free parameters, and
the amount of shrinkage varies with model width and the tuned regularisation.
*Consequence:* test sign and rank agreement, not raw magnitudes; and include
regularisation strength as a covariate. This is the direct analogue of the width
artefact and must be handled with the same seriousness.

**Shared taxa between continents may be fewer than hoped.** Harmonisation is at
genus level, which helps, but the number of genera present in both the European
and North American models after filtering needs checking before Rung 3 is
promised. If it is under ~15 genera, Rung 3 becomes a vignette rather than a
test.

**Associations are biased positive.** König found jSDM associations shifted
towards positive values; a naive sign-consistency test would then show spurious
recurrence. *Consequence:* the null must be built from the observed sign
distribution, not from a 50/50 coin.

**Genus-level pollen is coarse.** A *Quercus*–*Corylus* association aggregates
dozens of species. Conserved pairs at genus level are real but blunt; the
discussion has to own that.

**Time slices are not independent.** Adjacent 500-yr slices share sites and
share interpolated samples, so Rung 1's short lags are inflated by construction.
*Consequence:* the autocorrelation function must start from lags long enough to
exceed the interpolation window, and the floor matters more than the decay.

**It may simply not be there.** See §5 — this is the one risk that is not really
a risk.

---

## 9. The cheap test that decides it

Before any of this is committed to, one afternoon's work answers whether the
sexy version exists:

1. Pull `getCor()` from the Europe and America temporal stores — 76 matrices.
2. Restrict each to the taxa present in all slices of that continent.
3. Compute matrix similarity between every pair of slices; plot against time lag.
4. Build the null by permuting taxon labels within each slice.
5. Look at the floor.

If the curves decay to a floor clearly above the null, the conserved core exists
and the paper in this document is live. If they decay to the null, you have the
negative result — which is still a paper, just a different one, and you will
know within a day which one you are writing.

A second, equally cheap check: count the genera shared between the fitted
European and North American continental models. That number determines whether
Rung 3 is a headline or a footnote.
