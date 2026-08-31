# Interim trait-review closure

## Outcome

The current raw review queue contains 4,305 taxon-trait candidates. Existing approved decisions cover 2,423 candidates. This workflow also records nine exact scale approvals and one rejected scale proposal from the prior 24-case human review. It then records 1,479 additional approved no-action decisions after structured investigation and one narrow exclusion for a nonpositive Plant heigh value in Lapsana communis.

No scale proposal beyond those nine explicit human approvals is approved by this workflow. The remaining 392 candidates have objective scale or source-pattern evidence and remain unresolved for grouped programmatic investigation. The production raw-review gate therefore remains intentionally incomplete.

| Trait domain | Closure outcome | Candidates |
|---|---|---:|
| Leaf Area | approve_none_insufficient_evidence | 407 |
| Leaf Area | pending_objective_scale_evidence | 46 |
| Leaf mass per area | approve_none_insufficient_evidence | 11 |
| Leaf mass per area | pending_objective_scale_evidence | 78 |
| Leaf nitrogen content per unit mass | approve_none_insufficient_evidence | 237 |
| Leaf nitrogen content per unit mass | pending_objective_scale_evidence | 230 |
| Plant heigh | approve_exclude_invalid_nonpositive | 1 |
| Plant heigh | approve_none_insufficient_evidence | 824 |
| Plant heigh | pending_objective_scale_evidence | 38 |

## Remaining objective-evidence exceptions

| Trait domain | Evidence class | Candidates |
|---|---|---:|
| Leaf Area | Repeated source pattern | 23 |
| Leaf Area | Strong isolated source pattern | 15 |
| Leaf Area | Validated threshold factor | 8 |
| Leaf mass per area | Repeated source pattern | 31 |
| Leaf mass per area | Strong isolated source pattern | 47 |
| Leaf nitrogen content per unit mass | Repeated source pattern | 12 |
| Leaf nitrogen content per unit mass | Strong isolated source pattern | 5 |
| Leaf nitrogen content per unit mass | Validated threshold factor | 213 |
| Plant heigh | Corroborated source factor | 2 |
| Plant heigh | Repeated source pattern | 8 |
| Plant heigh | Strong isolated source pattern | 16 |
| Plant heigh | Validated threshold factor | 12 |

The exception queue is not a request for another broad manual review. Its repeated patterns should be investigated by source, trait definition, and proposed unit factor. Only corroborated source-level or atomic correction rules should be promoted; otherwise the standing conservative policy resolves the investigated candidate to no action.

Leaf mass per area remains provisional. This closure does not alter TRY-derived values or treat distributional factor patterns as proof of a unit correction.

## Provenance and safeguards

- Approved by OndrejMottl on 2026-08-28.
- Input records are the source-scaled VegVault 1.0.0 trait records.
- Candidate identities come from the cached production raw-review target.
- All combined decisions were validated in memory before writing.
- The nine exact human-approved scale rules match and scale 2,781 current records.
- The rejected scale proposal is recorded as an explicit no-action decision.
- The 1,479 no-action decisions match and change zero records.
- The Lapsana communis exclusion matches and excludes exactly one value at or below zero.
- The 392 objective-evidence candidates are excluded from automatic approval.
