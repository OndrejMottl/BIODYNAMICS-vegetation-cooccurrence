#' @title Plot Pipeline Progress Visualisations
#' @description
#' Builds full and targets-only pipeline progress visualisations in memory.
#' @param sel_script
#' Pipeline script passed to [targets::tar_visnetwork()].
#' @param sel_store
#' Path to the targets store.
#' @param physics
#' Logical indicating whether network physics are enabled initially.
#' @param level_separation
#' Numeric separation between network levels.
#' @return
#' Named list with `full` and `static` `visNetwork` objects.
#' @export
plot_pipeline_progress_visualisations <- function(
    sel_script,
    sel_store,
    physics = TRUE,
    level_separation = 250) {
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
    )

  data_nodes <-
    network_graph_raw[["x"]][["nodes"]]

  if (
    "type" %in% base::names(data_nodes)
  ) {
    vec_target_node_ids <-
      data_nodes |>
      dplyr::filter(
        !(.data[["type"]] %in% base::c("function", "object", "value"))
      ) |>
      dplyr::pull("id")

    network_graph_static_base <-
      network_graph_raw

    network_graph_static_base[["x"]][["nodes"]] <-
      dplyr::filter(
        data_nodes,
        .data[["id"]] %in% vec_target_node_ids
      )

    network_graph_static_base[["x"]][["edges"]] <-
      dplyr::filter(
        network_graph_raw[["x"]][["edges"]],
        .data[["from"]] %in% vec_target_node_ids,
        .data[["to"]] %in% vec_target_node_ids
      )
  } else {
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
    visNetwork::visEvents(
      stabilizationIterationsDone = "function() {
        this.setOptions({ physics: false });
      }"
    )

  res <-
    base::list(
      full = network_graph,
      static = network_graph_static
    )

  return(res)
}
