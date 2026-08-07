#' @title Save Pipeline Progress Visualisation
#' @description
#' Builds pipeline progress visualisations and saves HTML and PNG artifacts.
#' @param sel_script
#' Pipeline script passed to [plot_pipeline_progress_visualisations()].
#' @param sel_store
#' Path to the targets store directory.
#' @param output_file
#' Base name for output files.
#' @param output_dir
#' Root directory for progress artifacts.
#' @param background_color
#' Background colour used for saved HTML widgets.
#' @param physics
#' Logical indicating whether network physics are enabled initially.
#' @param level_separation
#' Numeric separation between network levels.
#' @param plot_function
#' Injectable progress-plot builder used for isolated side-effect tests.
#' @return
#' Named character vector containing paths written successfully.
#' @details
#' Browser-backed PNG export is best effort. A PNG failure emits a warning and
#' leaves the two HTML outputs available to the caller.
#' @export
save_pipeline_progress_visualisation <- function(
    sel_script,
    sel_store = load_active_config_value("target_store"),
    output_file = "project_status",
    output_dir = here::here("Documentation/Progress"),
    background_color = "#141B22",
    physics = TRUE,
    level_separation = 250,
    plot_function = plot_pipeline_progress_visualisations) {
  assertthat::assert_that(
    base::is.function(plot_function),
    msg = "`plot_function` must be a function."
  )

  if (
    base::is.null(rmarkdown::find_pandoc()[["dir"]])
  ) {
    pandoc::pandoc_activate()
  }

  list_visualisations <-
    plot_function(
      sel_script = sel_script,
      sel_store = sel_store,
      physics = physics,
      level_separation = level_separation
    )

  sel_store_simple <-
    stringr::str_replace(
      string = sel_store,
      pattern = ".*/targets/",
      replacement = ""
    )

  output_store_dir <-
    fs::path(output_dir, sel_store_simple)

  output_html_path <-
    fs::path(output_store_dir, stringr::str_c(output_file, ".html"))
  output_small_html_path <-
    fs::path(
      output_store_dir,
      stringr::str_c(output_file, "_small.html")
    )
  output_png_path <-
    fs::path(
      output_store_dir,
      stringr::str_c(output_file, "_static.png")
    )

  fs::dir_create(output_store_dir, recurse = TRUE)

  visNetwork::visSave(
    graph = list_visualisations[["full"]],
    file = output_html_path,
    selfcontained = TRUE,
    background = background_color
  )
  visNetwork::visSave(
    graph = list_visualisations[["static"]],
    file = output_small_html_path,
    selfcontained = TRUE,
    background = background_color
  )

  tryCatch(
    webshot2::webshot(
      url = output_small_html_path,
      file = output_png_path,
      vwidth = 950,
      vheight = 750,
      delay = 3
    ),
    error = function(err) {
      cli::cli_warn(
        base::c(
          "Failed to save static PNG progress visualisation.",
          "i" = "HTML progress files were saved successfully.",
          "i" = stringr::str_c(
            "Original error: ",
            base::conditionMessage(err)
          )
        )
      )
      base::invisible(NULL)
    }
  )

  res <-
    base::c(
      full_html = output_html_path,
      targets_html = output_small_html_path
    )

  if (
    base::file.exists(output_png_path)
  ) {
    res <-
      base::c(
        res,
        static_png = output_png_path
      )
  }

  return(res)
}
