build_test_findings <- function() {
  tibble::tibble(
    store_path = "/abs/Data/targets/a/pipeline",
    store_path_relative = "Data/targets/a/pipeline",
    target_name = base::c(
      "list_jsdm_variance_partition_genus",
      "mod_jsdm_genus",
      "data_progress"
    ),
    finding_type = base::c(
      "outdated",
      "outdated",
      "always_cued_not_evaluated"
    ),
    flag_blocking = base::c(TRUE, TRUE, FALSE),
    detail = NA_character_
  )
}

build_test_ledger <- function(vec_patterns, vec_stores = NULL) {
  vec_store_paths <-
    if (
      base::is.null(vec_stores)
    ) {
      base::rep("Data/targets/a/pipeline", base::length(vec_patterns))
    } else {
      vec_stores
    }
  tibble::tibble(
    store_path = vec_store_paths,
    target_pattern = vec_patterns,
    reason = "reason",
    evidence = "evidence",
    owner = "owner",
    expiry_issue = "#999"
  )
}

testthat::test_that(
  "apply_model_store_freshness_ledger() covers matching targets only",
  {
    res <-
      apply_model_store_freshness_ledger(
        data_findings = build_test_findings(),
        data_ledger = build_test_ledger("list_jsdm_variance_partition_.*"),
        vec_inspected_store_paths = "Data/targets/a/pipeline"
      )

    testthat::expect_equal(
      res[["resolution_status"]],
      base::c("ledger_covered", "blocking", "informational")
    )
  }
)

testthat::test_that(
  "apply_model_store_freshness_ledger() matches whole target names",
  {
    res <-
      apply_model_store_freshness_ledger(
        data_findings = build_test_findings(),
        data_ledger = build_test_ledger("mod_jsdm"),
        vec_inspected_store_paths = "Data/targets/a/pipeline"
      )

    testthat::expect_equal(
      res[["resolution_status"]][res[["target_name"]] == "mod_jsdm_genus"],
      "blocking"
    )
    testthat::expect_true("stale_ledger_row" %in% res[["finding_type"]])
  }
)

testthat::test_that(
  "apply_model_store_freshness_ledger() reports stale rows of inspected stores",
  {
    res <-
      apply_model_store_freshness_ledger(
        data_findings = build_test_findings(),
        data_ledger = build_test_ledger(
          vec_patterns = base::c("data_never_.*", "data_other_.*"),
          vec_stores = base::c(
            "Data/targets/a/pipeline",
            "Data/targets/not_inspected/pipeline"
          )
        ),
        vec_inspected_store_paths = "Data/targets/a/pipeline"
      )

    data_stale <-
      res |>
      dplyr::filter(.data[["finding_type"]] == "stale_ledger_row")

    testthat::expect_equal(base::nrow(data_stale), 1L)
    testthat::expect_equal(data_stale[["target_name"]], "data_never_.*")
    testthat::expect_equal(data_stale[["resolution_status"]], "blocking")
  }
)

testthat::test_that(
  "apply_model_store_freshness_ledger() validates its inputs",
  {
    testthat::expect_error(
      apply_model_store_freshness_ledger(
        data_findings = tibble::tibble(target_name = "a"),
        data_ledger = build_test_ledger("a"),
        vec_inspected_store_paths = "Data/targets/a/pipeline"
      ),
      "findings schema"
    )
    testthat::expect_error(
      apply_model_store_freshness_ledger(
        data_findings = build_test_findings(),
        data_ledger = tibble::tibble(store_path = "a"),
        vec_inspected_store_paths = "Data/targets/a/pipeline"
      ),
      "ledger schema"
    )
  }
)
