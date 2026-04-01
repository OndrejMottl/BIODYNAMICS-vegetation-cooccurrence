---
applyTo: "**/*.R"
description: >
  Visualisation conventions for this project: loading graphical options
  from config, using ggview::canvas() for plot dimensions, and saving
  with ggview::save_ggplot().
---

# Visualisation Guidelines

## Graphical Options

All canvas dimensions and output settings are stored centrally in the `graphical:` section of `config.yml` under `default:`. The defaults are:

```yaml
graphical:
  width: 2000
  height: 1600
  units: "px"
  dpi: 300
  bg: "white"
```

Project-specific configurations inherit these defaults automatically. Override individual values in any project config block only when a specific output requires different dimensions or quality.

## Loading Graphical Options in a Script

At the start of every script that produces plots, load the graphical options once in the **Setup** section  -  after `R_CONFIG_ACTIVE` has been set  -  and store them in `graphical_options`:

```r
# Graphical options shared across all plots in this script.
graphical_options <-
  get_active_config("graphical")
```

This must be placed **after** `Sys.setenv(R_CONFIG_ACTIVE = "...")` so that `get_active_config()` resolves the correct configuration.

## Applying Canvas Dimensions

Every `ggplot2` plot object must be extended with `ggview::canvas()` before being saved. Append it with `+` directly after the plot call, using the values loaded from `graphical_options`:

```r
plot_example <-
  my_plot_function(
    data = data_example,
    title = "Example title"
  ) +
  ggview::canvas(
    width = graphical_options[["width"]],
    height = graphical_options[["height"]],
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]],
    bg = graphical_options[["bg"]]
  )
```

**Never** hardcode width, height, dpi, or other canvas values directly in a script. Always read them from `graphical_options`.

## Plot Layer Order

When building a `ggplot2` plot directly (not via a wrapper function), always add layers in this order:

1. `ggplot2::ggplot()`  -  data and global aesthetics
2. Facets  -  `ggplot2::facet_*()` calls
3. Scales  -  `ggplot2::scale_*()` calls
4. Labels  -  `ggplot2::labs()`
5. Theme  -  `ggplot2::theme_*()` and `ggplot2::theme()` calls
6. `ggview::canvas()`  -  canvas dimensions
7. Geoms  -  `ggplot2::geom_*()` calls, from bottom to top layer

This keeps all structural/setup decisions together at the top and all data-ink decisions at the bottom, making it easy to scan what is being drawn versus how the chart is configured.

```r
# Good  -  setup first, geoms last
plot_example <-
  data_example |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(x = age, y = value, colour = group)
  ) +
  ggplot2::facet_wrap(ggplot2::vars(region)) +
  ggplot2::scale_x_continuous(trans = "reverse") +
  ggplot2::labs(x = "Age (cal yr BP)", y = NULL, colour = "Group") +
  ggplot2::theme_classic() +
  ggview::canvas(
    width = graphical_options[["width"]],
    height = graphical_options[["height"]],
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]],
    bg = graphical_options[["bg"]]
  ) +
  ggplot2::geom_line() +
  ggplot2::geom_point(size = 0.8)

# Avoid  -  geoms mixed in with or before setup layers
plot_example <-
  data_example |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(x = age, y = value, colour = group)
  ) +
  ggplot2::geom_line() +
  ggplot2::geom_point(size = 0.8) +
  ggplot2::scale_x_continuous(trans = "reverse") +
  ggplot2::labs(x = "Age (cal yr BP)", y = NULL, colour = "Group") +
  ggview::canvas(...)
```

## Saving Plots

Always use `ggview::save_ggplot()` (never `ggplot2::ggsave()`) to save plots. This ensures the canvas dimensions set by `ggview::canvas()` are respected in the output file:

```r
ggview::save_ggplot(
  plot = plot_example,
  file = base::file.path(
    path_output,
    "plot_example.pdf"
  )
)
```

## Complete Canonical Pattern

Below is the full pattern from setup through saving, showing the three parts together in context:

```r
#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

Sys.setenv(R_CONFIG_ACTIVE = "project_cz")

path_output <-
  here::here("Outputs/Figures/My_analysis")

base::dir.create(
  path = path_output,
  showWarnings = FALSE,
  recursive = TRUE
)

# Graphical options shared across all plots in this script.
graphical_options <-
  get_active_config("graphical")


#----------------------------------------------------------#
# 1. My plot -----
#----------------------------------------------------------#

plot_example <-
  my_plot_function(
    data = data_example,
    title = "Example title",
    subtitle = base::paste(
      "project:", Sys.getenv("R_CONFIG_ACTIVE")
    )
  ) +
  ggview::canvas(
    width = graphical_options[["width"]],
    height = graphical_options[["height"]],
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]],
    bg = graphical_options[["bg"]]
  )

ggview::save_ggplot(
  plot = plot_example,
  file = base::file.path(
    path_output,
    "plot_example.pdf"
  )
)
```

## Rules Summary

| Rule | Correct | Avoid |
|------|---------|-------|
| Load options once per script | `graphical_options <- get_active_config("graphical")` | Hardcoding values |
| Apply dimensions | `+ ggview::canvas(width = graphical_options[["width"]], ...)` | `+ ggview::canvas(width = 2000, ...)` |
| Save plots | `ggview::save_ggplot(plot = ..., file = ...)` | `ggplot2::ggsave(...)` |
| Layer order | Facets â†’ Scales â†’ Labs â†’ Theme â†’ Canvas â†’ Geoms | Geoms before setup layers |

