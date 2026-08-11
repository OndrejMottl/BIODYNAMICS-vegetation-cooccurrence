testthat::test_that(
  "repository architecture has no blocking findings",
  {
    path_checker <-
      here::here(
        "R/03_Supplementary_analyses/Validation/Architecture/",
        "check_r_architecture.R"
      )

    result <-
      processx::run(
        command = "Rscript",
        args = path_checker,
        echo = FALSE,
        error_on_status = FALSE
      )

    testthat::expect_equal(
      result[["status"]],
      0L,
      info = stringr::str_c(
        result[["stdout"]],
        result[["stderr"]],
        sep = "\n"
      )
    )
  }
)
