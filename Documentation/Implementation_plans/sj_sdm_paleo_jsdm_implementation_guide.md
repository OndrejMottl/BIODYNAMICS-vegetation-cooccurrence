# sjSDM with paleo pollen time series: step-by-step implementation guide

This guide assumes you have **100 cores** across Europe, each with multiple time slices (0–20,000 yr BP), **presence/absence** for multiple taxa, and paleo-climate predictors (`bio1`, `bio12`) per sample (core × time).

**Goal:** fit a JSDM where **climate effects can change through time**, while **not including a standalone age effect**.

---

## 0) Packages & expected data layout

### Packages

```r
install.packages(c("sjSDM", "sf", "dplyr"))
```

```r
library(sjSDM)
library(sf)
library(dplyr)
```

### Data structures (recommended)

- `samples`: data.frame with **one row per observation** (core × time)
  - columns: `core_id`, `lon`, `lat`, `age` (yr BP), `bio1`, `bio12`
- `Y`: matrix/data.frame of 0/1 with **same number of rows as `samples`**
  - columns = taxa/species

Sanity checks:

```r
stopifnot(nrow(samples) == nrow(Y))
stopifnot(all(c("core_id","lon","lat","age","bio1","bio12") %in% names(samples)))
```

---

## 1) Basic cleaning (highly recommended)

### 1.1 Remove taxa that are too rare

Rare taxa can destabilize estimation for binomial JSDMs.

```r
prev <- colMeans(Y, na.rm = TRUE)
keep_taxa <- prev >= 0.01   # e.g., present in at least 1% of samples
Y2 <- Y[, keep_taxa, drop = FALSE]
```

### 1.2 Handle missing predictors

Choose a strategy (drop rows, impute, etc.). Here: drop rows with any missing predictor.

```r
keep_rows <- complete.cases(samples[, c("bio1","bio12","age","lon","lat","core_id")])
samples2 <- samples[keep_rows, ]
Y2 <- Y2[keep_rows, , drop = FALSE]
```

---

## 2) Put age in sensible units + standardize predictors

### 2.1 Convert age to kyr (optional but common)

```r
samples2 <- samples2 %>%
  mutate(
    age_kyr = age / 1000
  )
```

### 2.2 Standardize (recommended)

- **Scale climate** (`bio1`, `bio12`) to mean 0, sd 1.
- For time in interactions, **center + scale** is usually fine (stable optimization; interaction interpretable as “per SD of time”).

```r
samples2 <- samples2 %>%
  mutate(
    bio1_z  = as.numeric(scale(bio1)),
    bio12_z = as.numeric(scale(bio12)),
    age_z   = as.numeric(scale(age_kyr))  # centered & scaled
  )
```

> If you prefer “per 1 kyr” interpretation for interactions, use a centered but not scaled time variable:
>
> `age_c = as.numeric(scale(age_kyr, center = TRUE, scale = FALSE))`

---

## 3) Environmental formula: time-varying climate effects, no age main effect

**Recommended env formula**

- Keep intercept (default)
- Include climate main effects
- Include age×climate interactions
- Exclude age main effect

```r
env_form <- ~ bio1_z + bio12_z + age_z:bio1_z + age_z:bio12_z
# equivalent shorthand: ~ (bio1_z + bio12_z) * age_z - age_z
```

Why this form:

- avoids forcing climate effects to be 0 at age = 0
- allows slopes of climate effects to change with time
- does not include a pure “time trend”

---

## 4) Spatial component from core locations (WGS84 → projected)

### 4.1 Make one row per core & project coordinates

Don’t use degrees in Euclidean distances. For Europe, a common CRS is **EPSG:3035**.

```r
cores <- samples2 %>%
  distinct(core_id, lon, lat)

sf_cores <- st_as_sf(cores, coords = c("lon","lat"), crs = 4326) %>%
  st_transform(3035)

XY_m  <- st_coordinates(sf_cores)     # meters
XY_km <- XY_m / 1000
```

### 4.2 Moran eigenvector spatial filtering (recommended)

Compute eigenvectors on **unique core locations**, then replicate to sample rows.

```r
SPV_core <- generateSpatialEV(XY_km)  # [n_cores x n_evec]

k <- 20  # start here; tune later

idx <- match(samples2$core_id, cores$core_id)
SPV <- SPV_core[idx, 1:k, drop = FALSE]
```

### 4.3 Spatial formula: remove intercept here

Keep intercept in env; set spatial to `~ 0 + .`.

```r
sp_form <- ~ 0 + .
```

---

## 5) Fit the sjSDM model (baseline setup)

```r
m <- sjSDM(
  Y       = Y2,
  env     = linear(data = samples2, formula = env_form),
  spatial = linear(data = SPV,      formula = sp_form, lambda = 0.1),
  family  = binomial("probit")
)

m
```

Notes:

- `lambda` is regularization strength for the spatial predictors. If you include many eigenvectors, regularization is usually helpful.

---

## 6) Tune spatial complexity (k) and regularization (lambda)

A pragmatic approach:

1. Try a small grid of `k` (e.g., 10, 20, 30, 40)
2. Try `lambda` (e.g., 0, 0.01, 0.1, 1)
3. Evaluate with **blocked cross-validation by core** (next section)

Example grids:

```r
k_grid <- c(10, 20, 30, 40)
lam_grid <- c(0, 0.01, 0.1, 1)
```

---

## 7) Correct validation: blocked CV by core (respects repeated measures)

### 7.1 Create core-blocked folds

```r
set.seed(1)
core_ids <- unique(samples2$core_id)
K <- 5
fold_id_by_core <- sample(rep(1:K, length.out = length(core_ids)))
names(fold_id_by_core) <- core_ids
fold <- fold_id_by_core[samples2$core_id]
```

### 7.2 Fit/evaluate loop (skeleton)

(Choose a metric: AUC, log score, etc. This is a minimal structure.)

```r
fits <- vector("list", K)

for (kfold in 1:K) {
  test_idx  <- which(fold == kfold)
  train_idx <- which(fold != kfold)

  m_k <- sjSDM(
    Y = Y2[train_idx, , drop = FALSE],
    env = linear(samples2[train_idx, ], env_form),
    spatial = linear(SPV[train_idx, , drop = FALSE], sp_form, lambda = 0.1),
    family = binomial("probit")
  )

  fits[[kfold]] <- m_k

  # TODO: prediction on test set depends on sjSDM version / predict methods
  # preds <- predict(m_k, newdata = ...)
}
```

**Tip:** even if prediction isn’t wired up yet, blocked CV is the right framework for comparing model variants once your prediction pipeline is set.

---

## 8) Optional: soak up spatiotemporal residual correlation (advanced)

If you still see strong within-core serial dependence, one workaround is to build eigenvectors on a 3D coordinate `(x, y, t)`.

### Caveat

This can “compete” with your `age × climate` interactions (the nuisance basis may capture time structure). Use carefully.

### Example (z-score x/y/time so none dominates)

```r
XYZ <- scale(cbind(
  XY_km[idx, 1],
  XY_km[idx, 2],
  samples2$age_kyr
))

SPV_st <- generateSpatialEV(XYZ)

m_st <- sjSDM(
  Y       = Y2,
  env     = linear(samples2, env_form),
  spatial = linear(SPV_st[, 1:30, drop = FALSE], ~ 0 + ., lambda = 0.1),
  family  = binomial("probit")
)
```

---

## 9) Interpreting coefficients

With:

```r
~ bio1_z + bio12_z + age_z:bio1_z + age_z:bio12_z
```

- `bio1_z` = effect of bio1 at **average age** (because `age_z` is centered)
- `age_z:bio1_z` = how the bio1 effect changes **per 1 SD of age**
- similarly for `bio12`

To visualize time-varying climate effects:

1. Choose a sequence of ages
2. Compute implied slope (example for bio1):
   - slope(age) = `beta_bio1 + beta_age:bio1 * age_z`
3. Plot slope vs time

---

## 10) Common pitfalls checklist

- Using lon/lat degrees directly in distance-based spatial modeling → **project first**.
- Removing the env intercept (`~0+...`) → usually a bad idea for multi-species prevalence differences.
- Including only `age:bio1` and `age:bio12` but no `bio1/bio12` main effects → forces climate effects to be 0 at reference age.
- Validating with random row splits → over-optimistic due to within-core dependence; use **core-blocked** splits.
- Too many spatial eigenvectors without regularization → overfitting; tune `k` and/or increase `lambda`.

---

## Minimal starter template (copy-paste)

```r
library(sjSDM)
library(sf)
library(dplyr)

# --- assume: samples (core_id, lon, lat, age, bio1, bio12), Y (0/1 matrix)

# 1) filter rows
keep_rows <- complete.cases(samples[, c("core_id","lon","lat","age","bio1","bio12")])
samples2 <- samples[keep_rows, ]
Y2 <- Y[keep_rows, , drop = FALSE]

# 2) standardize
samples2 <- samples2 %>%
  mutate(
    age_kyr = age / 1000,
    age_z   = as.numeric(scale(age_kyr)),
    bio1_z  = as.numeric(scale(bio1)),
    bio12_z = as.numeric(scale(bio12))
  )

env_form <- ~ bio1_z + bio12_z + age_z:bio1_z + age_z:bio12_z

# 3) core coords -> EPSG:3035
cores <- samples2 %>% distinct(core_id, lon, lat)
sf_cores <- st_as_sf(cores, coords = c("lon","lat"), crs = 4326) %>% st_transform(3035)
XY_km <- st_coordinates(sf_cores) / 1000

# 4) spatial EV
SPV_core <- generateSpatialEV(XY_km)
k <- 20
idx <- match(samples2$core_id, cores$core_id)
SPV <- SPV_core[idx, 1:k, drop = FALSE]

# 5) fit model
m <- sjSDM(
  Y = Y2,
  env = linear(samples2, env_form),
  spatial = linear(SPV, ~ 0 + ., lambda = 0.1),
  family = binomial("probit")
)

m
```
