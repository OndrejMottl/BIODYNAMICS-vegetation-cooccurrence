testthat::test_that(
  "collect_sjsdm_tuning_summaries() reads every requested summary",
  {
    read_target_function <- function(name, store) {
      tibble::tibble(
        source_id = base::basename(store),
        taxonomic_resolution = stringr::str_remove(
          name,
          "^data_sjsdm_tuning_summary_"
        ),
        candidate_id = "candidate_001"
      )
    }

    res <-
      collect_sjsdm_tuning_summaries(
        store_paths = base::c("store_a", "store_b"),
        resolution_ids = base::c("genus", "family"),
        read_target_function = read_target_function
      )

    testthat::expect_equal(base::nrow(res), 4L)
    testthat::expect_setequal(
      res[["source_store"]],
      base::c("store_a", "store_b")
    )
    testthat::expect_setequal(
      res[["resolution_id"]],
      base::c("genus", "family")
    )
  }
)

testthat::test_that(
  "collect_sjsdm_tuning_summaries() rejects partial evidence",
  {
    read_target_function <- function(name, store) {
      if (
        store == "store_b" &&
          name == "data_sjsdm_tuning_summary_family"
      ) {
        base::stop("target unavailable")
      }

      tibble::tibble(
        source_id = base::basename(store),
        candidate_id = "candidate_001"
      )
    }

    error_condition <-
      testthat::expect_error(
        collect_sjsdm_tuning_summaries(
          store_paths = base::c("store_a", "store_b"),
          resolution_ids = base::c("genus", "family"),
          read_target_function = read_target_function
        )
      )

    error_message <-
      base::conditionMessage(error_condition)

    testthat::expect_match(
      error_message,
      "Could not read every requested tuning summary",
      fixed = TRUE
    )
    testthat::expect_match(
      error_message,
      "store_b",
      fixed = TRUE
    )
    testthat::expect_match(
      error_message,
      "data_sjsdm_tuning_summary_family",
      fixed = TRUE
    )
  }
)

testthat::test_that(
  "collect_sjsdm_tuning_summaries() validates inputs",
  {
    testthat::expect_error(
      collect_sjsdm_tuning_summaries(
        store_paths = base::character(),
        resolution_ids = "genus"
      ),
      "store_paths"
    )
  }
)

testthat::test_that(
  "collect_sjsdm_tuning_summaries() identifies temporal branches",
  {
    read_target_function <- function(name, store) {
      tibble::tibble(
        source_id = "unit",
        candidate_id = "candidate_001"
      )
    }

    res <-
      collect_sjsdm_tuning_summaries(
        store_paths = "temporal_store",
        resolution_ids = base::c("timeslice_0", "timeslice_500"),
        read_target_function = read_target_function
      )

    testthat::expect_setequal(
      res[["source_id"]],
      base::c("timeslice_0", "timeslice_500")
    )
  }
)

testthat::test_that(
  "collect_sjsdm_tuning_summaries() reads explicit round targets",
  {
    environment_reads <-
      base::new.env(parent = base::emptyenv())

    environment_reads[["names"]] <-
      base::character()

    read_target_function <- function(name, store) {
      environment_reads[["names"]] <-
        base::c(environment_reads[["names"]], name)

      tibble::tibble(
        source_id = base::basename(store),
        candidate_id = "candidate_001"
      )
    }

    res <-
      collect_sjsdm_tuning_summaries(
        store_paths = "store_a",
        resolution_ids = base::c("genus", "family"),
        target_prefix = "data_sjsdm_tuning_summary_round_2",
        read_target_function = read_target_function
      )

    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_setequal(
      environment_reads[["names"]],
      base::c(
        "data_sjsdm_tuning_summary_round_2_genus",
        "data_sjsdm_tuning_summary_round_2_family"
      )
    )
  }
)

testthat::test_that(
  "collect_sjsdm_tuning_summaries() validates the target prefix",
  {
    testthat::expect_error(
      collect_sjsdm_tuning_summaries(
        store_paths = "store_a",
        resolution_ids = "genus",
        target_prefix = base::character()
      ),
      "target_prefix"
    )
  }
)
