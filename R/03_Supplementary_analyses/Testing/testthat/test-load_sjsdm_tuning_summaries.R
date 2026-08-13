testthat::test_that(
  "load_sjsdm_tuning_summaries() reads every native v2 summary",
  {
    read_target_function <- function(name, store) {
      make_sjsdm_tuning_artifact_fixture(
        source_id = base::basename(store),
        taxonomic_resolution = stringr::str_remove(
          name,
          "^list_sjsdm_cv_tuning_artifact_"
        )
      )
    }

    res <-
      load_sjsdm_tuning_summaries(
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
  "load_sjsdm_tuning_summaries() rejects raw v1 tables",
  {
    testthat::expect_error(
      load_sjsdm_tuning_summaries(
        store_paths = "legacy_store",
        resolution_ids = "genus",
        read_target_function = function(name, store) {
          tibble::tibble(
            source_id = "unit",
            candidate_id = "candidate_001"
          )
        }
      ),
      "exact v2 envelope"
    )
  }
)

testthat::test_that(
  "load_sjsdm_tuning_summaries() rejects partial evidence",
  {
    read_target_function <- function(name, store) {
      if (
        store == "store_b" &&
          name == "list_sjsdm_cv_tuning_artifact_family"
      ) {
        base::stop("target unavailable")
      }

      make_sjsdm_tuning_artifact_fixture()
    }

    error_condition <-
      testthat::expect_error(
        load_sjsdm_tuning_summaries(
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
    testthat::expect_match(error_message, "store_b", fixed = TRUE)
    testthat::expect_match(
      error_message,
      "list_sjsdm_cv_tuning_artifact_family",
      fixed = TRUE
    )
  }
)

testthat::test_that(
  "load_sjsdm_tuning_summaries() validates inputs",
  {
    testthat::expect_error(
      load_sjsdm_tuning_summaries(
        store_paths = base::character(),
        resolution_ids = "genus"
      ),
      "store_paths"
    )
  }
)

testthat::test_that(
  "load_sjsdm_tuning_summaries() identifies temporal branches",
  {
    res <-
      load_sjsdm_tuning_summaries(
        store_paths = "temporal_store",
        resolution_ids = base::c("timeslice_0", "timeslice_500"),
        read_target_function = function(name, store) {
          make_sjsdm_tuning_artifact_fixture(source_id = "unit")
        }
      )

    testthat::expect_setequal(
      res[["source_id"]],
      base::c("timeslice_0", "timeslice_500")
    )
  }
)

testthat::test_that(
  "load_sjsdm_tuning_summaries() reads explicit round targets",
  {
    environment_reads <-
      base::new.env(parent = base::emptyenv())
    environment_reads[["names"]] <- base::character()

    res <-
      load_sjsdm_tuning_summaries(
        store_paths = "store_a",
        resolution_ids = base::c("genus", "family"),
        target_prefix =
          "list_sjsdm_cv_tuning_artifact_round_2",
        read_target_function = function(name, store) {
          environment_reads[["names"]] <-
            base::c(environment_reads[["names"]], name)
          make_sjsdm_tuning_artifact_fixture()
        }
      )

    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_setequal(
      environment_reads[["names"]],
      base::c(
        "list_sjsdm_cv_tuning_artifact_round_2_genus",
        "list_sjsdm_cv_tuning_artifact_round_2_family"
      )
    )
  }
)

testthat::test_that(
  "load_sjsdm_tuning_summaries() reads exact direct-unit targets",
  {
    environment_reads <-
      base::new.env(parent = base::emptyenv())
    environment_reads[["names"]] <- base::character()

    res <-
      load_sjsdm_tuning_summaries(
        store_paths = "direct_store",
        resolution_ids = "genus",
        target_names = "list_sjsdm_cv_tuning_artifact",
        read_target_function = function(name, store) {
          environment_reads[["names"]] <-
            base::c(environment_reads[["names"]], name)
          make_sjsdm_tuning_artifact_fixture()
        }
      )

    testthat::expect_identical(
      environment_reads[["names"]],
      "list_sjsdm_cv_tuning_artifact"
    )
    testthat::expect_identical(res[["resolution_id"]], "genus")
  }
)

testthat::test_that(
  "load_sjsdm_tuning_summaries() validates the target prefix",
  {
    testthat::expect_error(
      load_sjsdm_tuning_summaries(
        store_paths = "store_a",
        resolution_ids = "genus",
        target_prefix = base::character()
      ),
      "target_prefix"
    )
  }
)
