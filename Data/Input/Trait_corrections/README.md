# Trait correction inputs

## Purpose

This directory separates immutable source material from the reviewed decisions that the trait pipeline reads. Never clean, normalise, or overwrite files under `Review_submission/`; all parsing repairs belong in generated review candidates or approved decision files.

## Folder layout

- `Review_submission/`: the submitted review of VegVault 1.0.0 trait values, kept as submitted.
- `VegVault_2_0_0/`: the reviewed files of the current release, VegVault 2.0.0. The pipeline reads these.
- `VegVault_1_0_0/`: the reviewed files of VegVault 1.0.0, kept as provenance (last section). No pipeline reads them for 2.0.0.

The pipeline chooses the folder from the release record of `Data/Input/VegVault.sqlite`: `resolve_trait_correction_directory()` turns version 2.0.0 into `VegVault_2_0_0/` and stops with an error when the release has no folder. Review candidates are identified only by stage, taxon and trait domain, so decisions reviewed for one release would also match the candidates of the next. One folder per release keeps them from being applied to another release by accident.

## Review submission

- `Review_submission/trait_manual_corrections.csv` is the original 1,879-row review CSV. It has no header and contains trailing empty columns; this is preserved as submitted. SHA-256: `89DEF6E308D57BB4DC0C0A308BD02B7C001791C76959BA72FCA573BA626B3B37`.
- `Review_submission/review_notes.pdf` contains the submitted general review notes for five trait domains. SHA-256: `666BEAA4F2E34C620017EF4738AD08AE74C9F191D9050FCB613F3BE45529175E`.

## Files of a release folder

| File | Content |
| --- | --- |
| `trait_domain_units.csv` | One row per trait domain: the unit of all its values, the evidence status, inclusion in the primary analysis, and the review fields. |
| `trait_source_scale_rules.csv` | Whole-source scaling factors, applied before the taxon review. |
| `trait_review_decisions_raw.csv`, `trait_review_decisions_classified.csv` | The approved taxon review decisions of each stage. Only the approval runner writes them. |
| `trait_review_manual_resolutions_raw.csv`, `trait_review_manual_resolutions_classified.csv` | The reviewer's resolutions of the cases that the automated sorting leaves open, in the columns of the decision files. |

### Trait units

VegVault 2.0.0 stores every trait value in one unit per trait domain, and each value carries the rule that converted it. Leaf mass per area is derived from specific leaf area by the rule `sla_to_lma`. `trait_domain_units.csv` records the six units, copied from the `TraitsDomain` table of the release: diaspore mass in mg, leaf area in mm2, leaf mass per area in mg/mm2, leaf nitrogen content per unit mass in mg/g, plant height in m, and stem specific density in g/cm3. The evidence status is `source_standardised` for five domains and `source_derived` for leaf mass per area, and all six domains are in the primary analysis. Ondřej approved the table on 26 November 2026; the evidence is in `Documentation/Reports/Model_evaluation/vegvault_2_migration_2026-11/`.

The pipeline checks that the table belongs to the release in the release record, and that every trait record carries the unit of its domain (`validate_trait_domain_units()`). It stops with an error otherwise.

### Source-scale rules

A rule scales every value of one data source in one trait domain, optionally of one exact `trait_name`, by a positive finite factor; taxon selectors and value thresholds are not allowed. Each row records a stable SHA-256 rule id, the VegVault version, the data source id and its expected description, the factor, the expected number of matched records, the rationale, the evidence and the review fields. The pipeline stops with an error when an approved rule names another VegVault version or another source description, when its match count changes, when a selector matches nothing, or when approved rules overlap.

For VegVault 2.0.0 the file holds only its header. The retirement check found that VegVault 2.0.0 applies the factor of every one of the ten 1.0.0 rules at the source (`trait_source_rule_retirement.csv` in the evidence folder). An empty rule file passes the check, and the source-scale report then records that no rule applies.

### Taxon review decisions

The pipeline reads two independent review files:

- `trait_review_decisions_raw.csv` applies to raw taxon names before classification.
- `trait_review_decisions_classified.csv` applies to resolved taxon names after classification.

Both files, and the two resolution files, use this exact schema:

| Column | Meaning |
| --- | --- |
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

## Reviewing a VegVault release

The trait pipeline has two review stages: raw (original taxon names) and classified (after taxonomic classification). Each stage stops at a check until every review candidate of the stage has an approved decision. For VegVault 2.0.0 the review runs as follows; the runners are in `R/03_Supplementary_analyses/One_time/Trait_corrections/`.

1. Build the trait pipeline. It stops at the raw decision check while `trait_review_decisions_raw.csv` holds no decisions.
2. Run `run_trait_source_rule_retirement_check.R`. For each source rule of the previous release, it finds the source in the new release by its description and classifies the rule as `fixed_at_source`, `still_unscaled`, `absent_from_release` or `unresolved`. It stops on `still_unscaled` or `unresolved`: such a rule must be corrected in VegVault, or replaced by a rule of the new release.
3. Run `recover_trait_review_submission.R`, then `run_trait_review_vegvault_2_0_0_triage.R raw`. The automated sorting gives every candidate one proposal: the policy (`none`, or `exclude` of values at or below zero), else the interim closure (`none` for insufficient evidence, `exclude` of non-positive values), else the reviewer's queue. Scale factors taken from the 1.0.0 submission reach the queue only as suggestions. The runner writes the proposals, the queue and a resolution template to `Data/Temp/Trait_corrections/raw/vegvault_2_0_0_triage/`, and a report with the SHA-256 of the proposal file to `Outputs/Reports/Trait_corrections/raw/`. Nothing is approved.
4. The reviewer resolves every queue case in `trait_review_manual_resolutions_raw.csv`: one or more rows in the decision columns, with `review_status` `approved` and a rationale. `decision_id`, the reviewer, the date and the references may stay empty; the approval runner fills them. A row for a candidate outside the queue replaces its automated proposal. The reviewer then records the approval in section 0 of `run_trait_review_vegvault_2_0_0_approval.R`: the SHA-256 of the proposal file they reviewed, their name and the date. For a second reviewer, `render_trait_review_raw_queue_packet.R` renders a PDF packet with one page per queue case (all datasets of the taxon, the lowest and highest dataset with their source and original unit, and the drafted decision) and a pre-filled response sheet, both in `Outputs/Reports/Trait_corrections/raw/`.
5. Run `run_trait_review_vegvault_2_0_0_approval.R raw`. It stops when the proposal file changed after the review, when the stage already has decisions, or when a queue case has no resolution. Otherwise it merges the automated proposals with the resolutions, checks the result with `validate_trait_review_decisions()`, simulates its application, and only then writes `trait_review_decisions_raw.csv`.
6. Rerun the pipeline. It classifies the taxa and stops at the classified decision check. Repeat steps 3 to 5 with the argument `classified`.
7. Set `release_id` and `release_date` of the trait analysis release in `R/Pipelines/_pipes/pipe_segment_traits_table.R`, and rerun the pipeline to the release.

`recover_trait_review_submission.R` parses the 1.0.0 review submission into a source audit, a conservative proposal draft and a queue of rows left for visual review, under `Data/Temp/Trait_corrections/raw/`. The raw sorting reads its source audit. The parser recognises only exact numeric below/above/at wording, graph-only Plant height variants and unqualified positive scale factors; it leaves ambiguous, composite, mild/extreme, around-zero, duplicate and uncertain cases pending. The submission does not cover leaf mass per area.

### A new VegVault release

1. Add a folder `VegVault_<major>_<minor>_<patch>/` with header-only rule, decision and resolution files, and a unit table built from the `TraitsDomain` table of the release and reviewed by a human.
2. Copy the 2.0.0 sorting and approval runners for the new release; they carry the version in their names and output paths.
3. Run steps 1 to 7 above. Do not copy decisions from the previous folder: the queues of a new release are reviewed afresh, as they were for 2.0.0.

## Trait analysis release

The pipeline freezes the corrected classified records as the target `data_traits_analysis_release`, built by `build_trait_analysis_release()` from the records, the validated unit table and the VegVault version of the release record; `data_trait_analysis_release_status` holds the unit table with the release id and date. The release id must start with `vegvault_` and the version (for example `vegvault_2_0_0_reviewed_<YYYY_MM_DD>`). The release stops with an error when the unit table belongs to another release, when a domain is missing, or when a record's unit differs from the unit of its domain. For 2.0.0 the release id and date stay empty until the classified review is approved, so the release stops until then.

Functional-type sensitivity runs are selected with the run-scoped environment variable `BIODYNAMICS_FT_TRAIT_VARIANT`. Supported values are `all_six` (the default primary analysis), `without_lma`, `without_nitrogen`, `without_lma_nitrogen`, and `without_ssd`. Every saved classification records `trait_variant_id`; non-primary classifications receive the variant ID in their filename so they cannot replace the primary six-trait classification. Use a separate target store for each full-analysis sensitivity run so downstream model outputs remain independently restartable and comparable.

The source-scale audit is `Outputs/Reports/Trait_corrections/raw/trait_source_scale_report.md`, with counts by source, domain, and taxon in `trait_source_scale_taxon_counts.csv`. Record-level provenance retains VegVault identifiers, old value, new value, and factor. When an approved taxon-scale rule describes records already corrected by an identical source factor, the review layer records those matches as source-satisfied and never scales them twice; a different factor fails validation.

## VegVault 1.0.0 review (provenance)

The files in `VegVault_1_0_0/` record the review of VegVault 1.0.0. The pipeline does not read them for 2.0.0. The retirement check shows that VegVault 2.0.0 applies all ten 1.0.0 source rules at the source, and 29 of the 57 1.0.0 `scale` decisions would still select records in 2.0.0 and scale them a second time (`trait_v1_review_decision_evidence.csv` in `Documentation/Reports/Model_evaluation/vegvault_2_migration_2026-11/`). The 1.0.0 runners described below are kept as provenance and are not part of the 2.0.0 review. The approval runners among them check 1.0.0 counts or dates and stop with an error on 2.0.0; the others build on the 1.0.0 review scope and decisions. They still name the 1.0.0 files by their former paths directly under `Trait_corrections/`, before the files moved to `VegVault_1_0_0/`. The 2.0.0 sorting runner reuses their functions. The text below describes the 1.0.0 state.

### VegVault 1.0.0 source-scale compatibility rules

`trait_source_scale_rules.csv` is an interim, version-guarded compatibility contract applied to untouched VegVault records before taxon-level quality control. It permits only positive finite whole-source scaling factors selected by `data_source_id`, trait domain, and optional exact `trait_name`; taxon selectors and value thresholds are forbidden.

Each row records a stable SHA-256 rule ID, exact VegVault version, exact expected source description, factor, expected current match count, rationale, evidence, status, and human-review metadata. Approved rules fail closed when the latest VegVault version changes, a source identity changes, the expected count changes, a selector is unmatched, or approved rules overlap. This intentional failure is the retirement guard: after a corrected VegVault release, the 1.0.0 compatibility rows must be explicitly removed or replaced.

The ten approved VegVault 1.0.0 rules scale 28,856 records. Six factor-100 rules established during raw review cover Leaf Area sources 294 (`BE_LOW`, 1,324 records), 509 (`AlpinePlants_Austria`, 2,308 records), and 243 (`Niwot Alpine Plant Traits`, 111 records), plus Plant height sources 155 (`Tundra Trait Team`, 19,715 records), 187 (`Abisko & Sheffield Database`, 248 records), and 457 (`Alpine tundra plants`, 127 records). Classified-stage investigation added Stem specific density source 154 (`BAAD`, 182 records) at factor 0.001, Plant height source 352 (`Global Seed Mass, Plant Height Database`, 772 records) at factor 100, Leaf Area source 497 (`Global leaf size dataset`, 1,592 records) at factor 100, and Plant height source 564 (`Carmona CP`, 2,477 records) at factor 100. The immutable extraction remains `data_traits_raw`; `data_traits_source_scaled` contains source-compatible values; `data_traits_corrected` remains the final result after raw taxon review.

Both mandatory review gates are complete for the current VegVault 1.0.0 snapshot. The raw gate contains 4,339 approved decisions: 4,262 `none`, 20 `exclude`, and 57 residual `scale` decisions. The classified gate contains 4,223 approved `none` decisions after taxonomic resolution. The earlier ARCTOSTAPHYLOS UVA-URSI factor-0.01 and Betula papyrifera factor-0.1 Plant height threshold rules are preserved through approved supersession records because their interpretations predated the source-155 and source-352 corrections and would now reverse valid source scaling. Any changed input, candidate queue, selector match, or source identity reopens the corresponding fail-closed gate.

**PROVISIONAL:** All 124,643 TRY-derived Leaf mass per area records remain unchanged because their original units have not been reconstructed. They remain available for this project pending the corrected VegVault release, but this uncertainty must be carried into interpretation.

### VegVault 1.0.0 interim analysis release

The trait pipeline exposes the corrected classified records as the frozen target `data_traits_analysis_release` under release ID `vegvault_1_0_0_interim_2026_08_31`. The accompanying six-row target `data_trait_analysis_release_status` records VegVault version, release date, inclusion in the primary analysis, and evidence status. Leaf mass per area and leaf nitrogen content per unit mass are `provisional_units`; stem specific density is `interim_source_uncertainty`; the other three domains are `interim_reviewed`. All six domains remain included in the primary functional-type analysis.

No additional local unit reconstruction is planned for this interim release. A corrected future VegVault version must replace this release contract and retire the version-1.0.0 compatibility rules explicitly.

### VegVault 1.0.0 review workflow

1. Run the raw trait extraction and candidate targets.
2. Review `Data/Temp/Trait_corrections/raw/trait_review_candidates.csv` and the raw reports in `Outputs/Reports/Trait_corrections/raw/`.
3. Add proposed decisions to `trait_review_decisions_raw.csv`; only a human changes `review_status` to `approved` and supplies reviewer metadata.
4. Rerun the pipeline. The raw guard remains closed until every candidate has an approved correction or explicit no-action decision.
5. After classification, repeat the process with the classified candidate and decision files.

The mandatory candidate queues combine within-taxon outlier flags with every submitted taxon-domain key. Whole-domain flags remain diagnostic signals for detecting scale or dataset problems, but a domain-only flag does not require an individual decision.

Generated candidate queues and reports are derived artifacts. They must be regenerated when VegVault, trait extraction, taxonomic classification, or approved decisions change.

### VegVault 1.0.0 recovery report

Run `R/03_Supplementary_analyses/One_time/Trait_corrections/render_trait_review_reconciliation_report.R` after recovery to render the human-readable situation and next-steps report as `Outputs/Reports/Trait_corrections/raw/trait_review_reconciliation_report.html` and `.pdf`. Historical coverage extraction uses the R package `{pdftools}` and fails closed when the archived report counts or candidate identifiers change.

For VegVault 1.0.0, the recovery yielded 330 unapproved selector drafts and 1,549 pending review rows. Use `.ai/agents/trait-correction-reviewer.agent.md` for bounded evidence-gathering batches; agent output remains proposed until a human approves it.

### Automation pilot

Run `R/03_Supplementary_analyses/One_time/Trait_corrections/run_trait_review_automation_pilot.R` to generate a non-mutating pilot for Diaspore mass and Stem specific density under `Data/Temp/Trait_corrections/raw/automation/`. The pilot creates candidate-, dataset-, and record-level evidence, exact recovered-selector diagnostics, conservative deterministic recommendations, batches of at most 25 candidates, and a comparison with the archived review heuristics and statistics.

The pilot never edits canonical decisions and never applies a correction. Only invalid non-positive values in these strictly positive domains and stable historical no-action evidence are marked eligible for policy acceptance; recovered selectors, possible unit patterns, drift, and other uncertain values are routed to agent review. Use `.ai/agents/trait-correction-pilot-reviewer.agent.md` to run two blind reviews and a separate adjudication for one batch. Agent consensus remains a proposal, not human approval.

### All-domain policy workflow

Run `R/03_Supplementary_analyses/One_time/Trait_corrections/run_trait_review_policy_workflow.R` to rebuild the current raw candidate queue directly from `data_traits_raw`, include invalid-value groups missed by IQR screening, and write non-mutating policy outputs under `Data/Temp/Trait_corrections/raw/policy/`.

The workflow proposes `none` only when no objective error evidence or unresolved submitted concern exists. It proposes exact-zero exclusions for strictly positive domains, while negative and non-finite values remain targeted investigations because they may reflect a source-level transformation. Recovered selectors, unresolved submitted notes, possible unit patterns, and historical drift are never approved automatically.

Run `R/03_Supplementary_analyses/One_time/Trait_corrections/render_trait_review_policy_report.R` to regenerate `Outputs/Reports/Trait_corrections/raw/trait_review_policy_report.md`. Review `.ai/agents/trait-correction-policy-reviewer.agent.md` before assigning one bounded `agent_batch_id`. Agent outputs remain proposals and cannot edit either canonical decision file.

### Cost-gated programmatic triage

Run `R/03_Supplementary_analyses/One_time/Trait_corrections/run_trait_review_programmatic_triage.R` after recording approved policy decisions. The workflow removes candidates already covered by canonical approvals and proposes `none` only for completed investigations that support that conclusion. Invalid values, matched recovered selectors, and repeated cross-taxon source-factor patterns enter grouped agent review. Submitted concerns, isolated source-factor hints, recovered proposals, historical drift, and residual unresolved evidence remain explicitly pending programmatic review; failure to find a repeated error pattern is not treated as evidence for `none`. Ordinary `NA` missingness is not an invalid trait value, while `NaN`, infinities, and negative observed values remain exceptions.

Generated CSVs are written under `Data/Temp/Trait_corrections/raw/programmatic_triage/`. The grouped agent queue assigns evidence groups rather than individual candidates and supports one initial reviewer per batch; independent replication and adjudication are reserved for groups that propose an exclusion or scaling rule.

The same runner performs a second deterministic reconciliation of every `pending_programmatic` candidate. It writes candidate-level outcomes, unapproved decision proposals, and a summary with the `trait_review_programmatic_*reconciliation*` and `trait_review_programmatic_decision_proposals.csv` filenames. Threshold-scale proposals require a substantial simulated improvement in current within-candidate agreement. Dataset-specific scale proposals require independent agreement between one archived factor and a current source-median ratio. No proposal is approved or applied by this workflow.

Run `R/03_Supplementary_analyses/One_time/Trait_corrections/render_trait_review_programmatic_triage_report.R` to regenerate `Outputs/Reports/Trait_corrections/raw/trait_review_programmatic_triage_report.md`. The workflow is non-mutating: it does not approve decisions, apply corrections, or launch agents.

The same workflow writes a reproducible 24-case scale-proposal roster and bounded record evidence under `Data/Temp/Trait_corrections/raw/programmatic_triage/`. Render `R/03_Supplementary_analyses/One_time/Trait_corrections/trait_review_programmatic_spot_check_report.qmd` to regenerate `Outputs/Reports/Trait_corrections/raw/trait_review_programmatic_spot_check_report.md`. The report covers every factor-and-direction stratum, all represented trait domains, contrasting record impacts and distribution gaps, and both dataset-specific proposals; it remains a human decision aid and does not approve the 293-rule batch.

Run `R/03_Supplementary_analyses/One_time/Trait_corrections/run_trait_review_spot_check_decision_capture.R` after human review to preserve normalized outcomes in `trait_review_programmatic_spot_check_decisions.csv` and regenerate the temporary stratum assessment. The decision capture preserves the original entered text, records normalization notes, and keeps the reviewed sample separate from canonical correction rules. The report reads this durable CSV on subsequent renders, so reviewed outcomes are not reset to pending.

Run `R/03_Supplementary_analyses/One_time/Trait_corrections/run_trait_review_supported_scale_approval.R` only after explicit project-owner approval of the unanimously supported strata. The runner fails closed against the reviewed 50-rule snapshot, validates the combined canonical decision set against current candidates and records, simulates application, requires exactly 3,301 scaled records with no overlaps, writes the canonical decisions only after those checks pass, and records the per-rule audit at `Outputs/Reports/Trait_corrections/raw/trait_review_supported_scale_approval_audit.csv`.
