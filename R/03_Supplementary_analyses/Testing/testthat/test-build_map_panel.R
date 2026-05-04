#----------------------------------------------------------#
# Shared fixtures -----
#----------------------------------------------------------#

# Minimal sf world polygon covering entire globe
sf_world_fixture <-
  sf::st_sf(
    name = "world",
    geometry = sf::st_sfc(
      sf::st_polygon(
        base::list(
          base::cbind(
            c(-180, 180, 180, -180, -180),
            c(-90, -90, 90, 90, -90)
          )
        )
      )
    ),
    crs = 4326
  )

# Grid with two europe × continental × genus cells
data_grid_fixture <-
  tibble::tibble(
    continent = c("europe", "europe"),
    scale = c("continental", "continental"),
    taxonomic_resolution = c("genus", "family"),
    x_min = c(10, 10),
    x_max = c(20, 20),
    y_min = c(45, 45),
    y_max = c(55, 55),
    assoc_pct = c(60, 40)
  )

# Coords with one fossil core in europe × continental
data_coords_with_cores <-
  tibble::tibble(
    continent = "europe",
    scale = "continental",
    coords = base::list(
      tibble::tibble(
        coord_long = 15,
        coord_lat = 50
      )
    )
  )

# Coords tibble with no rows for this continent × scale
data_coords_no_cores <-
  tibble::tibble(
    continent = "asia",
    scale = "continental",
    coords = base::list(
      tibble::tibble(
        coord_long = base::numeric(0),
        coord_lat = base::numeric(0)
      )
    )
  )

graphical_options_fixture <-
  base::list(
    width = 2000,
    height = 1600,
    units = "px",
    dpi = 300,
    bg = "white"
  )

xlim_fixture <-
  c(-10, 30)
ylim_fixture <-
  c(35, 70)


#----------------------------------------------------------#
# Input validation -----
#----------------------------------------------------------#

testthat::test_that(
  "build_map_panel() rejects non-character sel_continent",
  {
    testthat::expect_error(
      build_map_panel(
        sel_continent = 1L,
        sel_scale = "continental",
        sel_resolution = "genus",
        xlim_val = xlim_fixture,
        ylim_val = ylim_fixture,
        data_grid_with_results = data_grid_fixture,
        data_coords_per_unit = data_coords_with_cores,
        sf_world = sf_world_fixture,
        graphical_options = graphical_options_fixture
      )
    )
  }
)

testthat::test_that(
  "build_map_panel() rejects non-length-2 xlim_val",
  {
    testthat::expect_error(
      build_map_panel(
        sel_continent = "europe",
        sel_scale = "continental",
        sel_resolution = "genus",
        xlim_val = c(-10, 0, 30),
        ylim_val = ylim_fixture,
        data_grid_with_results = data_grid_fixture,
        data_coords_per_unit = data_coords_with_cores,
        sf_world = sf_world_fixture,
        graphical_options = graphical_options_fixture
      )
    )
  }
)

testthat::test_that(
  "build_map_panel() rejects non-numeric ylim_val",
  {
    testthat::expect_error(
      build_map_panel(
        sel_continent = "europe",
        sel_scale = "continental",
        sel_resolution = "genus",
        xlim_val = xlim_fixture,
        ylim_val = c("a", "b"),
        data_grid_with_results = data_grid_fixture,
        data_coords_per_unit = data_coords_with_cores,
        sf_world = sf_world_fixture,
        graphical_options = graphical_options_fixture
      )
    )
  }
)

testthat::test_that(
  "build_map_panel() rejects non-data-frame grid",
  {
    testthat::expect_error(
      build_map_panel(
        sel_continent = "europe",
        sel_scale = "continental",
        sel_resolution = "genus",
        xlim_val = xlim_fixture,
        ylim_val = ylim_fixture,
        data_grid_with_results = "not_a_df",
        data_coords_per_unit = data_coords_with_cores,
        sf_world = sf_world_fixture,
        graphical_options = graphical_options_fixture
      )
    )
  }
)

testthat::test_that(
  "build_map_panel() rejects non-sf sf_world",
  {
    testthat::expect_error(
      build_map_panel(
        sel_continent = "europe",
        sel_scale = "continental",
        sel_resolution = "genus",
        xlim_val = xlim_fixture,
        ylim_val = ylim_fixture,
        data_grid_with_results = data_grid_fixture,
        data_coords_per_unit = data_coords_with_cores,
        sf_world = base::data.frame(x = 1),
        graphical_options = graphical_options_fixture
      )
    )
  }
)

testthat::test_that(
  "build_map_panel() rejects graphical_options missing keys",
  {
    testthat::expect_error(
      build_map_panel(
        sel_continent = "europe",
        sel_scale = "continental",
        sel_resolution = "genus",
        xlim_val = xlim_fixture,
        ylim_val = ylim_fixture,
        data_grid_with_results = data_grid_fixture,
        data_coords_per_unit = data_coords_with_cores,
        sf_world = sf_world_fixture,
        graphical_options = base::list(width = 100)
      )
    )
  }
)


#----------------------------------------------------------#
# Return type -----
#----------------------------------------------------------#

testthat::test_that(
  "build_map_panel() returns a ggplot object",
  {
    res <-
      build_map_panel(
        sel_continent = "europe",
        sel_scale = "continental",
        sel_resolution = "genus",
        xlim_val = xlim_fixture,
        ylim_val = ylim_fixture,
        data_grid_with_results = data_grid_fixture,
        data_coords_per_unit = data_coords_with_cores,
        sf_world = sf_world_fixture,
        graphical_options = graphical_options_fixture
      )

    testthat::expect_true(
      base::inherits(res, "gg")
    )
  }
)


#----------------------------------------------------------#
# Core overlay -----
#----------------------------------------------------------#

testthat::test_that(
  "panel without cores has fewer layers than with cores",
  {
    res_with <-
      build_map_panel(
        sel_continent = "europe",
        sel_scale = "continental",
        sel_resolution = "genus",
        xlim_val = xlim_fixture,
        ylim_val = ylim_fixture,
        data_grid_with_results = data_grid_fixture,
        data_coords_per_unit = data_coords_with_cores,
        sf_world = sf_world_fixture,
        graphical_options = graphical_options_fixture
      )

    res_without <-
      build_map_panel(
        sel_continent = "europe",
        sel_scale = "continental",
        sel_resolution = "genus",
        xlim_val = xlim_fixture,
        ylim_val = ylim_fixture,
        data_grid_with_results = data_grid_fixture,
        data_coords_per_unit = data_coords_no_cores,
        sf_world = sf_world_fixture,
        graphical_options = graphical_options_fixture
      )

    testthat::expect_gt(
      base::length(res_with[["layers"]]),
      base::length(res_without[["layers"]])
    )
  }
)

testthat::test_that(
  "panel with cores contains a GeomPoint layer",
  {
    res <-
      build_map_panel(
        sel_continent = "europe",
        sel_scale = "continental",
        sel_resolution = "genus",
        xlim_val = xlim_fixture,
        ylim_val = ylim_fixture,
        data_grid_with_results = data_grid_fixture,
        data_coords_per_unit = data_coords_with_cores,
        sf_world = sf_world_fixture,
        graphical_options = graphical_options_fixture
      )

    layer_classes <-
      res[["layers"]] |>
      purrr::map_chr(
        .f = ~ base::class(.x[["geom"]])[[1]]
      )

    testthat::expect_true(
      "GeomPoint" %in% layer_classes
    )
  }
)


#----------------------------------------------------------#
# coord_sf limits -----
#----------------------------------------------------------#

testthat::test_that(
  "coord_sf xlim and ylim match supplied values",
  {
    res <-
      build_map_panel(
        sel_continent = "europe",
        sel_scale = "continental",
        sel_resolution = "genus",
        xlim_val = xlim_fixture,
        ylim_val = ylim_fixture,
        data_grid_with_results = data_grid_fixture,
        data_coords_per_unit = data_coords_with_cores,
        sf_world = sf_world_fixture,
        graphical_options = graphical_options_fixture
      )

    coord_limits <-
      ggplot2::layer_scales(res)

    testthat::expect_equal(
      res[["coordinates"]][["limits"]][["x"]],
      xlim_fixture
    )

    testthat::expect_equal(
      res[["coordinates"]][["limits"]][["y"]],
      ylim_fixture
    )
  }
)


#----------------------------------------------------------#
# Axis visibility and embedded labels -----
#----------------------------------------------------------#

testthat::test_that(
  "build_map_panel() rejects non-logical show_x_axis",
  {
    testthat::expect_error(
      build_map_panel(
        sel_continent = "europe",
        sel_scale = "continental",
        sel_resolution = "genus",
        xlim_val = xlim_fixture,
        ylim_val = ylim_fixture,
        data_grid_with_results = data_grid_fixture,
        data_coords_per_unit = data_coords_with_cores,
        sf_world = sf_world_fixture,
        graphical_options = graphical_options_fixture,
        show_x_axis = "yes"
      )
    )
  }
)

testthat::test_that(
  "build_map_panel() rejects non-logical show_y_axis",
  {
    testthat::expect_error(
      build_map_panel(
        sel_continent = "europe",
        sel_scale = "continental",
        sel_resolution = "genus",
        xlim_val = xlim_fixture,
        ylim_val = ylim_fixture,
        data_grid_with_results = data_grid_fixture,
        data_coords_per_unit = data_coords_with_cores,
        sf_world = sf_world_fixture,
        graphical_options = graphical_options_fixture,
        show_y_axis = 1L
      )
    )
  }
)

testthat::test_that(
  "build_map_panel() rejects numeric col_label",
  {
    testthat::expect_error(
      build_map_panel(
        sel_continent = "europe",
        sel_scale = "continental",
        sel_resolution = "genus",
        xlim_val = xlim_fixture,
        ylim_val = ylim_fixture,
        data_grid_with_results = data_grid_fixture,
        data_coords_per_unit = data_coords_with_cores,
        sf_world = sf_world_fixture,
        graphical_options = graphical_options_fixture,
        col_label = 42
      )
    )
  }
)

testthat::test_that(
  "build_map_panel() rejects numeric row_label",
  {
    testthat::expect_error(
      build_map_panel(
        sel_continent = "europe",
        sel_scale = "continental",
        sel_resolution = "genus",
        xlim_val = xlim_fixture,
        ylim_val = ylim_fixture,
        data_grid_with_results = data_grid_fixture,
        data_coords_per_unit = data_coords_with_cores,
        sf_world = sf_world_fixture,
        graphical_options = graphical_options_fixture,
        row_label = 42
      )
    )
  }
)

testthat::test_that(
  "col_label sets the plot title on the returned ggplot",
  {
    res <-
      build_map_panel(
        sel_continent = "europe",
        sel_scale = "continental",
        sel_resolution = "genus",
        xlim_val = xlim_fixture,
        ylim_val = ylim_fixture,
        data_grid_with_results = data_grid_fixture,
        data_coords_per_unit = data_coords_with_cores,
        sf_world = sf_world_fixture,
        graphical_options = graphical_options_fixture,
        col_label = "Genus"
      )

    testthat::expect_equal(
      res[["labels"]][["title"]],
      "Genus"
    )
  }
)

testthat::test_that(
  "row_label sets the y-axis label on the returned ggplot",
  {
    res <-
      build_map_panel(
        sel_continent = "europe",
        sel_scale = "continental",
        sel_resolution = "genus",
        xlim_val = xlim_fixture,
        ylim_val = ylim_fixture,
        data_grid_with_results = data_grid_fixture,
        data_coords_per_unit = data_coords_with_cores,
        sf_world = sf_world_fixture,
        graphical_options = graphical_options_fixture,
        row_label = "Continental"
      )

    testthat::expect_equal(
      res[["labels"]][["y"]],
      "Continental"
    )
  }
)

testthat::test_that(
  "show_x_axis = FALSE returns a valid ggplot",
  {
    res <-
      build_map_panel(
        sel_continent = "europe",
        sel_scale = "continental",
        sel_resolution = "genus",
        xlim_val = xlim_fixture,
        ylim_val = ylim_fixture,
        data_grid_with_results = data_grid_fixture,
        data_coords_per_unit = data_coords_with_cores,
        sf_world = sf_world_fixture,
        graphical_options = graphical_options_fixture,
        show_x_axis = FALSE
      )

    testthat::expect_true(
      base::inherits(res, "gg")
    )
  }
)

testthat::test_that(
  "show_y_axis = FALSE returns a valid ggplot",
  {
    res <-
      build_map_panel(
        sel_continent = "europe",
        sel_scale = "continental",
        sel_resolution = "genus",
        xlim_val = xlim_fixture,
        ylim_val = ylim_fixture,
        data_grid_with_results = data_grid_fixture,
        data_coords_per_unit = data_coords_with_cores,
        sf_world = sf_world_fixture,
        graphical_options = graphical_options_fixture,
        show_y_axis = FALSE
      )

    testthat::expect_true(
      base::inherits(res, "gg")
    )
  }
)
