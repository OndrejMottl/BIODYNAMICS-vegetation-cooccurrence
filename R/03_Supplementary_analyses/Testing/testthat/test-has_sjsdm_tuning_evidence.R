testthat::test_that(
  "has_sjsdm_tuning_evidence() checks every requested summary",
  {
    environment_reads <- base::new.env(parent = base::emptyenv())
    environment_reads[["keys"]] <- base::character()

    read_target_function <- function(name, store) {
      environment_reads[["keys"]] <-
        base::c(
          environment_reads[["keys"]],
          stringr::str_c(store, name, sep = " ")
        )

      if (
        store == "store_b" && name == "summary_family"
      ) {
        return(tibble::tibble(candidate_id = "candidate_1"))
      }

      return(tibble::tibble(candidate_id = base::character()))
    }

    res <-
      has_sjsdm_tuning_evidence(
        store_paths = base::c("store_a", "store_b"),
        target_names = base::c("summary_genus", "summary_family"),
        read_target_function = read_target_function
      )

    testthat::expect_true(res)
    testthat::expect_setequal(
      environment_reads[["keys"]],
      base::c(
        "store_a summary_genus",
        "store_a summary_family",
        "store_b summary_genus",
        "store_b summary_family"
      )
    )
  }
)

testthat::test_that(
  "has_sjsdm_tuning_evidence() recognizes complete empty evidence",
  {
    res <-
      has_sjsdm_tuning_evidence(
        store_paths = "store_a",
        target_names = base::c("summary_genus", "summary_family"),
        read_target_function = function(name, store) {
          tibble::tibble(candidate_id = base::character())
        }
      )

    testthat::expect_false(res)
  }
)

testthat::test_that(
  "has_sjsdm_tuning_evidence() fails closed",
  {
    testthat::expect_error(
      has_sjsdm_tuning_evidence(
        store_paths = "store_a",
        target_names = "summary_genus",
        read_target_function = function(name, store) {
          base::stop("missing target")
        }
      ),
      "Could not read every requested tuning summary"
    )

    testthat::expect_error(
      has_sjsdm_tuning_evidence(
        store_paths = "store_a",
        target_names = "summary_genus",
        read_target_function = function(name, store) {
          "not a data frame"
        }
      ),
      "must be data frames"
    )
  }
)

testthat::test_that(
  "has_sjsdm_tuning_evidence() validates inputs",
  {
    testthat::expect_error(
      has_sjsdm_tuning_evidence(
        store_paths = base::character(),
        target_names = "summary"
      ),
      "store_paths"
    )
    testthat::expect_error(
      has_sjsdm_tuning_evidence(
        store_paths = "store",
        target_names = base::character()
      ),
      "target_names"
    )
  }
)
