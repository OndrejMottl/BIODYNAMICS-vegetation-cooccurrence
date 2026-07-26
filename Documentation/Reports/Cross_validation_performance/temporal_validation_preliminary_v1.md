# Issue 138 temporal validation: preliminary evidence

Date: 2026-07-26  
Branch: `issue138-production-staged`  
Status: preliminary; Europe and America temporal gates passed; no Asia slice
is currently applicable

## Clean Europe run

Repetition 900 ran from an absent isolated target store with full
0--20,000-year Europe preprocessing and tuning restricted to
`timeslice_16000`.

The monitored process completed after 11,906 seconds (3 h 18 min 26 s).
Peak process-tree working set was 25.9 GB, peak system memory used was
40.9 GB, peak VRAM was 1.7 GB, and no GPU-memory failure was detected. The
target store occupied 116.3 MB.

These measurements are retained as diagnostic evidence only. The scientific
and orchestration gate failed:

- the selected slice resolved to 25-location leave-one-location-out CV;
- the fallback provided only repeat 1, while staged tuning required repeats
  1--3;
- round 1 executed 200 candidate-fold fits because the 25 leave-one-out folds
  were represented under one repeat;
- tier round 2 failed because repeat-2 evidence was unavailable; and
- final OOF, evaluation, provenance, and tier artifacts were consequently
  errored.

The harness initially returned exit code zero because the temporal pipeline
uses `{targets}` error mode `null`; the completed process was therefore not a
successful validation.

## Corrections

The shared implementation now:

- validates full staged-repeat coverage before the first candidate fit;
- propagates newly recorded `{targets}` errors from `run_pipeline()` so the
  harness cannot report false success;
- retains shared `mori` inputs in the parent R process and refreshes them once
  after a process restart;
- runs representative scripts in resume mode by default;
- exclusively locks each benchmark target store against concurrent retry
  processes; and
- uses full temporal preprocessing while constraining tier evidence to one
  explicitly configured slice.

Europe `timeslice_6500` was probed from the clean preprocessing artifact. It
resolved to three grouped repeats with five folds per repeat and 105
locations per fold. Europe and America use the comparable 6,500-year slice.
Asia 6,500 was subsequently shown to require leave-one-location-out CV after
fold-level scientific safeguards were applied, so it cannot supply all three
staged repeats. Although adjacent Asia slices retain three grouped repeats
with five folds per repeat, a full feasibility probe showed that none meets
the full-model taxon safeguard. No continent-specific modelling threshold or
execution branch was introduced.

## Clean Europe 6,500-year validation

Repetition 901 ran from an absent isolated target store with full
0--20,000-year Europe preprocessing and tuning restricted to
`timeslice_6500`. The run completed successfully in 8,563 seconds
(2 h 22 min 43 s) with process exit code zero.

The shared interpolation prebuild executed once. It completed 708
dataset-level interpolation branches and 736 total preprocessing targets with
zero skipped targets and zero errors. The summed interpolation worker time was
7 h 25 min 33 s; four-worker wall time was 1 h 55 min 55 s. Peak process-tree
working set was 25.38 GB, peak system memory used was 37.04 GB, peak VRAM was
1.188 GB, and no GPU-memory failure was detected. The completed target store
occupied 121.63 MB.

The staged tuning gate passed:

- round 1 completed 40 fits for eight candidates across repeat 1;
- round 2 completed 20 new fits for four tier-wide survivors across repeat 2;
- round 3 completed 10 new fits for two tier-wide finalists across repeat 3;
- all 70 fits had status `ok`, with no duplicate
  repeat/fold/candidate work keys;
- the 15 prepared fold caches contained candidate widths 8, 4, and 2 for
  five folds each;
- `candidate_001` and `candidate_002` both had complete three-repeat evidence;
- `candidate_002` was selected by both equal-ID and sample-weighted
  aggregation; and
- round decisions recorded strategy version `sjsdm_staged_tuning_v1` and the
  expected 8 -> 4 -> 2 entering/surviving counts.

The public artifact gate also passed. The unit store contained 1,855 targets
with zero error rows. The selected-model, cached OOF, OOF diagnostics,
cross-validated evaluation, and model-provenance targets were all present.
The OOF artifact contained 72,450 held-out predictions and 15 fold diagnostics.
It was assembled from cached predictions without selected-candidate fold
refits. The final full-data model fit completed once.

The standard-error target encountered a singular matrix while inverting the
fixture model Hessian. `sjSDM::getSe()` printed the error but returned the
fitted model without populating its `$se` field, so `{targets}` recorded the
target as complete. This did not affect tuning, cached OOF prediction,
cross-validated evaluation, provenance, or model selection, but standard
errors were not produced. This pre-existing final-model diagnostic defect
requires separate review from the Issue 138 runtime gate.

## Clean America 6,500-year validation

Repetition 902 ran from an absent isolated target store with full
0--20,000-year America preprocessing and tuning restricted to
`timeslice_6500`. The run completed successfully in 5,339 seconds
(1 h 28 min 59 s) with process exit code zero.

The shared interpolation prebuild completed 404 dataset-level interpolation
branches and 432 total preprocessing targets with zero skipped targets and
zero errors. Summed interpolation worker time was 4 h 10 min 35 s and
four-worker wall time was 1 h 6 min 1 s. Peak process-tree working set was
12.94 GB, peak system memory used was 31.37 GB, peak VRAM was 1.184 GB, and
no GPU-memory failure was detected. The completed target store occupied
54.23 MB.

The staged and artifact gates passed with the same 40 + 20 + 10 fit budget.
All 70 fits had status `ok`, no repeat/fold/candidate key was duplicated, and
the prepared fold caches had widths 8, 4, and 2. `candidate_001` and
`candidate_002` had complete three-repeat evidence and `candidate_002` was
selected. The public cached OOF artifact contained 49,410 predictions and 15
fold diagnostics. The unit store contained 1,480 metadata rows with zero
errors, the tier store contained zero errors, OOF assembly took no measurable
time, and the final full-data model was fitted once.

The America standard-error target reproduced the same singular-Hessian
behavior as Europe: the target completed but the returned model's `$se` field
was unpopulated. It remains separate from the shared CV runtime gate.

## Clean Asia 6,500-year diagnostic

Repetition 903 started from an absent isolated store and failed closed after
307 seconds, before any candidate fit. The slice contained 21 locations.
Although the initial assignment had three grouped repeats and five folds,
fold-level taxon safeguards adapted it to single-repeat
leave-one-location-out CV. The shared staged-repeat validator then reported
missing repeat IDs 2 and 3. The harness propagated the target failure with
exit code one, and no GPU-memory failure occurred.

An assignment-only probe of the completed full Asia preprocessing showed that
the adjacent 6,000- and 7,000-year slices both preserve the required three
grouped repeats and five folds. A subsequent full feasibility probe was
therefore required before another GPU run.

## Clean Asia 7,000-year diagnostic

The isolated 7,000-year run confirmed the three-repeat, five-fold assignment
but also exposed that only four taxa met the full-model prevalence safeguard.
The shared feasibility target correctly resolved to `full_model_infeasible`
and `cv_strategy = "none"`.

The tuning path nevertheless executed the complete 40 + 20 + 10 fit budget.
Both finalists had complete evidence and `candidate_008` was selected, but
regularization correctly resolved to no model. Cached OOF assembly then
failed because the no-model artifact has no candidate ID. Four downstream
public artifacts consequently failed as well. The benchmark wrapper was
terminated by the calling shell timeout while its child R process continued,
so this run is correctness evidence only and has no valid monitored-resource
summary.

The failed 6,500- and 7,000-year stores are retained. Together they show that
the shared engine fails closed for missing repeats, but does not yet short
circuit tuning when feasibility has already selected no model.

## Next gate

Add a shared pre-fit feasibility short circuit so `cv_strategy = "none"`
produces compatible typed no-model artifacts without candidate fits or OOF
cache assembly. Validate that behavior with focused tests and a resumed Asia
diagnostic. Asia should be recorded as not applicable to staged-performance
comparison unless a future data/configuration change yields a slice that
passes the existing scientific safeguards.
