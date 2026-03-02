# BIODYNAMICS Vegetation Co-occurrence Project

## Overview

This project analyzes vegetation co-occurrence patterns using paleoecological and modern vegetation data. The project uses R for data processing, statistical modeling, and visualization.

## Coding Standards

This project follows specific R coding conventions defined in the [R Coding Instructions](instructions/r-coding.instructions.md). Please refer to that document for detailed style guidelines.

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

### Script Organization

Each script should be self-contained:

1. **Source the configuration file**
2. **Load required data**
3. **Perform its specific task**
4. **Save results**

Each script should do **one task only**. If describing the task requires multiple points, consider splitting into separate scripts.

## R Coding Conventions

For detailed R coding style guidelines, please refer to the [R Coding Instructions](instructions/r-coding.instructions.md), which includes:

- Script structure and headers
- Naming conventions for objects, functions, and variables
- Syntax rules (spacing, new lines, parentheses)
- Function documentation using roxygen2
- Testing conventions using testthat

## Debugging Workflow

For the standard approach to diagnosing and fixing bugs, please refer to the [Debugging Instructions](instructions/debugging.instructions.md).

The workflow in brief:

1. **Reproduce** the bug in a minimal `Data/Temp/debug_<topic>.R` script
2. **Run** with `Rscript` in a clean terminal (redirect output to file)
3. **Probe** environments / call patterns until root cause is confirmed
4. **Fix** the source file with an explanatory comment
5. **Clean up** all temp debug files with `Remove-Item`
6. **Run the targeted test** for the changed function:

```r
testthat::test_file(
  here::here(
    "R/03_Supplementary_analyses/testthat/test-<function_name>.R"
  )
)
```

7. **Run the full test suite** — all tests must pass:

```r
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

