# BIODYNAMICS Vegetation Co-occurrence Project

## Overview

This project analyzes vegetation co-occurrence patterns using paleoecological and modern vegetation data. The project uses R for data processing, statistical modeling, and visualization.

## Coding Standards

This project follows specific R coding conventions split across four instruction files:
- [r-coding.instructions.md](instructions/r-coding.instructions.md) — Script structure, naming, syntax
- [r-coding-tidyverse.instructions.md](instructions/r-coding-tidyverse.instructions.md) — Tidyverse, namespace, dplyr/purrr, data masking
- [r-coding-functions.instructions.md](instructions/r-coding-functions.instructions.md) — Writing functions, error handling, docs, tests
- [r-coding-performance.instructions.md](instructions/r-coding-performance.instructions.md) — Profiling and performance

## Project Structure

### Files & Folders

Folders and files can have numbering to guide a user to the sequences of analyses. However, this can be added later in the project as it causes various issues with version control.

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
source("R/___setup_project___.R")
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

#### Target Storage

Target outputs are stored in project-specific directories defined in `config.yml`:
- Default: `_targets/` (when using default configuration)
- Project-specific: `Data/targets/project_cz/`, `Data/targets/project_europe/`, etc.

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

2. **Project-specific configurations** (e.g., `project_cz`, `project_europe`):
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
Sys.setenv(R_CONFIG_ACTIVE = "project_europe")

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

R coding style guidelines are split across four instruction files:

- [r-coding.instructions.md](instructions/r-coding.instructions.md) — Script structure, naming conventions, syntax rules
- [r-coding-tidyverse.instructions.md](instructions/r-coding-tidyverse.instructions.md) — Tidyverse preferences, namespace, modern dplyr/purrr patterns, data masking
- [r-coding-functions.instructions.md](instructions/r-coding-functions.instructions.md) — Writing functions, anonymous functions, error handling, roxygen2 documentation, testthat testing
- [r-coding-performance.instructions.md](instructions/r-coding-performance.instructions.md) — Profiling, avoiding loop anti-patterns, parallel processing

## Debugging Workflow

For the standard approach to diagnosing and fixing bugs, please refer to the [Debugging Instructions](instructions/debugging.instructions.md).

The workflow in brief:

1. **Reproduce** the bug in a minimal `Data/Temp/debug_<topic>.R` script
2. **Run** with `Rscript` in a clean terminal (redirect output to file)
3. **Probe** environments / call patterns until root cause is confirmed
4. **Fix** the source file with an explanatory comment
5. **Clean up** all temp debug files with `Remove-Item`
6. **Run the targeted test** for the changed function (source project setup
   first so all functions are available):

```r
library(here)

source(
  here::here("R/___setup_project___.R")
)

testthat::test_file(
  here::here(
    "R/03_Supplementary_analyses/testthat/test-<function_name>.R"
  )
)
```

7. **Run the full test suite** — all tests must pass. The canonical way is
   to run the dedicated script that sources project setup automatically:

```powershell
Rscript R/03_Supplementary_analyses/Run_tests.R
```

   Alternatively, from an interactive R session:

```r
library(here)

source(
  here::here("R/___setup_project___.R")
)

testthat::test_dir(
  here::here("R/03_Supplementary_analyses/testthat")
)
```

8. **Verify** end-to-end by running the full pipeline without errors:

```r
library(here)

source(
  here::here("R/___setup_project___.R")
)

# Set specific config active
Sys.setenv(R_CONFIG_ACTIVE = "project_cz")

# Basic pipeline
run_pipeline(
  sel_script = "R/02_Main_analyses/pipeline_basic.R",
  level_separation = 100
)
```

**A bug fix is not complete until steps 6, 7, and 8 both pass without errors.**

## MCP Server for R Integration

This project has MCP (Model Context Protocol) server integration configured for enhanced R environment interaction through the [{btw}](https://posit-dev.github.io/btw/) and [{mcptools}](https://posit-dev.github.io/mcptools/) packages.

### Configuration

The MCP server is configured in VS Code/Claude Code settings with:
```json
{
  "mcpServers": {
    "r-mcptools": {
      "command": "Rscript",
      "args": ["-e", "btw::btw_mcp_server()"]
    }
  }
}
```

### Session Registration

For AI assistants to interact with your R session, each active R session must be registered with:
```r
btw::btw_mcp_session()
```

This should be already included in the `.Rprofile` file, so it runs automatically when you start an interactive R session.

### Available Capabilities

The MCP server provides tools for:

#### Working Reliably
- **Platform information**: `mcp_r-mcptools_btw_tool_sessioninfo_platform` - Get R version, OS, system info
- **Package information**: `mcp_r-mcptools_btw_tool_sessioninfo_package` - Check package versions
- **Documentation access**: Tools for reading package help, vignettes, and function documentation
- **File operations**: Reading and searching files in the project

#### Known Limitations
- **Environment inspection**: May fail with C stack errors if the global environment contains very large or deeply nested objects
- **Performance**: Some operations (especially file listings and environment descriptions) may hang or timeout
- **Subagent tools**: Require additional API key configuration beyond the main MCP setup

### Best Practices

1. **For Simple Queries**: Use MCP tools for getting platform info, package details, or documentation
2. **For Environment Inspection**: Use terminal commands (`ls()`, `ls.str()`) if MCP tools hang or error
3. **For Code Execution**: Terminal commands via `run_in_terminal` may be more reliable than MCP execution tools
4. **Timeout Handling**: If an MCP tool call takes >30 seconds, cancel it and use terminal alternatives

### Practical Usage Guidelines

**When to use MCP tools:**
- Getting R session information (platform, packages, versions)
- Reading specific documentation (help pages, vignettes)
- Inspecting specific small objects when you know their names
- Checking if packages are installed

**When to use terminal commands instead:**
- Listing all environment objects (use `ls()`)
- Describing object structures (use `str()`, `glimpse()`)
- Running R code that needs immediate results
- Any operation that needs to be fast and reliable
- When working with large data objects in the environment

### Troubleshooting

**MCP tools hanging:**
- Ensure `btw::btw_mcp_session()` has been called in your active R session
- Check if your environment has very large objects causing serialization issues
- Cancel the operation and use terminal commands instead

**C stack usage errors:**
- Your global environment likely has large/complex nested objects
- Use targeted queries for specific objects instead of full environment descriptions
- Clear unnecessary large objects from your environment

**Session not found:**
- Verify the R session has been registered with `btw::btw_mcp_session()`
- Check that the MCP server process is running (restart VS Code if needed)

## Project-Specific Guidelines

### Function Organization

- Each function must be in its own file in `R/Functions/` (or subdirectories)
- File name must match function name
- Include roxygen2 documentation
- Include corresponding test file in appropriate test directory
- Functions should follow the naming conventions in the R coding skill

**Whenever any function in `R/Functions/` is created or edited, immediately
update its roxygen2 documentation block** to reflect the current arguments,
return value, and behaviour. Follow the template in
[instructions/make_roxygen2_documentation.instructions.md](instructions/make_roxygen2_documentation.instructions.md).
Do not wait to be asked — treat documentation as part of every function edit.

**After the function has been edited and its documentation updated, launch a
subagent** with the full contents of
[instructions/make_test_file_for_a_function.instructions.md](instructions/make_test_file_for_a_function.instructions.md)
and the current function source as context. The subagent's sole task is to
review and improve the existing test file for that function (or create one if
it does not yet exist) at
`R/03_Supplementary_analyses/testthat/test-<function_name>.R`.
Do not wait to be asked — treat test improvement as part of every function
edit, alongside documentation.

**After all tests pass, run the full pipeline end-to-end.** This is
**MANDATORY** — do not consider any function creation or edit complete
until the pipeline has been executed and verified in the terminal.

Run via terminal (preferred — avoids stale session state):

```powershell
Rscript -e "
library(here)
source(here::here('R/___setup_project___.R'))
Sys.setenv(R_CONFIG_ACTIVE = 'project_cz')
run_pipeline(
  sel_script = 'R/02_Main_analyses/pipeline_basic.R',
  level_separation = 100
)
" > Data/Temp/pipeline_out.txt 2>&1
Get-Content Data/Temp/pipeline_out.txt |
  Select-String -Pattern 'ERROR|error|started|completed|up to date|outdated|Target'
Remove-Item Data/Temp/pipeline_out.txt -ErrorAction SilentlyContinue
```

Or from an interactive R session:

```r
library(here)

source(
  here::here("R/___setup_project___.R")
)

Sys.setenv(R_CONFIG_ACTIVE = "project_cz")

run_pipeline(
  sel_script = "R/02_Main_analyses/pipeline_basic.R",
  level_separation = 100
)
```

**An implementation is not complete until this pipeline run passes without
unexpected errors.** Do not wait to be asked — treat the pipeline run as
the final mandatory step of every function creation or edit.

### Data Workflow

1. **Input data** → `Data/Input/`
2. **Processed data** → `Data/Processed/`
3. **Outputs** → `Outputs/Data/` and `Outputs/Tables/`
4. **Temporary files** → `Data/Temp/` (git-ignored)
5. **Target stores** → `Data/targets/` (project-specific pipeline outputs)
   - `Data/targets/project_cz/`
   - `Data/targets/project_europe/`
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
- Project website → `website/` (rendered to `docs/`)

