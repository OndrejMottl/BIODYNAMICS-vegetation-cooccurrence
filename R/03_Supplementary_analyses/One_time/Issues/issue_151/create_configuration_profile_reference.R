#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          Create configuration semantic reference
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# One-time issue #151 reference from the pre-migration config.yml.

path_config <-
  here::here("config.yml")

hash_expected_source <-
  "cd3749d3c0c3e0152d8705c4333d2a336977be72bffab5c68883ab12a48559c7"

hash_source <-
  digest::digest(
    object = path_config,
    algo = "sha256",
    file = TRUE
  )

if (
  !base::identical(
    hash_source,
    hash_expected_source
  )
) {
  cli::cli_abort(
    "The semantic reference requires the exact pre-migration config.yml."
  )
}

list_raw_profiles <-
  yaml::read_yaml(
    file = path_config,
    handlers = base::list(
      expr = function(value) {
        value
      }
    )
  )

vec_profile_ids <-
  base::names(list_raw_profiles)

list_resolved_profiles <-
  stats::setNames(
    object = base::lapply(
      X = vec_profile_ids,
      FUN = function(profile_id) {
        list_profile <-
          config::get(
            config = profile_id,
            file = path_config,
            use_parent = FALSE
          )

        base::attr(
          x = list_profile,
          which = "file"
        ) <- NULL

        list_profile
      }
    ),
    nm = vec_profile_ids
  )

vec_semantic_hashes <-
  base::vapply(
    X = list_resolved_profiles,
    FUN = digest::digest,
    FUN.VALUE = base::character(1L),
    algo = "sha256"
  )

list_reference <-
  base::list(
    reference_version = 1L,
    created_from_commit = "1b163e16",
    source_path = "config.yml",
    source_file_sha256 = hash_source,
    aggregate_semantic_sha256 = digest::digest(
      object = list_resolved_profiles,
      algo = "sha256"
    ),
    r_version = R.version.string,
    config_version = base::as.character(
      utils::packageVersion("config")
    ),
    profile_ids = vec_profile_ids,
    semantic_hashes = vec_semantic_hashes,
    resolved_profiles = list_resolved_profiles
  )

path_reference <-
  here::here(
    "Documentation/Implementation_inventories/Configuration",
    "configuration_profile_reference_v1.rds"
  )

base::dir.create(
  path = base::dirname(path_reference),
  recursive = TRUE,
  showWarnings = FALSE
)

base::saveRDS(
  object = list_reference,
  file = path_reference,
  version = 3L
)

cli::cli_inform(
  base::c(
    "v" = "Configuration semantic reference created.",
    "i" = stringr::str_glue(
      "{base::length(vec_profile_ids)} profiles; aggregate hash ",
      "{list_reference[['aggregate_semantic_sha256']]}."
    )
  )
)
