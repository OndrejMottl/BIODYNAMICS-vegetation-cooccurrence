#' @title Run Project Configuration Generation
#' @description
#' Validates modular configuration sources and materialises tracked artifacts.
#' @param path_manifest
#' Path to the configuration ordering manifest.
#' @param path_source_root
#' Repository root used to resolve manifest fragment and reference paths.
#' @param path_destination_root
#' Root under which generated artifact paths are written.
#' @return
#' Data frame describing validated profiles and their generated catalog fields.
#' @details
#' The function validates the complete source set and semantic reference in a
#' temporary directory before writing either destination artifact.
#' @export
run_configuration_generation <- function(
    path_manifest = here::here("Configuration/manifest.yml"),
    path_source_root = here::here(),
    path_destination_root = path_source_root) {
  assertthat::assert_that(
    base::is.character(path_manifest) &&
      base::length(path_manifest) == 1L &&
      !base::is.na(path_manifest) &&
      base::file.exists(path_manifest),
    msg = "`path_manifest` must be one existing file."
  )
  assertthat::assert_that(
    base::is.character(path_source_root) &&
      base::length(path_source_root) == 1L &&
      !base::is.na(path_source_root) &&
      base::dir.exists(path_source_root),
    msg = "`path_source_root` must be one existing directory."
  )
  assertthat::assert_that(
    base::is.character(path_destination_root) &&
      base::length(path_destination_root) == 1L &&
      !base::is.na(path_destination_root) &&
      base::nzchar(path_destination_root),
    msg = "`path_destination_root` must be one non-empty path."
  )

  path_source_root <-
    base::normalizePath(
      path = path_source_root,
      winslash = "/",
      mustWork = TRUE
    )

  list_manifest <-
    yaml::read_yaml(path_manifest)

  vec_required_manifest_fields <-
    base::c(
      "version",
      "output",
      "catalog",
      "semantic_reference",
      "maximum_inheritance_depth",
      "fragments"
    )

  vec_missing_manifest_fields <-
    base::setdiff(
      x = vec_required_manifest_fields,
      y = base::names(list_manifest)
    )

  if (
    base::length(vec_missing_manifest_fields) > 0L
  ) {
    cli::cli_abort(
      base::c(
        "The configuration manifest is incomplete.",
        "x" = stringr::str_c(
          vec_missing_manifest_fields,
          collapse = ", "
        )
      )
    )
  }

  assertthat::assert_that(
    base::identical(list_manifest[["version"]], 1L),
    msg = "The configuration manifest version must be 1."
  )
  assertthat::assert_that(
    base::is.numeric(
      list_manifest[["maximum_inheritance_depth"]]
    ) &&
      base::length(
        list_manifest[["maximum_inheritance_depth"]]
      ) == 1L &&
      base::is.finite(
        list_manifest[["maximum_inheritance_depth"]]
      ) &&
      list_manifest[["maximum_inheritance_depth"]] >= 1,
    msg = "`maximum_inheritance_depth` must be a positive number."
  )

  vec_fragment_paths_relative <-
    base::unlist(
      x = list_manifest[["fragments"]],
      use.names = FALSE
    )

  assertthat::assert_that(
    base::is.character(vec_fragment_paths_relative) &&
      base::length(vec_fragment_paths_relative) > 0L &&
      base::all(base::nzchar(vec_fragment_paths_relative)),
    msg = "The manifest must list non-empty fragment paths."
  )
  assertthat::assert_that(
    !base::anyDuplicated(vec_fragment_paths_relative),
    msg = "Every manifest fragment must be listed exactly once."
  )
  assertthat::assert_that(
    base::all(
      base::startsWith(
        x = vec_fragment_paths_relative,
        prefix = "Configuration/"
      )
    ),
    msg = "Every fragment must be inside `Configuration/`."
  )

  vec_fragment_paths <-
    base::file.path(
      path_source_root,
      vec_fragment_paths_relative
    )

  vec_missing_fragment_paths <-
    vec_fragment_paths_relative[
      !base::file.exists(vec_fragment_paths)
    ]

  if (
    base::length(vec_missing_fragment_paths) > 0L
  ) {
    cli::cli_abort(
      base::c(
        "A manifest fragment does not exist.",
        "x" = stringr::str_c(
          vec_missing_fragment_paths,
          collapse = ", "
        )
      )
    )
  }

  vec_discovered_fragment_paths <-
    base::list.files(
      path = base::file.path(
        path_source_root,
        "Configuration"
      ),
      pattern = "[.]ya?ml$",
      recursive = TRUE,
      full.names = TRUE
    ) |>
    base::normalizePath(
      winslash = "/",
      mustWork = TRUE
    )

  path_manifest_normalized <-
    base::normalizePath(
      path = path_manifest,
      winslash = "/",
      mustWork = TRUE
    )

  vec_discovered_fragment_paths <-
    base::setdiff(
      x = vec_discovered_fragment_paths,
      y = path_manifest_normalized
    )

  vec_discovered_fragment_paths_relative <-
    base::substring(
      text = vec_discovered_fragment_paths,
      first = base::nchar(path_source_root) + 2L
    )

  vec_unlisted_fragment_paths <-
    base::setdiff(
      x = vec_discovered_fragment_paths_relative,
      y = vec_fragment_paths_relative
    )

  if (
    base::length(vec_unlisted_fragment_paths) > 0L
  ) {
    cli::cli_abort(
      base::c(
        "A configuration fragment is absent from the manifest.",
        "x" = stringr::str_c(
          vec_unlisted_fragment_paths,
          collapse = ", "
        )
      )
    )
  }

  list_fragment_records <-
    vec_fragment_paths |>
    purrr::map2(
      .y = vec_fragment_paths_relative,
      .f = ~ {
        path_fragment <- .x
        path_fragment_relative <- .y

        vec_lines <-
          base::readLines(
            con = path_fragment,
            warn = FALSE,
            encoding = "UTF-8"
          )

        vec_key_lines <-
          base::grep(
            pattern = "^[ ]*[A-Za-z0-9_]+:[ ]*",
            x = vec_lines,
            value = TRUE
          )

        vec_key_lines |>
          purrr::reduce(
            .init = base::list(
              seen_key_paths = base::character(),
              parent_keys = base::character(),
              parent_indents = base::integer()
            ),
            .f = ~ {
              list_key_state <- .x
              key_line <- .y

              vec_seen_key_paths <-
                purrr::chuck(
                  list_key_state,
                  "seen_key_paths"
                )
              vec_parent_keys <-
                purrr::chuck(
                  list_key_state,
                  "parent_keys"
                )
              vec_parent_indents <-
                purrr::chuck(
                  list_key_state,
                  "parent_indents"
                )

              key_indent <-
                base::nchar(
                  base::sub(
                    pattern = "^([ ]*).*$",
                    replacement = "\\1",
                    x = key_line
                  )
                )

              key_name <-
                key_line |>
                base::trimws() |>
                base::sub(
                  pattern = ":.*$",
                  replacement = ""
                )

              while (
                base::length(vec_parent_indents) > 0L &&
                  utils::tail(vec_parent_indents, 1L) >= key_indent
              ) {
                vec_parent_indents <-
                  utils::head(vec_parent_indents, -1L)
                vec_parent_keys <-
                  utils::head(vec_parent_keys, -1L)
              }

              key_path <-
                stringr::str_c(
                  base::c(vec_parent_keys, key_name),
                  collapse = "/"
                )

              if (
                key_path %in% vec_seen_key_paths
              ) {
                cli::cli_abort(
                  stringr::str_glue(
                    "Duplicate YAML key `{key_path}` in ",
                    "`{path_fragment_relative}`."
                  )
                )
              }

              return(
                base::list(
                  seen_key_paths = base::c(
                    vec_seen_key_paths,
                    key_path
                  ),
                  parent_keys = base::c(
                    vec_parent_keys,
                    key_name
                  ),
                  parent_indents = base::c(
                    vec_parent_indents,
                    key_indent
                  )
                )
              )
            }
          )

        list_fragment <-
          yaml::read_yaml(
            file = path_fragment,
            handlers = base::list(
              expr = function(value) {
                value
              }
            )
          )

        assertthat::assert_that(
          base::is.list(list_fragment) &&
            base::length(list_fragment) > 0L &&
            !base::is.null(base::names(list_fragment)) &&
            base::all(base::nzchar(base::names(list_fragment))),
          msg = stringr::str_glue(
            "Fragment `{path_fragment_relative}` must contain named profiles."
          )
        )

        vec_fragment_profile_ids <-
          base::names(list_fragment)

        return(
          base::list(
            fragment = list_fragment,
            lines = vec_lines,
            profile_ids = vec_fragment_profile_ids,
            profile_fragments = base::rep(
              path_fragment_relative,
              base::length(vec_fragment_profile_ids)
            )
          )
        )
      }
    )

  list_fragments <-
    list_fragment_records |>
    purrr::map(
      .f = ~ purrr::chuck(.x, "fragment")
    )

  list_fragment_lines <-
    list_fragment_records |>
    purrr::map(
      .f = ~ purrr::chuck(.x, "lines")
    )

  vec_profile_ids <-
    list_fragment_records |>
    purrr::map(
      .f = ~ purrr::chuck(.x, "profile_ids")
    ) |>
    purrr::list_c()

  vec_profile_fragments <-
    list_fragment_records |>
    purrr::map(
      .f = ~ purrr::chuck(.x, "profile_fragments")
    ) |>
    purrr::list_c()

  vec_duplicate_profile_ids <-
    vec_profile_ids[
      base::duplicated(vec_profile_ids)
    ] |>
    base::unique()

  if (
    base::length(vec_duplicate_profile_ids) > 0L
  ) {
    cli::cli_abort(
      base::c(
        "A profile is declared in multiple fragments.",
        "x" = stringr::str_c(
          vec_duplicate_profile_ids,
          collapse = ", "
        )
      )
    )
  }

  list_profiles <-
    list_fragments |>
    purrr::list_flatten()

  if (
    base::sum(vec_profile_ids == "default") != 1L
  ) {
    cli::cli_abort(
      "Configuration sources must declare exactly one `default` profile."
    )
  }

  vec_required_metadata_fields <-
    base::c(
      "role",
      "status",
      "selectable",
      "pipeline",
      "description",
      "related_issue",
      "retirement",
      "supported_runners"
    )

  vec_allowed_roles <-
    base::c(
      "base",
      "main",
      "smoke",
      "reference",
      "one_time"
    )

  vec_allowed_statuses <-
    base::c(
      "active",
      "frozen",
      "archived"
    )

  data_profile_metadata <-
    vec_profile_ids |>
    purrr::map(
      .f = ~ {
        profile_id <- .x

        list_profile <-
          purrr::chuck(
            list_profiles,
            profile_id
          )

        list_metadata <-
          list_profile[["_profile"]]

        if (
          base::is.null(list_metadata)
        ) {
          cli::cli_abort(
            stringr::str_glue(
              "Profile `{profile_id}` has no `_profile` metadata."
            )
          )
        }

        vec_missing_metadata_fields <-
          base::setdiff(
            x = vec_required_metadata_fields,
            y = base::names(list_metadata)
          )

        if (
          base::length(vec_missing_metadata_fields) > 0L
        ) {
          cli::cli_abort(
            base::c(
              stringr::str_glue(
                "Profile `{profile_id}` has incomplete metadata."
              ),
              "x" = stringr::str_c(
                vec_missing_metadata_fields,
                collapse = ", "
              )
            )
          )
        }

        role <-
          list_metadata[["role"]]

        status <-
          list_metadata[["status"]]

        selectable <-
          list_metadata[["selectable"]]

        pipeline <-
          list_metadata[["pipeline"]]

        description <-
          list_metadata[["description"]]

        related_issue <-
          list_metadata[["related_issue"]]

        retirement <-
          list_metadata[["retirement"]]

        supported_runners <-
          list_metadata[["supported_runners"]]

        if (
          base::length(supported_runners) == 0L
        ) {
          supported_runners <- base::character()
        } else {
          supported_runners <-
            supported_runners |>
            base::as.list() |>
            purrr::list_c()
        }

        assertthat::assert_that(
          base::is.character(role) &&
            base::length(role) == 1L &&
            role %in% vec_allowed_roles,
          msg = stringr::str_glue(
            "Profile `{profile_id}` has an invalid role."
          )
        )
        assertthat::assert_that(
          base::is.character(status) &&
            base::length(status) == 1L &&
            status %in% vec_allowed_statuses,
          msg = stringr::str_glue(
            "Profile `{profile_id}` has an invalid status."
          )
        )
        assertthat::assert_that(
          base::is.logical(selectable) &&
            base::length(selectable) == 1L &&
            !base::is.na(selectable),
          msg = stringr::str_glue(
            "Profile `{profile_id}` has invalid selectability."
          )
        )
        assertthat::assert_that(
          base::is.character(pipeline) &&
            base::length(pipeline) == 1L &&
            base::nzchar(pipeline),
          msg = stringr::str_glue(
            "Profile `{profile_id}` must name one pipeline."
          )
        )
        assertthat::assert_that(
          base::is.character(description) &&
            base::length(description) == 1L &&
            base::nzchar(description),
          msg = stringr::str_glue(
            "Profile `{profile_id}` must have a description."
          )
        )
        assertthat::assert_that(
          base::is.null(related_issue) ||
            (
              base::is.numeric(related_issue) &&
                base::length(related_issue) == 1L &&
                base::is.finite(related_issue) &&
                related_issue > 0
            ),
          msg = stringr::str_glue(
            "Profile `{profile_id}` has an invalid related issue."
          )
        )
        assertthat::assert_that(
          base::is.null(retirement) ||
            (
              base::is.character(retirement) &&
                base::length(retirement) == 1L &&
                base::nzchar(retirement)
            ),
          msg = stringr::str_glue(
            "Profile `{profile_id}` has an invalid retirement criterion."
          )
        )
        assertthat::assert_that(
          base::is.character(supported_runners) &&
            base::all(base::nzchar(supported_runners)),
          msg = stringr::str_glue(
            "Profile `{profile_id}` has invalid supported runners."
          )
        )

        if (
          role == "one_time" &&
            base::is.null(related_issue)
        ) {
          cli::cli_abort(
            stringr::str_glue(
              "One-time profile `{profile_id}` must name a related issue."
            )
          )
        }

        if (
          role %in% base::c("reference", "one_time") &&
            base::is.null(retirement)
        ) {
          cli::cli_abort(
            stringr::str_glue(
              "Temporary profile `{profile_id}` needs a retirement criterion."
            )
          )
        }

        if (
          role == "base" &&
            base::isTRUE(selectable)
        ) {
          cli::cli_abort(
            stringr::str_glue(
              "Base profile `{profile_id}` cannot be selectable."
            )
          )
        }

        inheritance_parent <-
          list_profile[["inherits"]]

        if (
          !base::is.null(inheritance_parent)
        ) {
          assertthat::assert_that(
            base::is.character(inheritance_parent) &&
              base::length(inheritance_parent) == 1L &&
              base::nzchar(inheritance_parent),
            msg = stringr::str_glue(
              "Profile `{profile_id}` has an invalid parent."
            )
          )
        }

        return(
          tibble::tibble(
            profile_id = profile_id,
            role = role,
            status = status,
            selectable = selectable,
            pipeline = pipeline,
            description = description,
            related_issue = if (
              base::is.null(related_issue)
            ) {
              NA_integer_
            } else {
              base::as.integer(related_issue)
            },
            retirement = if (
              base::is.null(retirement)
            ) {
              NA_character_
            } else {
              retirement
            },
            supported_runners = stringr::str_c(
              supported_runners,
              collapse = ";"
            ),
            inheritance_parent = if (
              base::is.null(inheritance_parent)
            ) {
              NA_character_
            } else {
              inheritance_parent
            }
          )
        )
      }
    ) |>
    purrr::list_rbind()

  vec_roles <-
    data_profile_metadata |>
    dplyr::pull("role")

  vec_statuses <-
    data_profile_metadata |>
    dplyr::pull("status")

  vec_selectable <-
    data_profile_metadata |>
    dplyr::pull("selectable")

  vec_pipelines <-
    data_profile_metadata |>
    dplyr::pull("pipeline")

  vec_descriptions <-
    data_profile_metadata |>
    dplyr::pull("description")

  vec_related_issues <-
    data_profile_metadata |>
    dplyr::pull("related_issue")

  vec_retirement <-
    data_profile_metadata |>
    dplyr::pull("retirement")

  vec_supported_runners <-
    data_profile_metadata |>
    dplyr::pull("supported_runners")

  vec_inheritance_parents <-
    data_profile_metadata |>
    dplyr::pull("inheritance_parent")

  vec_unknown_parents <-
    base::setdiff(
      x = vec_inheritance_parents[
        !base::is.na(vec_inheritance_parents)
      ],
      y = vec_profile_ids
    )

  if (
    base::length(vec_unknown_parents) > 0L
  ) {
    cli::cli_abort(
      base::c(
        "A configuration profile has an unknown parent.",
        "x" = stringr::str_c(
          vec_unknown_parents,
          collapse = ", "
        )
      )
    )
  }

  vec_inheritance_depths <-
    vec_profile_ids |>
    purrr::map_int(
      .f = ~ {
        profile_id <- .x

        index_profile <-
          base::match(
            x = profile_id,
            table = vec_profile_ids
          )

        vec_visited_profiles <-
          profile_id

        current_parent <-
          vec_inheritance_parents[[index_profile]]

        inheritance_depth <- 0L

        while (
          !base::is.na(current_parent)
        ) {
          if (
            current_parent %in% vec_visited_profiles
          ) {
            cli::cli_abort(
              stringr::str_glue(
                "Inheritance cycle detected from profile `{profile_id}`."
              )
            )
          }

          vec_visited_profiles <-
            base::c(
              vec_visited_profiles,
              current_parent
            )

          inheritance_depth <-
            inheritance_depth + 1L

          index_parent <-
            base::match(
              x = current_parent,
              table = vec_profile_ids
            )

          current_parent <-
            vec_inheritance_parents[[index_parent]]
        }

        if (
          inheritance_depth >
            list_manifest[["maximum_inheritance_depth"]]
        ) {
          cli::cli_abort(
            stringr::str_glue(
              "Profile `{profile_id}` exceeds the maximum inheritance depth."
            )
          )
        }

        return(inheritance_depth)
      }
    )

  list_reference <-
    base::readRDS(
      base::file.path(
        path_source_root,
        list_manifest[["semantic_reference"]]
      )
    )

  if (
    !base::setequal(
      vec_profile_ids,
      list_reference[["profile_ids"]]
    )
  ) {
    cli::cli_abort(
      "Generated profile IDs differ from the semantic reference."
    )
  }

  vec_generated_config_lines <-
    base::c(
      "# GENERATED FILE - DO NOT EDIT DIRECTLY.",
      "# Edit Configuration fragments and run the documented generator.",
      "",
      vec_fragment_paths_relative |>
        purrr::map2(
          .y = list_fragment_lines,
          .f = ~ {
            return(
              base::c(
                base::paste0(
                  "# Source: ",
                  .x
                ),
                .y,
                ""
              )
            )
          }
        ) |>
        purrr::list_c()
    )

  index_last_generated_line <-
    vec_generated_config_lines |>
    base::nzchar() |>
    base::which() |>
    base::max()

  vec_generated_config_lines <-
    vec_generated_config_lines |>
    utils::head(index_last_generated_line)

  path_validation_directory <-
    base::tempfile(
      pattern = "configuration-generation-"
    )

  base::dir.create(
    path = path_validation_directory,
    recursive = TRUE,
    showWarnings = FALSE
  )

  on.exit(
    base::unlink(
      x = path_validation_directory,
      recursive = TRUE,
      force = TRUE
    ),
    add = TRUE
  )

  path_validation_config <-
    base::file.path(
      path_validation_directory,
      "config.yml"
    )

  base::writeLines(
    text = vec_generated_config_lines,
    con = path_validation_config,
    useBytes = TRUE
  )

  list_resolved_profiles <-
    vec_profile_ids |>
    rlang::set_names() |>
    purrr::map(
      .f = ~ {
        profile_id <- .x

        return(
          config::get(
            config = profile_id,
            file = path_validation_config,
            use_parent = FALSE
          )
        )
      }
    )

  list_resolved_legacy_profiles <-
    list_resolved_profiles |>
    purrr::map(
      .f = ~ {
        list_profile <- .x

        list_profile[["_profile"]] <- NULL

        base::attr(
          x = list_profile,
          which = "file"
        ) <- NULL

        return(list_profile)
      }
    )

  vec_profiles_unchanged <-
    vec_profile_ids |>
    purrr::map_lgl(
      .f = ~ {
        profile_id <- .x

        return(
          base::identical(
            list_resolved_legacy_profiles[[profile_id]],
            list_reference[["resolved_profiles"]][[profile_id]]
          )
        )
      }
    )

  vec_changed_profile_ids <-
    vec_profile_ids[
      !vec_profiles_unchanged
    ]

  if (
    base::length(vec_changed_profile_ids) > 0L
  ) {
    cli::cli_abort(
      base::c(
        "Generated profiles differ from the semantic reference.",
        "x" = stringr::str_c(
          vec_changed_profile_ids,
          collapse = ", "
        )
      )
    )
  }

  vec_semantic_hashes <-
    list_resolved_legacy_profiles |>
    purrr::map_chr(
      .f = ~ {
        return(
          digest::digest(
            object = .x,
            algo = "sha256"
          )
        )
      }
    )

  if (
    !base::identical(
      vec_semantic_hashes[
        list_reference[["profile_ids"]]
      ],
      list_reference[["semantic_hashes"]]
    )
  ) {
    cli::cli_abort(
      "Generated semantic hashes differ from the version-one reference."
    )
  }

  vec_target_stores <-
    list_resolved_profiles |>
    purrr::map_chr(
      .f = ~ {
        list_profile <- .x

        target_store <-
          list_profile[["target_store"]]

        if (
          base::is.null(target_store)
        ) {
          return(NA_character_)
        }

        return(
          base::as.character(target_store)
        )
      }
    )

  data_profile_catalog <-
    base::data.frame(
      profile_id = vec_profile_ids,
      role = vec_roles,
      status = vec_statuses,
      selectable = vec_selectable,
      pipeline = vec_pipelines,
      inherits = vec_inheritance_parents,
      inheritance_depth = vec_inheritance_depths,
      related_issue = vec_related_issues,
      target_store = vec_target_stores,
      supported_runners = vec_supported_runners,
      source_fragment = vec_profile_fragments,
      description = vec_descriptions,
      retirement = vec_retirement,
      semantic_hash = vec_semantic_hashes[vec_profile_ids],
      stringsAsFactors = FALSE
    )

  data_profile_catalog[["inherits"]][
    base::is.na(data_profile_catalog[["inherits"]])
  ] <- "default"

  data_profile_catalog[["related_issue"]] <-
    base::ifelse(
      test = base::is.na(
        data_profile_catalog[["related_issue"]]
      ),
      yes = "",
      no = paste0(
        "#",
        data_profile_catalog[["related_issue"]]
      )
    )

  vec_catalog_lines <-
    base::c(
      "# Configuration profile catalog",
      "",
      "Generated from `Configuration/manifest.yml`. Do not edit manually.",
      "",
      paste0(
        "Profiles: ",
        base::nrow(data_profile_catalog),
        ". Maximum explicit inheritance depth: ",
        base::max(data_profile_catalog[["inheritance_depth"]]),
        "."
      ),
      "",
      paste0(
        "| Profile | Role | Status | Selectable | Pipeline | Parent | ",
        "Issue | Target store | Supported runner | Source |"
      ),
      paste0(
        "|---|---|---|---:|---|---|---|---|---|---|"
      ),
      base::seq_len(
        base::nrow(data_profile_catalog)
      ) |>
        purrr::map_chr(
          .f = ~ {
            index_profile <- .x

            data_profile <-
              data_profile_catalog[
                index_profile,
                ,
                drop = FALSE
              ]

            vec_catalog_values <-
              base::c(
                data_profile[["profile_id"]],
                data_profile[["role"]],
                data_profile[["status"]],
                base::tolower(data_profile[["selectable"]]),
                data_profile[["pipeline"]],
                data_profile[["inherits"]],
                data_profile[["related_issue"]],
                data_profile[["target_store"]],
                data_profile[["supported_runners"]],
                data_profile[["source_fragment"]]
              )

            vec_catalog_values <-
              stringr::str_replace_all(
                string = vec_catalog_values,
                pattern = stringr::fixed("|"),
                replacement = "\\|"
              )

            return(
              paste0(
                "| ",
                stringr::str_c(
                  vec_catalog_values,
                  collapse = " | "
                ),
                " |"
              )
            )
          }
        )
    )

  path_output_config <-
    base::file.path(
      path_destination_root,
      list_manifest[["output"]]
    )

  path_output_catalog <-
    base::file.path(
      path_destination_root,
      list_manifest[["catalog"]]
    )

  base::dir.create(
    path = base::dirname(path_output_config),
    recursive = TRUE,
    showWarnings = FALSE
  )
  base::dir.create(
    path = base::dirname(path_output_catalog),
    recursive = TRUE,
    showWarnings = FALSE
  )

  base::writeLines(
    text = vec_generated_config_lines,
    con = path_output_config,
    useBytes = TRUE
  )
  base::writeLines(
    text = vec_catalog_lines,
    con = path_output_catalog,
    useBytes = TRUE
  )

  cli::cli_inform(
    base::c(
      "v" = "Project configuration generated.",
      "i" = stringr::str_glue(
        "{base::length(vec_profile_ids)} profiles remain ",
        "semantically identical to the v1 reference."
      )
    )
  )

  return(data_profile_catalog)
}
