---
title: "Trait review policy proposal"
subtitle: "All-domain raw-stage triage"
format: gfm
execute:
  echo: false
  warning: false
  message: false
---



## Decision requested

This report proposes a conservative policy for completing raw-stage trait review without treating statistical outliers as measurement errors.

No row in this report is approved, and neither canonical decision file has been edited.

The proposed policy would retain a flagged taxon-domain group when no objective error evidence or unresolved submitted concern exists, exclude only exact zero values in strictly positive trait domains, and send negative, non-finite, source-unit, recovered-selector, and unresolved submitted concerns to targeted investigation.

One human policy decision can authorize a defined proposal category, but agents cannot authorize or apply any correction.

## Current scope

The fresh all-domain queue contains 4,300 candidates.

It is five candidates larger than the earlier 4,295-row queue because objective invalid-value groups are now included even when within-taxon IQR screening does not flag them.

The workflow generated 2,320 unapproved proposals: 2,301 conservative no-action proposals and 19 exact-zero exclusion proposals.

The remaining 1,980 candidates require targeted investigation; the bounded first queue contains 143, leaving 1,837 for later batches.


|Trait domain                        | Candidates|
|:-----------------------------------|----------:|
|Diaspore mass                       |         44|
|Leaf Area                           |       1095|
|Leaf mass per area                  |       1371|
|Leaf nitrogen content per unit mass |        519|
|Plant heigh                         |       1168|
|Stem specific density               |        103|

## Proposed policy decisions

An `action = "none"` proposal means that the values remain unchanged and the original flag remains auditable.

An exclusion proposal has the exact selector `trait_value <= 0`; it does not remove positive outliers or an entire taxon-domain group.


|Trait domain                        |Proposed action | Candidates|
|:-----------------------------------|:---------------|----------:|
|Diaspore mass                       |none            |         26|
|Leaf Area                           |exclude         |          3|
|Leaf Area                           |none            |        594|
|Leaf mass per area                  |none            |       1282|
|Leaf nitrogen content per unit mass |none            |         45|
|Plant heigh                         |exclude         |         14|
|Plant heigh                         |none            |        287|
|Stem specific density               |exclude         |          2|
|Stem specific density               |none            |         67|

### Exact-zero exclusions

The 19 exclusion proposals select 15,864 exact-zero records.

Negative values are deliberately excluded from this policy category because a large source-specific negative pattern may indicate a transformation rather than disposable measurements.


|Trait domain          |Taxon                | Records| Zero records| Datasets|Impact tier |
|:---------------------|:--------------------|-------:|------------:|--------:|:-----------|
|Leaf Area             |Alnus glutinosa      |      45|            4|        9|medium      |
|Leaf Area             |Quercus robur        |     120|            3|       16|high        |
|Leaf Area             |Taraxacum campylodes |     163|            2|       29|medium      |
|Plant heigh           |Betula pendula       |    6199|            4|       18|medium      |
|Plant heigh           |Brassica napus       |     137|            3|       96|medium      |
|Plant heigh           |Cinnamomum camphora  |      20|            1|        6|low         |
|Plant heigh           |Picea abies          |   94933|        15784|      276|medium      |
|Plant heigh           |Picea engelmannii    |   80229|            1|     8106|medium      |
|Plant heigh           |Pinus contorta       |  183996|            2|     9392|high        |
|Plant heigh           |Pinus pinaster       |    5645|            9|       15|medium      |
|Plant heigh           |Pinus ponderosa      |  145371|            1|    12132|high        |
|Plant heigh           |Poa alpina           |     343|            2|       12|medium      |
|Plant heigh           |Quercus ilex         |    5518|           29|       19|medium      |
|Plant heigh           |Quercus pyrenaica    |    5583|            7|        7|medium      |
|Plant heigh           |Quercus robur        |    5905|            5|       26|medium      |
|Plant heigh           |Tamarix ramosissima  |       4|            1|        4|low         |
|Plant heigh           |Viburnum tinus       |      32|            1|        3|low         |
|Stem specific density |Ajuga reptans        |       2|            2|        2|low         |
|Stem specific density |Carex riparia        |       3|            3|        3|low         |

## Before-and-after scenario

The scenario below applies only the proposed exact-zero exclusions; all other records remain unchanged.


|Trait domain                        | Records before| Proposed exclusions| Records after| Minimum before| Minimum after| Median before| Median after| Maximum before| Maximum after|
|:-----------------------------------|--------------:|-------------------:|-------------:|--------------:|-------------:|-------------:|------------:|--------------:|-------------:|
|Diaspore mass                       |          46122|                   0|         46122|         0.0001|        0.0001|       55.0000|      55.0000|       35714.29|      35714.29|
|Leaf Area                           |          58983|                   9|         58974|         0.0000|        0.0010|       36.7500|      36.7907|      200170.62|     200170.62|
|Leaf mass per area                  |         133061|                   0|        133061|         0.0000|        0.0000|        0.0156|       0.0156|            Inf|           Inf|
|Leaf nitrogen content per unit mass |          44095|                   0|         44095|         0.0004|        0.0004|        2.2400|       2.2400|         102.00|        102.00|
|Plant heigh                         |        8683200|               15850|       8667350|       -10.3776|      -10.3776|       14.3256|      14.3256|        3180.00|       3180.00|
|Stem specific density               |          11689|                   5|         11684|         0.0000|        0.0003|        0.5500|       0.5500|        1300.00|       1300.00|

## Targeted investigation

Submitted concerns and recovered correction selectors are never converted automatically to no-action decisions.

Negative or non-finite values also require investigation because they can identify a source-level transformation or ingestion problem.


|Investigation reason           | Candidates|
|:------------------------------|----------:|
|investigate_submitted_note     |       1540|
|validate_recovered_proposal    |        314|
|investigate_unit_pattern       |         99|
|investigate_invalid_values     |         12|
|investigate_recovered_proposal |         11|
|investigate_historical_drift   |          4|

The first agent queue is capped at 25 high-priority candidates per domain and prioritizes invalid-value patterns, recovered selectors, and unresolved submitted concerns before generic historical drift.


|Trait domain                        |Agent batch                            | Candidates|
|:-----------------------------------|:--------------------------------------|----------:|
|Diaspore mass                       |diaspore_mass_01                       |         18|
|Leaf Area                           |leaf_area_01                           |         25|
|Leaf mass per area                  |leaf_mass_per_area_01                  |         25|
|Leaf nitrogen content per unit mass |leaf_nitrogen_content_per_unit_mass_01 |         25|
|Plant heigh                         |plant_heigh_01                         |         25|
|Stem specific density               |stem_specific_density_01               |         25|

## Approval boundary

Approval should be recorded by policy category, with a named human reviewer and review date, only after this report is accepted.

The recommended first approval decision is whether to accept the conservative `none` category and the exact-zero exclusion category separately.

Targeted investigation results remain proposed until a later evidence report supports a human decision.

After raw decisions are approved and applied, the classified-stage queue must be regenerated and reviewed independently.
