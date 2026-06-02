# Plan: Trait pipeline — geo-filter, flat-structure wrangling, proper classification, taxa renaming

## TL;DR

Four focused changes across five files:

1. **Geo-filter traits to the active project's continent** (auto-detect bounds from `spatial_grid.csv`)
2. **Update wrangling for the flat `return_raw_data = TRUE` structure** (remove dead unnest; update comments)
3. **Replace first-word genus extraction with full taxospace classification pipeline** (handles genus/family/order; output column renamed to `taxon_community`)
4. **Rename all "genera" language to "taxa"** across `check_trait_coverage.R` and `03_Build_trait_table.R`

---

## Phase 1 — `R/Functions/Traits/extract_traits_from_vegvault.R`

- Add `x_lim = NULL` and `y_lim = NULL` optional parameters (NULL = no geo filter)
- When provided: insert `vaultkeepr::select_dataset_by_geo(lat_lim = y_lim, long_lim = x_lim, verbose = FALSE)` AFTER `select_dataset_by_type()`, BEFORE `get_samples()`
- Update `@param` docs for the two new args
- Update `@description` / `@details`: return is a flat data frame (not nested), `get_taxa()` not called, geo filtering optional

---

## Phase 2 — `R/02_Main_analyses/02_Trait_analyses/01_Extract_trait_data.R`

### New section "Determine continental spatial bounds for geo-filtering"

1. `readr::read_csv(here::here("Data/Input/spatial_grid.csv"), show_col_types = FALSE)` -> `data_spatial_grid`
2. `get_active_config("vegvault_data")` -> `vegvault_cfg`; extract `x_lim` and `y_lim`
3. Filter to `scale == "continental"`, find row where project bounds are contained (x_min <= min(x_lim), x_max >= max(x_lim), same for y)
4. Assert exactly one row found
5. Extract `vec_continental_x_lim` and `vec_continental_y_lim`; log which continent was identified

### Update extraction call: pass `x_lim = vec_continental_x_lim`, `y_lim = vec_continental_y_lim`

### Section 3 wrangling (flat structure)

- Remove `tidyr::unnest(cols = dplyr::any_of("data_traits"))` (no-op with flat output but misleading)
- Keep `dplyr::select()` and `dplyr::filter()` steps; update block comment to describe flat output

---

## Phase 3 — `R/02_Main_analyses/02_Trait_analyses/02_Classify_and_align_taxa.R` (major rewrite)

### Sections 1 & 2 unchanged; rename `vec_community_genera` -> `vec_community_taxa`

### Replace section 3 with taxospace classification pipeline

1. Extract `taxon_name_genus` (first word) for unique genera — same as before
2. Map `get_taxa_classification()` over `vec_unique_genera` -> `list_genus_classifications`
3. `make_classification_table(list_genus_classifications)` -> `data_genus_classification_table`
4. `get_aux_classification_table()` -> `data_aux_classification_table`
5. `combine_classification_tables()` -> `data_combined_genus_classification`
6. Report: genera classified / total

Note: `get_taxa_classification()` already filters to Plantae — non-plant genera excluded automatically

### Replace section 4 with community-taxon matching

1. `vec_ranks <- c("kingdom", "phylum", "class", "order", "family", "genus")` (coarsest to finest; `species` excluded)
2. pivot_longer over `vec_ranks`; drop NAs; filter to `vec_community_taxa`
3. Group by `sel_name`; `slice_max(rank_order, n=1)` — finest rank wins
4. Result: `data_genus_to_community` with `taxon_name_genus` + `taxon_community`
5. Inner-join to `data_traits_with_genus` -> `data_traits_classified` with `taxon_community` column

### Sections 5 & 6: update variable/column refs to `taxon_community` where needed

---

## Phase 4 — `R/Functions/Traits/check_trait_coverage.R`

- `@title` / `@description`: "genera" / "genus names" -> "taxa" / "taxon names"
- `@param vec_community_genera` -> `@param vec_community_taxa`
- `@return` list keys: `n_community_genera` -> `n_community_taxa`; `vec_missing_genera` -> `vec_missing_taxa`; `vec_extra_genera` -> `vec_extra_taxa`
- All matching internal variables and returned list keys renamed consistently
- `cli::cli_inform()` messages: "community genera" -> "community taxa"

---

## Phase 5 — `R/02_Main_analyses/02_Trait_analyses/03_Build_trait_table.R`

Column-name replacements `"taxon_name_genus"` -> `"taxon_community"`:

- `group_cols` in `filter_trait_outliers()` and `aggregate_trait_values()` calls
- `taxon_col` in `make_trait_table()` call
- Inline comment: "genera x" -> "community taxa x"

Section 2: `vec_community_genera` -> `vec_community_taxa`

Section 6 coverage check:

- `check_trait_coverage(vec_community_genera = ...)` -> `(vec_community_taxa = ...)`
- `list_coverage[["n_community_genera"]]` -> `[["n_community_taxa"]]`
- `list_coverage[["vec_missing_genera"]]` -> `[["vec_missing_taxa"]]` (x2)
- Comments/messages: "community genera" / "Missing genera" -> "community taxa" / "Missing taxa"

Output filename prefix: `"data_trait_table_genus_"` -> `"data_trait_table_"`

---

## Verification

1. Spot-check: `project_cz` (x=[12,18.9], y=[48.5,51.5]) -> selects `europe` row (x:[-10,40], y:[35,70])
2. Spot-check: `vec_ranks` ordering — `match("genus", vec_ranks) = 6 > family = 5`, so `slice_max` picks genus over family
3. Run full test suite: `Rscript R/03_Supplementary_analyses/Run_tests.R`
4. Run `project_cz` pipeline end-to-end

---

## Decisions

- `x_lim`/`y_lim` default `NULL` (backward compatible; function usable without project context)
- Containment (not overlap) for continental detection — avoids ambiguous edge cases
- `taxon_name_genus` kept as intermediate column; `taxon_community` is the output linking column
- `species` rank excluded from matching pivot (taxa are species-level, not community-level)
- Non-plant genera excluded automatically by `get_taxa_classification()` Plantae filter

## Implementation Progress

| Phase | File | Status |
|-------|------|--------|
| 1 | `R/Functions/Traits/extract_traits_from_vegvault.R` | ✅ DONE |
| 2 | `R/02_Main_analyses/02_Trait_analyses/01_Extract_trait_data.R` | ✅ DONE |
| 3 | `R/02_Main_analyses/02_Trait_analyses/02_Classify_and_align_taxa.R` | ✅ DONE |
| 4 | `R/Functions/Traits/check_trait_coverage.R` | ❌ NEXT |
| 5 | `R/02_Main_analyses/02_Trait_analyses/03_Build_trait_table.R` | ❌ TODO |

---

## Phase 4 — Detailed changes needed for `check_trait_coverage.R`

Current file content (the active file in the editor) has these specific strings to change:

### Roxygen docs

- `@title Check Trait Coverage Against Community Genera`
  -> `@title Check Trait Coverage Against Community Taxa`
- `@description` first line: `Compares a character vector of genus names from the community data`
  -> `Compares a character vector of taxon names from the community data`
- `@description` second line: `proportion of community genera covered` -> `proportion of community taxa covered`
- `@description` last phrase: `which genera are missing or extra` -> `which taxa are missing or extra`
- `@param vec_community_genera` -> `@param vec_community_taxa`
- `@param` description: `character vector of unique genus names` -> `character vector of unique taxon names`
- `@return` item `n_community_genera`: rename key and description to `n_community_taxa` / "unique taxa"
- `@return` item `vec_missing_genera`: rename to `vec_missing_taxa` / "community taxa absent"
- `@return` item `vec_extra_genera`: rename to `vec_extra_taxa` / "taxa in the trait table not found"

### Function signature

- `vec_community_genera,` -> `vec_community_taxa,`
S
### assertthat validation

- `base::is.character(vec_community_genera)` -> `vec_community_taxa`
- msg: `'vec_community_genera' must be...` -> `'vec_community_taxa' must be...`

### Internal variables

- `n_community_genera <-` -> `n_community_taxa <-`
- `vec_missing_genera <-` -> `vec_missing_taxa <-`
- `vec_extra_genera <-` -> `vec_extra_taxa <-`
- All references to `vec_community_genera` inside function body -> `vec_community_taxa`

### cli messages

- `n_community_genera, " community genera ("` -> `n_community_taxa, " community taxa ("`
- `" genera missing from trait table; "` -> `" taxa missing from trait table; "`
- `" extra genera in trait table."` -> `" extra taxa in trait table."`

### Return list

- `n_community_genera = n_community_genera,` -> `n_community_taxa = n_community_taxa,`
- `vec_missing_genera = vec_missing_genera,` -> `vec_missing_taxa = vec_missing_taxa,`
- `vec_extra_genera = vec_extra_genera` -> `vec_extra_taxa = vec_extra_taxa`

---

## Phase 5 — Detailed changes needed for `03_Build_trait_table.R`

### Section 2 (load community genera)

- `vec_community_genera <-` -> `vec_community_taxa <-`
- `"Community genera: "` -> `"Community taxa: "`
- All `vec_community_genera` references -> `vec_community_taxa`

### Section 3 (filter outliers)

- `group_cols = base::c("taxon_name_genus", "trait_domain_name")` -> `"taxon_community"`

### Section 4 (aggregate)

- `group_cols = base::c("taxon_name_genus", "trait_domain_name")` -> `"taxon_community"`
- Message: `"Aggregated: ... genus × trait domain"` -> `"community taxon × trait domain"`

### Section 5 (pivot wide)

- `taxon_col = "taxon_name_genus"` -> `"taxon_community"`
- Comment: `"genera ×"` -> `"community taxa ×"`

### Section 6 (coverage check)

- `check_trait_coverage(vec_community_genera = vec_community_genera,` -> `(vec_community_taxa = vec_community_taxa,`
- `list_coverage[["n_community_genera"]]` -> `[["n_community_taxa"]]` (x2: in message)
- `list_coverage[["vec_missing_genera"]]` -> `[["vec_missing_taxa"]]` (x2: condition + print)
- `"Missing genera"` -> `"Missing taxa"`

### Section 7 (save)

- Filename prefix: `"data_trait_table_genus_"` -> `"data_trait_table_"`
- Header comment: `"Trait analyses 03 — Build genus × traits table"` -> `"— Build community taxa × traits table"`
