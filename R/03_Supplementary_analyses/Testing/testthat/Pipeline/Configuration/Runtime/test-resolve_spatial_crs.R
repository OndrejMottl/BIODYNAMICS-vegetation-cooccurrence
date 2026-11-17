write_test_spatial_grid <- function() {
  file_grid <-
    base::tempfile(fileext = ".csv")
  readr::write_csv(
    x = tibble::tibble(
      scale_id = base::c("europe", "eu_r001", "am_r001_l001"),
      scale = base::c("continental", "regional", "local"),
      parent_id = base::c(NA, "europe", "am_r001"),
      continent_id = base::c("europe", "europe", "america")
    ),
    file = file_grid
  )
  return(file_grid)
}

list_test_crs <-
  base::list(
    europe = 3035L,
    america = "+proj=aeqd +lat_0=50 +lon_0=-95 +datum=WGS84 +units=m +no_defs"
  )

testthat::test_that(
  "resolve_spatial_crs() maps spatial units through their continent",
  {
    file_grid <-
      write_test_spatial_grid()

    testthat::expect_identical(
      resolve_spatial_crs(
        scale_id = "eu_r001",
        crs_by_continent = list_test_crs,
        file_spatial_grid = file_grid
      ),
      3035L
    )
    testthat::expect_identical(
      resolve_spatial_crs(
        scale_id = "am_r001_l001",
        crs_by_continent = list_test_crs,
        file_spatial_grid = file_grid
      ),
      list_test_crs[["america"]]
    )
  }
)

testthat::test_that(
  "resolve_spatial_crs() uses the profile continent without a unit",
  {
    testthat::expect_identical(
      resolve_spatial_crs(
        continent_id = "america",
        crs_by_continent = list_test_crs
      ),
      list_test_crs[["america"]]
    )
  }
)

testthat::test_that(
  "resolve_spatial_crs() aborts instead of falling back",
  {
    file_grid <-
      write_test_spatial_grid()

    testthat::expect_error(
      resolve_spatial_crs(crs_by_continent = list_test_crs),
      class = "spatial_crs_continent_missing"
    )
    testthat::expect_error(
      resolve_spatial_crs(
        continent_id = "asia",
        crs_by_continent = list_test_crs
      ),
      class = "spatial_crs_projection_missing"
    )
    testthat::expect_error(
      resolve_spatial_crs(
        scale_id = "eu_r001",
        continent_id = "america",
        crs_by_continent = list_test_crs,
        file_spatial_grid = file_grid
      ),
      class = "spatial_crs_continent_conflict"
    )
    testthat::expect_error(
      resolve_spatial_crs(continent_id = "europe", crs_by_continent = 3035L),
      "named list"
    )
  }
)
