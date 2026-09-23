# Adaptive sjSDM CV calibration timing estimate

Date: 2026-09-10

The previous exhaustive inventory contained 145 representatives and required at least 17,400 sequential GPU fits. It was stopped before any representative completed.

The approved adaptive design contains 20 eligible representatives: one maximum-complexity spatial unit for each analysis, tier, and resolution across continents, plus two eligible paleo temporal profiles. Each representative requires at least 48 screening fits (eight candidates, three folds, and two adjacent iteration rungs) plus 20 confirmation fits (two candidates, five folds, and two repeats), for a strict minimum of 1,360 sequential GPU fits. Production tuning remains unchanged at eight candidates, five folds, three repeats, and sampling 200.

The sampling-100 smoke fit for paleo continental Europe genus, candidate 001, repeat 1, fold 1, and 500 iterations completed in 61.54 seconds after 384 epochs. The equivalent earlier sampling-200 smoke fit completed in 78.3 seconds after 379 epochs.

The same sampling-100 smoke fit for the largest selected representative, modern continental Europe genus, completed in 246.46 seconds after 291 epochs. Both fits converged and triggered early stopping.

A two-point response-size estimate gives about 23 GPU-hours for the strict minimum design. Additional iteration or sampling rungs can increase this substantially, so the operational estimate is approximately one to two days. This remains a large improvement over the earlier four-to-seven-day exhaustive design.

The completed preparation caches, reduced representative inventory, focused tests, full test suite, and architecture validation remain available for the production calibration.
