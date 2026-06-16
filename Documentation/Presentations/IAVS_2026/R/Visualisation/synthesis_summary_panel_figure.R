library(here)

base::source(
  here::here("R", "___setup_project___.R")
)

list_oracle_design <-
  load_design_config(
    path = here::here(
      "Documentation",
      "Presentations",
      "IAVS_2026",
      "design_config.json"
    )
  )

list_slide_12_figures <-
  base::list(
    synthesis_panel =
      save_result_placeholder(
        slide_label = "SLIDE 12",
        panel_label = "SYNTHESIS PANEL",
        title = "Verified synthesis placeholder",
        subtitle = "Space, taxonomy, and time summary",
        status_label = "PROVISIONAL // RESULT FRAMEWORK",
        file_name = "slide_12_synthesis_panel.png",
        width = 1600,
        height = 460
      )
  )
