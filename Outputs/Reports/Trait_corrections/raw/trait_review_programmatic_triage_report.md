---
title: "Programmatic trait-review triage"
subtitle: "Cost gate before further agent investigation"
format: gfm
execute:
  echo: false
  warning: false
  message: false
---



## Outcome

The programmatic pass examined all 1,980 raw candidates that were not already covered by canonical approvals.

It proposes `action = "none"` for 1,604 candidates and retains 376 candidates in grouped exception review.

The exceptions collapse to 71 evidence groups and 9 bounded initial batches.

Under the previous two-reviewer-plus-adjudicator design, the same grouped batches would require up to 27 agent runs.

The cost-gated design requires at most 9 initial reviewer runs, followed by a second review and adjudication only for groups that propose an actual correction.

The programmatic workflow itself does not launch agents.

One manually launched pilot reviewer run examined 10 former Leaf mass per area `invalid_source` groups covering nine candidates. Its proposed no-action rows were rejected because it incorrectly described 23 positive infinite values as `NA`. Direct production-data inspection traced the infinities to reciprocal conversion of zero SLA values. After the ingestion boundary was corrected to retain only finite trait values and the triage was regenerated, the nine candidates independently entered the programmatic no-action category. The pilot proposals remain unapproved and do not count as review of any group in the current exception queue.

The pilot used `gpt-5.6-terra` with high reasoning. Runtime token usage was not exposed, so no verified token total is available.

## Decision boundary

All no-action rows remain unapproved proposals.

The workflow does not edit either canonical decision file and does not apply any correction.

The 52 candidates that already completed adjudication are resolved under the approved policy that insufficient evidence becomes `none`.

Other candidates receive a proposed `none` only when structured checks find no negative or non-missing non-finite record, no matched recovered selector, and no source-specific factor pattern repeated across enough taxa.

Ordinary `NA` missingness is not treated as a correctable trait value. After missing rows are ignored, finite source summaries are still checked for repeated factor patterns before a candidate can receive a no-action proposal.

## Structured checks

A source pattern is escalated only when at least 3 candidates share the same low-source and high-source pairing and their median ratio is within 25% of a factor of ten, one hundred, or one thousand.

Matched recovered selectors remain exceptions because the archived review material is evidence but not automatic authority for changing current records.

Negative, `NaN`, and infinite observed records remain exceptions and are grouped by trait domain, dataset, trait variant, and invalid-value type.

Isolated outliers, unmatched archived selectors, historical drift, and submitted concerns without a repeated error pattern do not establish a correction under the conservative policy.

## Candidate outcomes


|Trait domain                        |Triage outcome                          | Candidates|
|:-----------------------------------|:---------------------------------------|----------:|
|Diaspore mass                       |propose_none_completed_investigation    |         18|
|Leaf Area                           |agent_recovered_rule                    |          9|
|Leaf Area                           |agent_repeated_source_pattern           |         22|
|Leaf Area                           |propose_none_no_repeated_error_evidence |        467|
|Leaf mass per area                  |agent_repeated_source_pattern           |         31|
|Leaf mass per area                  |propose_none_no_repeated_error_evidence |         58|
|Leaf nitrogen content per unit mass |agent_recovered_rule                    |          5|
|Leaf nitrogen content per unit mass |agent_repeated_source_pattern           |         12|
|Leaf nitrogen content per unit mass |propose_none_no_repeated_error_evidence |        457|
|Plant heigh                         |agent_invalid_values                    |          1|
|Plant heigh                         |agent_recovered_rule                    |        288|
|Plant heigh                         |agent_repeated_source_pattern           |          8|
|Plant heigh                         |propose_none_no_repeated_error_evidence |        570|
|Stem specific density               |propose_none_completed_investigation    |         34|

## Grouped exception queue


|Trait domain                        |Evidence type  | Evidence groups| Candidate memberships|
|:-----------------------------------|:--------------|---------------:|---------------------:|
|Leaf Area                           |recovered_rule |               6|                     9|
|Leaf Area                           |source_pattern |               2|                    23|
|Leaf mass per area                  |source_pattern |               7|                    31|
|Leaf nitrogen content per unit mass |recovered_rule |               2|                     5|
|Leaf nitrogen content per unit mass |source_pattern |               3|                    12|
|Plant heigh                         |invalid_source |               1|                     1|
|Plant heigh                         |recovered_rule |              48|                   288|
|Plant heigh                         |source_pattern |               2|                    27|

One candidate can belong to more than one evidence group, so candidate-membership totals in this section can exceed the unique candidate count reported above.

Each initial batch contains at most 10 evidence groups, not a fixed number of taxon-domain candidates.


|Trait domain                        |Agent batch                                   | Evidence groups| Candidate memberships|
|:-----------------------------------|:---------------------------------------------|---------------:|---------------------:|
|Leaf Area                           |leaf_area_triage_01                           |               8|                    32|
|Leaf mass per area                  |leaf_mass_per_area_triage_01                  |               7|                    31|
|Leaf nitrogen content per unit mass |leaf_nitrogen_content_per_unit_mass_triage_01 |               5|                    17|
|Plant heigh                         |plant_heigh_triage_01                         |              10|                   106|
|Plant heigh                         |plant_heigh_triage_02                         |              10|                    34|
|Plant heigh                         |plant_heigh_triage_03                         |              10|                   111|
|Plant heigh                         |plant_heigh_triage_04                         |              10|                    22|
|Plant heigh                         |plant_heigh_triage_05                         |              10|                    19|
|Plant heigh                         |plant_heigh_triage_06                         |               1|                    24|

## Recommended next decision

Decide whether the regenerated 1,604 no-action proposals, including the nine candidates recovered after the ingestion fix, are approved for canonicalization.

If the no-action category is approved, append those decisions to the canonical raw file with human reviewer metadata.

Then run one reviewer per current grouped batch and reserve expensive independent replication for any group that recommends exclusion or scaling. The rejected pilot does not reduce the nine current batches because it reviewed obsolete invalid-source groups rather than the current Leaf mass per area source-pattern groups.
