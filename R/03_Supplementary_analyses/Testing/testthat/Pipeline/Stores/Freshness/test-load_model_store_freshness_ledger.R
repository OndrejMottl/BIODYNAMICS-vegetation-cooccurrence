write_test_ledger <- function(vec_lines) {
  file_ledger <-
    base::tempfile(fileext = ".csv")
  base::writeLines(text = vec_lines, con = file_ledger)
  return(file_ledger)
}

testthat::test_that(
  "load_model_store_freshness_ledger() reads a header-only ledger",
  {
    res <-
      load_model_store_freshness_ledger(
        file = write_test_ledger(
          "store_path,target_pattern,reason,evidence,owner,expiry_issue"
        )
      )

    testthat::expect_equal(base::nrow(res), 0L)
    testthat::expect_equal(
      base::names(res),
      base::c(
        "store_path",
        "target_pattern",
        "reason",
        "evidence",
        "owner",
        "expiry_issue"
      )
    )
  }
)

testthat::test_that(
  "load_model_store_freshness_ledger() reads complete rows",
  {
    res <-
      load_model_store_freshness_ledger(
        file = write_test_ledger(
          base::c(
            "store_path,target_pattern,reason,evidence,owner,expiry_issue",
            "Data/targets/a/p,list_jsdm_variance_partition_.*,r,e,o,#1"
          )
        )
      )

    testthat::expect_equal(base::nrow(res), 1L)
    testthat::expect_equal(
      res[["target_pattern"]],
      "list_jsdm_variance_partition_.*"
    )
  }
)

testthat::test_that(
  "load_model_store_freshness_ledger() rejects invalid ledgers",
  {
    testthat::expect_error(
      load_model_store_freshness_ledger(
        file = write_test_ledger("store_path,target_pattern")
      ),
      "exactly these columns"
    )
    testthat::expect_error(
      load_model_store_freshness_ledger(
        file = write_test_ledger(
          base::c(
            "store_path,target_pattern,reason,evidence,owner,expiry_issue",
            "Data/targets/a/p,mod_.*,r,,o,#1"
          )
        )
      ),
      class = "model_store_ledger_incomplete"
    )
    testthat::expect_error(
      load_model_store_freshness_ledger(
        file = write_test_ledger(
          base::c(
            "store_path,target_pattern,reason,evidence,owner,expiry_issue",
            "Data/targets/a/p,mod_.*,r,e,o,#1",
            "Data/targets/a/p,mod_.*,r2,e2,o2,#2"
          )
        )
      ),
      class = "model_store_ledger_duplicate"
    )
    testthat::expect_error(
      load_model_store_freshness_ledger(
        file = write_test_ledger(
          base::c(
            "store_path,target_pattern,reason,evidence,owner,expiry_issue",
            "Data/targets/a/p,mod_(,r,e,o,#1"
          )
        )
      ),
      class = "model_store_ledger_invalid_pattern"
    )
    testthat::expect_error(
      load_model_store_freshness_ledger(file = "no_such_ledger.csv"),
      "existing ledger"
    )
  }
)
