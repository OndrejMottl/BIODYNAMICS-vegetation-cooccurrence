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
#   taxonomic rank (species preferred, genus as fallback). The
#   shared auxiliary classification CSV
#   (Data/Input/aux_classification_table.csv) allows manual
#   overrides for taxa that the taxospace service cannot classify
#   (same file used by the community pipeline). If any taxa remain
#   unclassified after combining automatic and auxiliary results,
#   they are appended to Data/Input/missing_taxa_template.csv and
#   a guard target aborts the pipeline so the user can fill in the
#   missing entries.

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

    # ── 4. Track auxiliary classification CSV ───────────
    # format = "file" causes {targets} to detect file changes so
    # that downstream targets become outdated when a human edits
    # the CSV and adds manual classifications.
    # The same shared file is used by the community pipeline, so
    #   one manual edit covers both datasets.
    targets::tar_target(
      description = "Track shared auxiliary classification CSV",
      name = file_aux_classification_table_traits,
      command = here::here(
        "Data/Input/aux_classification_table.csv"
      ),
      format = "file"
    ),

    # ── 5. Load auxiliary classification table ──────────
    targets::tar_target(
      description = "Load shared auxiliary classification table",
      name = data_aux_classification_table_traits,
      command = get_aux_classification_table(
        file_path = file_aux_classification_table_traits
      )
    ),

    # ── 6. Combine auto + auxiliary classifications ──────
    targets::tar_target(
      description = "Combine automatic and auxiliary trait classifications",
      name = data_combined_classification_table_traits,
      command = combine_classification_tables(
        data_classification_table = data_classification_table_traits,
        data_aux_classification_table =
          data_aux_classification_table_traits
      )
    ),

    # ── 7. Detect unclassified taxa ──────────────────────
    targets::tar_target(
      description = "Find trait taxa without any classification",
      name = vec_trait_taxa_without_classification,
      command = get_taxa_without_classification(
        vec_community_taxa = vec_unique_trait_taxa,
        data_classification_table =
          data_combined_classification_table_traits
      )
    ),

    # ── 8. Build missing-taxa template tibble ────────────
    targets::tar_target(
      description = "Build missing-trait-taxa template tibble",
      name = data_missing_trait_taxa_template,
      command = tibble::tibble(
        sel_name = vec_trait_taxa_without_classification,
        kingdom = NA_character_,
        phylum = NA_character_,
        class = NA_character_,
        order = NA_character_,
        family = NA_character_,
        genus = NA_character_,
        species = NA_character_
      )
    ),

    # ── 9. Append missing taxa to shared CSV template ───
    targets::tar_target(
      description = "Append missing trait taxa to template CSV",
      name = file_missing_trait_taxa_template,
      command = append_missing_taxa_to_template(
        data_missing_taxa = data_missing_trait_taxa_template,
        file_path = here::here(
          "Data/Input/missing_taxa_template.csv"
        )
      ),
      format = "file"
    ),

    # ── 10. GUARD: abort if any taxa unclassified ────────
    # Stops after appending unresolved trait taxa to
    # Data/Input/missing_taxa_template.csv so the user can review
    # them and add the needed manual classifications.
    targets::tar_target(
      description = "Check all trait taxa are classified; stop if not",
      name = check_trait_taxa_classification,
      command = {
        base::force(file_missing_trait_taxa_template)

        if (
          base::length(vec_trait_taxa_without_classification) == 0
        ) {
          return(invisible(TRUE))
        }

        cli::cli_abort(
          base::c(
            base::paste(
              base::length(vec_trait_taxa_without_classification),
              "trait taxon/taxa could not be classified."
            ),
            "i" = base::paste(
              "Missing taxa were appended to",
              "{.path Data/Input/missing_taxa_template.csv}."
            ),
            "i" = base::paste(
              "Add manual classifications to",
              "{.path Data/Input/aux_classification_table.csv}",
              "and re-run the pipeline."
            )
          )
        )
      }
    ),

    # ── 11. Resolve to finest rank per taxon ────────────
    # Species is the finest rank: a species-level taxon resolves
    # to its full species name. No filtering against any project's
    # community taxa — all classified trait taxa are retained.
    targets::tar_target(
      description = "Resolve each trait taxon to finest taxonomic rank",
      name = data_resolution_to_finest,
      command = {
        base::force(check_trait_taxa_classification)
        resolve_classification_to_finest_rank(
          data_classification_table =
            data_combined_classification_table_traits,
          column_name_taxon = "taxon_resolved"
        )
      }
    ),

    # ── 12. Join resolved taxon back to trait records ───
    targets::tar_target(
      description = "Join resolved taxon name to corrected trait records",
      name = data_traits_classified,
      command = data_traits_corrected |>
        dplyr::inner_join(
          y = data_resolution_to_finest,
          by = dplyr::join_by("taxon_name" == "sel_name"),
          multiple = "all",
          unmatched = "error",
          relationship = "many-to-many"
        )
    )
  )
