# Issue #170 — Functional-type classification reproducibility and provenance

**Date:** 2026-08-12
**Status:** In progress

## Goal

Explain the regenerated functional-type classification differences, make cross-store trait inputs invalidate downstream spatial pipelines when their scientific content changes, and provide deterministic provenance and comparison evidence for an explicit scientific decision on the updated modern classification.

## Established baseline

- The retained May 16 modern artifact contains 563 taxa and eight functional types.
- The retained August 7 Issue #156 store reproduces the May artifact exactly.
- Running the current clustering code on the August 7 inputs also reproduces the May artifact exactly: eight groups, zero assignment differences, and zero silhouette-width differences.
- The August 12 smoke store contains 565 taxa and selects seven functional types. Among the 563 shared taxa, 21 raw assignments change and 9,330 taxon pairs change their co-clustering relationship.
- The corrected trait-record target is identical between the August 7 and August 12 stores. The first changed scientific input is the trait taxonomy table, which expands from 7,985 to 8,004 rows.
- Eleven of the 19 added taxonomy rows were intentionally added to `Data/Input/aux_classification_table.csv` on May 22. Eight additional species were resolved by refreshed automatic taxonomic-classification branches.
- The expanded taxonomy adds `Apera` and `Hydrocharis` to the modern trait matrix and changes aggregated trait values for `Alisma`, `Impatiens`, `Oxalis`, `Poaceae`, and `Veronica`.
- The spatial pipeline continued using its cached May cross-store import until Issue #141 invalidated the importing target. This reveals missing dependency tracking at the external trait-store boundary rather than nondeterministic clustering behavior.
- The retained August 7 paleo store also reproduces the May artifact exactly. The current taxonomy expansion changes the aggregated trait vector only for `Ericales`; the taxon universe, 23-group selection, and assignments remain identical, while the changed distances produce 20 small silhouette differences with maximum absolute delta `0.003114496`.

## Scope

### In scope

- Strict fingerprints for scientific targets imported from external `{targets}` stores.
- Explicit invalidation of functional-type inputs when the shared trait store changes.
- Provenance for taxonomy, trait records, aligned trait matrices, clustering configuration, selected group counts, classification payloads, package versions, and retained stores.
- Partition-aware comparison that distinguishes arbitrary labels from genuine co-clustering changes.
- Deterministic replay tests with identical inputs and controlled taxon ordering.
- Scientific comparison of the May and updated modern classifications.
- A documented decision to retain the May reference or approve a provenance-complete regenerated replacement.

### Out of scope

- Changing the Gower distance, average-linkage clustering, silhouette criterion, downstream viability rule, or functional-type interpretation without separate scientific approval.
- Publishing regenerated classification files before scientific review.
- Rerunning all downstream scientific models; that work belongs to #171 after #140 closes.

## Implementation checkpoints

### 1. Reproducibility evidence and frozen fixtures

- Add an Issue #170 diagnostic runner that reads the May artifacts, the retained August 7 stores, and isolated current stores without rewriting them.
- Record taxon universes, trait-input differences, taxonomy-source differences, selected group counts, raw assignment changes, partition changes, and silhouette changes.
- Freeze compact fixtures containing the relevant target hashes and taxon-level differences rather than copying complete target stores into Git.
- Validate that current code reproduces the May modern artifact exactly from the August 7 inputs.

Validation gate: the evidence runner must be deterministic, read-only for retained stores, and covered by focused tests for label-invariant partition comparison.

### 2. External-store dependency contract

- Add one reusable function that reads and validates exact target fingerprints from a `{targets}` store.
- Fail closed for missing stores, missing targets, duplicate metadata rows, errored targets, or absent data hashes.
- Add an always-checked fingerprint target for `data_traits_classified_corrected` and `data_combined_classification_table_traits` in the continental functional-type segment.
- Make both imported data targets depend on the corresponding fingerprint so upstream scientific changes invalidate the local spatial graph.
- Keep the external store read-only and preserve current target payloads.

Validation gate: focused helper tests, manifest inspection for paleo and modern routes, a fixture proving unchanged fingerprints do not invalidate downstream work, and a fixture proving changed fingerprints do invalidate both imported targets.

### 3. Classification provenance and deterministic replay

- Publish an internal provenance target at the classification boundary containing external target hashes, aligned trait-matrix hash, community-taxon hash, clustering settings, selected group count, taxon ordering, classification hash, and runtime/package evidence.
- Canonically order taxa before distance computation and test permutation-invariant replay from identical scientific inputs.
- Add fail-closed uniqueness and schema checks for taxon names, classification rows, and provenance keys.
- Confirm the paleo and modern test pipelines remain restartable and do not rewrite classifications when scientific inputs are unchanged.

Validation gate: focused function tests, exact replay hashes, both test manifests, and clean isolated paleo and modern classification runs.

### 4. Scientific comparison and decision

- Produce taxon-level and group-level comparisons for the May and updated modern classifications, including the seven-versus-eight-group trade-off, cluster sizes, mean silhouettes, changed taxa, changed trait aggregates, and downstream FT occurrence viability.
- Explain the small paleo silhouette drift using exact input and package/runtime evidence.
- Record whether the expanded taxonomy is scientifically preferable and whether the seven-group result should replace the May reference.
- Only after approval, regenerate and publish the accepted classification artifacts with full provenance and update the retained reference fixtures.

Validation gate: explicit scientific approval, independent read-only review, full focused trait tests, affected pipeline smoke tests, architecture validation, and `git diff --check`.

## Risks and controls

| Risk | Control |
|---|---|
| External taxonomic services change responses over time | Persist exact target hashes and require intentional refresh evidence at the shared trait-store boundary. |
| Cluster labels are mistaken for scientific changes | Compare partitions through co-clustering relationships in addition to raw integer labels. |
| New taxa legitimately alter the dendrogram | Report taxon-universe and trait-input changes separately from deterministic replay. |
| A cross-store fingerprint causes unnecessary model reruns | Fingerprint only exact imported scientific targets, not timestamps or complete store metadata. |
| Regenerated files silently become the new baseline | Keep writers out of the diagnostic path until explicit scientific approval. |

## Completion criteria

- The modern drift has a reproducible, evidence-backed explanation.
- Identical scientific inputs produce identical group selection, assignments, silhouettes, and hashes.
- Changes to either imported trait-store target invalidate the corresponding local spatial targets.
- The accepted modern taxon universe and classification have explicit scientific approval and complete provenance.
- No retained store is rewritten during diagnosis, and no unreviewed classification artifact is published.
