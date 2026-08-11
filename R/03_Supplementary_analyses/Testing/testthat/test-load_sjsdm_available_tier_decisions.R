make_available_decision_context <- function() {
  res <-
    tibble::tibble(
      tier_id = "continental",
      taxonomic_resolution = "genus",
      response_family = "binomial",
      predictor_structure = "abiotic_spatial",
      candidate_table_hash = "hash_001"
    )

  return(res)
}

testthat::test_that(
  "load_sjsdm_available_tier_decisions() reads a prefix",
  {
    read_meta_function <- function(store_path) {
      tibble::tibble(
        name = base::c(
          "data_sjsdm_tier_survivor_decisions_round_1",
          "unrelated_target"
        ),
        error = NA_character_
      )
    }

    read_decision_function <- function(
        store_path,
        data_model_context,
        round_id) {
      tibble::tibble(
        round_id = round_id,
        candidate_id = "candidate_001",
        staged_decision = "survive"
      )
    }

    res <-
      load_sjsdm_available_tier_decisions(
        store_path = "tier_store",
        data_model_context = make_available_decision_context(),
        n_non_final_rounds = 2L,
        read_meta_function = read_meta_function,
        read_decision_function = read_decision_function
      )

    testthat::expect_length(res, 1L)
    testthat::expect_identical(res[[1L]][["round_id"]], 1L)
  }
)

testthat::test_that(
  "load_sjsdm_available_tier_decisions() allows no decisions",
  {
    read_meta_function <- function(store_path) {
      NULL
    }

    res <-
      load_sjsdm_available_tier_decisions(
        store_path = "tier_store",
        data_model_context = make_available_decision_context(),
        n_non_final_rounds = 2L,
        read_meta_function = read_meta_function
      )

    testthat::expect_length(res, 0L)
  }
)

testthat::test_that(
  "load_sjsdm_available_tier_decisions() rejects gaps",
  {
    read_meta_function <- function(store_path) {
      tibble::tibble(
        name = "data_sjsdm_tier_survivor_decisions_round_2",
        error = NA_character_
      )
    }

    testthat::expect_error(
      load_sjsdm_available_tier_decisions(
        store_path = "tier_store",
        data_model_context = make_available_decision_context(),
        n_non_final_rounds = 2L,
        read_meta_function = read_meta_function
      ),
      "gap"
    )
  }
)

testthat::test_that(
  "load_sjsdm_available_tier_decisions() rejects failed targets",
  {
    read_meta_function <- function(store_path) {
      tibble::tibble(
        name = "data_sjsdm_tier_survivor_decisions_round_1",
        error = "tier aggregation failed"
      )
    }

    testthat::expect_error(
      load_sjsdm_available_tier_decisions(
        store_path = "tier_store",
        data_model_context = make_available_decision_context(),
        n_non_final_rounds = 2L,
        read_meta_function = read_meta_function
      ),
      "errored"
    )
  }
)
