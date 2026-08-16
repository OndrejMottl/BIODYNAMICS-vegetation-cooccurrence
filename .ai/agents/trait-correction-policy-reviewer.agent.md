# Trait correction policy reviewer

Use this prompt to review one bounded batch from the raw-stage all-domain policy queue. Replace `<ROLE>`, `<BATCH_ID>`, and `<RUN_ID>` before running it.

## Parameters

- `ROLE`: `reviewer_a`, `reviewer_b`, or `adjudicator`
- `BATCH_ID`: one `agent_batch_id` from `Data/Temp/Trait_corrections/raw/policy/trait_review_policy_agent_queue.csv`
- `RUN_ID`: a unique short identifier for this run

## Task

Review only `<BATCH_ID>` in role `<ROLE>`. Treat deterministic outcomes and recovered corrections as hypotheses, not answers. Do not edit either canonical decision CSV, do not apply corrections, and do not change trait records, pipeline code, source submissions, or policy proposals.

Read:

- `Data/Temp/Trait_corrections/raw/policy/trait_review_policy_agent_queue.csv`
- `Data/Temp/Trait_corrections/raw/policy/trait_review_policy_targeted_dataset_evidence.csv`
- `Data/Temp/Trait_corrections/raw/policy/trait_review_policy_targeted_record_evidence.csv`
- `Data/Temp/Trait_corrections/raw/policy/trait_review_policy_proposal_diagnostics.csv`
- `Data/Temp/Trait_corrections/raw/review_submission_audit.csv`
- `Outputs/Reports/Trait_corrections/raw/trait_review_policy_report.md`
- `Data/Input/Trait_corrections/README.md`

For `reviewer_a` or `reviewer_b`, work blind and do not read another reviewer's output. Examine the exact candidate reason, records split by `trait_name` and dataset, recovered selectors, submitted notes, possible unit patterns, and source-level negative or non-finite patterns. Use authoritative source-dataset documentation, primary trait publications, or authoritative floras when external evidence is needed. Family or growth-form expectations may prioritize investigation but cannot justify exclusion or scaling by themselves.

Default to `none` when measurements remain plausible and there is no positive evidence of an ingestion, unit, transformation, or transcription error. Use `insufficient_evidence` when a submitted concern or apparent source pattern cannot be resolved. Never infer a whole-group correction from a few extreme values.

For each candidate, return exactly one recommendation: `none`, `exclude`, `scale`, or `insufficient_evidence`. An `exclude` or `scale` recommendation must provide atomic selectors and the number of currently matched records. A scale recommendation must identify the source convention or documentation supporting the factor. Never claim human review, human approval, or production readiness.

Write one CSV to `Data/Temp/Trait_corrections/raw/policy/agent_reviews/<BATCH_ID>_<ROLE>_<RUN_ID>.csv` with these columns:

`candidate_id,agent_batch_id,review_role,run_id,recommendation,trait_name,dataset_id,value_lower,value_lower_inclusive,value_upper,value_upper_inclusive,scale_factor,n_matched_records,confidence,rationale,evidence_reference,conflicts_or_uncertainty`

For `adjudicator`, require two completed blind-review CSVs for the same batch. Compare both reviews against the deterministic and source evidence. Record `agent_consensus` confidence only when both reviewers independently recommend the same action and identical selectors. Otherwise record `insufficient_evidence` and explain the disagreement. Adjudication remains a proposal and must not be copied automatically into canonical decisions.

At the end, report counts by recommendation and confidence, list disagreements or missing source evidence, and explicitly confirm that no canonical decision or trait record was changed.
