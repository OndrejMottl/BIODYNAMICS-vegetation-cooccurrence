testthat::test_that("target requests retain only viable resolutions", {
  data_plan <-
    tibble::tibble(scale_id = base::c("b", "b", "a", "a"),
      resolution_id = base::rep(base::c("genus", "family"), 2L),
      fitting_status = base::c("expected_infeasible", "eligible",
        "expected_infeasible", "expected_infeasible"))
  res <-
    build_sjsdm_unit_fitting_targets(data_plan,
      base::c("mod_jsdm_genus", "mod_jsdm_family", "shared_input"))
  testthat::expect_identical(res,
    base::list(b = "mod_jsdm_family", a = base::character()))
})

testthat::test_that("unresolved target requests fail closed", {
  testthat::expect_error(
    build_sjsdm_unit_fitting_targets(
      tibble::tibble(scale_id = "a", resolution_id = "genus",
        fitting_status = "error"), "mod_jsdm_genus"),
    "classified"
  )
})
