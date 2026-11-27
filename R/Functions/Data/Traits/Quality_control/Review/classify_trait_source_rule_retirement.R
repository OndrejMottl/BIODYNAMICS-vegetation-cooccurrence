#' @title Classify Trait Source Rule Retirement
#' @description
#' Classifies each whole-source scaling rule of one VegVault release by
#' whether a later release already corrects the source, so that the rule can
#' be retired without scaling the source twice.
#' @param data_source_scale_rules
#' Rules of the earlier release with `source_scale_rule_id`,
#' `data_source_id`, `expected_data_source_desc`, `trait_domain_name`,
#' `trait_name`, and `scale_factor`.
#' @param data_trait_records_before
#' Unscaled trait records of the earlier release with `data_source_id`,
#' `taxon_name`, `trait_domain_name`, `trait_name`, and `trait_value`.
#' @param data_trait_records_after
#' Trait records of the later release with the same columns. Their
#' `data_source_id` values use the numbering of the later release.
#' @param data_sources_after
#' Data sources of the later release with `data_source_id` and
#' `data_source_desc`.
#' @param min_shared_taxa
#' Integer scalar. The fewest taxa a rule's source must share between the
#' releases before it is classified (default `3L`).
#' @param exponent_tolerance
#' Numeric scalar between 0 and 0.5. How far the scale exponent may lie from
#' 1 or 0 for `fixed_at_source` or `still_unscaled` (default `0.25`).
#' @return
#' A tibble with one row per rule: the rule fields, `data_source_id_after`,
#' `n_taxa_before`, `n_taxa_after`, `n_taxa_shared`, `ratio_source`,
#' `ratio_reference`, `scale_exponent`, and `retirement_status`.
#' @details
#' Data source ids are not stable between releases, so a rule's source is
#' found in the later release by its exact description. For the rule's
#' source and, separately, for all sources of the same domain (and trait
#' name, when the rule names one) that no rule names, the function takes the
#' median
#' value per taxon in each release and the median over shared taxa of the
#' ratio later / earlier (`ratio_source`, `ratio_reference`). Dividing the
#' two removes any unit change that the later release applied to the whole
#' domain. `scale_exponent` is the logarithm of that quotient in the base of
#' the rule's `scale_factor`:
#'
#'   * `fixed_at_source`: the exponent lies within `exponent_tolerance` of
#'     1, so the later release applies the rule's factor itself;
#'   * `still_unscaled`: the exponent lies within `exponent_tolerance` of
#'     0, so the source keeps its earlier scale;
#'   * `absent_from_release`: the source has no records of the rule's
#'     domain in the later release, or its description is not found;
#'   * `unresolved`: fewer than `min_shared_taxa` shared taxa, or an
#'     exponent near neither 0 nor 1.
#'
#' Only positive per-taxon medians enter the ratios.
#' @seealso [validate_trait_source_scale_rules()],
#'   [apply_trait_source_scale_rules()]
#' @export
classify_trait_source_rule_retirement <- function(
    data_source_scale_rules,
    data_trait_records_before,
    data_trait_records_after,
    data_sources_after,
    min_shared_taxa = 3L,
    exponent_tolerance = 0.25) {
  assertthat::assert_that(
    base::is.data.frame(data_source_scale_rules),
    base::is.data.frame(data_trait_records_before),
    base::is.data.frame(data_trait_records_after),
    base::is.data.frame(data_sources_after),
    msg = "Rules, records, and data sources must be data frames."
  )

  vec_rule_columns <-
    base::c(
      "source_scale_rule_id",
      "data_source_id",
      "expected_data_source_desc",
      "trait_domain_name",
      "trait_name",
      "scale_factor"
    )
  vec_record_columns <-
    base::c(
      "data_source_id",
      "taxon_name",
      "trait_domain_name",
      "trait_name",
      "trait_value"
    )
  assertthat::assert_that(
    base::all(vec_rule_columns %in% base::names(data_source_scale_rules)),
    base::all(
      vec_record_columns %in% base::names(data_trait_records_before)
    ),
    base::all(
      vec_record_columns %in% base::names(data_trait_records_after)
    ),
    base::all(
      base::c("data_source_id", "data_source_desc") %in%
        base::names(data_sources_after)
    ),
    msg = "Rules, records, or data sources are missing required columns."
  )
  assertthat::assert_that(
    base::is.numeric(min_shared_taxa) &&
      base::length(min_shared_taxa) == 1L &&
      !base::is.na(min_shared_taxa) &&
      min_shared_taxa >= 1,
    msg = "'min_shared_taxa' must be a single number of at least 1."
  )
  assertthat::assert_that(
    base::is.numeric(exponent_tolerance) &&
      base::length(exponent_tolerance) == 1L &&
      !base::is.na(exponent_tolerance) &&
      exponent_tolerance > 0 &&
      exponent_tolerance < 0.5,
    msg = "'exponent_tolerance' must be a single number in (0, 0.5)."
  )

  # Sources named by any rule carry the scale errors in one release only,
  #   so they never enter the reference group
  vec_rule_sources_before <-
    data_source_scale_rules[["data_source_id"]]
  vec_rule_sources_after <-
    data_sources_after[["data_source_id"]][
      data_sources_after[["data_source_desc"]] %in%
        data_source_scale_rules[["expected_data_source_desc"]]
    ]

  data_rule_summary <-
    base::seq_len(base::nrow(data_source_scale_rules)) |>
    purrr::map(
      .f = ~ {
        data_rule <-
          data_source_scale_rules[.x, , drop = FALSE]
        rule_source_before <- data_rule[["data_source_id"]][[1L]]
        rule_domain <- data_rule[["trait_domain_name"]][[1L]]
        rule_trait_name <- data_rule[["trait_name"]][[1L]]
        rule_scale_factor <- data_rule[["scale_factor"]][[1L]]

        vec_source_after <-
          data_sources_after[["data_source_id"]][
            data_sources_after[["data_source_desc"]] %in%
              data_rule[["expected_data_source_desc"]][[1L]]
          ]

        if (
          base::length(vec_source_after) > 1L
        ) {
          cli::cli_abort(
            c(
              "A rule's source description names more than one source.",
              "x" = "{.val {data_rule[['expected_data_source_desc']]}}"
            )
          )
        }

        rule_source_after <-
          base::c(vec_source_after, NA)[[1L]]
        flag_filter_trait_name <-
          !base::is.na(rule_trait_name) && base::nzchar(rule_trait_name)

        # Median per taxon, for the rule's source and for the reference
        #   sources of the domain together, in each release
        data_medians_before <-
          data_trait_records_before |>
          dplyr::filter(
            .data[["trait_domain_name"]] == rule_domain,
            !flag_filter_trait_name |
              .data[["trait_name"]] == rule_trait_name
          ) |>
          dplyr::mutate(
            is_rule_source = dplyr::coalesce(
              .data[["data_source_id"]] == rule_source_before,
              FALSE
            )
          ) |>
          dplyr::filter(
            .data[["is_rule_source"]] |
              !.data[["data_source_id"]] %in% vec_rule_sources_before
          ) |>
          dplyr::summarise(
            median_before = stats::median(.data[["trait_value"]]),
            .by = dplyr::all_of(base::c("is_rule_source", "taxon_name"))
          ) |>
          dplyr::filter(.data[["median_before"]] > 0)

        data_medians_after <-
          data_trait_records_after |>
          dplyr::filter(
            .data[["trait_domain_name"]] == rule_domain,
            !flag_filter_trait_name |
              .data[["trait_name"]] == rule_trait_name
          ) |>
          dplyr::mutate(
            is_rule_source = dplyr::coalesce(
              .data[["data_source_id"]] == rule_source_after,
              FALSE
            )
          ) |>
          dplyr::filter(
            .data[["is_rule_source"]] |
              !.data[["data_source_id"]] %in% vec_rule_sources_after
          ) |>
          dplyr::summarise(
            median_after = stats::median(.data[["trait_value"]]),
            .by = dplyr::all_of(base::c("is_rule_source", "taxon_name"))
          ) |>
          dplyr::filter(.data[["median_after"]] > 0)

        data_ratios <-
          dplyr::inner_join(
            data_medians_before,
            data_medians_after,
            by = dplyr::join_by("is_rule_source", "taxon_name")
          ) |>
          dplyr::mutate(
            ratio = .data[["median_after"]] / .data[["median_before"]]
          )

        vec_ratio_source <-
          data_ratios[["ratio"]][data_ratios[["is_rule_source"]]]
        vec_ratio_reference <-
          data_ratios[["ratio"]][!data_ratios[["is_rule_source"]]]

        ratio_source <-
          stats::median(vec_ratio_source)
        ratio_reference <-
          stats::median(vec_ratio_reference)
        scale_exponent <-
          base::log(ratio_source / ratio_reference) /
          base::log(rule_scale_factor)

        n_taxa_after <-
          base::sum(data_medians_after[["is_rule_source"]])
        n_taxa_shared <-
          base::length(vec_ratio_source)

        retirement_status <-
          dplyr::case_when(
            base::is.na(rule_source_after) | n_taxa_after == 0L ~
              "absent_from_release",
            n_taxa_shared < min_shared_taxa |
              !base::is.finite(scale_exponent) ~
              "unresolved",
            base::abs(scale_exponent - 1) <= exponent_tolerance ~
              "fixed_at_source",
            base::abs(scale_exponent) <= exponent_tolerance ~
              "still_unscaled",
            .default = "unresolved"
          )

        data_rule |>
          dplyr::select(dplyr::all_of(vec_rule_columns)) |>
          dplyr::mutate(
            data_source_id_after = base::as.integer(rule_source_after),
            n_taxa_before = base::as.integer(
              base::sum(data_medians_before[["is_rule_source"]])
            ),
            n_taxa_after = base::as.integer(n_taxa_after),
            n_taxa_shared = base::as.integer(n_taxa_shared),
            ratio_source = ratio_source,
            ratio_reference = ratio_reference,
            scale_exponent = scale_exponent,
            retirement_status = retirement_status
          )
      }
    ) |>
    purrr::list_rbind()

  res_rule_retirement <-
    tibble::as_tibble(data_rule_summary)

  return(res_rule_retirement)
}
