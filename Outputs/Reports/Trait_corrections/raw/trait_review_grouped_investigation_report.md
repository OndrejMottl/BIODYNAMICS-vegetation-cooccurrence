# Grouped trait-review investigation

## Outcome

The 392 interim exceptions were investigated as grouped source and unit-factor patterns. Of these, 357 lack reproducible source-level support and are now approved as explicit no-action decisions under the project owner's conservative closure policy.

The remaining 35 historical candidates contain records from two sources with credible whole-source unit hypotheses. The project owner approved both rules on 2026-08-30. Of those candidates, 29 remain in the queue with explicit residual no-action decisions and six are no longer generated after source scaling.

Rebuilding the queue exposed nine new within-taxon outlier groups. Six lack reproducible source-level evidence and resolve to none under the conservative policy. The project owner approved the two newly exposed metre-scaled source rules on 2026-08-30. Two affected candidates retired and Phyteuma hemisphaericum receives an explicit residual no-action decision after source scaling.

Classified-stage investigation subsequently identified four more source-wide unit corrections, approved on 2026-08-31. Rebuilding the raw queue exposed 33 additional outlier groups. None contains invalid values or a repeated source-factor pattern, so all 33 resolve to no action under the conservative policy.

| Trait domain | Investigation outcome | Candidates |
|---|---|---:|
| Leaf Area | approve_none_after_source_rule | 12 |
| Leaf Area | approve_none_grouped | 46 |
| Leaf Area | resolved_by_source_rule_candidate_retired | 6 |
| Leaf mass per area | approve_none_grouped | 78 |
| Leaf nitrogen content per unit mass | approve_none_grouped | 230 |
| Plant heigh | approve_none_after_source_rule | 18 |
| Plant heigh | approve_none_grouped | 41 |
| Stem specific density | approve_none_grouped | 1 |

## Approved source rules

| Source ID | Source | Trait domain | Factor | Records | Median cross-source ratio | Shared taxa within 25% |
|---:|---|---|---:|---:|---:|---:|
| 155 | Tundra Trait Team | Plant heigh | x100 | 19715 | 1.06 | 0% |
| 243 | Niwot Alpine Plant Traits | Leaf Area | x100 | 111 | 0.94 | 0% |

Source 155 (Tundra Trait Team) contains Plant heigh values with median 0.075 and range 0 to 2.8, consistent with metres. Across 213 taxa shared with independent sources, the median conversion ratio is 97.6, supporting conversion to centimetres with x100.

Source 243 (Niwot Alpine Plant Traits) contains Leaf Area values with median 2.9442 and range 0.0524 to 47.327. Across 100 shared taxa, the median conversion ratio is 94.21 and 77% fall within 25% of x100, supporting square centimetres to square millimetres.

## Additional approved source rules

Source 187 (Abisko & Sheffield Database) contains 248 Plant heigh records with median 0.15 and range 0.02 to 12, consistent with metres. Source 457 (Alpine tundra plants) contains 127 records with median 0.025 and range 0.002 to 0.11, also consistent with metres. The project owner approved both x100 rules on 2026-08-30; they apply to 248 and 127 records respectively.

## Rejected taxon-specific interpretation

The earlier Poa sp and Prunella vulgaris x0.01 proposals are not supported. Values near 30 to 50 are already plausible centimetres. The apparent discrepancy is explained in the opposite direction by metre-valued Tundra Trait Team records requiring source x100.

The approved ARCTOSTAPHYLOS UVA-URSI Plant heigh x0.01 threshold rule is likewise superseded. It was inferred before source 155 was corrected and would now shrink valid centimetre observations. The canonical review records an approved residual none decision instead.

The approved Betula papyrifera Plant heigh x0.1 threshold rule is also superseded. It was inferred before source 352 was corrected and would partially reverse that source-wide x100 correction. The canonical review records an approved residual none decision.

## Conservative decisions

All Leaf mass per area exceptions resolve to no action. TRY-derived Leaf mass per area remains provisional and unchanged because its original units have not been reconstructed. Other isolated or threshold-derived power-of-ten matches also resolve to no action when they lack consistent source-level corroboration.

## Safeguards

- All ten production source rules were owner-approved.
- All ten rules are version-guarded source-scale inputs.
- Twenty-nine affected current candidates have residual no-action decisions.
- Six historical candidates retired because source scaling resolved them.
- Forty post-investigation candidates resolve to no action.
- Two newly exposed candidates retired after source scaling.
- Every current raw candidate has an approved review decision.
- Approved no-action decisions alter no trait records.
- Production validation still fails closed on source or count drift.
