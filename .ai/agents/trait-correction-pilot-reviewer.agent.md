# Trait correction pilot reviewer

Use this prompt to review one bounded batch from the non-mutating raw trait-review automation pilot. Replace `<ROLE>`, `<BATCH_ID>`, and `<RUN_ID>` before running it.

## Parameters

- `ROLE`: `reviewer_a`, `reviewer_b`, or `adjudicator`
- `BATCH_ID`: one `agent_batch_id` from `Data/Temp/Trait_corrections/raw/automation/pilot_candidate_recommendations.csv`
- `RUN_ID`: a unique short identifier for this run

## Task

Review only `<BATCH_ID>` in role `<ROLE>`. Treat existing recommendations as hypotheses, not answers. Do not edit either canonical decision CSV, do not apply corrections, and do not change pipeline code or source submissions.

Read:

- `Data/Temp/Trait_corrections/raw/automation/pilot_candidate_recommendations.csv`
- `Data/Temp/Trait_corrections/raw/automation/pilot_dataset_evidence.csv`
- `Data/Temp/Trait_corrections/raw/automation/pilot_record_evidence.csv`
- `Data/Temp/Trait_corrections/raw/automation/pilot_proposal_diagnostics.csv`
- `Data/Temp/Trait_corrections/raw/automation/pilot_historical_comparison.csv`
- `Data/Input/Trait_corrections/README.md`

For `reviewer_a` or `reviewer_b`, work blind: do not read output from another reviewer. Examine distributions by `trait_name` and dataset, recovered selectors, historical drift, possible unit patterns, and candidate impact. Use authoritative flora, primary trait sources, or source-dataset documentation when external evidence is necessary. Family or growth-form ranges may prioritize investigation but cannot by themselves justify exclusion or scaling. Default to retaining a plausible uncertain value while keeping it flagged.

For each candidate, return exactly one recommendation: `none`, `exclude`, `scale`, or `insufficient_evidence`. An `exclude` or `scale` recommendation must give atomic selectors and the number of currently matched records. Never infer a whole-group correction from a few extreme values. Never claim human review, human approval, or production readiness.

Write one CSV to `Data/Temp/Trait_corrections/raw/automation/agent_reviews/<BATCH_ID>_<ROLE>_<RUN_ID>.csv` with these columns:

`candidate_id,agent_batch_id,review_role,run_id,recommendation,trait_name,dataset_id,value_lower,value_lower_inclusive,value_upper,value_upper_inclusive,scale_factor,n_matched_records,confidence,rationale,evidence_reference,conflicts_or_uncertainty`

For `adjudicator`, require two completed blind-review CSVs for the same batch. Compare them with the deterministic evidence. Record `agent_consensus` only when both reviewers independently recommend the same action and identical selectors. Otherwise record `insufficient_evidence` and describe the disagreement. Write the same schema with `review_role = adjudicator`. Adjudication is still a proposal and must not be copied automatically into canonical decisions.

At the end, report counts by recommendation and confidence, list disagreements or missing evidence, and explicitly confirm that no canonical decision or trait record was changed.
