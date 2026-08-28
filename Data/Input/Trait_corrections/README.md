# Trait correction inputs

## Purpose

This directory separates immutable source material from the reviewed decisions consumed by the trait pipeline. Never clean, normalize, or overwrite files under `Review_submission/`; all parsing repairs belong in generated review candidates or approved decision files.

## Review submission

- `Review_submission/trait_manual_corrections.csv` is the original 1,879-row review CSV. It has no header and contains trailing empty columns; this is preserved as submitted. SHA-256: `89DEF6E308D57BB4DC0C0A308BD02B7C001791C76959BA72FCA573BA626B3B37`.
- `Review_submission/review_notes.pdf` contains the submitted general review notes for five trait domains. SHA-256: `666BEAA4F2E34C620017EF4738AD08AE74C9F191D9050FCB613F3BE45529175E`.

## Canonical decisions

### VegVault source-scale compatibility rules

`trait_source_scale_rules.csv` is an interim, version-guarded compatibility contract applied to untouched VegVault records before taxon-level quality control. It permits only positive finite whole-source scaling factors selected by `data_source_id`, trait domain, and optional exact `trait_name`; taxon selectors and value thresholds are forbidden.

Each row records a stable SHA-256 rule ID, exact VegVault version, exact expected source description, factor, expected current match count, rationale, evidence, status, and human-review metadata. Approved rules fail closed when the latest VegVault version changes, a source identity changes, the expected count changes, a selector is unmatched, or approved rules overlap. This intentional failure is the retirement guard: after a corrected VegVault release, the 1.0.0 compatibility rows must be explicitly removed or replaced.

The approved VegVault 1.0.0 rules convert Leaf Area from cm2 to mm2 for source 294 (`BE_LOW`, 1,324 records) and source 509 (`AlpinePlants_Austria`, 2,308 records), both with factor 100. The immutable extraction remains `data_traits_raw`; `data_traits_source_scaled` contains source-compatible values; `data_traits_corrected` remains the final result after taxon review.

**PROVISIONAL:** All 124,643 TRY-derived Leaf mass per area records remain unchanged because their original units have not been reconstructed. They remain available for this project pending the corrected VegVault release, but this uncertainty must be carried into interpretation.

The durable audit is `Outputs/Reports/Trait_corrections/raw/trait_source_scale_report.md`, with complete counts by source, domain, and taxon in `trait_source_scale_taxon_counts.csv`. Record-level provenance retains VegVault identifiers, old value, new value, and factor. When an approved taxon-scale rule describes records already corrected by an identical source factor, the review layer records those matches as source-satisfied and never scales them twice; a different factor fails validation.

### Taxon review decisions

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

Run `R/03_Supplementary_analyses/One_time/Trait_corrections/recover_trait_review_submission.R` to regenerate the source audit, historical PDF coverage index, conservative proposal draft, pending visual-review queue, and authoritative candidate reconciliation under `Data/Temp/Trait_corrections/raw/`. Historical coverage extraction uses the R package `{pdftools}` and fails closed when the archived report counts or candidate identifiers change. The submission parser recognizes only exact numeric below/above/at wording, graph-only Plant height variants, and unqualified positive scale factors. It leaves ambiguous, composite, mild/extreme, around-zero, duplicate, and uncertain cases pending.

Run `R/03_Supplementary_analyses/One_time/Trait_corrections/render_trait_review_reconciliation_report.R` after recovery to render the human-readable situation and next-steps report as `Outputs/Reports/Trait_corrections/raw/trait_review_reconciliation_report.html` and `.pdf`.

The current recovery yields 330 unapproved selector drafts and 1,549 pending review rows. This does not cover Leaf mass per area, which is absent from the submission. Use `.ai/agents/trait-correction-reviewer.agent.md` for bounded evidence-gathering batches; agent output remains proposed until a human approves it.

## Automation pilot

Run `R/03_Supplementary_analyses/One_time/Trait_corrections/run_trait_review_automation_pilot.R` to generate a non-mutating pilot for Diaspore mass and Stem specific density under `Data/Temp/Trait_corrections/raw/automation/`. The pilot creates candidate-, dataset-, and record-level evidence, exact recovered-selector diagnostics, conservative deterministic recommendations, batches of at most 25 candidates, and a comparison with the archived review heuristics and statistics.

The pilot never edits canonical decisions and never applies a correction. Only invalid non-positive values in these strictly positive domains and stable historical no-action evidence are marked eligible for policy acceptance; recovered selectors, possible unit patterns, drift, and other uncertain values are routed to agent review. Use `.ai/agents/trait-correction-pilot-reviewer.agent.md` to run two blind reviews and a separate adjudication for one batch. Agent consensus remains a proposal, not human approval.

## All-domain policy workflow

Run `R/03_Supplementary_analyses/One_time/Trait_corrections/run_trait_review_policy_workflow.R` to rebuild the current raw candidate queue directly from `data_traits_raw`, include invalid-value groups missed by IQR screening, and write non-mutating policy outputs under `Data/Temp/Trait_corrections/raw/policy/`.

The workflow proposes `none` only when no objective error evidence or unresolved submitted concern exists. It proposes exact-zero exclusions for strictly positive domains, while negative and non-finite values remain targeted investigations because they may reflect a source-level transformation. Recovered selectors, unresolved submitted notes, possible unit patterns, and historical drift are never approved automatically.

Run `R/03_Supplementary_analyses/One_time/Trait_corrections/render_trait_review_policy_report.R` to regenerate `Outputs/Reports/Trait_corrections/raw/trait_review_policy_report.md`. Review `.ai/agents/trait-correction-policy-reviewer.agent.md` before assigning one bounded `agent_batch_id`. Agent outputs remain proposals and cannot edit either canonical decision file.

## Cost-gated programmatic triage

Run `R/03_Supplementary_analyses/One_time/Trait_corrections/run_trait_review_programmatic_triage.R` after recording approved policy decisions. The workflow removes candidates already covered by canonical approvals and proposes `none` only for completed investigations that support that conclusion. Invalid values, matched recovered selectors, and repeated cross-taxon source-factor patterns enter grouped agent review. Submitted concerns, isolated source-factor hints, recovered proposals, historical drift, and residual unresolved evidence remain explicitly pending programmatic review; failure to find a repeated error pattern is not treated as evidence for `none`. Ordinary `NA` missingness is not an invalid trait value, while `NaN`, infinities, and negative observed values remain exceptions.

Generated CSVs are written under `Data/Temp/Trait_corrections/raw/programmatic_triage/`. The grouped agent queue assigns evidence groups rather than individual candidates and supports one initial reviewer per batch; independent replication and adjudication are reserved for groups that propose an exclusion or scaling rule.

The same runner performs a second deterministic reconciliation of every `pending_programmatic` candidate. It writes candidate-level outcomes, unapproved decision proposals, and a summary with the `trait_review_programmatic_*reconciliation*` and `trait_review_programmatic_decision_proposals.csv` filenames. Threshold-scale proposals require a substantial simulated improvement in current within-candidate agreement. Dataset-specific scale proposals require independent agreement between one archived factor and a current source-median ratio. No proposal is approved or applied by this workflow.

Run `R/03_Supplementary_analyses/One_time/Trait_corrections/render_trait_review_programmatic_triage_report.R` to regenerate `Outputs/Reports/Trait_corrections/raw/trait_review_programmatic_triage_report.md`. The workflow is non-mutating: it does not approve decisions, apply corrections, or launch agents.

The same workflow writes a reproducible 24-case scale-proposal roster and bounded record evidence under `Data/Temp/Trait_corrections/raw/programmatic_triage/`. Render `R/03_Supplementary_analyses/One_time/Trait_corrections/trait_review_programmatic_spot_check_report.qmd` to regenerate `Outputs/Reports/Trait_corrections/raw/trait_review_programmatic_spot_check_report.md`. The report covers every factor-and-direction stratum, all represented trait domains, contrasting record impacts and distribution gaps, and both dataset-specific proposals; it remains a human decision aid and does not approve the 293-rule batch.

Run `R/03_Supplementary_analyses/One_time/Trait_corrections/run_trait_review_spot_check_decision_capture.R` after human review to preserve normalized outcomes in `trait_review_programmatic_spot_check_decisions.csv` and regenerate the temporary stratum assessment. The decision capture preserves the original entered text, records normalization notes, and keeps the reviewed sample separate from canonical correction rules. The report reads this durable CSV on subsequent renders, so reviewed outcomes are not reset to pending.

Run `R/03_Supplementary_analyses/One_time/Trait_corrections/run_trait_review_supported_scale_approval.R` only after explicit project-owner approval of the unanimously supported strata. The runner fails closed against the reviewed 50-rule snapshot, validates the combined canonical decision set against current candidates and records, simulates application, requires exactly 3,301 scaled records with no overlaps, writes the canonical decisions only after those checks pass, and records the per-rule audit at `Outputs/Reports/Trait_corrections/raw/trait_review_supported_scale_approval_audit.csv`.
