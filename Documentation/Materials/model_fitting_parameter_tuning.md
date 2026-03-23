# Model Fitting Parameter Tuning Guide

After a pipeline run completes, use this guide to assess whether the model converged well and how to adjust the key parameters in `config.yml` before re-running.

---

## Key Parameters (in `config.yml` under `model_fitting:`)

| Parameter | Default | Role |
|-----------|---------|------|
| `n_iter` | 100 | Number of training epochs |
| `n_sampling` | 100 | Monte Carlo samples for likelihood estimation |
| `n_step_size` | `~` (NULL) | Mini-batch size; `~` lets sjSDM choose automatically (10 % of sites) |
| `n_mev` | 2 | Number of Moran Eigenvectors (MEVs) used as spatial predictor terms |
| `n_samples_anova` | 1000 | Bootstrap samples for ANOVA variance partitioning |
| `n_cores` | 5 | CPU cores for parallel processing (GPU runs ignore this) |

---

## Step 1 — Check Convergence from the Loss History

Run the `check_convergence()` helper on the fitted model:

```r
targets::tar_read("mod_jsdm", store = set_store)  |> 
  check_convergence()
```

or load the convergence target directly:

```r
targets::tar_read(
      "model_evaluation",
      store = sel_store_path
    )
```

Interpret the output:

| Metric | Good | Action if bad |
|--------|------|---------------|
| `linear_trend_slope` | < 0.01 | Increase `n_iter` |
| `median_diff` | < 1.0 | Increase `n_iter` |
| Convergence plot tail | Flat, low noise | Increase `n_step_size` or increase `n_sampling` |

### `n_iter` — Epochs

- **Loss is still decreasing at the end of training** → double `n_iter` (e.g. 100 → 200 → 400).
- **Loss plateaued early (< 50 % of epochs)** → `n_iter` is sufficient; no need to increase further.
- **Loss is oscillating wildly** → increase `n_step_size` (larger batches reduce gradient noise and smooth the loss trajectory).

### `n_step_size` — Mini-batch Size

`n_step_size` is the SGD mini-batch size: the number of sites used per gradient update. Larger batches produce more stable gradient estimates and smoother convergence. The automatic default (`NULL` / `~`) sets it to 10 % of the number of sites, which is a reasonable starting point.

- `~` (NULL) lets sjSDM choose automatically (usually fine for moderate datasets).
- **If loss oscillates**: increase `n_step_size` (more sites per gradient step = less noisy updates). Try doubling the current value, or set to `~` to let sjSDM auto-size if you have been using a manually small value.
- **If training is very slow**: keep `n_step_size` at or above the auto default; do not lower it to speed up training.
- Typical manual values by dataset size:
  - ~100 sites: auto default (~10) is appropriate; try 20–30 if oscillating.
  - ~500 sites: auto default (~50); try 64–100 if oscillating.
  - ~2000 sites: auto default (~200); try 256–512 if oscillating.

### `n_sampling` — Monte Carlo Samples

Increasing `n_sampling` reduces gradient noise at the cost of memory and time. Typical progression:

```
100 (default) → 150 → 200
```

Raise if:

- Loss curve is noisy despite a flat trend (and `n_step_size` is already large).
- Model evaluation metrics (AUC, R²) are unstable across repeated runs.

### Additional optimizer controls via `sjSDMControl`

For persistent convergence problems, consider passing `control` to the model fitting call. These options are not exposed as `config.yml` parameters and require a code change in `pipe_segment_model_simple.R`:

- **`scheduler`**: reduce the learning rate automatically when the loss plateaus. Example: `sjSDMControl(scheduler = 50)` reduces the rate after 50 epochs without improvement (with `lr_reduce_factor = 0.99` per epoch).
- **`early_stopping_training`**: halt training if the loss has not decrease for *n* epochs. Prevents wasted compute on stalled runs.
- **`learning_rate`** (top-level `sjSDM()` argument): controls the learning rate for the Adamax optimizer specifically. To change the rate of the default RMSprop optimizer, supply a custom `sjSDMControl(optimizer = RMSprop(...))` object.

---

## Step 2 — Check Model Evaluation

```r
model_evaluation <- targets::tar_read("model_evaluation", store = set_store)
model_evaluation
```

Key metrics to inspect:

| Metric | Target | Action if below target |
|--------|--------|----------------------|
| AUC (mean across species) | > 0.7 | Check data quality, increase `n_iter` |
| R² Nagelkerke (full model) | > 0.1 | Check predictors, increase `n_mev` |

---

## Step 3 — Assess Spatial Structure (`n_mev`)

`n_mev` controls how many **Moran Eigenvectors (MEVs)** are computed and used as spatial predictor terms in the `spatial` component of the model. MEVs are spatial basis functions derived from the site distance matrix; they capture spatial autocorrelation patterns explicitly rather than leaving them to be absorbed into the biotic associations term.

**Important**: `n_mev` governs the spatial predictor, not biotic latent factors. Increasing `n_mev` gives the model more spatial terms to explain observed co-occurrence patterns — this typically *reduces* the Associations fraction in the ANOVA output, not increases it.

Check the ANOVA output:

```r
model_anova <- targets::tar_read("model_anova", store = set_store)
summary(model_anova)
plot(model_anova)
```

Rules of thumb:

- **Space fraction is low (< 5 %) and Associations fraction is high (> 30 %)** → spatial autocorrelation may be under-modelled and bleeding into the biotic associations term. Try increasing `n_mev` by 1–2 (e.g. 3 → 5).
- **Space fraction is already large and Associations fraction is small** → `n_mev` is sufficient; no need to increase further.
- **Model fit is poor (low AUC / R²) and both spatial and environmental fractions are small** → consider increasing `n_mev` and checking predictor quality.
- Increasing `n_mev` substantially increases compute time. Step up by 1–2 at a time.
- Typical range for paleoecological data: **3–6**.

---

## Step 4 — Check ANOVA Stability (`n_samples_anova`)

Re-run or increase `n_samples_anova` if the variance partitioning fractions are unstable or implausibly noisy across time slices or runs.

```
100 (fast, for exploration) → 500 → 1000 (publication quality)
```

Note: `n_samples_anova` only affects the ANOVA step, not model fitting. It is safe to re-run only the ANOVA targets after increasing this value (the fitted model target `mod_jsdm` will not be invalidated).

---

## Step 5 — Update `config.yml` and Re-run

After deciding on new values, edit the relevant project block in `config.yml`. Example: improving convergence for `project_cz`:

```yaml
project_cz:
  model_fitting:
    n_iter: 200       # was 100
    n_sampling: 150   # was 100
    n_step_size: 64   # was null; increase if oscillating
    n_mev: 4          # was 3
    n_samples_anova: 500
```

Then invalidate only the affected targets and re-run:

```r
Sys.setenv(R_CONFIG_ACTIVE = "project_cz")

# Check what will be rebuilt
targets::tar_outdated(
  script = here::here("R/02_Main_analyses/pipeline_basic.R"),
  store = set_store
)

# Re-run
run_pipeline(
  sel_script = "R/02_Main_analyses/pipeline_basic.R",
  level_separation = 100
)
```

Changing `n_iter`, `n_sampling`, `n_step_size`, or `n_mev` will invalidate `mod_jsdm` and all downstream targets (evaluation, ANOVA, plots). Changing only `n_samples_anova` invalidates only the ANOVA targets.

---

## Quick Decision Flowchart

```
After pipeline finishes
        │
        ▼
check_convergence(mod_jsdm)
        │
  ┌─────┴─────┐
slope > 0.01?  median_diff > 1?
  YES          YES
  └────────────┘
        │
   ↑ n_iter (double)
   ↑ n_step_size (double if oscillating)
        │
        ▼
Model evaluation (AUC, R²) acceptable?
   NO → check predictors / ↑ n_mev
  YES
        │
        ▼
ANOVA fractions stable?
   NO → ↑ n_samples_anova
  YES
        │
        ▼
Associations fraction >> Space fraction?
  YES → ↑ n_mev (spatial under-modelled)
   NO → done
```
