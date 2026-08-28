# Interim VegVault source-scaling report

## Status

Approved source rules scaled 3,632 records.

The review layer recognized 551 review-layer matches as already satisfied by source scaling.

Approved residual taxon rules scaled 2,750 additional records, yielding 6,382 uniquely scaled records overall.

## Approved source rules

| data_source_id|trait_domain_name | scale_factor| n_scaled| value_min_before| value_max_before| value_min_after| value_max_after|
|--------------:|:-----------------|------------:|--------:|----------------:|----------------:|---------------:|---------------:|
|            294|Leaf Area         |          100|     1324|        0.0527000|         562.6527|       5.2700000|        56265.27|
|            509|Leaf Area         |          100|     2308|        0.0044953|         111.7692|       0.4495329|        11176.92|

## Provisional Leaf mass per area warning

**PROVISIONAL:** All 124,643 TRY-derived Leaf mass per area records remain unchanged because their original units have not been reconstructed. They remain available only as an interim input pending the corrected VegVault release.

## Detailed counts

Counts by source, trait domain, and taxon are in `trait_source_scale_taxon_counts.csv`.

## Retirement guard

These compatibility rules are version-bound. A VegVault release other than 1.0.0 must fail validation until the rules are explicitly removed or replaced.
