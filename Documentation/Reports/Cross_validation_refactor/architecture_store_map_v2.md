# Cross-validation architecture and store map v2

Issue #168 retired all temporary v1 read boundaries. Active cross-store interfaces are native-v2-only.

**Schema version:** `2.0.0`
**Owning issue:** #141

## Execution architecture

```text
production runner
  -> deterministic tuning round plan
  -> isolated unit-store execution
       -> route-specific cross-validation design
       -> shared execution pipe segment
            -> fold preparation
            -> candidate-fold work items
            -> candidate execution and compact cache
            -> unit selection
            -> selected out-of-fold artifacts
            -> evaluation and provenance
  -> complete-evidence check
  -> isolated tier-store survivor or final selection
  -> resume unit stores with tier selection
```

## Pipeline ownership

- `pipe_segment_model_cross_validation_shared.R` owns the shared pre-resolution design.
- The direct and from-shared pipe segments own only route-specific design and model context.
- `pipe_segment_model_cross_validation_execution.R` owns the literal common execution graph from the tuning schedule through v2 evaluation publication.
- `pipeline_sjsdm_tier_tuning.R` owns explicit tier round targets and one public tier artifact.
- Production runners own sequencing across physically isolated stores.

## Store boundaries

| Store | Native-v2 public reads | Native-v2 public writes | Retention policy |
|---|---|---|---|
| Unit model store | Project data/configuration and validated tier tuning artifact | Design, tuning, regularization selection, prediction, and evaluation artifacts | Retained only with canonical native-v2 inputs |
| Tier tuning store | Validated unit tuning artifacts | Tier tuning artifact | Retained; raw v1 summary tables fail closed |
| Common sensitivity store | Validated unit tuning and regularization artifacts | Common regularization artifact and sensitivity results | Retained; legacy tables and target names are not read |
| Component and structured-regularization reference stores | Design and regularization-selection artifacts from `cz_paleo_cv_reference_gpu` | Reference-only scientific outputs | Retained consumers; their output stores are not classified as v1 artifact sources |
| Reporting | Validated evaluation artifact payloads | None | Native-v2-only; superseded pre-#171 main stores are historical |

Store paths remain physically isolated. Stable paths are not content invalidation tokens; external reads remain always-cued or depend on explicit content hashes. Frozen one-time validation stores and ad hoc stores are historical and do not keep compatibility code alive.

## Restartability

Granular computational targets remain internal where they preserve restartability. One authorized candidate-fold work item remains the fitting branch, fold preparation is cached separately, successful sibling branches survive failures, and same-code v2 reruns must not refit unchanged work.
