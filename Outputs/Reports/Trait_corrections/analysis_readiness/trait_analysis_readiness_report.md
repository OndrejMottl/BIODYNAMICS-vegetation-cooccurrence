---
title: "Trait pipeline analysis-readiness review"
date: "2026-08-31"
format: gfm
---



# Decision summary

**Do not start the complete main-results reanalysis yet.** The correction pipeline, both review gates, the six-domain trait table, and the paleo and modern functional-type smoke pipelines all complete. However, the new analysis-readiness checks show unresolved unit-scale heterogeneity in traits that would directly affect Gower distances and functional-type assignments.

The pipeline is computationally operational but the all-six-trait input is not yet scientifically ready for the definitive reanalysis.

# What was run

- The terminal trait targets and both durable review reports were rebuilt in the existing traits store; cached extraction and classification branches were retained.
- All six traits were included in the paleo and modern functional-type smoke pipelines.
- Diaspore mass, Leaf Area, Leaf mass per area, and Plant heigh were transformed with `log10`; Leaf nitrogen content per unit mass and Stem specific density remained on their identity scales.
- Source/taxon anomalies were diagnosed without changing or approving any additional data.

# Smoke-test results

The paleo smoke matched 58 community taxa to traits and completed functional-type classification. Its readiness check found 9 robust taxon-domain extremes.


|trait_domain_name                   |transformation | n_taxa| n_present| n_missing| missing_fraction| value_minimum_raw| value_median_raw| value_maximum_raw|
|:-----------------------------------|:--------------|------:|---------:|---------:|----------------:|-----------------:|----------------:|-----------------:|
|Diaspore mass                       |log10          |     58|        52|         6|           0.1034|            0.0340|          12.9500|         35714.280|
|Leaf Area                           |log10          |     58|        55|         3|           0.0517|            0.9222|         149.5398|         35910.000|
|Leaf mass per area                  |log10          |     58|        56|         2|           0.0345|            0.0027|           0.0095|             0.277|
|Leaf nitrogen content per unit mass |identity       |     58|        55|         3|           0.0517|            1.1148|           2.1967|            22.827|
|Plant heigh                         |log10          |     58|        58|         0|           0.0000|            0.2550|          13.2588|           150.000|
|Stem specific density               |identity       |     58|        53|         5|           0.0862|            0.0003|           0.5405|             0.830|


|taxon_name |trait_domain_name                   | trait_value_raw| trait_value_prepared|anomaly_direction |
|:----------|:-----------------------------------|---------------:|--------------------:|:-----------------|
|Daphne     |Leaf nitrogen content per unit mass |        14.73108|             14.73108|high              |
|Genista    |Leaf nitrogen content per unit mass |        22.82700|             22.82700|high              |
|Hippophae  |Leaf nitrogen content per unit mass |        20.45565|             20.45565|high              |
|Lonicera   |Leaf nitrogen content per unit mass |        12.03000|             12.03000|high              |
|Rhamnus    |Leaf nitrogen content per unit mass |        16.79800|             16.79800|high              |
|Ulex       |Leaf nitrogen content per unit mass |        20.83187|             20.83187|high              |
|Genista    |Stem specific density               |         0.01089|              0.01089|low               |
|Picea      |Stem specific density               |         0.00033|              0.00033|low               |
|Rhamnus    |Stem specific density               |         0.00854|              0.00854|low               |

The modern smoke matched 565 community taxa to traits and completed functional-type classification. Its readiness check found 4 robust taxon-domain extremes. Stem specific density was present for only 195 of 565 matched taxa, so its missingness is also a material trait-specific limitation.


|trait_domain_name                   |transformation | n_taxa| n_present| n_missing| missing_fraction| value_minimum_raw| value_median_raw| value_maximum_raw|
|:-----------------------------------|:--------------|------:|---------:|---------:|----------------:|-----------------:|----------------:|-----------------:|
|Diaspore mass                       |log10          |    565|       365|       200|           0.3540|            0.0001|           1.0040|         8950.2700|
|Leaf Area                           |log10          |    565|       483|        82|           0.1451|            0.0013|         213.1650|       154882.0000|
|Leaf mass per area                  |log10          |    565|       530|        35|           0.0619|            0.0001|           0.0229|          111.5111|
|Leaf nitrogen content per unit mass |identity       |    565|       421|       144|           0.2549|            0.0235|           2.8000|           56.6530|
|Plant heigh                         |log10          |    565|       517|        48|           0.0850|            0.0500|          20.0000|          300.0000|
|Stem specific density               |identity       |    565|       195|       370|           0.6549|            0.0003|           0.3148|            0.8300|


|taxon_name  |trait_domain_name                   | trait_value_raw| trait_value_prepared|anomaly_direction |
|:-----------|:-----------------------------------|---------------:|--------------------:|:-----------------|
|Cladium     |Leaf mass per area                  |       111.51115|              2.04732|high              |
|Pseudorchis |Leaf mass per area                  |        17.37773|              1.23999|high              |
|Corydalis   |Leaf nitrogen content per unit mass |        56.65300|             56.65300|high              |
|Hedysarum   |Leaf nitrogen content per unit mass |        48.96558|             48.96558|high              |

# Strongest newly exposed source problems

The broad diagnostic produced 5257 prioritization rows. These are not correction candidates and must not be batch-approved. A deliberately strict filter requiring both cross-source corroboration and a global log-scale outlier produced only 4 rows, but that filter can miss genuine errors when the observed ratio is not close enough to an exact power of ten.

Stem specific density has three especially important source patterns:


| data_source_id|source_description                                |investigation_hypothesis                        | n_records| n_taxa| value_minimum| value_median| value_maximum|
|--------------:|:-------------------------------------------------|:-----------------------------------------------|---------:|------:|-------------:|------------:|-------------:|
|            123|Global A, N, P, SLA Database                      |Possible x0.001 correction                      |        18|      4|      3.50e+02|    6.500e+02|    650.000000|
|            137|Plant Traits From Spanish Mediteranean shrublands |Possible x100 correction; verify source subsets |       713|     32|      4.23e-04|    5.796e-03|      2.957645|
|            660|El-Kassaby YA                                     |Strong x1000 correction candidate               |      1120|      1|      2.57e-04|    3.320e-04|      0.000489|

- Source 660 is the clearest immediate issue. Its 1,120 *Picea glauca* records have median 0.000332 while independent observations have median about 0.465. A ×1000 source-trait correction would move the source median to about 0.332. This source causes the paleo *Picea* aggregate of 0.000335.
- Source 123 contains stem-density values of 350–650, including the final *Tsuga heterophylla* value of 450. These are consistent with values recorded in kg/m3 rather than g/cm3 and therefore with a ×0.001 conversion, but the source must be checked before approval.
- Source 137 contains many stem-density values around 0.005–0.008 where independent sources are around 0.5–0.7. A ×100 hypothesis is strong for part of the source, but its full 0.000423–2.96 range means source subsets or trait-name variants must be checked before using a whole-source rule.

# Other scientific limitations

Leaf mass per area remains provisional. Its final taxon medians span approximately 0.0000169 to 2,975, and the modern matrix contains high values for *Cladium* and *Pseudorchis* against a global median near 0.0134. Log transformation limits numerical domination but does not reconstruct or harmonize the original units.

Leaf nitrogen content per unit mass also shows values on incompatible-looking scales: the final taxon medians span approximately 0.0154 to 56.7, and both smoke matrices contain high extremes. This should be investigated as a possible fraction-versus-percent or mass-unit issue rather than treated as biological variation by default.

The smoke classifications are therefore implementation evidence only. They are not approved scientific outputs for the complete reanalysis.

# Recommended next decision

The smallest defensible next step is a focused source-unit repair, not another taxon-by-taxon review. Investigate and, if confirmed, approve source-trait rules for stem density sources 660, 123, and the appropriate subsets of 137. In parallel, decide whether Leaf mass per area and Leaf nitrogen content can be normalized from source metadata or must be temporarily excluded from functional-type distances. Because the current requirement is to include all six traits, the definitive reanalysis should wait until those two domains have a documented unit contract.

No new correction was applied by this review, and no main analysis store was invalidated.
