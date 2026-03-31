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
#' Background color for the visualisation
#' (default: `"#141B22"` — BIODYNAMICS brand Console Panel; one step lighter
#' than the page background, used for cards and panels).
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
#'
#' The targets store is read only once. `targets_only = FALSE` retrieves the
#' full network; the targets-only variant for the static PNG graph is derived
#' by filtering non-target nodes (`type` values `"function"`, `"object"`,
#' `"value"`) from the same object, avoiding a second store read. If the
#' `type` column is absent (targets internal change), the function falls back
#' to a second `tar_visnetwork()` call so correctness is preserved.
#'
#' When `physics = TRUE`, the static graph for the PNG uses a
#' `stabilizationIterationsDone` vis.js event to disable physics as soon as
#' the silent background layout pass finishes. This ensures the screenshot
#' captures the fully settled layout without requiring a long wait or
#' rendering the graph twice.
#' @export
save_progress_visualisation <- function(
    sel_script,
    sel_store = get_active_config("target_store"),
    output_file = "project_status",
    output_dir = here::here(
      "Documentation/Progress"
    ),
    background_color = "#141B22",
    physics = TRUE,
    level_separation = 250) {
  # test to make sure {pandoc} is installed for webshot to work

  if (
    is.null(rmarkdown::find_pandoc()$dir)
  ) {
    pandoc::pandoc_activate()
  }

  # Read the targets store once. targets_only = FALSE gives the full network;
  #   the targets-only static variant is derived below by filtering the same
  #   object, avoiding a second expensive store read.
  network_graph_raw <-
    targets::tar_visnetwork(
      script = sel_script,
      outdated = FALSE,
      store = sel_store,
      targets_only = FALSE,
      physics = physics,
      level_separation = level_separation
    )

  network_graph <-
    network_graph_raw |>
    # Apply BIODYNAMICS brand theme over the targets-generated colors.
    # Node fill colors (status: up-to-date / outdated / etc.) are set
    #   internally by targets and cannot be overridden here; only font
    #   and edge styling are applied.
    visNetwork::visNodes(
      font = base::list(
        color = "#E6EDF3",  # Bone Text
        face = "IBM Plex Mono, monospace"
      )
    ) |>
    visNetwork::visEdges(
      color = base::list(
        color = "#2A3441",    # Slate Border
        highlight = "#8DF59A", # Phosphor Green
        hover = "#48C7B8"      # Moss Teal
      ),
      font = base::list(
        color = "#98A6B3",   # Muted Mist
        strokeWidth = 0
      )
    )

  # Derive the targets-only static base graph from the raw object already
  #   in memory. targets sets type = "function" / "object" / "value" for
  #   non-target nodes; filtering them mirrors targets_only = TRUE.
  #   The fallback re-calls tar_visnetwork() if targets ever drops the
  #   type column, so correctness is preserved across package changes.
  if (
    "type" %in% base::names(network_graph_raw$x$nodes)
  ) {
    vec_target_node_ids <-
      network_graph_raw$x$nodes |>
      dplyr::filter(
        !(.data[["type"]] %in% c("function", "object", "value"))
      ) |>
      dplyr::pull(id)

    network_graph_static_base <- network_graph_raw
    network_graph_static_base$x$nodes <-
      dplyr::filter(
        network_graph_raw$x$nodes,
        .data[["id"]] %in% vec_target_node_ids
      )
    network_graph_static_base$x$edges <-
      dplyr::filter(
        network_graph_raw$x$edges,
        .data[["from"]] %in% vec_target_node_ids,
        .data[["to"]] %in% vec_target_node_ids
      )
  } else {
    # Fallback: targets internals changed and type column is absent.
    network_graph_static_base <-
      targets::tar_visnetwork(
        script = sel_script,
        store = sel_store,
        targets_only = TRUE,
        outdated = FALSE,
        physics = physics,
        level_separation = level_separation
      )
  }

  network_graph_static <-
    network_graph_static_base |>
    visNetwork::visNodes(
      font = base::list(
        color = "#E6EDF3",
        face = "IBM Plex Mono, monospace"
      )
    ) |>
    visNetwork::visEdges(
      color = base::list(
        color = "#2A3441",
        highlight = "#8DF59A",
        hover = "#48C7B8"
      ),
      font = base::list(
        color = "#98A6B3",
        strokeWidth = 0
      )
    ) |>
    # Freeze the graph the moment background stabilization finishes so the
    #   webshot captures the settled layout, not a mid-simulation frame.
    #   vis.js fires `stabilizationIterationsDone` after the silent pre-layout
    #   pass (fast, < 1 s), then starts the animated physics — disabling
    #   physics here prevents any further movement before the screenshot.
    visNetwork::visEvents(
      stabilizationIterationsDone = "function() {
        this.setOptions({ physics: false });
      }"
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
  # `delay = 1` gives the browser time to complete the background
  #   stabilization pass before the screenshot is taken; the visEvents
  #   handler then keeps the graph frozen so the captured layout is stable.
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
