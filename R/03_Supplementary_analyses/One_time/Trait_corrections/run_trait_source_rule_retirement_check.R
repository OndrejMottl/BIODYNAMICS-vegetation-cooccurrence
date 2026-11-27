#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#     Check the retirement of the VegVault 1.0.0 trait rules
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# One-time runner of the VegVault 2.0.0 migration (Stage V, step V3e).
# For each of the ten VegVault 1.0.0 source-scale rules, it finds the
#   source in VegVault 2.0.0 by its description and classifies whether
#   2.0.0 already applies the rule's factor at the source
#   (classify_trait_source_rule_retirement()). It also lists the v1
#   `scale` and `exclude` review decisions with their 2.0.0 evidence, for
#   information only; no v1 decision is carried over.
# Inputs:
#   - the v1 rules and decisions in Data/Input/Trait_corrections/
#     VegVault_1_0_0/;
#   - data_traits_raw of the archived v1 trait store;
#   - data_traits_raw of the VegVault 2.0.0 trait store under Data/Temp
#     (built up to the raw review queue);
#   - DatasetSourcesID of Data/Input/VegVault.sqlite, read-only.
# Outputs (Documentation/Reports/Model_evaluation/
#   vegvault_2_migration_2026-11/):
#   - trait_source_rule_retirement.csv
#   - trait_v1_review_decision_evidence.csv
# The runner stops when a rule is still unscaled or unresolved: such a
#   rule must be corrected in VegVault or replaced by a 2.0.0 rule keyed
#   to its 2.0.0 source id.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

Sys.setenv(
  R_CONFIG_ACTIVE = "project_traits_reference",
  BIODYNAMICS_PREPROCESSING_WORKER = "false",
  BIODYNAMICS_PREPROCESSING_WORKERS = ""
)
source(here::here("R/___setup_project___.R"))

path_vegvault <-
  here::here("Data/Input/VegVault.sqlite")
dir_trait_corrections_v1 <-
  here::here("Data/Input/Trait_corrections/VegVault_1_0_0")
path_store_v1 <-
  here::here(
    "Data/targets/_archive/2026-11_vegvault_1_0_0_traits_reference",
    "pipeline_traits_reference"
  )
path_store_v2 <-
  here::here(
    "Data/Temp/vegvault_2_migration/traits_reference_v2",
    "pipeline_traits_reference"
  )
dir_evidence <-
  here::here(
    "Documentation/Reports/Model_evaluation/vegvault_2_migration_2026-11"
  )


#----------------------------------------------------------#
# 1. Load inputs -----
#----------------------------------------------------------#

data_vegvault_release <-
  load_vegvault_database_version(
    path_to_vegvault = path_vegvault,
    vegvault_version = "2.0.0"
  )

data_release_store_v2 <-
  targets::tar_read_raw(
    name = "config_vegvault_release",
    store = path_store_v2
  )

assertthat::assert_that(
  base::identical(
    base::as.list(data_release_store_v2),
    base::as.list(data_vegvault_release)
  ),
  msg = "The 2.0.0 trait store was built from another VegVault file."
)

data_source_scale_rules_v1 <-
  load_trait_source_scale_rules(
    path_trait_source_scale_rules = base::file.path(
      dir_trait_corrections_v1,
      "trait_source_scale_rules.csv"
    )
  )

data_trait_review_decisions_v1 <-
  load_trait_review_decisions(
    path_trait_review_decisions = base::file.path(
      dir_trait_corrections_v1,
      "trait_review_decisions_raw.csv"
    )
  )

data_traits_raw_v1 <-
  targets::tar_read_raw(
    name = "data_traits_raw",
    store = path_store_v1
  )

data_traits_raw_v2 <-
  targets::tar_read_raw(
    name = "data_traits_raw",
    store = path_store_v2
  )

connection_vegvault <-
  DBI::dbConnect(
    drv = RSQLite::SQLite(),
    dbname = path_vegvault,
    flags = RSQLite::SQLITE_RO
  )

data_sources_v2 <-
  DBI::dbGetQuery(
    connection_vegvault,
    "SELECT data_source_id, data_source_desc FROM DatasetSourcesID"
  ) |>
  tibble::as_tibble()

DBI::dbDisconnect(connection_vegvault)


#----------------------------------------------------------#
# 2. Classify the v1 source rules -----
#----------------------------------------------------------#

data_rule_retirement <-
  classify_trait_source_rule_retirement(
    data_source_scale_rules = data_source_scale_rules_v1,
    data_trait_records_before = data_traits_raw_v1,
    data_trait_records_after = data_traits_raw_v2,
    data_sources_after = data_sources_v2
  ) |>
  dplyr::mutate(
    vegvault_version_after = data_vegvault_release[["vegvault_version"]],
    vegvault_build_reference_after =
      data_vegvault_release[["manifest_sha256"]]
  )

readr::write_csv(
  data_rule_retirement,
  base::file.path(dir_evidence, "trait_source_rule_retirement.csv"),
  na = ""
)


#----------------------------------------------------------#
# 3. v1 scale and exclude decisions with 2.0.0 evidence -----
#----------------------------------------------------------#

# The v1 decisions select records by taxon, domain and value bounds only;
#   the bounds are in v1 units and are reported for information
data_decisions_v1_selected <-
  data_trait_review_decisions_v1 |>
  dplyr::filter(
    .data[["action"]] %in% base::c("scale", "exclude")
  )

assertthat::assert_that(
  base::all(base::is.na(data_decisions_v1_selected[["dataset_id"]])),
  base::all(base::is.na(data_decisions_v1_selected[["trait_name"]])),
  msg = "v1 decisions with dataset or trait-name selectors need review."
)

data_decision_evidence <-
  base::seq_len(base::nrow(data_decisions_v1_selected)) |>
  purrr::map(
    .f = ~ {
      data_decision <-
        data_decisions_v1_selected[.x, , drop = FALSE]

      vec_values_v1 <-
        data_traits_raw_v1[["trait_value"]][
          data_traits_raw_v1[["taxon_name"]] ==
            data_decision[["taxon_name"]] &
            data_traits_raw_v1[["trait_domain_name"]] ==
              data_decision[["trait_domain_name"]]
        ]
      vec_values_v2 <-
        data_traits_raw_v2[["trait_value"]][
          data_traits_raw_v2[["taxon_name"]] ==
            data_decision[["taxon_name"]] &
            data_traits_raw_v2[["trait_domain_name"]] ==
              data_decision[["trait_domain_name"]]
        ]

      value_lower <- data_decision[["value_lower"]]
      value_upper <- data_decision[["value_upper"]]
      flag_lower_inclusive <-
        base::isTRUE(data_decision[["value_lower_inclusive"]])
      flag_upper_inclusive <-
        base::isTRUE(data_decision[["value_upper_inclusive"]])

      is_selected_v1 <-
        (base::is.na(value_lower) |
          (vec_values_v1 > value_lower) |
          (flag_lower_inclusive & vec_values_v1 == value_lower)) &
        (base::is.na(value_upper) |
          (vec_values_v1 < value_upper) |
          (flag_upper_inclusive & vec_values_v1 == value_upper))
      is_selected_v2 <-
        (base::is.na(value_lower) |
          (vec_values_v2 > value_lower) |
          (flag_lower_inclusive & vec_values_v2 == value_lower)) &
        (base::is.na(value_upper) |
          (vec_values_v2 < value_upper) |
          (flag_upper_inclusive & vec_values_v2 == value_upper))

      data_decision |>
        dplyr::select(
          "decision_id",
          "taxon_name",
          "trait_domain_name",
          "action",
          "value_lower",
          "value_lower_inclusive",
          "value_upper",
          "value_upper_inclusive",
          "scale_factor"
        ) |>
        dplyr::mutate(
          n_records_v1 = base::length(vec_values_v1),
          n_selected_v1 = base::sum(is_selected_v1, na.rm = TRUE),
          median_v1 = stats::median(vec_values_v1),
          n_records_v2 = base::length(vec_values_v2),
          n_selected_v2 = base::sum(is_selected_v2, na.rm = TRUE),
          n_nonpositive_v2 = base::sum(vec_values_v2 <= 0, na.rm = TRUE),
          median_v2 = stats::median(vec_values_v2)
        )
    }
  ) |>
  purrr::list_rbind()

readr::write_csv(
  data_decision_evidence,
  base::file.path(dir_evidence, "trait_v1_review_decision_evidence.csv"),
  na = ""
)


#----------------------------------------------------------#
# 4. Report and stop on a rule that is not retired -----
#----------------------------------------------------------#

data_rule_retirement |>
  dplyr::select(
    "expected_data_source_desc",
    "trait_domain_name",
    "scale_factor",
    "data_source_id_after",
    "n_taxa_shared",
    "ratio_source",
    "ratio_reference",
    "scale_exponent",
    "retirement_status"
  ) |>
  base::print(n = Inf, width = Inf)

data_decision_evidence |>
  dplyr::summarise(
    n_decisions = dplyr::n(),
    n_with_v2_records = base::sum(.data[["n_records_v2"]] > 0L),
    n_selecting_v2_records = base::sum(.data[["n_selected_v2"]] > 0L),
    n_with_v2_nonpositive = base::sum(.data[["n_nonpositive_v2"]] > 0L),
    .by = "action"
  ) |>
  base::print()

vec_rules_not_retired <-
  data_rule_retirement |>
  dplyr::filter(
    .data[["retirement_status"]] %in%
      base::c("still_unscaled", "unresolved")
  ) |>
  dplyr::pull("expected_data_source_desc")

if (
  base::length(vec_rules_not_retired) > 0L
) {
  cli::cli_abort(
    c(
      "VegVault 1.0.0 source rules are not retired by VegVault 2.0.0.",
      "x" = "{.val {vec_rules_not_retired}}",
      "i" = stringr::str_c(
        "Correct the source in VegVault, or add a 2.0.0 rule keyed to ",
        "its 2.0.0 source id."
      )
    )
  )
}

cli::cli_inform(
  c(
    "v" = stringr::str_c(
      "Every VegVault 1.0.0 source rule is fixed at the source or ",
      "absent from VegVault 2.0.0."
    )
  )
)
