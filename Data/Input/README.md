# Note on the input data

## VegVault database

The project reads its vegetation plots, fossil pollen, plant traits and climate from [VegVault](https://ondrejmottl.github.io/VegVault/) 2.0.0, a SQLite database, with the R package [vaultkeepr](https://github.com/OndrejMottl/vaultkeepr) 0.2.0.

- **Database:** VegVault 2.0.0, DOI [10.48700/y3p8y-g8106](https://doi.org/10.48700/y3p8y-g8106); the DOI of all versions, which leads to the newest one, is [10.48700/frrj8-ync93](https://doi.org/10.48700/frrj8-ync93). Download `VegVault_2.0.0.sqlite` and place it in this folder as `VegVault.sqlite`. The file has 6,509,383,680 bytes and the SHA-256 `559577c774b8cae272e711b9be6d24ad8376b3d5445390976460f1dd25b1b398`.
- **Flat files** of the same data: DOI [10.48700/gpf0m-ptq85](https://doi.org/10.48700/gpf0m-ptq85). The project does not read them.
- **Code that built the database:** VegVault release [`v2.0.0`](https://github.com/OndrejMottl/VegVault/releases/tag/v2.0.0) (commit `f19d588`), archived as [10.5281/zenodo.24585825](https://doi.org/10.5281/zenodo.24585825). The [changelog](https://ondrejmottl.github.io/VegVault/website/database_changelog.html) lists every change from 1.0.0.
- **vaultkeepr 0.2.0:** release [`v0.2.0`](https://github.com/OndrejMottl/vaultkeepr/releases/tag/v0.2.0) (commit `cb215cf`), archived as [10.5281/zenodo.24582103](https://doi.org/10.5281/zenodo.24582103). `renv.lock` records it, and `R/___Init_project___.R` installs it from the tag.
- **Release record:** every pipeline reads the version, build commit and build manifest hash of the file on each build (target `config_vegvault_release`). Replacing the file therefore marks the extraction targets as outdated, and the trait corrections are read from the folder of that version (`Trait_corrections/README.md`).
- **`VegVault_1.0.0.sqlite`:** the previous release, kept only for the comparison of the two releases (`R/03_Supplementary_analyses/One_time/Data_migrations/VegVault_2_0_0/`) and for the retirement check of the 1.0.0 trait corrections. No pipeline reads it. It can be deleted once the models are rebuilt on 2.0.0.

Both database files are git-ignored. Every script opens them read-only.

## Spatial grid and model tuning

`spatial_grid.csv` is the geometry catalogue for spatial analyses. It contains one row per spatial unit with:

```text
scale_id, scale, parent_id, continent_id, x_min, x_max, y_min, y_max
```

Model fitting parameters are stored separately in `Model_tuning/`. Each tuning file has the same schema:

```text
scale_id, n_iter, n_step_size, n_sampling, n_samples_anova, n_early_stopping
```

File names follow:

```text
model_tuning_<analysis_id>_<resolution>.csv
```

Current spatial analyses use:

```text
model_tuning_paleo_spatial_genus.csv
model_tuning_paleo_spatial_family.csv
model_tuning_paleo_spatial_ft.csv
model_tuning_modern_spatial_genus.csv
model_tuning_modern_spatial_family.csv
model_tuning_modern_spatial_ft.csv
```

Use `spatial_grid.csv` for spatial unit boundaries and hierarchy. Tune model effort in the matching `Model_tuning/` file.

## Combined pollen types of VegVault 2.0.0

`vegvault_2_0_0_combined_pollen_types.csv` lists the 116 combined pollen types (for example "Larix Pseudotsuga") that VegVault 2.0.0 places at the family their genera share, or leaves unclassified when the families differ. Columns: `taxon_name`, `genera` (separated by `/`) and VegVault's `kind`. It copies three columns of the VegVault release evidence file `full_build_dev/combined_pollen_types.csv` (SHA-256 `fb679ee4714d452594e36d4d339617edc931e0caa4e7633abb515bff3e935429`); the placement columns of that file come from a development build and are left out. The placements themselves are read from the database files. The diagnostic `R/03_Supplementary_analyses/Diagnostics/Data_processing/Taxa/Classification_coverage/diagnose_taxa_classification_coverage.R` uses this list.
