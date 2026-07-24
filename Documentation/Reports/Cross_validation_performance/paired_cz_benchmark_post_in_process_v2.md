# Paired CZ benchmark after in-process tier orchestration: v2

Date: 2026-07-22  
Branch: `issue138-cv-runtime`  
Benchmark commit: `129d4400`  
Engine optimization commit: `54287622`  
Policy: `issue138_staged_benchmark_v2`

## Decision

The three clean post-optimization pairs pass all 15 gates in the version-two
benchmark evaluator. Staged tuning is accepted by the CZ promotion gate.

Production remains `exhaustive` while the same shared implementation is
validated on the required representative continental and temporal workloads.
No project-specific threshold or tuning logic is introduced.

## Clean paired measurements

All six runs started from fresh isolated target stores. Repetitions 4--6 are
separate from the pre-optimization repetitions 1--3. The benchmark policy was
committed before these measurements.

| Repetition | Exhaustive wall time | Staged wall time | Wall reduction |
|---:|---:|---:|---:|
| 4 | 1,207.6 s | 1,013.1 s | 16.1% |
| 5 | 1,238.0 s | 1,046.1 s | 15.5% |
| 6 | 1,247.7 s | 1,015.1 s | 18.6% |

The median paired reduction was 16.1%. The minimum paired reduction was
15.5%. Both pass the frozen 15% median and 10% per-pair requirements.

| Measurement | Worst observed staged change | Gate | Result |
|---|---:|---:|---:|
| Executed CV fits | -41.7% | at least -40% | Pass |
| Target-store size | -9.0% | no more than +25% | Pass |
| Peak process RAM | +1.8% | no more than +10% | Pass |
| Peak VRAM | +6.2% | no more than +10% | Pass |
| GPU-memory failure | none | none | Pass |

The staged runs executed 70 successful candidate/fold fits and the exhaustive
runs executed 120. Both strategies reused all 15 selected-candidate fold
predictions instead of refitting them for OOF assembly.

## Technical and scientific equivalence

Every completed unit and tier store had zero target errors. Staged and
exhaustive tuning produced:

- identical grouped assignments, with audit hash
  `ec5dcdda6049a504cb0b69f845c64aa8`;
- identical 9,840-row OOF artifacts with 9,840 unique rows;
- identical fold-local metrics;
- identical public OOF, diagnostics, fold-metric, evaluation, and
  model-provenance schemas, with audit hash
  `2d727fd54623501e0ac384e0674c17f3`;
- the same selected `candidate_008`; and
- complete three-repeat evidence for finalists `candidate_004` and
  `candidate_008`.

The strategy-specific tier-selection value is intentionally `NULL` for direct
exhaustive selection and a version `1.0.0` tier artifact for staged selection.
The public target name is preserved. Final-model targets `model_jsdm` and
`model_jsdm_selected`, cross-validated evaluation, and model provenance were
present in both stores with the same `qs` format and no errors.

Fold-macro predictive values were 0.3102028 log loss, 0.6583597 AUC, and
0.0518790 Tjur R2. Evaluable fold-taxon coverage was 0.6625. All staged-minus-
exhaustive regressions were zero, so no candidate-selection review is needed.

## Evaluator result

`assess_sjsdm_staged_benchmark()` returned:

- policy version: `issue138_staged_benchmark_v2`;
- benchmark status: `pass`;
- failed gates: none; and
- scientific review required: `FALSE`.

All 15 runtime, fit-count, storage, memory, GPU, technical, assignment,
schema, predictive-performance, and coverage gates passed.

Raw logs, environment records, one-second resource samples, and summaries are
retained in ignored directories under `Data/Temp/issue138/` for staged and
exhaustive repetitions 4--6. Generated progress pages are excluded from the
implementation and evidence commits.

## Issue 141 handoff and next gate

The selected design demonstrates a reproducible shared-engine improvement:
41.7% fewer tuning fits and a 16.1% median end-to-end reduction without a
scientific regression. The allowable predictive regressions remain 0.005 log
loss, 0.01 AUC, 0.01 Tjur R2, and two percentage points of evaluable coverage.

The next gate applies this unchanged engine and policy to representative
continental paleo and modern units, then eligible Europe, America, and Asia
temporal slices. Production should switch to `staged` only after those runs
confirm compatibility and resource safety.
