# Main analyses

This tree contains only stable production-facing runners, scientific synthesis,
and final visualisation scripts.

```text
R/02_Main_analyses/
|-- 01_Spatial/
|   |-- 01_Paleo/
|   |   |-- 01_Runners/
|   |   |-- 02_Synthesis/
|   |   `-- 03_Visualisation/
|   `-- 02_Modern/
|       |-- 01_Runners/
|       |-- 02_Synthesis/
|       `-- 03_Visualisation/
`-- 02_Temporal/
    `-- 01_Paleo/
        |-- 01_Runners/
        `-- 02_Visualisation/
```

Two-digit prefixes on folders and scripts define the supported execution
order. Follow the sequence within the relevant domain rather than sorting by
an unnumbered basename.

Diagnostics, sensitivity work, smoke tests, validation, experiments, repairs,
and one-time issue evidence belong under `R/03_Supplementary_analyses`.
Reusable implementation belongs under `R/Functions`, while target definitions
belong under `R/Pipelines`.

The structure was introduced by issue #152 as part of the repository
architecture refactor in issue #149.
