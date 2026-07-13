testthat::test_that(
  "collect_sjsdm_tuning_summaries() reads successful unit summaries",
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

    testthat::expect_equal(base::nrow(res), 3L)
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
