testthat::test_that(
  "read_sjsdm_tier_survivor_decisions() selects one context",
  {
    data_context <-
      tibble::tibble(
        tier_id = "continental",
        taxonomic_resolution = "genus",
        response_family = "binomial",
        predictor_structure = "abiotic_spatial",
        candidate_table_hash = "hash_001"
      )

    read_target_function <- function(name, store) {
      testthat::expect_identical(
        name,
        "data_sjsdm_tier_survivor_decisions_round_1"
      )
      testthat::expect_identical(store, "tier_store")

      tidyr::crossing(
        tier_id = "continental",
        taxonomic_resolution = base::c("family", "genus"),
        response_family = "binomial",
        predictor_structure = "abiotic_spatial",
        candidate_table_hash = "hash_001",
        round_id = 1L,
        candidate_id = base::c("candidate_001", "candidate_002")
      ) |>
      dplyr::mutate(
        staged_decision = base::rep(
          base::c("survive", "prune"),
          times = 2L
        )
      )
    }

    res <-
      read_sjsdm_tier_survivor_decisions(
        store_path = "tier_store",
        data_model_context = data_context,
        round_id = 1L,
        read_target_function = read_target_function
      )

    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_identical(
      base::unique(res[["taxonomic_resolution"]]),
      "genus"
    )
  }
)

testthat::test_that(
  "read_sjsdm_tier_survivor_decisions() fails closed",
  {
    data_context <-
      tibble::tibble(
        tier_id = "continental",
        taxonomic_resolution = "genus",
        response_family = "binomial",
        predictor_structure = "abiotic_spatial",
        candidate_table_hash = "hash_001"
      )

    read_missing_target <- function(name, store) {
      base::stop("missing target")
    }

    testthat::expect_error(
      read_sjsdm_tier_survivor_decisions(
        store_path = "tier_store",
        data_model_context = data_context,
        round_id = 1L,
        read_target_function = read_missing_target
      ),
      "Could not read tier survivor decisions"
    )

    read_wrong_context <- function(name, store) {
      data_context |>
        dplyr::mutate(
          taxonomic_resolution = "family",
          round_id = 1L,
          candidate_id = "candidate_001",
          staged_decision = "survive"
        )
    }

    testthat::expect_error(
      read_sjsdm_tier_survivor_decisions(
        store_path = "tier_store",
        data_model_context = data_context,
        round_id = 1L,
        read_target_function = read_wrong_context
      ),
      "No tier survivor decisions match"
    )
  }
)
