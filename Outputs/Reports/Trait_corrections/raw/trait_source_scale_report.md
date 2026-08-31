# Interim VegVault source-scaling report

## Status

Approved source rules scaled 28,856 records.

The review layer recognized 616 review-layer matches as already satisfied by source scaling.

Approved residual taxon rules scaled 5,379 additional records, yielding 34,235 uniquely scaled records overall.

## Approved source rules

| data_source_id|trait_domain_name     | scale_factor| n_scaled| value_min_before| value_max_before| value_min_after| value_max_after|
|--------------:|:---------------------|------------:|--------:|----------------:|----------------:|---------------:|---------------:|
|            294|Leaf Area             |        1e+02|     1324|        0.0527000|         562.6527|       5.2700000|        56265.27|
|            509|Leaf Area             |        1e+02|     2308|        0.0044953|         111.7692|       0.4495329|        11176.92|
|            155|Plant heigh           |        1e+02|    19715|        0.0000000|           2.8000|       0.0000000|          280.00|
|            243|Leaf Area             |        1e+02|      111|        0.0524091|          47.3270|       5.2409091|         4732.70|
|            187|Plant heigh           |        1e+02|      248|        0.0200000|          12.0000|       2.0000000|         1200.00|
|            457|Plant heigh           |        1e+02|      127|        0.0020000|           0.1100|       0.2000000|           11.00|
|            154|Stem specific density |        1e-03|      182|      262.8876910|        1300.0000|       0.2628877|            1.30|
|            352|Plant heigh           |        1e+02|      772|        0.0300000|          60.0000|       3.0000000|         6000.00|
|            497|Leaf Area             |        1e+02|     1592|        0.0095280|        1937.9740|       0.9528000|       193797.40|
|            564|Plant heigh           |        1e+02|     2477|        0.0050000|           0.5200|       0.5000000|           52.00|

## Provisional Leaf mass per area warning

**PROVISIONAL:** All 124,643 TRY-derived Leaf mass per area records remain unchanged because their original units have not been reconstructed. They remain available only as an interim input pending the corrected VegVault release.

## Detailed counts

Counts by source, trait domain, and taxon are in `trait_source_scale_taxon_counts.csv`.

## Retirement guard

These compatibility rules are version-bound. A VegVault release other than 1.0.0 must fail validation until the rules are explicitly removed or replaced.
