#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#            Bootstrap configuration sources
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# One-time issue #151 split of the frozen flat config.yml.


#----------------------------------------------------------#
# 1. Verify the frozen source -----
#----------------------------------------------------------#

path_config <-
  here::here("config.yml")

path_reference <-
  here::here(
    "Documentation/Implementation_inventories/Configuration",
    "configuration_profile_reference_v1.rds"
  )

list_reference <-
  base::readRDS(path_reference)

hash_config <-
  digest::digest(
    object = path_config,
    algo = "sha256",
    file = TRUE
  )

if (
  !base::identical(
    hash_config,
    list_reference[["source_file_sha256"]]
  )
) {
  cli::cli_abort(
    base::c(
      "The configuration bootstrap only accepts the frozen source file.",
      "x" = "The current config.yml hash differs from the v1 reference."
    )
  )
}

vec_config_lines <-
  base::readLines(
    con = path_config,
    warn = FALSE,
    encoding = "UTF-8"
  )

vec_profile_start_indices <-
  base::grep(
    pattern = "^[A-Za-z0-9_]+:$",
    x = vec_config_lines
  )

vec_profile_ids <-
  vec_config_lines[vec_profile_start_indices] |>
  base::sub(
    pattern = ":$",
    replacement = ""
  )

list_profile_blocks <-
  stats::setNames(
    object = base::vector(
      mode = "list",
      length = base::length(vec_profile_ids)
    ),
    nm = vec_profile_ids
  )

for (
  index_profile in base::seq_along(vec_profile_ids)
) {
  index_start <-
    vec_profile_start_indices[[index_profile]]

  index_end <-
    if (
      index_profile == base::length(vec_profile_ids)
    ) {
      base::length(vec_config_lines)
    } else {
      vec_profile_start_indices[[index_profile + 1L]] - 1L
    }

  list_profile_blocks[[index_profile]] <-
    vec_config_lines[index_start:index_end]
}


#----------------------------------------------------------#
# 2. Define the approved profile classification -----
#----------------------------------------------------------#

data_profiles <-
  base::data.frame(
    profile_id = vec_profile_ids,
    target_fragment = base::c(
      "Configuration/Defaults/default.yml",
      "Configuration/Profiles/Validation/cz_smoke.yml",
      base::rep(
        "Configuration/Profiles/References/cross_validation.yml",
        5L
      ),
      "Configuration/Profiles/References/traits.yml",
      base::rep(
        "Configuration/Profiles/Main/Paleo/temporal.yml",
        3L
      ),
      base::rep(
        "Configuration/Profiles/Main/Paleo/spatial.yml",
        3L
      ),
      base::rep(
        "Configuration/Profiles/References/cross_validation.yml",
        2L
      ),
      base::rep(
        "Configuration/Profiles/Main/Modern/spatial.yml",
        3L
      ),
      "Configuration/Profiles/Validation/cz_smoke.yml",
      base::rep(
        "Configuration/Profiles/One_time/Issues/issue_138.yml",
        2L
      ),
      "Configuration/Profiles/One_time/Issues/issue_143.yml",
      base::rep(
        "Configuration/Profiles/One_time/Issues/issue_138.yml",
        3L
      )
    ),
    role = base::c(
      "base",
      "smoke",
      base::rep("reference", 6L),
      base::rep("main", 6L),
      base::rep("reference", 2L),
      base::rep("main", 3L),
      "smoke",
      base::rep("one_time", 6L)
    ),
    status = base::c(
      "active",
      "active",
      base::rep("frozen", 6L),
      base::rep("active", 6L),
      base::rep("frozen", 2L),
      base::rep("active", 3L),
      "active",
      base::rep("frozen", 6L)
    ),
    selectable = base::c(
      FALSE,
      TRUE,
      base::rep(FALSE, 6L),
      base::rep(TRUE, 6L),
      base::rep(FALSE, 2L),
      base::rep(TRUE, 3L),
      TRUE,
      base::rep(FALSE, 6L)
    ),
    pipeline = base::c(
      "shared",
      "paleo_smoke",
      "paleo_core_cv",
      "paleo_core_cv",
      "paleo_core_cv",
      "paleo_cv_component_reference",
      "paleo_cv_regularization_reference",
      "traits",
      base::rep("paleo_temporal", 3L),
      base::rep("paleo_spatial", 3L),
      "paleo_local_cv",
      "paleo_local_cv_decomposition",
      base::rep("modern_spatial", 3L),
      "modern_spatial_smoke",
      "issue_138_paleo_spatial",
      "issue_138_modern_spatial",
      "issue_143_modern_spatial",
      base::rep("issue_138_paleo_temporal", 3L)
    ),
    related_issue = base::c(
      NA_integer_,
      NA_integer_,
      139L,
      139L,
      138L,
      139L,
      139L,
      NA_integer_,
      base::rep(NA_integer_, 6L),
      141L,
      141L,
      base::rep(NA_integer_, 3L),
      NA_integer_,
      138L,
      138L,
      143L,
      base::rep(138L, 3L)
    ),
    stringsAsFactors = FALSE
  )

data_profiles[["description"]] <-
  base::c(
    "Shared defaults inherited by project profiles.",
    "Small Czech paleo workflow for smoke validation.",
    "Frozen CPU reference for Czech paleo cross-validation.",
    "Frozen GPU reference for Czech paleo cross-validation.",
    "Frozen staged GPU reference paired with the exhaustive reference.",
    "Frozen Czech paleo component reference workflow.",
    "Frozen Czech paleo regularization reference workflow.",
    "Reference profile for the functional-trait pipeline.",
    "Main European paleo-temporal analysis.",
    "Main American paleo-temporal analysis.",
    "Main Asian paleo-temporal analysis.",
    "Main continental paleo-spatial analysis.",
    "Main regional paleo-spatial analysis.",
    "Main local paleo-spatial analysis.",
    "Frozen local paleo scientific-performance reference.",
    "Frozen local paleo decomposition reference.",
    "Main continental modern-spatial analysis.",
    "Main regional modern-spatial analysis.",
    "Main local modern-spatial analysis.",
    "Small Czech modern workflow for smoke validation.",
    "Issue 138 staged continental paleo benchmark.",
    "Issue 138 staged continental modern benchmark.",
    "Issue 143 shared-MEM continental modern benchmark.",
    "Issue 138 staged European temporal benchmark.",
    "Issue 138 staged American temporal benchmark.",
    "Issue 138 staged Asian temporal benchmark."
  )

vec_reference_retirement <-
  "Retain while Issue 141 contract validation uses this reference."

vec_issue_138_retirement <-
  paste(
    "Archive only after Issue 141 no longer requires",
    "Issue 138 benchmark reproduction."
  )

data_profiles[["retirement"]] <-
  base::c(
    base::rep(NA_character_, 2L),
    base::rep(vec_reference_retirement, 5L),
    "Retain while the functional-trait reference pipeline is supported.",
    base::rep(NA_character_, 6L),
    base::rep(vec_reference_retirement, 2L),
    base::rep(NA_character_, 4L),
    base::rep(vec_issue_138_retirement, 2L),
    paste(
      "Archive only after the shared-MEM implementation no longer",
      "requires Issue 143 reproduction."
    ),
    base::rep(vec_issue_138_retirement, 3L)
  )

list_supported_runners <-
  stats::setNames(
    object = base::list(
      base::character(),
      "R/03_Supplementary_analyses/Testing/Smoke/run_cz_pipelines.R",
      "R/03_Supplementary_analyses/Validation/Cross_validation/Reference_runs/run_cz_paleo_cv_reference.R",
      "R/03_Supplementary_analyses/Validation/Cross_validation/Reference_runs/run_cz_paleo_cv_reference_gpu.R",
      "R/03_Supplementary_analyses/Validation/Cross_validation/Reference_runs/run_cz_paleo_cv_staged_reference_gpu.R",
      "R/03_Supplementary_analyses/Validation/Cross_validation/Reference_runs/run_cz_paleo_cv_component_reference_gpu.R",
      "R/03_Supplementary_analyses/Validation/Cross_validation/Reference_runs/run_cz_paleo_cv_regularization_reference_gpu.R",
      "R/01_Data_processing/Traits/Run_trait_analyses.R",
      "R/02_Main_analyses/02_Temporal/01_Paleo/01_Runners/01_run_temporal_europe.R",
      "R/02_Main_analyses/02_Temporal/01_Paleo/01_Runners/02_run_temporal_america.R",
      "R/02_Main_analyses/02_Temporal/01_Paleo/01_Runners/03_run_temporal_asia.R",
      "R/02_Main_analyses/01_Spatial/01_Paleo/01_Runners/01_run_spatial_continental.R",
      "R/02_Main_analyses/01_Spatial/01_Paleo/01_Runners/02_run_spatial_regional.R",
      "R/02_Main_analyses/01_Spatial/01_Paleo/01_Runners/03_run_spatial_local.R",
      "R/03_Supplementary_analyses/Validation/Cross_validation/Reference_runs/run_paleo_local_cv_scientific_reference_gpu.R",
      "R/03_Supplementary_analyses/Validation/Cross_validation/Reference_runs/run_paleo_local_cv_decomposition_reference_gpu.R",
      paste0(
        "R/02_Main_analyses/01_Spatial/02_Modern/01_Runners/",
        "01_run_modern_continental.R"
      ),
      paste0(
        "R/02_Main_analyses/01_Spatial/02_Modern/01_Runners/",
        "02_run_modern_regional.R"
      ),
      paste0(
        "R/02_Main_analyses/01_Spatial/02_Modern/01_Runners/",
        "03_run_modern_local.R"
      ),
      "R/03_Supplementary_analyses/Testing/Smoke/run_cz_pipelines.R",
      "R/03_Supplementary_analyses/One_time/Issues/issue_138/run_paleo_continental_europe_staged.R",
      "R/03_Supplementary_analyses/One_time/Issues/issue_138/run_modern_continental_europe_staged.R",
      "R/03_Supplementary_analyses/One_time/Issues/issue_143/run_modern_continental_europe_shared_mem.R",
      "R/03_Supplementary_analyses/One_time/Issues/issue_138/run_temporal_europe_staged.R",
      "R/03_Supplementary_analyses/One_time/Issues/issue_138/run_temporal_america_staged.R",
      "R/03_Supplementary_analyses/One_time/Issues/issue_138/run_temporal_asia_staged.R"
    ),
    nm = vec_profile_ids
  )

if (
  !base::identical(
    data_profiles[["profile_id"]],
    vec_profile_ids
  )
) {
  cli::cli_abort(
    "The profile classification does not match the frozen source order."
  )
}


#----------------------------------------------------------#
# 3. Add metadata and write initial fragments -----
#----------------------------------------------------------#

vec_fragment_paths <-
  base::unique(data_profiles[["target_fragment"]])

for (
  path_fragment_relative in vec_fragment_paths
) {
  vec_fragment_profile_ids <-
    data_profiles[["profile_id"]][
      data_profiles[["target_fragment"]] == path_fragment_relative
    ]

  vec_fragment_lines <-
    base::c(
      "# Human-authored configuration source.",
      "# Regenerate config.yml; do not copy this fragment manually.",
      ""
    )

  for (
    profile_id in vec_fragment_profile_ids
  ) {
    index_profile <-
      base::match(
        x = profile_id,
        table = data_profiles[["profile_id"]]
      )

    data_profile <-
      data_profiles[index_profile, , drop = FALSE]

    vec_metadata_lines <-
      base::c(
        "  _profile:",
        paste0("    role: ", data_profile[["role"]]),
        paste0("    status: ", data_profile[["status"]]),
        paste0(
          "    selectable: ",
          base::tolower(data_profile[["selectable"]])
        ),
        paste0("    pipeline: ", data_profile[["pipeline"]]),
        paste0(
          "    description: ",
          base::encodeString(
            data_profile[["description"]],
            quote = "\""
          )
        ),
        if (
          base::is.na(data_profile[["related_issue"]])
        ) {
          "    related_issue: ~"
        } else {
          paste0(
            "    related_issue: ",
            data_profile[["related_issue"]]
          )
        },
        if (
          base::is.na(data_profile[["retirement"]])
        ) {
          "    retirement: ~"
        } else {
          paste0(
            "    retirement: ",
            base::encodeString(
              data_profile[["retirement"]],
              quote = "\""
            )
          )
        },
        "    supported_runners:"
      )

    vec_profile_runners <-
      list_supported_runners[[profile_id]]

    if (
      base::length(vec_profile_runners) == 0L
    ) {
      vec_metadata_lines <-
        base::c(
          vec_metadata_lines,
          "      []"
        )
    } else {
      vec_metadata_lines <-
        base::c(
          vec_metadata_lines,
          paste0(
            "      - ",
            vec_profile_runners
          )
        )
    }

    vec_fragment_lines <-
      base::c(
        vec_fragment_lines,
        list_profile_blocks[[profile_id]],
        vec_metadata_lines,
        ""
      )
  }

  path_fragment <-
    here::here(path_fragment_relative)

  base::dir.create(
    path = base::dirname(path_fragment),
    recursive = TRUE,
    showWarnings = FALSE
  )

  base::writeLines(
    text = vec_fragment_lines,
    con = path_fragment,
    useBytes = TRUE
  )
}

cli::cli_inform(
  base::c(
    "v" = "Initial configuration fragments created.",
    "i" = paste(
      base::length(vec_profile_ids),
      "profiles across",
      base::length(vec_fragment_paths),
      "fragments."
    )
  )
)
