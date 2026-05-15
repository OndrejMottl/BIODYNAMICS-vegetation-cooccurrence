# Pipeline Naming Conventions

This directory contains reusable pipe segments for `{targets}` pipelines.

## Pipelines

Pipeline scripts use:

```text
pipeline_<source>_<scope>[_<variant>].R
```

Examples:

- `pipeline_paleo_spatial_resolution.R`
- `pipeline_modern_spatial_resolution.R`
- `pipeline_traits_reference.R`

The source should name the data family (`paleo`, `modern`, `traits`). The
scope should name the analysis geometry or purpose (`spatial`, `temporal`,
`spatial_resolution`).

## Pipe Segments

New reusable pipe segments should use:

```text
pipe_segment_<domain>_<stage>
```

Examples:

- `pipe_segment_community_extract`
- `pipe_segment_community_prepare_modern`
- `pipe_segment_community_by_resolution`
- `pipe_segment_model_input`
- `pipe_segment_model_fit`

Use `pipe_segment_*` for reusable pipeline construction blocks. Reserve
`targets::tar_target()` names for the actual targets those segments create.

## Targets

New target names should use:

```text
<kind>_<domain>_<product>[_<qualifier>]
```

Use these kind prefixes:

- `data_` for data frames, matrices, and lists.
- `file_` for `format = "file"` targets.
- `config_` for configuration targets.
- `model_` for fitted models and model-derived objects.
- `check_` for validation or reporting targets.

Avoid `path_` for file targets. Prefer `file_` because the target tracks a file
dependency, not just a string path.

## Branch labels

Use `resolution_id` for resolution branches. Modern spatial-resolution branches
use:

```r
c("genus", "family", "ft_modern", "ft_paleo")
```

The shorter FT labels keep target suffixes readable while preserving the
scientific distinction between modern-derived and paleo-derived functional-type
classifications.
