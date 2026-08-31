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

The programmatic pass examined all 1,928 raw candidates that were not already covered by canonical approvals.

The 52 completed investigations approved by the project owner are now recorded canonically as `action = "none"` and are excluded from this queue.

The corrected first triage proposes `action = "none"` for 0 additional candidates. It sent 1,552 candidates to deterministic reconciliation and retained 376 candidates in grouped evidence review.

The second R pass checked all 1,552 pending candidates. It produced 293 unapproved scale proposals affecting 20,753 current records, 14 unapproved no-action proposals for candidates with no current records, 285 targeted-review cases, and 960 still-unresolved cases.

The exceptions collapse to 71 evidence groups and 9 bounded initial batches.

Under the previous two-reviewer-plus-adjudicator design, the same grouped batches would require up to 27 agent runs.

The cost-gated design requires at most 9 initial reviewer runs, followed by a second review and adjudication only for groups that propose an actual correction.

The programmatic workflow itself does not launch agents.

One manually launched pilot reviewer run examined 10 former Leaf mass per area `invalid_source` groups covering nine candidates. Its proposed no-action rows were rejected because it incorrectly described 23 positive infinite values as `NA`. Direct production-data inspection traced the infinities to reciprocal conversion of zero SLA values. After the ingestion boundary was corrected to retain only finite trait values, those obsolete invalid-source groups disappeared. The pilot proposals remain unapproved and do not count as review of any group in the current exception queue.

The pilot used `gpt-5.6-terra` with high reasoning. Runtime token usage was not exposed, so no verified token total is available.

## Decision boundary

The separate approval runner recorded only the 52 newly approved completed investigations. The triage workflow itself does not edit either canonical decision file and does not apply any correction.

No unresolved candidate receives a no-action proposal merely because the current checks failed to identify a repeated error pattern.

Submitted concerns, recovered proposals, isolated source-factor hints, and historical drift remain explicitly pending until a structured rule resolves them or a completed investigation supports a human decision.

All second-pass decision rows remain proposals. They have not been added to a canonical decision file, approved, or applied.

Ordinary `NA` missingness is not treated as a correctable trait value. After missing rows are ignored, finite source summaries are still checked for repeated factor patterns.

## Structured checks

A source pattern is escalated only when at least 3 candidates share the same low-source and high-source pairing and their median ratio is within 25% of a factor of ten, one hundred, or one thousand.

Matched recovered selectors remain exceptions because the archived review material is evidence but not automatic authority for changing current records.

Negative, `NaN`, and infinite observed records remain exceptions and are grouped by trait domain, dataset, trait variant, and invalid-value type.

Isolated outliers, unmatched archived selectors, historical drift, and submitted concerns without a repeated error pattern do not establish a correction under the conservative policy. They also do not establish that no correction is needed, so they remain pending programmatic review.

The second pass parses only exact instructions of the form `rescale values below X only` or `rescale values above X only`. A threshold rule is proposed only when at least two current positive finite records occur on each side, the original selected-versus-unselected median gap is at least 0.7 log10 units, the proposed correction reduces that gap by at least 0.5 log10 units, and the remaining gap is at most 0.3 log10 units.

A dataset-specific scale is proposed only when a single submitted factor with note `x` independently matches the current low-versus-high source median ratio within 5%, identifies an unambiguous scaling direction, and both sources contain at least two positive finite records.

## Candidate outcomes


|Trait domain                        |Triage outcome                  | Candidates|
|:-----------------------------------|:-------------------------------|----------:|
|Leaf Area                           |agent_recovered_rule            |          9|
|Leaf Area                           |agent_repeated_source_pattern   |         22|
|Leaf Area                           |pending_historical_drift        |          1|
|Leaf Area                           |pending_isolated_source_pattern |         50|
|Leaf Area                           |pending_submitted_note          |        416|
|Leaf mass per area                  |agent_repeated_source_pattern   |         31|
|Leaf mass per area                  |pending_isolated_source_pattern |         47|
|Leaf mass per area                  |pending_unresolved_evidence     |         11|
|Leaf nitrogen content per unit mass |agent_recovered_rule            |          5|
|Leaf nitrogen content per unit mass |agent_repeated_source_pattern   |         12|
|Leaf nitrogen content per unit mass |pending_isolated_source_pattern |         93|
|Leaf nitrogen content per unit mass |pending_recovered_proposal      |          1|
|Leaf nitrogen content per unit mass |pending_submitted_note          |        363|
|Plant heigh                         |agent_invalid_values            |          1|
|Plant heigh                         |agent_recovered_rule            |        288|
|Plant heigh                         |agent_repeated_source_pattern   |          8|
|Plant heigh                         |pending_historical_drift        |          2|
|Plant heigh                         |pending_isolated_source_pattern |         62|
|Plant heigh                         |pending_recovered_proposal      |         10|
|Plant heigh                         |pending_submitted_note          |        496|

## Deterministic reconciliation outcomes


|Trait domain                        |Reconciliation outcome                   | Candidates|
|:-----------------------------------|:----------------------------------------|----------:|
|Leaf Area                           |agent_historical_drift                   |          1|
|Leaf Area                           |agent_strong_isolated_source_pattern     |         15|
|Leaf Area                           |agent_threshold_rule_not_corroborated    |         47|
|Leaf Area                           |agent_unparsed_exclusion_instruction     |         39|
|Leaf Area                           |pending_isolated_source_pattern          |         12|
|Leaf Area                           |pending_submitted_note                   |        298|
|Leaf Area                           |propose_scale_validated_threshold        |         55|
|Leaf mass per area                  |agent_strong_isolated_source_pattern     |         47|
|Leaf mass per area                  |pending_unresolved_evidence              |         11|
|Leaf nitrogen content per unit mass |agent_strong_isolated_source_pattern     |          5|
|Leaf nitrogen content per unit mass |agent_threshold_rule_not_corroborated    |         49|
|Leaf nitrogen content per unit mass |agent_unparsed_exclusion_instruction     |         30|
|Leaf nitrogen content per unit mass |pending_isolated_source_pattern          |          4|
|Leaf nitrogen content per unit mass |pending_submitted_note                   |        148|
|Leaf nitrogen content per unit mass |propose_none_no_current_records          |          1|
|Leaf nitrogen content per unit mass |propose_scale_validated_threshold        |        220|
|Plant heigh                         |agent_conflicting_submitted_instructions |          2|
|Plant heigh                         |agent_historical_drift                   |          2|
|Plant heigh                         |agent_strong_isolated_source_pattern     |         16|
|Plant heigh                         |agent_threshold_rule_not_corroborated    |         14|
|Plant heigh                         |agent_unmatched_recovered_rule           |          5|
|Plant heigh                         |agent_unparsed_exclusion_instruction     |         13|
|Plant heigh                         |pending_isolated_source_pattern          |         38|
|Plant heigh                         |pending_submitted_note                   |        449|
|Plant heigh                         |propose_none_no_current_records          |         13|
|Plant heigh                         |propose_scale_corroborated_source        |          2|
|Plant heigh                         |propose_scale_validated_threshold        |         16|

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

Do not bulk-approve the 960 still-unresolved candidates as `none`: their absence of corroborating current evidence is not equivalent to a completed investigation.

First review the 293 scale proposals as a policy batch and the 14 obsolete-candidate no-action proposals separately. They are reproducible proposals, not approvals.

Then group the 285 newly targeted cases by evidence type before launching any reviewer. The original 376 evidence-backed exceptions already collapse to 71 groups. Reserve expensive independent replication for a group that recommends exclusion or scaling. The rejected pilot reviewed obsolete invalid-source groups and does not count toward the current batches.
