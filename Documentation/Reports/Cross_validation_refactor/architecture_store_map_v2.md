# Cross-validation architecture and store map v2

Temporary v1 read boundaries are owned by #141 and expire in #168. Their exact function inventory is `r_cv_v1_compatibility_exceptions_v2.csv`.

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

| Store | V2 public reads | V2 public writes | V1 compatibility |
|---|---|---|---|
| Unit model store | Project data/configuration and tier tuning artifact | Design, tuning, regularization selection, prediction, and evaluation artifacts | Clean v2 execution; no v1 fit or prediction-cache import |
| Tier tuning store | Unit tuning artifacts | Tier tuning artifact | May convert frozen v1 unit tuning summaries at the read boundary |
| Common sensitivity store | Unit tuning and regularization artifacts | Common regularization artifact and sensitivity results | May convert documented v1 summaries and regularization artifacts |
| Historical reporting | Any public v2 artifact | None | May assemble validated v2 artifacts from documented v1 public targets without rewriting stores |

Store paths remain physically isolated. Stable paths are not content invalidation tokens; external reads remain always-cued or depend on explicit content hashes.

## Restartability

Granular computational targets remain internal where they preserve restartability. One authorized candidate-fold work item remains the fitting branch, fold preparation is cached separately, successful sibling branches survive failures, and same-code v2 reruns must not refit unchanged work.
