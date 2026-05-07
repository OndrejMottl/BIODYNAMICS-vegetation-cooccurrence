# BIODYNAMICS Vegetation Co-occurrence Project

## Overview

This project analyzes vegetation co-occurrence patterns using paleoecological and modern vegetation data. The project uses R for data processing, statistical modeling, and visualization.

## Coding Standards

This project follows specific R coding conventions split across five instruction files:

- [r-coding.instructions.md](instructions/r-coding.instructions.md) — Script structure, naming, syntax
- [r-coding-tidyverse.instructions.md](instructions/r-coding-tidyverse.instructions.md) — Tidyverse, namespace, dplyr/purrr, data masking
- [r-coding-functions.instructions.md](instructions/r-coding-functions.instructions.md) — Writing functions, error handling, docs, tests
- [r-coding-performance.instructions.md](instructions/r-coding-performance.instructions.md) — Profiling and performance
- [r-coding-visualisation.instructions.md](instructions/r-coding-visualisation.instructions.md) — Canvas dimensions, ggview, saving plots

## Project Structure

### Files & Folders

Do not add numbering to folders or files at the start of a workflow. Add numbering only later if it is necessary to guide analysis order, because early numbering tends to create avoidable version-control churn.

#### Folder Names

- Underscore with only the first letter capitalized (Capital_snake_style)

#### File Naming

- Underscore with only the first letter capitalized (Capital_snake_style)
- File name should contain dates
  - dates should be in YYYY-MM-DD format
  - see [{RUtilpol}](https://github.com/HOPE-UIB-BIO/R-Utilpol-package) for easy handling of file version control

##### Temporary Files

- Temporary data files should not hold any important information
- No links between Temp files and scripts on GitHub
- `Data/Temp` should be included in `.gitignore`

#### Safe Paths

All paths should be using the [here](https://here.r-lib.org/) package to make sure that they work on all machines.

### Package Dependencies

The [{renv} package](https://rstudio.github.io/renv/articles/renv.html) is used for R package dependency management to ensure reproducibility.

The `___Init_project___.R` script is used for the preparation of all R packages. It will install [{RUtilpol}](https://github.com/HOPE-UIB-BIO/R-Utilpol-package) and all dependencies, which is used throughout the project for version control of files.

### Cascade of R Scripts

This project is constructed using a *script cascade*. This means that scripts can execute other scripts hierarchically:

- The master script in the `R` folder executes scripts within sub-folders
- Sub-folder scripts (like `R/01_Data_processing/Run_01.R`) can execute their own child scripts
- This creates a modular, organized workflow

Example: `R/01_Data_processing/Run_01.R` executes:

- `R/01_Data_processing/01_full_data_process.R`
- `R/01_Data_processing/02_data_overview.R`
- `R/01_Data_processing/03_data_ant_counts.R`
- …and so on

### Configuration File

The configuration file (`___setup_project___.R`) is central to this project. It:

- Defines global variables and constants
- Loads custom functions from the `R/Functions/` directory
- Specifies file paths for data inputs and outputs
- Sets up project-wide dependencies

**Usage**: Every script should initiate with:

```r
source(
  here::here("R/___setup_project___.R")
)
```

This approach:

- Minimizes code repetition
- Establishes an abstraction layer for centralized changes
- Allows path references by variable name
- Enables easy transitions (e.g., from down-sampled to full data)

Update the configuration file once, and changes propagate throughout the project.

### Pipeline Management with {targets}

This project uses the [{targets}](https://docs.ropensci.org/targets/) package for reproducible pipeline management. The targets framework ensures:

- **Reproducibility**: All analyses follow a defined, traceable workflow
- **Efficiency**: Only out-of-date targets are re-computed when dependencies change
- **Scalability**: Parallel processing and caching for large-scale analyses
- **Transparency**: Clear visualization of pipeline dependencies

#### Pipeline Structure

Pipelines are located in `R/02_Main_analyses/` and organized as:

1. **Main Pipeline File** (e.g., `pipeline_basic.R`):
   - Sources the configuration file
   - Loads all custom functions using `targets::tar_source()`
   - Sets global target options (seed, format, error handling)
   - Combines pipe segments into a complete workflow

2. **Pipe Segments** (`R/02_Main_analyses/_pipes/`):
   - Modular components defining specific analysis steps
   - Each segment returns a list of related `targets::tar_target()` calls
   - Examples: `pipe_segment_community_data.R`, `pipe_segment_model_fit.R`

#### Working with Pipelines

**Running a pipeline**:

```r
# Set active configuration (see Configuration Management below)
Sys.setenv(R_CONFIG_ACTIVE = "project_cz")

# Run the pipeline
targets::tar_make()
```

**Viewing pipeline status**:

```r
# Check outdated targets
targets::tar_outdated()

# Visualize the pipeline network
targets::tar_visnetwork()

# See metadata for all targets
targets::tar_meta()
```

**Reading pipeline outputs**:

```r
# Load a specific target
data_community <- targets::tar_read(data_community)
```

**Mandatory validation after any pipeline edit**:

After editing any pipeline file (`pipeline_*.R`) or pipe segment (`_pipes/*.R`), **always** run `targets::tar_manifest()` before attempting `tar_make()` or `tar_visnetwork()`. This catches definition-time errors (missing objects, rlang-injection issues, mis-named targets) cheaply — without spawning workers or actually executing targets.

```r
# Validate the edited pipeline (replace config and script path as needed)
Sys.setenv(R_CONFIG_ACTIVE = "project_spatial_continental")
targets::tar_manifest(
  script = here::here("R/02_Main_analyses/pipeline_spatial_resolution.R")
)
```

A pipeline edit is **not considered complete** until `tar_manifest()` succeeds without errors.

> **Why this matters**: `targets::tar_target()` uses rlang argument capture which eagerly evaluates `!!!` (unquote-splice) operators at call time, not at command execution time. Any `!!!rlang::syms()` call that references a *locally-defined* variable inside the command block will therefore fail during pipeline definition. This class of error is caught by `tar_manifest()` immediately. Use the pipe-based pattern instead of `!!!rlang::syms()` in `tar_target()` command blocks:
> ```r
> # Good — pipe-based, no rlang injection
> dplyr::pick(dplyr::all_of(base::rev(vec_ranks))) |>
>   base::as.list() |>
>   purrr::reduce(dplyr::coalesce)
>
> # Bad — fails at tar_target() definition time
> dplyr::coalesce(!!!rlang::syms(base::rev(vec_ranks)))
> ```

#### Never use `base::attr()` to pass information between targets

**`base::attr()` is forbidden as a data-transport mechanism in this pipeline.**
Attributes are invisible, not type-checked, and silently dropped by many tidyverse operations. If a target needs to carry additional metadata alongside its primary output, give that metadata its own independent pipeline target and read both targets in the downstream step that needs them.

```r
# Bad — taxon labels live as a hidden attribute; will silently disappear
targets::tar_target(
  name = res_dissimilarity_matrix,
  command = {
    res <- cluster::daisy(data_traits_wide)
    base::attr(res, "Labels") <- dplyr::pull(data_traits_wide, taxon_name)
    res
  }
)

# Good — labels are an explicit, inspectable, standalone target
targets::tar_target(
  name = vec_taxon_labels,
  command = dplyr::pull(data_traits_wide, taxon_name)
)
targets::tar_target(
  name = res_dissimilarity_matrix,
  command = cluster::daisy(data_traits_wide)
)
```

#### Target Storage

Target outputs are stored in project-specific directories defined in `config.yml`:

- Default: `_targets/` (when using default configuration)
- Project-specific: `Data/targets/project_cz/`, `Data/targets/project_temporal_europe/`, etc.

### Configuration Management with {config}

This project uses the [{config}](https://rstudio.github.io/config/) package to manage different analysis configurations through the `config.yml` file at the project root.

#### Configuration File Structure

The `config.yml` file contains:

1. **default**: Base configuration inherited by all other configurations
   - `target_store`: Directory for targets outputs
   - `seed`: Random seed for reproducibility
   - `graphical`: Plot settings (sizes, units)
   - `data_processing`: General processing parameters
   - `model_fitting`: Model parameters (cores, samples, etc.)

2. **Project-specific configurations** (e.g., `project_cz`, `project_temporal_europe`):
   - Override default settings
   - Define project-specific parameters (geographic limits, dataset types, etc.)
   - Each has its own target storage directory

#### Accessing Configuration Values

Use the `get_active_config()` function (wrapper around `config::get()`):

```r
# Get a single configuration value
seed <- get_active_config("seed")

# Get nested configuration values
time_step <- get_active_config("data_processing")$time_step
```

Configuration values can be used in:

- Pipeline definitions
- Target option settings
- Function arguments throughout the analysis

#### Switching Between Configurations

Set the active configuration using the `R_CONFIG_ACTIVE` environment variable:

```r
# Set configuration for Czechia project
Sys.setenv(R_CONFIG_ACTIVE = "project_cz")

# Set configuration for Europe project  
Sys.setenv(R_CONFIG_ACTIVE = "project_temporal_europe")

# Use default configuration
Sys.setenv(R_CONFIG_ACTIVE = "default")
```

This allows running the same pipeline with different parameters by simply switching the active configuration.

## Git Workflow

**Always create new branches and worktrees from `main`**, never from a feature branch.
Use git worktrees to develop features or run pipelines in parallel without
disturbing an active session in the main worktree. Prefer **squash merges**
so each feature lands as one clean commit on `main`.

See [git-workflow.instructions.md](instructions/git-workflow.instructions.md) for the full step-by-step workflow, checklist, and key rules.

### Script Organization

Each script should be self-contained:

1. **Source the configuration file**
2. **Load required data**
3. **Perform its specific task**
4. **Save results**

Each script should do **one task only**. If describing the task requires multiple points, consider splitting into separate scripts.

## R Coding Conventions

Use the instruction files listed above as the authoritative source for R style, tidyverse usage, function design, performance, and visualisation rules. Avoid restating those rules here.

## Test Tiers

The default verification command is the fast test suite:

```powershell
Rscript R/03_Supplementary_analyses/Testing/Run_tests.R
```

Some tests are opt-in integration tests because they query
`Data/Input/VegVault.sqlite` and can be slow. Run the VegVault integration
tier in addition to the fast suite when a change touches any of these:

- `build_vegvault_plan()`
- `extract_*_from_vegvault()` functions
- direct `vaultkeepr::*` calls
- VegVault-backed `testthat` files
- pipeline targets or pipe segments that depend on VegVault extraction
- tests containing `RUN_VEGVAULT_INTEGRATION`

Use this command for the opt-in tier:

```powershell
$env:RUN_VEGVAULT_INTEGRATION = "true"
Rscript R/03_Supplementary_analyses/Testing/Run_tests.R
```

For targeted verification of one VegVault-backed test file, set the same
environment variable before calling `testthat::test_file()`.

## Mandatory Change Review

After implementing any larger code change, run a review subagent before
finalising the answer. Treat requests to implement a larger code change in
this repository as also requesting this review step, unless the user explicitly
says to skip it.

A larger code change means any change that creates or edits one or more source,
pipeline, analysis, test, or instruction files beyond a trivial typo or comment
fix.

Preferred review workflow:

1. If the environment exposes a native `changes-reviewer` subagent, use it
   directly.
2. If a native `changes-reviewer` subagent is unavailable, launch an `explorer`
   subagent as a read-only reviewer.
3. Paste the full text of `.github/agents/changes-reviewer.agent.md`, every
   instruction file referenced by that agent file, and the complete contents of
   every file created or edited during the session into the subagent prompt.
4. Provide the exact list of files created or edited during the session.
5. Instruct the subagent to follow the changes-reviewer instructions exactly:
   read-only review, no edits, no terminal commands, report violations and
   suggested fixes.
6. Fix any confirmed violations, rerun the relevant checks, and run the review
   subagent again whenever the fixes meet the larger-code-change threshold
   above.

If no subagent tool is available, state that blocker explicitly in the final
response and perform a local manual review against the same instructions.

## Debugging Workflow

Follow [debugging.instructions.md](instructions/debugging.instructions.md) for the standard bug-fix workflow.

Minimum completion bar for a bug fix:

1. Reproduce the issue in a minimal debug script under `Data/Temp/`.
2. Confirm the root cause before editing the source file.
3. Run the targeted test for the changed function.
4. Run the full test suite.
5. Run the required end-to-end pipeline checks.
6. Review the session changes with the mandatory change-review subagent
   workflow above.

A bug fix is not complete until all required tests, pipeline checks, and the review step pass.

## MCP Server for R Integration

This project exposes R-focused MCP tools through `btw` and `mcptools`.

Use MCP tools for targeted session information, package checks, and documentation lookups. Prefer terminal execution for large environment inspection, time-sensitive code execution, or any MCP call that hangs or times out. If MCP tools cannot see the active session, ensure `btw::btw_mcp_session()` is registered in the current R session.

## saber Toolchain

This project uses the [{saber}](https://github.com/cornball-ai/saber) package for R code analysis and project context.
`saber` parses R source into structured symbol indices, traces function callers, discovers dependency graphs, and generates project briefings — giving AI agents accurate understanding of the codebase without guessing.

### Toolchain Rules

Use `saber` when you need package exports, help pages, a project briefing, call-graph context, or dependency tracing.

`saber::blast_radius()` is mandatory before renaming, moving, or changing the signature of any exported function.

## Project-Specific Guidelines

### Function Organization

- Each function must be in its own file in `R/Functions/` (or subdirectories)
- File name must match function name
- Include roxygen2 documentation
- Include corresponding test file in appropriate test directory
- Functions should follow the naming conventions in the R coding skill

#### Test-Driven Development (TDD) Workflow

All function work (creation **and** editing) follows a strict TDD cycle. **Never write or change implementation code before the tests exist and fail.**

##### Creating a New Function

1. Write the roxygen2 spec stub first, following [make_roxygen2_documentation.instructions.md](instructions/make_roxygen2_documentation.instructions.md).
2. Create or update the test file from the spec using [make_test_file_for_a_function.instructions.md](instructions/make_test_file_for_a_function.instructions.md).
3. Verify the relevant tests fail for the intended reason before implementation.
4. Implement the function until the targeted tests pass.
5. Run the full test suite, the required pipeline validations, and the
   mandatory change-review subagent workflow.

A new function is not complete until the targeted tests, full test suite, required pipeline checks, and review step all pass.

##### Editing an Existing Function

1. Update the roxygen2 spec before changing implementation.
2. Add or revise tests so the changed behaviour is captured first.
3. Verify the affected tests fail for the intended reason.
4. Implement the change until the targeted tests pass.
5. Run the full test suite, the required pipeline validations, and the
   mandatory change-review subagent workflow.

An edit is not complete until the targeted tests, full test suite, required pipeline checks, and review step all pass.

### Data Workflow

1. **Input data** → `Data/Input/`
2. **Processed data** → `Data/Processed/`
3. **Outputs** → `Outputs/Data/` and `Outputs/Tables/`
4. **Temporary files** → `Data/Temp/` (git-ignored)
5. **Target stores** → `Data/targets/` (project-specific pipeline outputs)
   - `Data/targets/project_cz/`
   - `Data/targets/project_temporal_europe/`
   - Each configuration stores its targets in a separate directory

### Pipeline Organization

- **Main pipelines** → `R/02_Main_analyses/`
  - Master pipeline files (e.g., `pipeline_basic.R`)
  - Execute complete analysis workflows
- **Pipe segments** → `R/02_Main_analyses/_pipes/`
  - Modular pipeline components
  - Each file defines a specific analysis segment
  - Combined by main pipeline files

### Documentation

- Function documentation → Generated to `Documentation/Functions/`
- Test coverage reports → `Documentation/Functions_test_coverage/`
- Progress reports → `Documentation/Progress/`
- Project website → `Documentation/Website/` (rendered to `docs/`)
