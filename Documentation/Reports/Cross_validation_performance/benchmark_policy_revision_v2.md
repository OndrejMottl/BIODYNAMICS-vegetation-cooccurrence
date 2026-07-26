# Cross-validation benchmark policy revision v2

Date approved: 2026-07-22  
Branch: `issue138-cv-runtime`  
Applies before: post-`54287622` clean paired measurements

## Decision

The issue 138 staged benchmark runtime contract is revised from a median
wall-time reduction of 20% to 15%. The minimum reduction required from every
paired repetition is revised from 15% to 10%.

The executable policy is versioned as `issue138_staged_benchmark_v2` and is
returned by `get_sjsdm_staged_benchmark_policy()`. The evaluator uses this
policy by default.

## Rationale for issue 141

A reproducible 15% end-to-end reduction is considered scientifically and
operationally worthwhile for the shared CV engine. The production-like CZ
schedule already reduces fitting from 120 to 70 candidate/fold fits, a 41.7%
reduction. Fixed data preparation, worker startup, final fitting, and
evaluation prevent total wall time from falling in direct proportion to fit
count.

The revised threshold was approved before measuring the committed in-process
tier optimization. It therefore does not respond to or select among the new
benchmark outcomes.

The 10% per-pair floor prevents a favorable median from hiding a repetition
with negligible or negative improvement. Three clean paired repetitions are
still required.

## Unchanged gates

All other version-one safeguards remain unchanged:

- at least 40% fewer CV fits;
- no more than 25% target-store growth;
- no more than 10% paired peak RAM or VRAM growth;
- no GPU-memory failure;
- matching technical statuses, assignments, and public artifact schemas;
- no more than 0.005 log-loss regression;
- no more than 0.01 AUC or Tjur R2 regression;
- no more than two percentage points of evaluable-coverage regression; and
- explicit scientific review for a changed selected candidate.

Production was required to remain `exhaustive` until three clean
post-`54287622` pairs passed the complete version-two contract. The required
clean pairs subsequently passed all version-two gates. Their measurements and
formal decision are recorded in
[`paired_cz_benchmark_post_in_process_v2.md`](paired_cz_benchmark_post_in_process_v2.md).

Representative paleo and modern continental validations subsequently passed
the shared staged execution, scientific, memory, and restart gates. The
production default is therefore switched to `staged` on
`issue138-production-staged`. Reduced CZ and explicit exhaustive reference
profiles remain `exhaustive`. The production-switch PR remains conditional on
the applicable Europe, America, and Asia temporal-slice validations.

The first clean Europe temporal diagnostic at 16,000 years was rejected:
leave-one-location-out supplied only one repeat, so the three-round staged
contract could not proceed beyond round 1. The shared engine now validates
repeat coverage before fitting and propagates target errors to the process
exit code. The applicable temporal validation profiles use full preprocessing
and one comparable 6,500-year slice per region. Evidence and the replacement
gate are recorded in
[`temporal_validation_preliminary_v1.md`](temporal_validation_preliminary_v1.md).
