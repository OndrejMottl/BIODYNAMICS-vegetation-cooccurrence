# Stage V VegVault 2.0.0 migration: evidence (November 2026)

Evidence produced while moving the project from VegVault 1.0.0 to VegVault 2.0.0, following `Documentation/Implementation_plans/2026-11-25_vegvault_2_migration_plan.md` (part of [#180]). Every query opened the database files read-only. No production store was rebuilt. The 1.0.0 file is kept as `Data/Input/VegVault_1.0.0.sqlite` for the comparisons.

## Files

| File | Content | Made by |
| --- | --- | --- |
| `trait_extraction_timing.csv` | Trait extraction time and record count per continental window, for VegVault 1.0.0 with vaultkeepr 0.1.0 and for 2.0.0 with vaultkeepr 0.2.0. The two releases time different steps; see `step_timed`. | 2.0.0: `Data/Temp/vegvault_2_migration/time_trait_extraction.R` (disposable helper). 1.0.0: metadata of the archived trait store `Data/targets/_archive/2026-11_vegvault_1_0_0_traits_reference/`. Combined by `Data/Temp/vegvault_2_migration/combine_trait_timing.R` (disposable helper). |
| `trait_source_rule_retirement.csv` | For each of the ten VegVault 1.0.0 source-scale rules: its 2.0.0 source id, the taxa shared between the releases, the 2.0.0/1.0.0 ratio of per-taxon medians for the rule's source and for the reference sources of its domain, the scale exponent and the retirement status. | `R/03_Supplementary_analyses/One_time/Trait_corrections/run_trait_source_rule_retirement_check.R`, with `classify_trait_source_rule_retirement()`. |
| `trait_v1_review_decision_evidence.csv` | The 57 `scale` and 20 `exclude` review decisions of VegVault 1.0.0 (raw stage; the classified stage had only `none`), with the records of their taxon and domain and the records their value bounds select in each release. For information; no v1 decision is carried over. | Same runner. |
| `trait_domain_unit_evidence.csv` | For each trait domain of the whole 2.0.0 file: the domain unit in `TraitsDomain`, the standardised unit of the unit-conversion rules and the output unit of the derivation rule its values carry, the number of values and the number of distinct conversion rules. | `Data/Temp/vegvault_2_migration/build_trait_domain_units.R` (disposable helper), which also wrote the proposed `Data/Input/Trait_corrections/VegVault_2_0_0/trait_domain_units.csv`. |

## Release record (step V1)

- Every pipeline now reads the VegVault release from the database file on each build (target `config_vegvault_release`: version, build commit and build manifest hash). Replacing the file therefore marks the extraction targets as outdated, and the store validator reports the change.
- The accepted 2.0.0 file reports version 2.0.0, commit `f19d588` and manifest hash `94516fdf…`. Its SHA-256 (`559577c7…`) matched the release check of 25 November 2026.
- The CZ trial run (`R/03_Supplementary_analyses/Testing/Smoke/run_cz_pipelines.R`) completed on 2.0.0. The CZ fossil-pollen window holds 56 datasets in 2.0.0 against 47 in 1.0.0, and 1,343 fossil samples with age uncertainty against 972. The CZ modern window holds 2,318 plot datasets against 2,320. The 1.0.0 trial stores are kept in `Data/Temp/vegvault_2_migration/cz_stores_vegvault_1_0_0/`.

## Extraction on vaultkeepr 0.2.0 (step V2)

- **Empty windows.** vaultkeepr 0.2.0 builds an empty query instead of stopping when a window holds no data. The project's own record check still raises the typed `biodynamics_vegvault_no_records` condition for every case tried: open ocean, a window with datasets but no samples in the age range, and a window without vegetation plots. The Eastern Siberia window (unit `as_r006`) that the tests used as an empty fossil-pollen window holds two fossil-pollen datasets (77 samples) in 2.0.0, so the test now uses a central Sahara window.
- **Age uncertainty.** `extract_age_uncertainty_from_vegvault()` returns the same columns (`dataset_name`, `sample_name`, `iteration`, `age_uncertainty`) and 1,000 iterations per sample. Fossil sample names now carry the Neotoma dataset id (`fossilpol_<Neotoma dataset id>_<level>`).
- **dbplyr version.** vaultkeepr 0.2.0 needs dbplyr 2.6.0 or newer: with dbplyr 2.5.0, its filters on selected ids produce invalid SQL and `get_age_uncertainty()` stops. The project now pins dbplyr 2.6.0; reported as [vaultkeepr#79].
- **Trait extraction time.** Raw extraction on 2.0.0 took 203 s for America (8.7 million records), 76 s for Europe and 72 s for Asia, so one run per continent is affordable without a change to vaultkeepr. About 70 s of each run is the full join of the trait table that `get_traits()` builds when taxon names stay original ([vaultkeepr#77]). The 1.0.0 times (591 s for America, 5 s for Europe, 3 s for Asia) time the whole continental loader, including the completeness filter and taxon names, so they are not directly comparable. The America window holds almost the same number of records in both releases (8,713,468 in 1.0.0, 8,711,891 in 2.0.0).
- **Trait data sources.** The America extraction stopped after 211 s on the project's check that every trait record has one data source. In 2.0.0, 3,609 BIEN trait datasets (7,869 plant height values, 3,604 of the datasets in the America window) have no data source, because their BIEN records name no provider. VegVault 1.0.0 linked the same records to a data source with an empty description (id 616): every one of these datasets with coordinates lies at the coordinates of a 1.0.0 dataset of that source, and of no other. 2.0.0 leaves the link empty, and the accepted file stays as it is ([VegVault#167]; the issue first read this as lost links, which the reply there corrects). `load_trait_records_from_vegvault()` therefore now keeps trait records without a data source, with `data_source_id` `NA`, and still stops when a record's dataset is missing from `Datasets` or appears twice. With this change the America window loads completely: 8,711,891 records, of which 6,653 (in 3,604 datasets, all plant height) have no data source.
- **Trait call.** `load_trait_records_from_vegvault()` now asks vaultkeepr for original taxon names explicitly (`classify_to = "original"`). vaultkeepr 0.2.0 reads the previous `NULL` the same way, so the records do not change.
- **Outdated supplementary scripts, left as they are.** `R/03_Supplementary_analyses/Prediction/Predict_from_model.R` uses the 1.0.0 ids for the gridpoint source type and two climate variables and opens the database writable. `R/03_Supplementary_analyses/Age_uncertainty_exploration_2026-05-04.R` calls `build_vegvault_plan()` without the release record that the function has required since step V1. Neither is part of the rebuild.

## Trait units (step V3c)

- **One unit per domain.** `TraitsDomain` of the accepted 2.0.0 file lists six trait domains, each with one unit: diaspore mass in mg, leaf area in mm2, leaf mass per area in mg/mm2, leaf nitrogen content per unit mass in mg/g, plant height in m, and stem specific density in g/cm3.
- **Unit rules on every value.** All 10,920,952 trait values of the file carry a unit-conversion rule. In five domains, the standardised unit of every rule is the domain unit. All 276,786 leaf mass per area values are first standardised as specific leaf area (mm2 mg-1, 21 conversion rules) and then carry the derivation rule `sla_to_lma`, whose output unit is mg/mm2.
- **Unit table.** `Data/Input/Trait_corrections/VegVault_2_0_0/trait_domain_units.csv` records these six units, copied from `TraitsDomain` with a read-only query. Its build reference is the manifest hash of the release record. Its status is `source_standardised` for five domains and `source_derived` for leaf mass per area. Ondřej approved the six rows on 26 November 2026.
- **Unit column lost in extraction.** The first 2.0.0 trait store (`Data/Temp/vegvault_2_migration/traits_reference_v2/`) stopped at `validate_trait_domain_units()`: its 8,945,850 records carry `conversion_rule_key` and `derivation_rule_key` but no `trait_unit`. In vaultkeepr 0.2.0, `get_traits()` adds `trait_unit`, and `select_traits_by_domain_name()` then joins the whole `TraitsDomain` table, which also holds `trait_unit`; the query returns `trait_unit.x` and `trait_unit.y`, and the project keeps neither. Reported as [vaultkeepr#80], to be fixed before 0.2.0 is tagged.

## Retirement of the v1 trait corrections (step V3e)

- **Source rules.** All ten VegVault 1.0.0 source-scale rules are `fixed_at_source`: VegVault 2.0.0 applies each rule's factor itself, with scale exponents between 0.99 and 1.00 over 13 to 995 shared taxa per source. The four leaf area sources reported in cm2 are converted to mm2 (source ratio 100, reference ratio 1.03). The five plant height sources were the only ones in m while the rest of 1.0.0 was in cm; 2.0.0 is in m throughout (source ratio 1, reference ratio 0.01). Stem specific density of BAAD is divided by 1,000 at the source. No 2.0.0 source-scale rule is needed.
- **Review decisions.** 29 of the 57 v1 `scale` decisions would still select 279 records in 2.0.0, and scale them a second time; dropping them was right. All 20 v1 `exclude` decisions still find their 15,865 non-positive values in 2.0.0; the automated sorting proposes such exclusions again from the 2.0.0 data.

## Raw review queue (step V3f)

- **Candidates.** The raw review queue of 2.0.0 holds 5,223 candidates, against the 3,500 to 4,300 that the plan estimated. Leaf mass per area contributes 1,646, of which 1,135 were in the part of the v1 review that was never finished.
- **Automated sorting.** `run_trait_review_vegvault_2_0_0_triage.R` gives 5,172 candidates (99%) an automated proposal: 5,125 `none` and 23 `exclude` from the policy, 23 `none` and 1 `exclude` from the interim closure. All are proposals; none is approved.
- **Human queue.** 51 candidates remain. In each, one source differs from the others of the same taxon by a factor that looks like a unit error. For one, the review submission's scale factor is corroborated by a source pair and is offered as a suggestion; the other 50 have no proposal.

<!-- Issue and pull-request links -->

[#180]: https://github.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/issues/180
[vaultkeepr#77]: https://github.com/OndrejMottl/vaultkeepr/issues/77
[vaultkeepr#79]: https://github.com/OndrejMottl/vaultkeepr/issues/79
[vaultkeepr#80]: https://github.com/OndrejMottl/vaultkeepr/issues/80
[VegVault#167]: https://github.com/OndrejMottl/VegVault/issues/167
