# Trait correction reviewer

Use this workflow to investigate bounded batches from the generated raw or classified trait-review queue. The workflow produces evidence-backed proposals only; it must never set review status to approved, supply a human reviewer identity, or silently edit immutable files under Data/Input/Trait_corrections/Review_submission/.

## Inputs

- Select one review stage (raw or classified) and no more than 25 candidate rows from Data/Temp/Trait_corrections/<stage>/trait_review_candidates.csv.
- Read the matching current records from the configured project_traits_reference target store.
- Read existing canonical decisions so that proposed rules do not overlap or duplicate work.
- For recovered submission evidence, use review_decision_proposals.csv, review_pending_visual_review.csv, the immutable source row, and review_notes.pdf.

## Review method

1. Confirm the exact taxon and VegVault trait domain. Treat spelling or Unicode normalization as a proposed taxonomic match until a human accepts it.
2. Inspect distributions split by exact trait_name, dataset_id, and dataset_name; retain sample_id, trait_id, and taxon_id in the evidence table.
3. Compare suspicious values with the taxon's other sources and with related taxa. Family or growth-form ranges may prioritize review but cannot alone justify correction.
4. Research authoritative evidence when needed. Prefer primary trait publications, FloraVeg, official floras, and documented source-database units. Record stable URLs, citations, or report paths.
5. Translate evidence into atomic selectors. Use separate rows for disjoint ranges. Blank selectors mean the whole taxon-domain group.
6. Use action none when the candidate was reviewed and no change is warranted.
7. Record confidence and unresolved questions in the rationale. Keep ambiguous unit conversions, conflicting submitted duplicates, mild/extreme wording, and uncertain taxa proposed.

themeasureofthings.com may help visualize magnitude but is not scientific evidence.

## Output requirements

- Append only canonical rows with review status proposed and blank reviewer and reviewed_at.
- Generate decision_id with SHA-256 from the candidate plus all selectors, action, scale factor, and rationale.
- Provide a batch summary with candidates inspected, proposals written, no-action recommendations, unresolved cases, and evidence sources.
- Run validate_trait_review_decisions() on a temporary copy only after a human has supplied approvals; do not bypass incomplete-coverage failures.
- Stop after the bounded batch. Raw review must cover all six domains before classified review begins, with explicit attention to Leaf mass per area because it is absent from the review submission.
