# Manuscript planning — October 2026

Working material behind the current manuscript plan. Nothing here is a result
for publication; the figures in `figures/mockups/` are **simulated data** and are
labelled as such inside the images.

**Start here:** [`STATUS_AND_PLAN.md`](STATUS_AND_PLAN.md) — where the project
stands, the six questions, and how to answer each one.

The manuscript-level plan is the sibling file
[`../manuscript_rework_skeleton_20261021.md`](../manuscript_rework_skeleton_20261021.md).
`direction_review_20261023.md` is the reasoning trail behind the current
direction, kept append-only including superseded sections; it is a record, not
a summary.

## Contents

| Path | What it is |
|---|---|
| `direction_options_six_framings.md` | Six candidate framings for the paper with pros and cons, written before the decay result. Historical; the decision is recorded in the plan. |
| `integrated_narrative_superseded.md` | The earlier "invariance + exception + measurement correction" arc. **Superseded** — its §2(a) treats the spatial and taxonomic gradients in the association share as ecological, which the width artefact explains away. Kept for the reasoning. |
| `recurrence_paper_concept.md` | The Clements–Gleason recurrence framing: ask whether the same taxon *pairs* recur rather than how much residual there is. Partly tested — see `figures/assoc_decay.png`. |
| `figures/taxon_count_confound.png` | **Real data.** Association share against number of modelled taxa, and the reversal of the spatial gradient once width is matched. |
| `figures/assoc_decay.png` | **Real data.** Association-matrix similarity against time lag, Europe and North America, with a label-permutation null and fitted exponential-plus-floor. Half-life 2.1 / 2.2 kyr. |
| `figures/mockups/` | **Simulated.** Layout mock-ups of the proposed figures, to judge whether each claim reads before the analyses are run. |
| `data/lag_similarity.csv` | 1,336 slice-pair comparisons: continent, the two ages, lag, observed Spearman similarity, permutation-null mean and 97.5th percentile, number of shared taxa. |
| `scripts/export_association_matrices_v2.R` | Read-only export of residual correlation matrices from the cold `paleo_temporal_*` stores. Diagnoses the reader first, then exports. Never calls `tar_make`; writes only to `Data/Temp/assoc_export`. |

## Key numbers established so far

- Association share scales with model width: `R² = 0.675` on `log(n_taxa)`;
  Type-II `η² = 0.516` for taxon number against `0.046` for taxonomic resolution.
  Matching width reverses the spatial gradient from 30.7 / 34.4 / 41.4 to
  27.1 / 24.9 / 18.6 (local / regional / continental, genus).
- Association similarity decays with a half-life of **2.1 kyr** (North America)
  and **2.2 kyr** (Europe), fitted on lags ≥ 2 kyr. Long-lag floors sit at or
  below the permutation null, so there is no strong conserved core; but 50 %
  (America) and 31 % (Europe) of slice pairs at 13.5–20 kyr still exceed their
  own null, against 2.5 % by chance.
- Adjacent-slice rewiring decelerates toward the present in North America
  (ρ = +0.66, p = 9.4 × 10⁻⁶ at 1 kyr lag) and is flat in Europe. **Caveat:** in
  America rewiring correlates with shared-taxon count (ρ = −0.44, p = 0.005),
  which rises with sampling, so this needs a joint model before it is claimed.
- 32 genera are shared between the European and North American temporal models;
  9 appear in every slice of both.

## Next analysis, in order

1. Export the binarised slice community matrices and compute raw co-occurrence
   turnover with the identical statistic — the internal control for the
   half-life.
2. Between-slice compositional turnover on the same matrices.
3. Per-slice rarefaction of the network metrics.
4. Model rewiring against age **and** shared-taxon count.
5. `RRatepol` rate of change, in its native per-sequence design, as corroboration.

Full list with costs in §7 and §9 of the plan.
