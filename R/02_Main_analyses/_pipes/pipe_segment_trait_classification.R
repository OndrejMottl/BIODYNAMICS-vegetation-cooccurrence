#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       {targets} pipe: Trait taxa classification
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Pipe segment that classifies every unique trait taxon via the
#   taxospace API and resolves each to its finest available
#   taxonomic rank (genus preferred). No project-specific
#   community taxa filtering is applied — the trait table is
#   a project-agnostic resource; projects join against it
#   downstream as needed.

#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(
  "here",
  quietly = TRUE,
  warn.conflicts = FALSE,
  verbose = FALSE
)

suppressMessages(
  suppressWarnings(
    source(
      here::here("R/___setup_project___.R")
    )
  )
)


#----------------------------------------------------------#
# 1. Pipe definition -----
#----------------------------------------------------------#

pipe_segment_trait_classification <-
  list(

    # ── 1. Extract unique taxon names ───────────────────
    # Character vector used as the iteration variable for dynamic
    # branching: one branch of data_trait_taxa_classification is
    # created per taxon name.
    targets::tar_target(
      description = "Get unique trait taxon names after corrections",
      name = vec_unique_trait_taxa,
      command = data_traits_corrected |>
        dplyr::distinct(.data[["taxon_name"]]) |>
        dplyr::pull("taxon_name") |>
        base::sort()
    ),

    # ── 2. Classify each taxon (dynamic branch) ─────────
    # Uses the same taxospace classification pipeline as the community
    # data. pattern = map() creates one branch per taxon, allowing
    # {targets} to cache individual results and skip re-querying taxa
    # that have not changed.
    targets::tar_target(
      description = "Classify each trait taxon via taxospace",
      name = data_trait_taxa_classification,
      command = get_taxa_classification(vec_unique_trait_taxa),
      pattern = map(vec_unique_trait_taxa)
    ),

    # ── 3. Combine into classification table ────────────
    targets::tar_target(
      description = "Build full classification table for trait taxa",
      name = data_classification_table_traits,
      command = make_classification_table(
        data = data_trait_taxa_classification
      )
    ),

    # ── 4. Resolve to finest rank per taxon ─────────────
    # Species rank is excluded: trait taxa may be species-level
    # but the table is aggregated to genus level downstream.
    # No filtering against any project's community taxa — all
    # classified trait taxa are retained.
    targets::tar_target(
      description = "Resolve each trait taxon to its finest taxonomic rank",
      name = data_classification_to_genus,
      command = resolve_classification_to_finest_rank(
        data_classification_table = data_classification_table_traits
      )
    ),

    # ── 5. Join resolved genus back to trait records ────
    targets::tar_target(
      description = "Join classification to corrected trait records",
      name = data_traits_classified,
      command = data_traits_corrected |>
        dplyr::inner_join(
          y = data_classification_to_genus,
          by = dplyr::join_by("taxon_name" == "sel_name"),
          multiple = "all",
          relationship = "many-to-many"
        )
    )
  )
