#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#              Generate function documentation
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Generate fail-closed documentation for every active project function.

library(here)

source(
  here::here("R/___setup_project___.R")
)

vec_function_files <-
  fs::dir_ls(
    path = here::here("R/Functions"),
    recurse = TRUE,
    type = "file",
    regexp = "[.]R$"
  ) |>
  purrr::discard(
    ~ stringr::str_detect(
      .x,
      "(^|[/\\\\])_legacy([/\\\\]|$)"
    )
  ) |>
  base::sort()

text_selected_functions <-
  base::Sys.getenv("BIODYNAMICS_DOCUMENT_FUNCTIONS", unset = "")
flag_selective_generation <-
  base::nzchar(text_selected_functions)
if (
  flag_selective_generation
) {
  vec_selected_function_names <-
    text_selected_functions |>
    stringr::str_split_1(pattern = ",") |>
    stringr::str_trim()
  vec_function_files <-
    vec_function_files[
      fs::path_ext_remove(fs::path_file(vec_function_files)) %in%
        vec_selected_function_names
    ]
  assertthat::assert_that(
    base::length(vec_function_files) ==
      base::length(vec_selected_function_names),
    msg = "Every selectively requested function must exist."
  )
}

vec_function_names <-
  vec_function_files |>
  fs::path_file() |>
  fs::path_ext_remove()

assertthat::assert_that(
  base::anyDuplicated(vec_function_names) == 0L,
  msg = "Active function basenames must be unique before documentation."
)

path_function_documents <-
  here::here("Documentation/Functions")
path_function_qmd <-
  here::here("Documentation/Website/Documentation/Functions")
path_function_published <-
  here::here(
    "docs/Documentation/Website/Documentation/Functions"
  )

base::dir.create(
  path = path_function_documents,
  recursive = TRUE,
  showWarnings = FALSE
)
base::dir.create(
  path = path_function_qmd,
  recursive = TRUE,
  showWarnings = FALSE
)

list_generated_roots <-
  base::list(
    base::list(path = path_function_documents, extension = "html"),
    base::list(path = path_function_documents, extension = "txt"),
    base::list(path = path_function_documents, extension = "pdf"),
    base::list(path = path_function_qmd, extension = "qmd"),
    base::list(path = path_function_published, extension = "html")
  )

purrr::walk(
  .x = list_generated_roots,
  .f = ~ {
    if (!base::dir.exists(.x[["path"]])) {
      return(invisible(NULL))
    }

    vec_artifacts <-
      fs::dir_ls(
        path = .x[["path"]],
        type = "file",
        regexp = stringr::str_c("[.]", .x[["extension"]], "$")
      )
    if (
      flag_selective_generation
    ) {
      vec_artifacts <-
        vec_artifacts[
          fs::path_ext_remove(fs::path_file(vec_artifacts)) %in%
            vec_function_names
        ]
    }
    if (base::length(vec_artifacts) > 0L) {
      fs::file_delete(vec_artifacts)
    }

    return(invisible(NULL))
  }
)

purrr::walk(
  .x = vec_function_files,
  .f = ~ {
    path_working_directory <-
      base::tempfile(pattern = "document_function_")
    path_package_name <-
      .x |>
      fs::path_file() |>
      fs::path_ext_remove() |>
      stringr::str_replace_all("_", ".")
    path_package_directory <-
      base::file.path(path_working_directory, path_package_name)
    path_manual_directory <-
      base::file.path(path_package_directory, "man")
    base::dir.create(
      path_working_directory,
      recursive = TRUE,
      showWarnings = FALSE
    )
    base::on.exit(
      base::unlink(path_working_directory, recursive = TRUE),
      add = TRUE
    )
    vec_roxygen_code <-
      fritools::get_lines_between_tags(.x)
    path_code_file <-
      base::file.path(path_working_directory, "code.R")
    base::writeLines(vec_roxygen_code, con = path_code_file)
    base::suppressMessages(
      utils::package.skeleton(
        code_files = path_code_file,
        name = path_package_name,
        path = path_working_directory,
        force = TRUE,
        encoding = "UTF-8"
      )
    )
    base::file.remove(path_code_file)
    base::file.remove(
      base::list.files(path_manual_directory, full.names = TRUE)
    )
    base::file.remove(
      base::file.path(path_package_directory, "NAMESPACE")
    )
    utils::capture.output(
      roxygen2::roxygenize(package.dir = path_package_directory)
    )
    fun_write_documentation <-
      utils::getFromNamespace("write_the_docs", "document")
    generation_result <-
      fun_write_documentation(
        package_directory = path_package_directory,
        file_name = .x,
        output_directory = path_function_documents
      )

    path_expected_html <-
      base::file.path(
        path_function_documents,
        stringr::str_c(fs::path_ext_remove(fs::path_file(.x)), ".html")
      )
    path_expected_txt <-
      base::file.path(
        path_function_documents,
        stringr::str_c(fs::path_ext_remove(fs::path_file(.x)), ".txt")
      )
    if (
      !base::file.exists(path_expected_html) ||
        !base::file.exists(path_expected_txt)
    ) {
      cli::cli_abort(
        message = "Function documentation failed for {.x}.",
        class = "biodynamics_error_function_documentation"
      )
    }

    return(invisible(NULL))
  }
)

vec_missing_pdf_names <-
  vec_function_names[
    !base::file.exists(
      base::file.path(
        path_function_documents,
        stringr::str_c(vec_function_names, ".pdf")
      )
    )
  ]

purrr::walk(
  .x = vec_missing_pdf_names,
  .f = ~ webshot2::webshot(
    url = base::normalizePath(
      base::file.path(
        path_function_documents,
        stringr::str_c(.x, ".html")
      ),
      winslash = "/",
      mustWork = TRUE
    ),
    file = base::file.path(
      path_function_documents,
      stringr::str_c(.x, ".pdf")
    ),
    quiet = TRUE
  )
)

purrr::walk(
  .x = vec_function_names,
  .f = ~ {
    path_html <-
      base::file.path(
        path_function_documents,
        stringr::str_c(.x, ".html")
      )

    if (!base::file.exists(path_html)) {
      cli::cli_abort(
        message = "Function documentation HTML is missing for {.x}.",
        class = "biodynamics_error_function_documentation"
      )
    }

    vec_html <-
      base::readLines(
        con = path_html,
        warn = FALSE,
        encoding = "UTF-8"
      ) |>
      purrr::discard(~ stringr::str_detect(.x, "^<!DOCTYPE html>")) |>
      stringr::str_remove("<title>.*</title>")

    vec_qmd <-
      base::c(
        "---",
        "format: html",
        stringr::str_c("title: ", .x, "()"),
        "---",
        "",
        vec_html
      )

    readr::write_lines(
      x = vec_qmd,
      file = base::file.path(
        path_function_qmd,
        stringr::str_c(.x, ".qmd")
      ),
      sep = "\n"
    )

    return(invisible(NULL))
  }
)

vec_required_artifacts <-
  base::c(
    base::file.path(
      path_function_documents,
      stringr::str_c(vec_function_names, ".html")
    ),
    base::file.path(
      path_function_documents,
      stringr::str_c(vec_function_names, ".txt")
    ),
    base::file.path(
      path_function_documents,
      stringr::str_c(vec_function_names, ".pdf")
    ),
    base::file.path(
      path_function_qmd,
      stringr::str_c(vec_function_names, ".qmd")
    )
  )

vec_missing_artifacts <-
  vec_required_artifacts[!base::file.exists(vec_required_artifacts)]

if (base::length(vec_missing_artifacts) > 0L) {
  cli::cli_abort(
    message = base::c(
      "Function documentation generation is incomplete.",
      "x" = vec_missing_artifacts
    ),
    class = "biodynamics_error_function_documentation"
  )
}

vec_generated_text_artifacts <-
  vec_required_artifacts[
    stringr::str_detect(vec_required_artifacts, "[.](html|txt|qmd)$")
  ]

purrr::walk(
  .x = vec_generated_text_artifacts,
  .f = ~ {
    vec_lines <-
      base::readLines(
        con = .x,
        warn = FALSE,
        encoding = "UTF-8"
      ) |>
      stringr::str_replace("[[:blank:]]+$", "")

    while (
      base::length(vec_lines) > 0L &&
        vec_lines[[base::length(vec_lines)]] == ""
    ) {
      vec_lines <- vec_lines[-base::length(vec_lines)]
    }

    readr::write_lines(
      x = vec_lines,
      file = .x,
      sep = "\n"
    )

    return(invisible(NULL))
  }
)

cli::cli_inform(
  base::c(
    "v" = "Function documentation generated without suppressed failures.",
    "i" = "{base::length(vec_function_names)} active functions documented."
  )
)
