# CZ paleo CPU/GPU reference comparison (v1)

**Recorded:** 2026-07-15  
**Historical CPU store:**
`Data/targets/cz_paleo_cv_reference/pipeline_paleo_core`  
**Fresh GPU store:**
`Data/targets/cz_paleo_cv_reference_gpu/pipeline_paleo_core`

## Purpose

This checkpoint tests whether changing the sjSDM fitting backend from CPU to GPU
changes the engineering or scientific conclusions of the dedicated three-repeat
CZ paleo cross-validation reference. The GPU run uses a separately named config
profile and target store, so it does not overwrite the historical CPU evidence.

Strict numerical parity uses the predeclared absolute tolerance of `1e-4`.
Scientific-conclusion parity asks whether candidate selection, fit success,
out-of-fold coverage, null-model improvement, and the interpretation of the low
Tjur R2 change materially.

## GPU execution

The fresh GPU run passed CUDA preflight and was observed using the GPU during
model fitting. It ended successfully in 27m 28.3s with 202 targets completed,
42 skipped, and zero target errors.

All 120 tuning fits and all 15 selected-candidate fold refits had status `ok`.
The GPU output contained the same 9,840 OOF rows as the CPU reference: 9,462
`ok` rows and 378 `constant_in_training` rows.

## Structural and selection comparison

The CPU and GPU stores have identical OOF keys, fit seeds, score seeds, fold
diagnostics, prediction-status counts, and schemas. The fold-diagnostics target
has the same data hash (`77f808478da98dd1`) in both stores.

Both backends selected fully regularized `candidate_008`, with lambda `0.1` for
covariance, coefficients, and spatial terms. The selected mean held-out
NLL/response was `0.306641469176137` on CPU and `0.306682376744656` on GPU. The
absolute difference, `0.000040907568519`, is within the `1e-4` tolerance.

## Prediction comparison

The 9,462 paired `ok` probabilities have correlation `0.999917265406295`.
However, backend-specific numerical optimization produces differences larger
than the strict elementwise tolerance:

| Comparison | Value |
|---|---:|
| Mean GPU minus CPU probability | 0.0000630 |
| Mean absolute difference | 0.00281 |
| Root mean squared difference | 0.00520 |
| Maximum absolute difference | 0.0555 |
| Proportion within `1e-4` | 10.4% |

The OOF prediction artifacts therefore do not have strict numerical parity and
must retain different hashes. They nevertheless represent almost identical
probability surfaces at the aggregate level.

## Fold-local metric comparison

The table reports repeat means under fold-macro aggregation. Positive
GPU-minus-CPU differences mean the GPU estimate is larger.

| Metric | CPU | GPU | GPU minus CPU | Within `1e-4` |
|---|---:|---:|---:|:---:|
| AUC | 0.64672 | 0.66079 | 0.01407 | No |
| Brier score | 0.0891745 | 0.0891079 | -0.0000666 | Yes |
| Log loss | 0.308272 | 0.308218 | -0.0000531 | Yes |
| Tjur R2 | 0.0527026 | 0.0525993 | -0.0001032 | No, narrowly |
| Calibration intercept | -0.0515 | -0.0535 | -0.00204 | No |
| Calibration slope | -2.08 | 2.30 | 4.38 | No |

Observation-weighted Brier score, log loss, and Tjur R2 lead to the same
interpretation. GPU Tjur R2 is `0.05248`, compared with `0.05253` on CPU.

The AUC change is larger because AUC depends on the ordering of close
probabilities; small optimizer differences can reorder observations without
materially changing proper scoring losses. Calibration slope changes sign, but
both estimates belong to the previously documented unstable, low-coverage
calibration diagnostic. It should not be used for model selection or backend
validation in this small reference.

## Null-model improvement

For both backends and all three repeats:

- AUC and Tjur R2 improvements over the prevalence null are positive;
- log-loss and Brier-score improvements over the prevalence null are positive;
- fold-taxon coverage is unchanged for the primary metrics.

The fold-macro GPU improvements are `0.1608` for AUC, `0.05260` for Tjur R2,
`0.01999` for log loss, and `0.00768` for Brier score. Thus the conclusion that
the model contains real but weak signal is backend-stable.

## Artifact hashes

| Target | CPU hash | GPU hash |
|---|---|---|
| Tuning candidates | `56c5682a1fde3691` | `f590974302111d65` |
| Selected regularization | `1442fd113d5f7363` | `b311db1b609b0dfb` |
| OOF diagnostics | `77f808478da98dd1` | `77f808478da98dd1` |
| OOF predictions | `9282cd94d08516ba` | `2014367502b88165` |
| Fold-local metrics | historical value recomputed | `458600ba5070665f` |
| Fold-metric summaries | historical value recomputed | `37c49a05c8d149f5` |
| Repeat distributions | historical value recomputed | `23b90fb8f2abbbae` |

The historical CPU store predates publication of the three fold-local targets.
Its fold-local values were recomputed from the preserved OOF prediction target
without modifying that store.

## Conclusion

The GPU backend passes structural and scientific-conclusion parity, but it does
not pass strict elementwise numerical parity with CPU. Candidate selection,
successful fold coverage, proper scoring losses, null-model improvements, and
the low Tjur R2 conclusion are stable. AUC shifts modestly and calibration slope
remains unusably unstable.

Future reference and production fitting should use GPU. The subsequent
provenance extension now records the fitting device and versioned fold-local
evaluation contract. Exact CPU/GPU target hashes or probability equality should
not be required. Most importantly, GPU fitting does not rescue the CZ model from
the provisional Tjur R2 threshold: the estimate remains near `0.053`, well below
`0.1`.

## Repository validation

The full regression suite completed with 3,370 passes, zero failures, and the
single documented opt-in VegVault integration skip.

The mandatory fresh CZ gate completed both paleo stores. During the modern
store, the external R subprocess for family tuning was killed while another
project was also running a heavy R workload. No target error was recorded, and
2,100 modern targets had completed. Four orphaned PSOCK workers belonging to
the failed validation parent were identified by parent process and command
line, stopped, and the same fresh modern store was resumed normally.

The resume completed 80 targets, reused 2,072 valid targets, and ended with exit
code 0. Final direct metadata checks found zero errors and zero incomplete
targets in all three stores. The paleo core contained all three new fold-local
targets; paleo and modern resolution stores each contained all nine expected
branch targets.
