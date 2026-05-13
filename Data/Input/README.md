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
