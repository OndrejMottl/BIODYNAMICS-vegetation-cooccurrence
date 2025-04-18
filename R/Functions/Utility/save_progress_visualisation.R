
save_progress_visualisation <- function(sel_script,
    output_file = "project_status",
    output_dir = here::here(
      "Outputs/Figures"
    ),
    level_separation = 250) {
  network_graph <-
    targets::tar_visnetwork(
      script = sel_script,
      store = get_active_config("target_store"),
      targets_only = TRUE,
      level_separation = level_separation
    )

  visNetwork::visSave(
    graph = network_graph,
    file = paste0(output_dir, "/", output_file, ".html"),
    selfcontained = TRUE,
    background = "white"
  )

  webshot2::webshot(
    url = paste0(output_dir, "/", output_file, ".html"),
    file = paste0(output_dir, "/", output_file, "_static.png")
  )
}