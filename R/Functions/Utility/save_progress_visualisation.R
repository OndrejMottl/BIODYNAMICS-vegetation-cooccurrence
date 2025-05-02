#' @title Save Progress Visualisation
#' @description
#' Generates a visualisation of project progress and saves it as HTML and PNG.
#' @param sel_script
#' The script file to be visualised.
#' @param output_file
#' The name of the output file (default: "project_status").
#' @param output_dir
#' Directory where the output files will be saved (default: "Outputs/Figures").
#' @param level_separation
#' Level separation for the visualisation graph (default: 250).
#' @details
#' Uses `targets::tar_visnetwork` to create a network graph and saves it as
#' HTML using `visNetwork::visSave`. Also generates a static PNG image using
#' `webshot2::webshot`.
#' @export
save_progress_visualisation <- function(
    sel_script,
    output_file = "project_status",
    output_dir = here::here(
      "Outputs/Figures"
    ),
    level_separation = 250) {



  network_graph <-
    targets::tar_visnetwork(
      script = sel_script,
      store = get_active_config("target_store"),
      targets_only = FALSE,
      level_separation = level_separation
    )

  network_graph_static <-
    targets::tar_visnetwork(
      script = sel_script,
      store = get_active_config("target_store"),
      targets_only = TRUE,
      level_separation = level_separation
    )

  visNetwork::visSave(
    graph = network_graph,
    file = here::here("docs/index.html"),
    selfcontained = TRUE,
    background = "white"
  )

  visNetwork::visSave(
    graph = network_graph_static,
    file = paste0(output_dir, "/", output_file, "_small.html"),
    selfcontained = TRUE,
    background = "white"
  )

  webshot2::webshot(
    url = paste0(output_dir, "/", output_file, "_small.html"),
    file = paste0(output_dir, "/", output_file, "_static.png"),
    vwidth = 992,
    vheight = 744
  )
}
