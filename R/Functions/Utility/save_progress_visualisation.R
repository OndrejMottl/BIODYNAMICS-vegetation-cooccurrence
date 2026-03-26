#' @title Save Progress Visualisation
#' @description
#' Generates a visualisation of project progress and saves it as HTML and PNG.
#' @param sel_script
#' The script file to be visualised.
#' @param sel_store
#' Path to the targets store directory. Defaults to the value from the active
#' configuration key "target_store".
#' @param output_file
#' The name of the output file (default: "project_status").
#' @param output_dir
#' Directory where the output files will be saved
#' (default: "Documentation/Progress").
#' @param background_color
#' Background color for the visualisation (default: "white").
#' @param physics
#' Logical indicating whether to enable physics simulation in the network
#' graph (default: TRUE).
#' @param level_separation
#' Level separation for the visualisation graph (default: 250).
#' @return
#' No return value. Called for side effects: saves HTML and PNG files to a
#' store-specific subdirectory within `output_dir`.
#' @details
#' Uses `targets::tar_visnetwork` to create a network graph and saves two
#' HTML files (full and targets-only) using `visNetwork::visSave`, plus a
#' static PNG via `webshot2::webshot`. If the browser-backed PNG export fails,
#' the function emits a warning and keeps the HTML outputs so progress saving
#' does not abort the surrounding pipeline run. Files are written to
#' `output_dir/<store_name>/` where `<store_name>` is the last path segment
#' of `sel_store` after the `targets/` directory.
#' @export
save_progress_visualisation <- function(
    sel_script,
    sel_store = get_active_config("target_store"),
    output_file = "project_status",
    output_dir = here::here(
      "Documentation/Progress"
    ),
    background_color = "white",
    physics = TRUE,
    level_separation = 250) {
  # test to make sure {pandoc} is installed for webshot to work

  if (
    is.null(rmarkdown::find_pandoc()$dir)
  ) {
    pandoc::pandoc_activate()
  }

  network_graph <-
    targets::tar_visnetwork(
      script = sel_script,
      outdated = FALSE,
      store = sel_store,
      targets_only = FALSE,
      physics = physics,
      level_separation = level_separation
    )

  network_graph_static <-
    targets::tar_visnetwork(
      script = sel_script,
      store = sel_store,
      targets_only = TRUE,
      outdated = FALSE,
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
    paste0(output_dir, "/", sel_store_simple)

  output_html_path <-
    paste0(output_store_dir, "/", output_file, ".html")

  output_small_html_path <-
    paste0(output_store_dir, "/", output_file, "_small.html")

  output_png_path <-
    paste0(output_store_dir, "/", output_file, "_static.png")

  # need to create the output directory if it doesn't exist
  if (
    !dir.exists(output_store_dir)
  ) {
    dir.create(output_store_dir, recursive = TRUE)
  }

  visNetwork::visSave(
    graph = network_graph,
    file = output_html_path,
    selfcontained = TRUE,
    background = background_color
  )

  visNetwork::visSave(
    graph = network_graph_static,
    file = output_small_html_path,
    selfcontained = TRUE,
    background = background_color
  )

  # PNG export depends on launching a browser through chromote/webshot2,
  #   which can fail in interactive sessions even when the HTML outputs save.
  tryCatch(
    webshot2::webshot(
      url = output_small_html_path,
      file = output_png_path,
      vwidth = 950,
      vheight = 750
    ),
    error = function(err) {
      cli::cli_warn(
        c(
          "Failed to save static PNG progress visualisation.",
          "i" = "HTML progress files were saved successfully.",
          "i" = paste0(
            "Original error: ",
            base::conditionMessage(err)
          )
        )
      )
      invisible(NULL)
    }
  )
}
