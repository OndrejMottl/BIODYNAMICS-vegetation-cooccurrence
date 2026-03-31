#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurence
#
#                       Run tests
#
#
#                       O. Mottl
#                         2025
# ;
#----------------------------------------------------------#
# Run all tests in the project

library(here)

source(
  here::here("R/___setup_project___.R")
)

library(covr)
library(jsonlite)

data_covr <-
  covr::file_coverage(
    source_files = list.files(
      here::here("R/Functions/"),
      recursive = TRUE,
      full.names = TRUE
    ) %>%
      purrr::discard(
        # Exclude outdated functions (e.g. HMSC-based)
        ~ stringr::str_detect(.x, "_outdated")
      ),
    test_files = list.files(
      here::here(
        "R/03_Supplementary_analyses/testthat"
      ),
      recursive = TRUE,
      full.names = TRUE
    ) %>%
      purrr::discard(
        # Exclude outdated tests (e.g. HMSC-based)
        ~ stringr::str_detect(.x, "_outdated")
      )
  )

data_covr %>%
  as.data.frame() %>%
  jsonlite::write_json(
    path = here::here(
      "Documentation/Functions_test_coverage/covr_report.json"
    ),
    auto_unbox = TRUE,
    pretty = TRUE
  )

covr::report(
  x = data_covr,
  file = here::here(
    "docs/Documentation/Functions_test_coverage/covr_report.html"
  ),
  browse = FALSE
)

#----------------------------------------------------------#
# Apply BIODYNAMICS brand theme to coverage report -----
#----------------------------------------------------------#
# covr::report() hardcodes styles; patch the HTML after generation.

vec_report_path <-
  here::here(
    "docs/Documentation/Functions_test_coverage/covr_report.html"
  )

str_html <-
  base::readLines(
    con = vec_report_path,
    encoding = "UTF-8",
    warn = FALSE
  ) |>
  base::paste(collapse = "\n")

str_brand_css <-
  "
  :root {
    --bd-bg      : #0B0F14;
    --bd-surface : #141B22;
    --bd-border  : #2A3441;
    --bd-text    : #E6EDF3;
    --bd-muted   : #98A6B3;
    --bd-green   : #8DF59A;
    --bd-amber   : #FFB35C;
    --bd-red     : #FF7B72;
  }
  body {
    background-color : var(--bd-bg)   !important;
    color            : var(--bd-text) !important;
    font-family : 'IBM Plex Sans', system-ui, sans-serif !important;
  }
  h1, h2, h3, h4, h5, h6 {
    font-family : 'IBM Plex Mono', monospace !important;
    color       : var(--bd-text) !important;
  }
  a       { color: var(--bd-green) !important; }
  a:hover { color: var(--bd-amber) !important; }
  .container-fluid { background-color: var(--bd-bg) !important; }
  .nav-tabs { border-bottom-color: var(--bd-border) !important; }
  .nav-tabs > li > a {
    font-family      : 'IBM Plex Mono', monospace   !important;
    color            : var(--bd-muted)   !important;
    background-color : var(--bd-surface) !important;
    border-color     : var(--bd-border)  !important;
  }
  .nav-tabs > li.active > a,
  .nav-tabs > li.active > a:hover,
  .nav-tabs > li.active > a:focus {
    color            : var(--bd-green) !important;
    background-color : var(--bd-bg)    !important;
    border-color : var(--bd-border) var(--bd-border) var(--bd-bg) !important;
  }
  .nav-tabs > li > a:hover {
    color            : var(--bd-amber)   !important;
    background-color : var(--bd-surface) !important;
  }
  .tab-content { background-color: var(--bd-bg) !important; }
  table, table.dataTable {
    background-color : var(--bd-surface) !important;
    color            : var(--bd-text)    !important;
  }
  table.dataTable thead th,
  table.dataTable thead td {
    color            : var(--bd-green)   !important;
    font-family      : 'IBM Plex Mono', monospace !important;
    border-bottom    : 1px solid var(--bd-border)  !important;
    background-color : var(--bd-surface) !important;
  }
  table tbody { border-color: var(--bd-border) !important; }
  table.row-border tbody tr td {
    border-top-color : var(--bd-border) !important;
  }
  table tr td { color: var(--bd-text) !important; }
  table .num {
    border-right-color : var(--bd-border) !important;
    color              : var(--bd-muted)  !important;
    font-family  : 'IBM Plex Mono', monospace !important;
  }
  table td.coverage {
    border-right-color : var(--bd-border) !important;
    font-family  : 'IBM Plex Mono', monospace !important;
  }
  table tr.covered td {
    background-color : rgba(141, 245, 154, 0.10) !important;
  }
  table tr:hover.covered .num {
    background-color : rgba(141, 245, 154, 0.30) !important;
  }
  table tr.missed td {
    background-color : rgba(255, 123, 114, 0.12) !important;
  }
  table tr:hover.missed .num {
    background-color : rgba(255, 123, 114, 0.30) !important;
  }
  table tr.missed:hover td {
    box-shadow : 0 -2px 0 0 var(--bd-red)   inset !important;
  }
  table tr.covered:hover td {
    box-shadow : 0 -2px 0 0 var(--bd-green) inset !important;
  }
  pre, code {
    background-color : var(--bd-surface) !important;
    color            : var(--bd-text)    !important;
    border-color     : var(--bd-border)  !important;
    font-family  : 'IBM Plex Mono', monospace !important;
  }
  table.table-condensed pre { background-color : transparent !important; }
  ::-webkit-scrollbar { background-color: var(--bd-bg); }
  ::-webkit-scrollbar-thumb {
    background-color : var(--bd-border);
    border-radius    : 3px;
  }
  "

# Inject Google Fonts link and brand CSS, replacing the default body
# style tag that covr::report() embeds in <head>.
str_html <-
  stringr::str_replace(
    string = str_html,
    pattern = stringr::fixed(
      "<style>body{background-color:white;}</style>"
    ),
    replacement = base::paste0(
      "<link href=\"https://fonts.googleapis.com/css2?",
      "family=IBM+Plex+Mono:wght@400;500;600",
      "&family=IBM+Plex+Sans:wght@400;500;600;700",
      "&display=swap\" rel=\"stylesheet\">\n",
      "<style>\n",
      str_brand_css,
      "\n</style>"
    )
  )

# Replace coverage column gradient stops with brand palette.
# Note: The colors are hardcoded inside the DataTables cell-renderer
#   callback that is embedded as a JSON string in the <script> block;
#   they must be patched as literal text substitutions.
str_html <-
  stringr::str_replace_all(
    string = str_html,
    pattern = stringr::fixed("#edfde7"),
    replacement = "rgba(141,245,154,0.22)"
  )

str_html <-
  stringr::str_replace_all(
    string = str_html,
    pattern = stringr::fixed("#f9ffe5"),
    replacement = "rgba(255,179,92,0.22)"
  )

str_html <-
  stringr::str_replace_all(
    string = str_html,
    pattern = stringr::fixed("#fcece9"),
    replacement = "rgba(255,123,114,0.22)"
  )

# Replace the "white" gradient end-stop with the brand background.
# Note: Inside the JSON blob, double-quotes are escaped as \" so the
#   literal in-file text to match is: , white \" + cellData
str_html <-
  stringr::str_replace_all(
    string = str_html,
    pattern = stringr::fixed(", white \\\""),
    replacement = ", #0B0F14 \\\""
  )

base::cat(
  str_html,
  file = vec_report_path,
  sep = ""
)


covr:::tally_coverage(data_covr, by = "line") %>%
  covr:::percent_coverage(by = "line") %>%
  round(digits = 2) %>%
  list(value = .) %>%
  jsonlite::write_json(
    x = .,
    path = here::here(
      "Documentation/Functions_test_coverage/covr_report_summary.json"
    ),
    auto_unbox = TRUE,
    pretty = TRUE
  )
