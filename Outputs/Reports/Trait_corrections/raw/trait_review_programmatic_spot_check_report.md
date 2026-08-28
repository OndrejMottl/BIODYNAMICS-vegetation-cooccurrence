# Representative review of programmatic scale proposals


- [Purpose and decision boundary](#purpose-and-decision-boundary)
- [Coverage](#coverage)
- [Review roster](#review-roster)
- [Recorded decisions](#recorded-decisions)
- [Conservative expansion assessment](#conservative-expansion-assessment)
- [Individual cases](#individual-cases)
  - [SC-01: Anchusa barrellieri - Leaf Area](#sc-01-anchusa-barrellieri---leaf-area)
  - [SC-02: Bellis perennis - Leaf Area](#sc-02-bellis-perennis---leaf-area)
  - [SC-03: Crupina vulgaris - Leaf Area](#sc-03-crupina-vulgaris---leaf-area)
  - [SC-04: Achillea millefolium - Leaf Area](#sc-04-achillea-millefolium---leaf-area)
  - [SC-05: Euphrasia minima - Leaf Area](#sc-05-euphrasia-minima---leaf-area)
  - [SC-06: Erysimum capitatum - Leaf Area](#sc-06-erysimum-capitatum---leaf-area)
  - [SC-07: Bupleurum fruticescens - Leaf Area](#sc-07-bupleurum-fruticescens---leaf-area)
  - [SC-08: Solidago canadensis - Leaf Area](#sc-08-solidago-canadensis---leaf-area)
  - [SC-09: Rosa pendulina - Leaf Area](#sc-09-rosa-pendulina---leaf-area)
  - [SC-10: Lonicera periclymenum - Leaf nitrogen content per unit mass](#sc-10-lonicera-periclymenum---leaf-nitrogen-content-per-unit-mass)
  - [SC-11: Vaccinium uliginosum - Leaf nitrogen content per unit mass](#sc-11-vaccinium-uliginosum---leaf-nitrogen-content-per-unit-mass)
  - [SC-12: Pinus sylvestris - Leaf nitrogen content per unit mass](#sc-12-pinus-sylvestris---leaf-nitrogen-content-per-unit-mass)
  - [SC-13: Quercus ilex - Leaf nitrogen content per unit mass](#sc-13-quercus-ilex---leaf-nitrogen-content-per-unit-mass)
  - [SC-14: Ammophila arenaria - Leaf nitrogen content per unit mass](#sc-14-ammophila-arenaria---leaf-nitrogen-content-per-unit-mass)
  - [SC-15: Deschampsia cespitosa - Leaf nitrogen content per unit mass](#sc-15-deschampsia-cespitosa---leaf-nitrogen-content-per-unit-mass)
  - [SC-16: Trifolium campestre - Leaf nitrogen content per unit mass](#sc-16-trifolium-campestre---leaf-nitrogen-content-per-unit-mass)
  - [SC-17: Polygonum douglasii - Leaf nitrogen content per unit mass](#sc-17-polygonum-douglasii---leaf-nitrogen-content-per-unit-mass)
  - [SC-18: Poa sp - Plant heigh](#sc-18-poa-sp---plant-heigh)
  - [SC-19: Prunella vulgaris - Plant heigh](#sc-19-prunella-vulgaris---plant-heigh)
  - [SC-20: Rhododendron ferrugineum - Plant heigh](#sc-20-rhododendron-ferrugineum---plant-heigh)
  - [SC-21: ARCTOSTAPHYLOS UVA-URSI - Plant heigh](#sc-21-arctostaphylos-uva-ursi---plant-heigh)
  - [SC-22: Erica carnea - Plant heigh](#sc-22-erica-carnea---plant-heigh)
  - [SC-23: Bupleurum falcatum - Plant heigh](#sc-23-bupleurum-falcatum---plant-heigh)
  - [SC-24: Betula papyrifera - Plant heigh](#sc-24-betula-papyrifera---plant-heigh)
- [How to use the result](#how-to-use-the-result)

## Purpose and decision boundary

This report presents 24 deliberately varied cases from the 293 unapproved programmatic scale proposals. It contains 22 threshold-based cases and both 2 independently corroborated dataset-specific cases. Together, the displayed rules would scale 3,924 current records if approved.

The sample is a policy check, not a random estimate of an error rate. It covers every factor-and-direction stratum, all three trait domains represented among the proposals, small and large record impacts, contrasting before/after gaps, and stable-hash fill cases. No proposal shown here has been approved, added to the canonical decision file, or applied to production data.

For each case, decide whether the selector isolates a plausible unit mismatch and whether multiplying only those selected records by the proposed factor makes the selected and unselected distributions scientifically coherent. Use `approve`, `reject`, or `needs targeted review` as the reviewer decision.

## Coverage

| Trait domain | Evidence rule | Scale factor | Threshold direction | Cases |
|:---|:---|---:|:---|---:|
| Leaf Area | propose_scale_validated_threshold | 1e-01 | above | 1 |
| Leaf Area | propose_scale_validated_threshold | 1e+01 | below | 3 |
| Leaf Area | propose_scale_validated_threshold | 1e+02 | below | 4 |
| Leaf Area | propose_scale_validated_threshold | 1e+03 | below | 1 |
| Leaf nitrogen content per unit mass | propose_scale_validated_threshold | 1e+01 | below | 8 |
| Plant heigh | propose_scale_corroborated_source | 1e-02 |  | 2 |
| Plant heigh | propose_scale_validated_threshold | 1e-02 | above | 4 |
| Plant heigh | propose_scale_validated_threshold | 1e-01 | above | 1 |

## Review roster

| Case | Taxon | Trait domain | Factor | Records changed | Selection reason | Reviewer decision | Reviewer notes |
|:---|:---|:---|---:|---:|:---|:---|:---|
| SC-01 | Anchusa barrellieri | Leaf Area | 1e-01 | 5 | Representative of a factor and threshold-direction stratum | approve |  |
| SC-02 | Bellis perennis | Leaf Area | 1e+01 | 41 | Representative of a factor and threshold-direction stratum | approve |  |
| SC-03 | Crupina vulgaris | Leaf Area | 1e+01 | 13 | Smallest accepted before-correction gap in the trait domain | needs_targeted_review |  |
| SC-04 | Achillea millefolium | Leaf Area | 1e+01 | 271 | Highest candidate impact score in the trait domain | needs_targeted_review | Investigate whether the factor should be 100 instead of 10. |
| SC-05 | Euphrasia minima | Leaf Area | 1e+02 | 55 | Representative of a factor and threshold-direction stratum | approve |  |
| SC-06 | Erysimum capitatum | Leaf Area | 1e+02 | 16 | Stable-hash fill for trait-domain coverage | approve |  |
| SC-07 | Bupleurum fruticescens | Leaf Area | 1e+02 | 8 | Largest residual median gap after correction | approve |  |
| SC-08 | Solidago canadensis | Leaf Area | 1e+02 | 624 | Largest proposed record impact in the trait domain | approve |  |
| SC-09 | Rosa pendulina | Leaf Area | 1e+03 | 10 | Representative of a factor and threshold-direction stratum | approve |  |
| SC-10 | Lonicera periclymenum | Leaf nitrogen content per unit mass | 1e+01 | 9 | Representative of a factor and threshold-direction stratum | approve |  |
| SC-11 | Vaccinium uliginosum | Leaf nitrogen content per unit mass | 1e+01 | 52 | Stable-hash fill for trait-domain coverage | approve |  |
| SC-12 | Pinus sylvestris | Leaf nitrogen content per unit mass | 1e+01 | 1781 | Largest proposed record impact in the trait domain | approve |  |
| SC-13 | Quercus ilex | Leaf nitrogen content per unit mass | 1e+01 | 836 | Highest candidate impact score in the trait domain | approve |  |
| SC-14 | Ammophila arenaria | Leaf nitrogen content per unit mass | 1e+01 | 3 | Smallest proposed record impact in the trait domain | approve |  |
| SC-15 | Deschampsia cespitosa | Leaf nitrogen content per unit mass | 1e+01 | 18 | Smallest accepted before-correction gap in the trait domain | needs_targeted_review |  |
| SC-16 | Trifolium campestre | Leaf nitrogen content per unit mass | 1e+01 | 3 | Smallest proposed record impact in the trait domain | approve |  |
| SC-17 | Polygonum douglasii | Leaf nitrogen content per unit mass | 1e+01 | 10 | Largest before-correction median gap in the trait domain | approve |  |
| SC-18 | Poa sp | Plant heigh | 1e-02 | 4 | All independently corroborated dataset-specific proposals | needs_targeted_review |  |
| SC-19 | Prunella vulgaris | Plant heigh | 1e-02 | 2 | All independently corroborated dataset-specific proposals | needs_targeted_review | Investigate whether the factor should be 0.1 instead of 0.01. |
| SC-20 | Rhododendron ferrugineum | Plant heigh | 1e-02 | 27 | Representative of a factor and threshold-direction stratum | needs_targeted_review |  |
| SC-21 | ARCTOSTAPHYLOS UVA-URSI | Plant heigh | 1e-02 | 42 | Largest residual median gap after correction | approve | Normalized the evident spelling error in the reviewed report. |
| SC-22 | Erica carnea | Plant heigh | 1e-02 | 4 | Smallest proposed record impact in the trait domain | reject |  |
| SC-23 | Bupleurum falcatum | Plant heigh | 1e-02 | 45 | Largest proposed record impact in the trait domain | approve |  |
| SC-24 | Betula papyrifera | Plant heigh | 1e-01 | 45 | Representative of a factor and threshold-direction stratum | approve |  |

## Recorded decisions

The durable review record contains 17 approvals, 1 rejection, and 6 cases requiring targeted investigation. These outcomes are stored separately from the canonical correction rules and do not themselves apply any correction.

## Conservative expansion assessment

A rule stratum supports conservative expansion only when every representative reviewed from that stratum was approved. Mixed strata, rejected strata, and the dataset-specific proposals are not expanded. Under this rule, the reviewed sample supported expansion to 50 of the 293 proposals, affecting 3,301 records. The project owner subsequently approved this expansion. Exactly 50 candidate-level scale rules are now recorded in the canonical raw decision file, and their application audit confirms 3,301 scaled records.

| Trait domain | Rule kind | Direction | Factor | All proposals | Reviewed | Approved | Rejected | Targeted review | Expansion assessment |
|:---|:---|:---|---:|---:|---:|---:|---:|---:|:---|
| Leaf Area | threshold | above | 1e-01 | 1 | 1 | 1 | 0 | 0 | supports_conservative_expansion |
| Leaf Area | threshold | below | 1e+01 | 6 | 3 | 1 | 0 | 2 | needs_investigation |
| Leaf Area | threshold | below | 1e+02 | 47 | 4 | 4 | 0 | 0 | supports_conservative_expansion |
| Leaf Area | threshold | below | 1e+03 | 1 | 1 | 1 | 0 | 0 | supports_conservative_expansion |
| Leaf nitrogen content per unit mass | threshold | below | 1e+01 | 220 | 8 | 7 | 0 | 1 | needs_investigation |
| Plant heigh | dataset_specific |  | 1e-02 | 2 | 2 | 0 | 0 | 2 | needs_investigation |
| Plant heigh | threshold | above | 1e-02 | 15 | 4 | 2 | 1 | 1 | do_not_expand |
| Plant heigh | threshold | above | 1e-01 | 1 | 1 | 1 | 0 | 0 | supports_conservative_expansion |

## Individual cases

### SC-01: Anchusa barrellieri - Leaf Area

**Why selected:** Representative of a factor and threshold-direction stratum. **Proposed rule:** multiply by 0.1; selector: value \> 10000. **Submitted instruction:** rescale values above 10000 only; archived source row 1567. **Quantitative check:** selected/unselected records = 5/10; median log10 gap before = 1.1364, after = 0.1364. **Reviewer decision:** approve **Reviewer notes:** None recorded. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 10 | 786.6 | 1598.1 | 2688.1 | 786.60 | 1598.10 | 2688.10 |
| TRUE | 5 | 11460.8 | 21877.8 | 28194.2 | 1146.08 | 2187.78 | 2819.42 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 120514 | try_27866 | Leaf area (in case of compound leaves: leaf, undefined if petiole in- or excluded) | TRUE | 5 | 21877.8 | 2187.78 |
| 120514 | try_27866 | Leaf area (in case of compound leaves: leaf, undefined if petiole in- or excluded) | FALSE | 5 | 1640.1 | 1640.10 |
| 120611 | try_27963 | Leaf area (in case of compound leaves: leaf, undefined if petiole in- or excluded) | FALSE | 5 | 1556.1 | 1556.10 |

### SC-02: Bellis perennis - Leaf Area

**Why selected:** Representative of a factor and threshold-direction stratum. **Proposed rule:** multiply by 10; selector: value \< 20. **Submitted instruction:** rescale values below 20 only; archived source row 1477. **Quantitative check:** selected/unselected records = 41/28; median log10 gap before = 1.2571, after = 0.25705. **Reviewer decision:** approve **Reviewer notes:** None recorded. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 28 | 20.3235 | 69.1327 | 459.670 | 20.3235 | 69.1327 | 459.67 |
| TRUE | 41 | 0.0527 | 3.8250 | 18.237 | 0.5270 | 38.2500 | 182.37 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 120882 | try_28234 | Leaf area (in case of compound leaves undefined if leaf or leaflet, undefined if petiole is in- or exluded) | TRUE | 7 | 0.90076 | 9.00762 |
| 120883 | try_28235 | Leaf area (in case of compound leaves undefined if leaf or leaflet, undefined if petiole is in- or exluded) | TRUE | 7 | 1.04100 | 10.40995 |
| 103933 | try_11285 | Leaf area (in case of compound leaves undefined if leaf or leaflet, undefined if petiole is in- or exluded) | TRUE | 2 | 1.93885 | 19.38850 |
| 103938 | try_11290 | Leaf area (in case of compound leaves undefined if leaf or leaflet, undefined if petiole is in- or exluded) | TRUE | 2 | 13.09030 | 130.90300 |
| 103946 | try_11298 | Leaf area (in case of compound leaves undefined if leaf or leaflet, undefined if petiole is in- or exluded) | TRUE | 2 | 8.19470 | 81.94700 |

### SC-03: Crupina vulgaris - Leaf Area

**Why selected:** Smallest accepted before-correction gap in the trait domain. **Proposed rule:** multiply by 10; selector: value \< 200. **Submitted instruction:** rescale values below 200 only; archived source row 1569. **Quantitative check:** selected/unselected records = 13/2; median log10 gap before = 0.8001, after = 0.1999. **Reviewer decision:** needs targeted review **Reviewer notes:** None recorded. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 2 | 286.80 | 412.30 | 537.8 | 286.8 | 412.3 | 537.8 |
| TRUE | 13 | 36.67 | 65.33 | 123.6 | 366.7 | 653.3 | 1236.0 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 120527 | try_27879 | Leaf area (in case of compound leaves: leaf, undefined if petiole in- or excluded) | TRUE | 10 | 60.5 | 605.0 |
| 120633 | try_27985 | Leaf area (in case of compound leaves: leaf, undefined if petiole in- or excluded) | TRUE | 3 | 83.1 | 831.0 |
| 120633 | try_27985 | Leaf area (in case of compound leaves: leaf, undefined if petiole in- or excluded) | FALSE | 2 | 412.3 | 412.3 |

### SC-04: Achillea millefolium - Leaf Area

**Why selected:** Highest candidate impact score in the trait domain. **Proposed rule:** multiply by 10; selector: value \< 5. **Submitted instruction:** rescale values below 5 only; archived source row 1016. **Quantitative check:** selected/unselected records = 271/172; median log10 gap before = 1.016, after = 0.015979. **Reviewer decision:** needs targeted review **Reviewer notes:** Investigate whether the factor should be 100 instead of 10. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 172 | 5.0920 | 15.94605 | 1397.0500 | 5.092 | 15.94605 | 1397.050 |
| TRUE | 271 | 0.0729 | 1.53700 | 4.9853 | 0.729 | 15.37000 | 49.853 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 108711 | try_16063 | Leaf area (in case of compound leaves undefined if leaf or leaflet, undefined if petiole is in- or exluded) | TRUE | 170 | 1.26600 | 12.6600 |
| 103587 | try_10939 | Leaf area (in case of compound leaves: leaf, petiole included) | TRUE | 10 | 2.35050 | 23.5050 |
| 111896 | try_19248 | Leaf area (in case of compound leaves: leaf, petiole excluded) | TRUE | 10 | 2.55255 | 25.5255 |
| 97890 | try_5242 | Leaf area (in case of compound leaves: leaf, petiole excluded) | TRUE | 9 | 1.56380 | 15.6380 |
| 103589 | try_10941 | Leaf area (in case of compound leaves: leaf, petiole included) | TRUE | 8 | 2.20750 | 22.0750 |

### SC-05: Euphrasia minima - Leaf Area

**Why selected:** Representative of a factor and threshold-direction stratum. **Proposed rule:** multiply by 100; selector: value \< 1. **Submitted instruction:** rescale values below 1 only; archived source row 1533. **Quantitative check:** selected/unselected records = 55/42; median log10 gap before = 1.9274, after = 0.072644. **Reviewer decision:** approve **Reviewer notes:** None recorded. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 42 | 1.00655 | 14.32255 | 30.24188 | 1.00655 | 14.32255 | 30.24188 |
| TRUE | 55 | 0.04065 | 0.16930 | 0.66319 | 4.06476 | 16.93029 | 66.31859 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 120885 | try_28237 | Leaf area (in case of compound leaves undefined if leaf or leaflet, undefined if petiole is in- or exluded) | TRUE | 10 | 0.17763 | 17.76288 |
| 120886 | try_28238 | Leaf area (in case of compound leaves undefined if leaf or leaflet, undefined if petiole is in- or exluded) | TRUE | 10 | 0.17515 | 17.51470 |
| 120888 | try_28240 | Leaf area (in case of compound leaves undefined if leaf or leaflet, undefined if petiole is in- or exluded) | TRUE | 10 | 0.16303 | 16.30285 |
| 120883 | try_28235 | Leaf area (in case of compound leaves undefined if leaf or leaflet, undefined if petiole is in- or exluded) | TRUE | 9 | 0.34738 | 34.73750 |
| 120889 | try_28241 | Leaf area (in case of compound leaves undefined if leaf or leaflet, undefined if petiole is in- or exluded) | TRUE | 9 | 0.08928 | 8.92845 |

### SC-06: Erysimum capitatum - Leaf Area

**Why selected:** Stable-hash fill for trait-domain coverage. **Proposed rule:** multiply by 100; selector: value \< 100. **Submitted instruction:** rescale values below 100 only; archived source row 1480. **Quantitative check:** selected/unselected records = 16/5; median log10 gap before = 2.1202, after = 0.12023. **Reviewer decision:** approve **Reviewer notes:** None recorded. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 5 | 109.9000 | 132.50000 | 160.8000 | 109.90 | 132.5000 | 160.80 |
| TRUE | 16 | 0.6299 | 1.00458 | 1.4573 | 62.99 | 100.4575 | 145.73 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 107857 | try_15209 | Leaf area (in case of compound leaves: leaf, petiole excluded) | TRUE | 15 | 0.99685 | 99.685 |
| 103052 | try_10404 | Leaf area (in case of compound leaves undefined if leaf or leaflet, undefined if petiole is in- or exluded) | TRUE | 1 | 1.37080 | 137.080 |
| 113765 | try_21117 | Leaf area (in case of compound leaves undefined if leaf or leaflet, undefined if petiole is in- or exluded) | FALSE | 5 | 132.50000 | 132.500 |

### SC-07: Bupleurum fruticescens - Leaf Area

**Why selected:** Largest residual median gap after correction. **Proposed rule:** multiply by 100; selector: value \< 1. **Submitted instruction:** rescale values below 1 only; archived source row 1703. **Quantitative check:** selected/unselected records = 8/4; median log10 gap before = 1.7242, after = 0.27579. **Reviewer decision:** approve **Reviewer notes:** None recorded. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 4 | 1.59317 | 20.67258 | 142.88000 | 1.59317 | 20.67258 | 142.88000 |
| TRUE | 8 | 0.19550 | 0.39011 | 0.54317 | 19.55000 | 39.01071 | 54.31667 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 98089 | try_5441 | Leaf area (in case of compound leaves undefined if leaf or leaflet, undefined if petiole is in- or exluded) | TRUE | 8 | 0.39011 | 39.01071 |
| 98089 | try_5441 | Leaf area (in case of compound leaves undefined if leaf or leaflet, undefined if petiole is in- or exluded) | FALSE | 2 | 1.76917 | 1.76917 |
| 110677 | try_18029 | Leaf area (in case of compound leaves: leaf, undefined if petiole in- or excluded) | FALSE | 1 | 39.40000 | 39.40000 |
| 114837 | try_22189 | Leaf area (in case of compound leaves: leaf, undefined if petiole in- or excluded) | FALSE | 1 | 142.88000 | 142.88000 |

### SC-08: Solidago canadensis - Leaf Area

**Why selected:** Largest proposed record impact in the trait domain. **Proposed rule:** multiply by 100; selector: value \< 500. **Submitted instruction:** rescale values below 500 only; archived source row 1747. **Quantitative check:** selected/unselected records = 624/6; median log10 gap before = 2.213, after = 0.21296. **Reviewer decision:** approve **Reviewer notes:** None recorded. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 6 | 1254.991 | 1472.869 | 1767.137 | 1254.991 | 1472.869 | 1767.137 |
| TRUE | 624 | 2.940 | 9.020 | 23.860 | 294.000 | 902.000 | 2386.000 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 111620 | try_18972 | Leaf area (in case of compound leaves: leaf, petiole included) | TRUE | 118 | 7.100 | 710.0 |
| 111622 | try_18974 | Leaf area (in case of compound leaves: leaf, petiole included) | TRUE | 81 | 8.180 | 818.0 |
| 111627 | try_18979 | Leaf area (in case of compound leaves: leaf, petiole included) | TRUE | 81 | 8.400 | 840.0 |
| 111624 | try_18976 | Leaf area (in case of compound leaves: leaf, petiole included) | TRUE | 69 | 11.000 | 1100.0 |
| 111619 | try_18971 | Leaf area (in case of compound leaves: leaf, petiole included) | TRUE | 62 | 11.655 | 1165.5 |

### SC-09: Rosa pendulina - Leaf Area

**Why selected:** Representative of a factor and threshold-direction stratum. **Proposed rule:** multiply by 1000; selector: value \< 2000. **Submitted instruction:** rescale values below 2000 only; archived source row 1772. **Quantitative check:** selected/unselected records = 10/5; median log10 gap before = 3.0345, after = 0.034486. **Reviewer decision:** approve **Reviewer notes:** None recorded. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 5 | 2928.20000 | 4709.10000 | 7122.8000 | 2928.20 | 4709.100 | 7122.8 |
| TRUE | 10 | 2.41675 | 4.34962 | 5.8555 | 2416.75 | 4349.625 | 5855.5 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 102756 | try_10108 | Leaf area (in case of compound leaves: leaf, petiole excluded) | TRUE | 10 | 4.34962 | 4349.625 |
| 120635 | try_27987 | Leaf area (in case of compound leaves: leaf, undefined if petiole in- or excluded) | FALSE | 5 | 4709.10000 | 4709.100 |

### SC-10: Lonicera periclymenum - Leaf nitrogen content per unit mass

**Why selected:** Representative of a factor and threshold-direction stratum. **Proposed rule:** multiply by 10; selector: value \< 10. **Submitted instruction:** rescale values below 10 only; archived source row 1381. **Quantitative check:** selected/unselected records = 9/4; median log10 gap before = 0.92771, after = 0.07229. **Reviewer decision:** approve **Reviewer notes:** None recorded. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 4 | 15.270 | 19.13454 | 24.0 | 15.27 | 19.13454 | 24 |
| TRUE | 9 | 1.527 | 2.26000 | 2.4 | 15.27 | 22.60000 | 24 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 101575 | try_8927 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 2 | 2.26000 | 22.60000 |
| 104619 | try_11971 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 2 | 2.26000 | 22.60000 |
| 104620 | try_11972 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 2 | 2.25833 | 22.58333 |
| 102281 | try_9633 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 1 | 2.26000 | 22.60000 |
| 104020 | try_11372 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 1 | 2.25833 | 22.58333 |

### SC-11: Vaccinium uliginosum - Leaf nitrogen content per unit mass

**Why selected:** Stable-hash fill for trait-domain coverage. **Proposed rule:** multiply by 10; selector: value \< 10. **Submitted instruction:** rescale values below 10 only; archived source row 1423. **Quantitative check:** selected/unselected records = 52/31; median log10 gap before = 0.9855, after = 0.014501. **Reviewer decision:** approve **Reviewer notes:** None recorded. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 31 | 16.60 | 20.80000 | 31.01 | 16.6 | 20.80000 | 31.01 |
| TRUE | 52 | 0.17 | 2.15062 | 2.94 | 1.7 | 21.50625 | 29.40 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 100915 | try_8267 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 14 | 2.03000 | 20.30000 |
| 106735 | try_14087 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 14 | 2.03000 | 20.30000 |
| 101574 | try_8926 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 3 | 2.15062 | 21.50625 |
| 104546 | try_11898 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 3 | 2.15062 | 21.50625 |
| 102926 | try_10278 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 2 | 0.94500 | 9.45000 |

### SC-12: Pinus sylvestris - Leaf nitrogen content per unit mass

**Why selected:** Largest proposed record impact in the trait domain. **Proposed rule:** multiply by 10; selector: value \< 2.5. **Submitted instruction:** rescale values below 2.5 only; archived source row 993. **Quantitative check:** selected/unselected records = 1781/60; median log10 gap before = 0.94799, after = 0.052008. **Reviewer decision:** approve **Reviewer notes:** None recorded. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 60 | 2.51396 | 11.5000 | 18.30000 | 2.51396 | 11.500 | 18.3000 |
| TRUE | 1781 | 0.00439 | 1.2963 | 2.49454 | 0.04390 | 12.963 | 24.9454 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 101800 | try_9152 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 72 | 1.4600 | 14.600 |
| 104553 | try_11905 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 62 | 0.8675 | 8.675 |
| 101662 | try_9014 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 47 | 1.0100 | 10.100 |
| 101796 | try_9148 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 36 | 1.4800 | 14.800 |
| 101668 | try_9020 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 34 | 1.2200 | 12.200 |

### SC-13: Quercus ilex - Leaf nitrogen content per unit mass

**Why selected:** Highest candidate impact score in the trait domain. **Proposed rule:** multiply by 10; selector: value \< 5. **Submitted instruction:** rescale values below 5 only; archived source row 940. **Quantitative check:** selected/unselected records = 836/117; median log10 gap before = 1.0029, after = 0.002921. **Reviewer decision:** approve **Reviewer notes:** None recorded. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 117 | 6.8401 | 13.9938 | 25.2000 | 6.8401 | 13.9938 | 25.200 |
| TRUE | 836 | 0.1210 | 1.3900 | 3.7321 | 1.2100 | 13.9000 | 37.321 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 106520 | try_13872 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 6 | 1.34400 | 13.44000 |
| 104619 | try_11971 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 5 | 2.06000 | 20.60000 |
| 101575 | try_8927 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 4 | 2.06000 | 20.60000 |
| 101621 | try_8973 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 3 | 1.10901 | 11.09008 |
| 101766 | try_9118 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 3 | 1.32000 | 13.20000 |

### SC-14: Ammophila arenaria - Leaf nitrogen content per unit mass

**Why selected:** Smallest proposed record impact in the trait domain. **Proposed rule:** multiply by 10; selector: value \< 5. **Submitted instruction:** rescale values below 5 only; archived source row 1160. **Quantitative check:** selected/unselected records = 3/11; median log10 gap before = 1.0725, after = 0.072532. **Reviewer decision:** approve **Reviewer notes:** None recorded. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 11 | 13.03105 | 16.70910 | 18.78022 | 13.03105 | 16.70910 | 18.78022 |
| TRUE | 3 | 1.30310 | 1.41391 | 1.44430 | 13.03105 | 14.13909 | 14.44300 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 104630 | try_11982 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 1 | 1.44430 | 14.44300 |
| 104757 | try_12109 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 1 | 1.30310 | 13.03105 |
| 104759 | try_12111 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 1 | 1.41391 | 14.13909 |
| 92735 | try_87 | Leaf nitrogen (N) content per leaf dry mass | FALSE | 1 | 13.03105 | 13.03105 |
| 92737 | try_89 | Leaf nitrogen (N) content per leaf dry mass | FALSE | 1 | 14.13909 | 14.13909 |

### SC-15: Deschampsia cespitosa - Leaf nitrogen content per unit mass

**Why selected:** Smallest accepted before-correction gap in the trait domain. **Proposed rule:** multiply by 10; selector: value \< 5. **Submitted instruction:** rescale values below 5 only; archived source row 1316. **Quantitative check:** selected/unselected records = 18/11; median log10 gap before = 0.76773, after = 0.23227. **Reviewer decision:** needs targeted review **Reviewer notes:** None recorded. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 11 | 8.88306 | 10.63169 | 19.48775 | 8.88306 | 10.63169 | 19.48775 |
| TRUE | 18 | 0.13000 | 1.81500 | 2.27200 | 1.30000 | 18.15000 | 22.72000 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 104628 | try_11980 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 4 | 1.68500 | 16.85000 |
| 101574 | try_8926 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 2 | 1.86418 | 18.64183 |
| 104546 | try_11898 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 2 | 1.86418 | 18.64183 |
| 102235 | try_9587 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 1 | 1.86418 | 18.64183 |
| 102273 | try_9625 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 1 | 1.34180 | 13.41798 |

### SC-16: Trifolium campestre - Leaf nitrogen content per unit mass

**Why selected:** Smallest proposed record impact in the trait domain. **Proposed rule:** multiply by 10; selector: value \< 10. **Submitted instruction:** rescale values below 10 only; archived source row 1180. **Quantitative check:** selected/unselected records = 3/12; median log10 gap before = 1.0363, after = 0.036267. **Reviewer decision:** approve **Reviewer notes:** None recorded. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 12 | 37.63352 | 41.47048 | 44.76991 | 37.63352 | 41.47048 | 44.76991 |
| TRUE | 3 | 3.68950 | 3.81480 | 4.14700 | 36.89500 | 38.14800 | 41.47000 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 104629 | try_11981 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 3 | 3.81480 | 38.14800 |
| 107882 | try_15234 | Leaf nitrogen (N) content per leaf dry mass | FALSE | 12 | 41.47048 | 41.47048 |

### SC-17: Polygonum douglasii - Leaf nitrogen content per unit mass

**Why selected:** Largest before-correction median gap in the trait domain. **Proposed rule:** multiply by 10; selector: value \< 5. **Submitted instruction:** rescale values below 5 only; archived source row 1146. **Quantitative check:** selected/unselected records = 10/3; median log10 gap before = 1.2247, after = 0.22466. **Reviewer decision:** approve **Reviewer notes:** None recorded. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 3 | 30.845 | 33.634 | 37.259 | 30.845 | 33.634 | 37.259 |
| TRUE | 10 | 1.558 | 2.005 | 2.463 | 15.580 | 20.050 | 24.630 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 97892 | try_5244 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 5 | 2.005 | 20.050 |
| 107352 | try_14704 | Leaf nitrogen (N) content per leaf dry mass | TRUE | 5 | 2.005 | 20.050 |
| 126349 | bien_traits_1359 | leaf nitrogen content per leaf dry mass | FALSE | 3 | 33.634 | 33.634 |

### SC-18: Poa sp - Plant heigh

**Why selected:** All independently corroborated dataset-specific proposals. **Proposed rule:** multiply by 0.01; selector: trait name = Plant height vegetative; dataset ID = 114910. **Submitted instruction:** x; archived source row 18. **Quantitative check:** low/high source records = 5/4; the submitted factor matches the current source-median ratio within 5%. **Reviewer decision:** needs targeted review **Reviewer notes:** None recorded. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 28 | 0.19 | 15.00 | 21.0 | 0.190 | 15.0000 | 21.000 |
| TRUE | 4 | 23.70 | 31.65 | 38.5 | 0.237 | 0.3165 | 0.385 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 114910 | try_22262 | Plant height vegetative | TRUE | 4 | 31.65 | 0.3165 |
| 103272 | try_10624 | Plant height vegetative | FALSE | 20 | 15.00 | 15.0000 |
| 113765 | try_21117 | Plant height vegetative | FALSE | 5 | 0.32 | 0.3200 |
| 114911 | try_22263 | Plant height vegetative | FALSE | 3 | 17.00 | 17.0000 |

### SC-19: Prunella vulgaris - Plant heigh

**Why selected:** All independently corroborated dataset-specific proposals. **Proposed rule:** multiply by 0.01; selector: trait name = Plant height vegetative; dataset ID = 111626. **Submitted instruction:** x; archived source row 73. **Quantitative check:** low/high source records = 2/2; the submitted factor matches the current source-median ratio within 5%. **Reviewer decision:** needs targeted review **Reviewer notes:** Investigate whether the factor should be 0.1 instead of 0.01. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 145 | 0.4 | 4.3 | 27.94 | 0.40 | 4.300 | 27.94 |
| TRUE | 2 | 34.0 | 41.5 | 49.00 | 0.34 | 0.415 | 0.49 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 111626 | try_18978 | Plant height vegetative | TRUE | 2 | 41.50 | 0.415 |
| 107882 | try_15234 | Plant height vegetative | FALSE | 116 | 4.00 | 4.000 |
| 112691 | try_20043 | Plant height vegetative | FALSE | 5 | 24.13 | 24.130 |
| 112680 | try_20032 | Plant height vegetative | FALSE | 3 | 21.59 | 21.590 |
| 114923 | try_22275 | Plant height vegetative | FALSE | 3 | 6.50 | 6.500 |

### SC-20: Rhododendron ferrugineum - Plant heigh

**Why selected:** Representative of a factor and threshold-direction stratum. **Proposed rule:** multiply by 0.01; selector: value \> 5. **Submitted instruction:** rescale values above 5 only; archived source row 867. **Quantitative check:** selected/unselected records = 27/41; median log10 gap before = 1.7812, after = 0.21884. **Reviewer decision:** needs targeted review **Reviewer notes:** None recorded. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 41 | 0.37 | 0.48 | 1 | 0.37 | 0.48 | 1.00 |
| TRUE | 27 | 16.00 | 29.00 | 67 | 0.16 | 0.29 | 0.67 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 113539 | try_20891 | Plant height vegetative | TRUE | 25 | 28.00000 | 0.28000 |
| 112385 | try_19737 | Plant height vegetative | TRUE | 1 | 40.00000 | 0.40000 |
| 115478 | try_22830 | Plant height vegetative | TRUE | 1 | 51.15769 | 0.51158 |
| 99656 | try_7008 | Plant height vegetative | FALSE | 20 | 0.45500 | 0.45500 |
| 99657 | try_7009 | Plant height vegetative | FALSE | 20 | 0.53000 | 0.53000 |

### SC-21: ARCTOSTAPHYLOS UVA-URSI - Plant heigh

**Why selected:** Largest residual median gap after correction. **Proposed rule:** multiply by 0.01; selector: value \> 1. **Submitted instruction:** rescale values above 1 only; archived source row 817. **Quantitative check:** selected/unselected records = 42/50; median log10 gap before = 1.7261, after = 0.27388. **Reviewer decision:** approve **Reviewer notes:** Normalized the evident spelling error in the reviewed report. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 50 | 0.046 | 0.155 | 0.26 | 0.046 | 0.1550 | 0.26 |
| TRUE | 42 | 2.500 | 8.250 | 40.00 | 0.025 | 0.0825 | 0.40 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 103274 | try_10626 | Plant height vegetative | TRUE | 20 | 8.0000 | 0.08000 |
| 98088 | try_5440 | Plant height vegetative | TRUE | 10 | 23.5000 | 0.23500 |
| 114939 | try_22291 | Plant height vegetative | TRUE | 6 | 5.3000 | 0.05300 |
| 112657 | try_20009 | Plant height vegetative | TRUE | 4 | 18.0000 | 0.18000 |
| 103052 | try_10404 | Plant height vegetative | TRUE | 1 | 7.3375 | 0.07338 |

### SC-22: Erica carnea - Plant heigh

**Why selected:** Smallest proposed record impact in the trait domain. **Proposed rule:** multiply by 0.01; selector: value \> 10. **Submitted instruction:** rescale values above 10 only; archived source row 871. **Quantitative check:** selected/unselected records = 4/11; median log10 gap before = 2.1614, after = 0.16137. **Reviewer decision:** reject **Reviewer notes:** None recorded. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 11 | 0.06 | 0.1 | 10 | 0.06 | 0.100 | 10.0 |
| TRUE | 4 | 12.00 | 14.5 | 20 | 0.12 | 0.145 | 0.2 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 115881 | try_23233 | Plant height vegetative | TRUE | 3 | 12.0 | 0.12 |
| 112278 | try_19630 | Plant height vegetative | TRUE | 1 | 20.0 | 0.20 |
| 113843 | try_21195 | Plant height vegetative | FALSE | 10 | 0.1 | 0.10 |
| 115881 | try_23233 | Plant height vegetative | FALSE | 1 | 10.0 | 10.00 |

### SC-23: Bupleurum falcatum - Plant heigh

**Why selected:** Largest proposed record impact in the trait domain. **Proposed rule:** multiply by 0.01; selector: value \> 5. **Submitted instruction:** rescale values above 5 only; archived source row 600. **Quantitative check:** selected/unselected records = 45/46; median log10 gap before = 2.1091, after = 0.10914. **Reviewer decision:** approve **Reviewer notes:** None recorded. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 46 | 0.28 | 0.42 | 0.87 | 0.28 | 0.42 | 0.87 |
| TRUE | 45 | 22.00 | 54.00 | 97.00 | 0.22 | 0.54 | 0.97 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 113562 | try_20914 | Plant height vegetative | TRUE | 24 | 51.00 | 0.510 |
| 113594 | try_20946 | Plant height vegetative | TRUE | 20 | 57.50 | 0.575 |
| 112286 | try_19638 | Plant height vegetative | TRUE | 1 | 40.00 | 0.400 |
| 112703 | try_20055 | Plant height vegetative | FALSE | 26 | 0.37 | 0.370 |
| 102519 | try_9871 | Plant height vegetative | FALSE | 10 | 0.73 | 0.730 |

### SC-24: Betula papyrifera - Plant heigh

**Why selected:** Representative of a factor and threshold-direction stratum. **Proposed rule:** multiply by 0.1; selector: value \> 50. **Submitted instruction:** rescale values above 50 only; archived source row 887. **Quantitative check:** selected/unselected records = 45/46155; median log10 gap before = 0.9875, after = 0.012498. **Reviewer decision:** approve **Reviewer notes:** None recorded. Distribution summary by selector status:

| Scaled | Records | Before minimum | Before median | Before maximum | After minimum | After median | After maximum |
|:---|---:|---:|---:|---:|---:|---:|---:|
| FALSE | 46155 | 0.004 | 15.8496 | 32.004 | 0.004 | 15.8496 | 32.004 |
| TRUE | 45 | 51.000 | 154.0000 | 295.000 | 5.100 | 15.4000 | 29.500 |

Five largest or selected source groups:

| Dataset ID | Dataset | Trait name | Scaled | Records | Median | Median after |
|---:|:---|:---|:---|---:|---:|---:|
| 112083 | try_19435 | Plant height vegetative | TRUE | 20 | 139.0000 | 13.9000 |
| 112079 | try_19431 | Plant height vegetative | TRUE | 19 | 158.0000 | 15.8000 |
| 112082 | try_19434 | Plant height vegetative | TRUE | 6 | 157.0000 | 15.7000 |
| 137936 | bien_traits_12946 | whole plant height | FALSE | 118 | 10.0584 | 10.0584 |
| 157023 | bien_traits_32033 | whole plant height | FALSE | 118 | 10.0584 | 10.0584 |

## How to use the result

The conservative 50-rule expansion is complete. There are 10 individually approved representatives inside mixed strata that were not part of the batch authorization and therefore remain outside the canonical correction file. The next decision is whether to promote those cases individually before investigating the six targeted-review cases.
