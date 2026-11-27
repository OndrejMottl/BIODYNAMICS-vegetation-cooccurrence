# Note on the input data

The project uses the [VegVault](bit.ly/VegVault) database, which is accessible from the [VegVault](https://bit.ly/VegVault) website.

In order to make the project work, you need to download the VegVault database and place it in the `Data/Input` folder. The database is a SQLite file with the name `VegVault.sqlite`.

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
