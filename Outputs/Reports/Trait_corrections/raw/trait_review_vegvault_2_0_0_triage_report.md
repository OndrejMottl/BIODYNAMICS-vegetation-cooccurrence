# VegVault 2.0.0 trait review triage: raw stage

## Status

Proposals only; nothing is approved. Built from VegVault 2.0.0 (manifest `94516fdfe161eb20031708f458e7bacd435841680d0054925a6ec7d8659c98a0`) on 2026-11-27.

5223 candidates: 5172 with an automated proposal, 51 in the human review queue. 21 automated proposals set aside a queue suggestion.

Proposal file: `trait_review_proposals.csv` in `Data/Temp/Trait_corrections/raw/vegvault_2_0_0_triage/`, SHA-256 `239c7bce684d911c8261f2c4a86dcaf4175e7151c15132018348c37b9a6c9ee2`.

## Proposals by domain, source and action

|trait_domain_name                   |proposal_source |action  | n_candidates|
|:-----------------------------------|:---------------|:-------|------------:|
|Diaspore mass                       |policy          |none    |           84|
|Diaspore mass                       |queue           |NA      |            1|
|Leaf Area                           |closure         |none    |            7|
|Leaf Area                           |policy          |exclude |            3|
|Leaf Area                           |policy          |none    |         1420|
|Leaf Area                           |queue           |scale   |            1|
|Leaf Area                           |queue           |NA      |           13|
|Leaf mass per area                  |policy          |none    |         1636|
|Leaf mass per area                  |queue           |NA      |           10|
|Leaf nitrogen content per unit mass |closure         |none    |            2|
|Leaf nitrogen content per unit mass |policy          |none    |          625|
|Leaf nitrogen content per unit mass |queue           |NA      |            1|
|Plant heigh                         |closure         |exclude |            1|
|Plant heigh                         |closure         |none    |           13|
|Plant heigh                         |policy          |exclude |           18|
|Plant heigh                         |policy          |none    |         1257|
|Plant heigh                         |queue           |NA      |           25|
|Stem specific density               |closure         |none    |            1|
|Stem specific density               |policy          |exclude |            2|
|Stem specific density               |policy          |none    |          103|

## Rules

Each candidate takes the first proposal available: the policy (`none`, or `exclude` of values <= 0), the interim closure (`none` for insufficient evidence, `exclude` of non-positive values), or the human review queue. Scale proposals derived from the review submission use VegVault 1.0.0 units and are never approved automatically. No VegVault 1.0.0 decision or historical review is used.
