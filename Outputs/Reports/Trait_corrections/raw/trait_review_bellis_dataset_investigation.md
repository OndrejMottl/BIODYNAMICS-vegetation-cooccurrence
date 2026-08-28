# Bellis perennis leaf-area dataset investigation

## Decision summary

The earlier proposal for 31 `Bellis perennis` dataset-specific rules is superseded. The approved VegVault 1.0.0 source rules convert every Leaf Area record from BE_LOW (`data_source_id = 294`) and AlpinePlants_Austria (`data_source_id = 509`) by 100 across all taxa before taxon-level review. They correct 59 Bellis records; the 10 Pannonian records remain unchanged and need no taxon-specific correction.

The canonical Bellis candidate now has an approved residual `none` decision. This means no additional Bellis-specific action is required after source scaling; it does not mean the affected source values remain unchanged.

## Records in the current raw target

The current raw target contains 69 finite positive `Bellis perennis` leaf-area records from three sources.

| Source | Dataset IDs | Records | Records below 20 | Stored range | Conclusion |
|---|---:|---:|---:|---:|---|
| Trait and biomass data 2014 and 2015 of the BE_LOW project | 29 | 45 | 27 | 0.0527–218.0586 | Source values are consistent with cm²; convert all 45 records by ×100 |
| AlpinePlants_Austria | 2 | 14 | 14 | 0.5785–1.6690 | Source methods explicitly use cm²; convert all 14 records by ×100 |
| Leaf trait records of rare and endangered plant species in the Pannonian flora | 1 | 10 | 0 | 212.33–459.67 | Values are already on a plausible mm² scale; no change proposed |

The original `<20` selector therefore captures 41 records: 27 BE_LOW records and all 14 Alpine records. A correct source-unit conversion would affect 59 records because it must also include the 18 BE_LOW records at or above 20.

## Evidence

The archived VegVault preparation code selected `OrigValueStr` from the TRY export and assigned it directly to `trait_value`. It did not select TRY's standardized numeric value. The same code reciprocated original SLA values for the `Leaf mass per area` domain and then labeled the result `mg/mm2`, regardless of the original SLA unit. See the [archived TRY preparation script](https://github.com/OndrejMottl/VegVault-Trait_data/blob/v1.2.0/R/01_Data_download/01_TRY.R#L157-L240).

VegVault documents leaf area as mm², but this documentation describes the intended harmonized contract rather than proving that every imported original value was converted. See the [VegVault data paper](https://pmc.ncbi.nlm.nih.gov/articles/PMC12680632/).

For `AlpinePlants_Austria`, the source article says that scanned leaf pixels were compared with a 1 cm² reference and that specific leaf weight was calculated using leaf area in cm². The 14 stored Bellis values, 0.5785–1.6690, match a cm² scale; after conversion they become 57.85–166.90 mm². See [Junker and Larue-Kontić (2018), Phenotyping of plants](https://link.springer.com/article/10.1007/s00035-017-0198-6#Sec4).

For BE_LOW, the TRY archive identifies the source workbook and its leaf-area, dry-mass, SLA and leaf-area-ratio fields. The associated study defines leaf area ratio as cm²/g. The stored Bellis values, 0.0527–218.0586, are consistent with unconverted cm² measurements of harvested plants; after conversion they become 5.27–21,805.86 mm². See the [TRY File Archive entry 18](https://www.try-db.org/TryWeb/Data.php#18) and [Herz et al. (2017)](https://pmc.ncbi.nlm.nih.gov/articles/PMC5689490/).

The proposed ×100 conversion is also consistent with botanical dimensions. Kew describes `Bellis perennis` leaves as approximately 20–60(–90) mm long and mostly 10–20 mm wide, so areas around 0.6–1.7 mm² would be physically implausible while 60–170 mm² are plausible for small leaves. This is supporting evidence rather than the basis of the unit conversion. See [Plants of the World Online](https://powo.science.kew.org/taxon/urn:lsid:ipni.org:names:184409-1/general-information).

## Implemented replacement decision

The compatibility layer applies two source-level rules rather than 31 Bellis-only dataset rules: BE_LOW scales 1,324 Leaf Area records and AlpinePlants_Austria scales 2,308 Leaf Area records, both by 100. The rules are guarded by VegVault version, exact source description, and exact match count. A corrected VegVault release must therefore fail this 1.0.0 guard until the compatibility rows are retired.

For Bellis specifically, these rules scale 45 BE_LOW and 14 Alpine records. The approved residual `none` decision documents that the 10 Pannonian records require no additional action. Review-layer reconciliation treats identical historical taxon-scale matches as already satisfied and cannot apply the factor twice.

## Broader finding and next step

This remains an interim compatibility repair for VegVault 1.0.0, not a substitute for corrected source harmonization in VegVault. The new VegVault release should incorporate the two source conversions upstream and reconstruct the original units for TRY-derived Leaf mass per area.

**PROVISIONAL:** All 124,643 TRY-derived Leaf mass per area records remain unchanged in this project because their original units have not been reconstructed. They remain available pending the corrected VegVault release, with that uncertainty carried into interpretation.

## Reproducibility artifacts

The ignored investigation artifacts are under `Data/Temp/Trait_corrections/raw/programmatic_triage/agent_reviews/`: `investigate_bellis_datasets.R`, `bellis_dataset_investigation.csv`, `bellis_dataset_references.csv`, `bellis_sample_references.csv`, `bellis_source_audit.csv`, and the archived processed TRY object `data_trait_try_2024-09-02.qs`.
