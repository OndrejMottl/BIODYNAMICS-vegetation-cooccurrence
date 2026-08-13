# Trait correction inputs

## Purpose

This directory separates immutable source material from the reviewed decisions consumed by the trait pipeline. Never clean, normalize, or overwrite files under `Review_submission/`; all parsing repairs belong in generated review candidates or approved decision files.

## Review submission

- `Review_submission/trait_manual_corrections.csv` is the original 1,879-row review CSV. It has no header and contains trailing empty columns; this is preserved as submitted. SHA-256: `89DEF6E308D57BB4DC0C0A308BD02B7C001791C76959BA72FCA573BA626B3B37`.
- `Review_submission/review_notes.pdf` contains the submitted general review notes for five trait domains. SHA-256: `666BEAA4F2E34C620017EF4738AD08AE74C9F191D9050FCB613F3BE45529175E`.

## Canonical decisions

The pipeline reads two independent review files:

- `trait_review_decisions_raw.csv` applies to raw taxon names before classification.
- `trait_review_decisions_classified.csv` applies to resolved taxon names after classification.

Both files use this exact schema:

| Column | Contract |
|---|---|
| `decision_id` | Stable SHA-256 identifier for one atomic decision row. |
| `candidate_id` | Stable SHA-256 identifier for the review candidate. |
| `taxon_name` | Exact taxon name in the corresponding pipeline stage. |
| `trait_domain_name` | Exact VegVault trait-domain name. |
| `trait_name` | Optional exact trait-name selector; blank selects all trait names. |
| `dataset_id` | Optional exact VegVault dataset selector; blank selects all datasets. |
| `value_lower` | Optional lower trait-value bound. |
| `value_lower_inclusive` | `TRUE` or `FALSE` when `value_lower` is supplied; blank otherwise. |
| `value_upper` | Optional upper trait-value bound. |
| `value_upper_inclusive` | `TRUE` or `FALSE` when `value_upper` is supplied; blank otherwise. |
| `action` | One of `none`, `exclude`, or `scale`. |
| `scale_factor` | Positive finite number for `scale`; blank otherwise. |
| `rationale` | Scientific or data-quality reason for the decision. |
| `evidence_reference` | Report path, source URL, or other auditable evidence. |
| `source_reference` | Provenance such as a review-submission row or generated candidate. |
| `review_status` | One of `proposed`, `approved`, or `rejected`. Agents may only write `proposed`; a human supplies `approved`. |
| `reviewer` | Human reviewer name; required for approved rows. |
| `reviewed_at` | ISO date (`YYYY-MM-DD`); required for approved rows. |

Blank selectors mean every record in the taxon-domain group. Bounds combine with logical AND. Equal lower and upper bounds are allowed only when both are inclusive. Use multiple rows with the same `candidate_id` for disjoint ranges. An approved `action = "none"` row must have blank selectors and cannot coexist with an approved correction for the same candidate.

## Review workflow

1. Run the raw trait extraction and candidate targets.
2. Review `Data/Temp/Trait_corrections/raw/trait_review_candidates.csv` and the raw reports in `Outputs/Reports/Trait_corrections/raw/`.
3. Add proposed decisions to `trait_review_decisions_raw.csv`; only a human changes `review_status` to `approved` and supplies reviewer metadata.
4. Rerun the pipeline. The raw guard remains closed until every candidate has an approved correction or explicit no-action decision.
5. After classification, repeat the process with the classified candidate and decision files.

The mandatory candidate queues combine within-taxon outlier flags with every submitted taxon-domain key. Whole-domain flags remain diagnostic signals for detecting scale or dataset problems, but a domain-only flag does not require an individual decision.

Generated candidate queues and reports are derived artifacts. They must be regenerated when VegVault, trait extraction, taxonomic classification, or approved decisions change.

## Recovery workflow

Run `R/03_Supplementary_analyses/One_time/Trait_corrections/recover_trait_review_submission.R` to regenerate the source audit, conservative proposal draft, and pending visual-review queue under `Data/Temp/Trait_corrections/raw/`. The parser recognizes only exact numeric below/above/at wording, graph-only Plant height variants, and unqualified positive scale factors. It leaves ambiguous, composite, mild/extreme, around-zero, duplicate, and uncertain cases pending.

The current recovery yields 330 unapproved selector drafts and 1,549 pending review rows. This does not cover Leaf mass per area, which is absent from the submission. Use `.ai/agents/trait-correction-reviewer.agent.md` for bounded evidence-gathering batches; agent output remains proposed until a human approves it.
