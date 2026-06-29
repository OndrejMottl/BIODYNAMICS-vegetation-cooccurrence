# R Coding Guidance

Canonical R coding guidance for this repository. Copilot, Cursor, Codex, Claude, Gemini, and other assistants should treat this file as the shared source of truth for R scripts, tidyverse usage, performance, and visualisation.

## Base R Coding Conventions

# R Coding Conventions and Style Guide

## Coding Style

This coding style is a combination of various sources ([Tidyverse](https://style.tidyverse.org/index.html), [Google](https://google.github.io/styleguide/Rguide.html), and others). Style should be consistent within a project.

## Script Structure

One script should serve one purpose and that should be obvious from its name. Scripts are always partitioned into clearly readable chunks.

### Script Header

The script header should contain the name of the project, objectives (purpose) of that script, authors, and rough date (year of the project).

Example of a header:

```r
#----------------------------------------------------------#
#
#
#                     Project name 
#
#                      Script name
#                      - continue
#
#                       Authors 
#                        Year
#
#----------------------------------------------------------#
```

### Section Headers

Each section of a script should begin with a header which consists of a name wrapped by two lines. The name of a header should start with a capital letter. Each header name should be followed by `-----` so that it is automatically picked by IDE as a section header.

Empty lines should be placed before each header to separate chunks.

Headings can have various hierarchies:

1. `#----------------------------------------------------------#`
2. `#--------------------------------------------------#`
3. `#----------------------------------------#`

Example of a header:

```r
#----------------------------------------------------------#
# Load data -----
#----------------------------------------------------------#
```

Header names can be denoted by numbers, with subsections separated by `.`

Example of a numbered header:

```r
#----------------------------------------------------------#
# 1. Estimate diversity -----
#----------------------------------------------------------#


#--------------------------------------------------#
## 1.1. Fit model -----
#--------------------------------------------------#
```

### Comments

#### Single-line comments

Adding comments to code plays a pivotal role in ensuring reproducibility and preserving code knowledge for future reference. When things change or break, the user will be thankful for comments. There's no need to comment excessively or unnecessarily, but a comment describing what a large or complex chunk of code does my be helpful. More importantly, it is crusial to comment WHY something is coded in that specific (non-standard) way. The first letter of a comment is capitalized and spaced away from the pound sign (`#`).

Example of a single-line comment:

```r
# This is a comment.
```

#### Multi-line comment

Multi-line comments should start with a capital letter and the new line should start with one tab.

Example of a multi-line comment:

```r
# This is a very long comment, where I need to describe
#    what this code is doing
```

#### Inline comment

Inline comments should always start with a space.

Example of inline comment:

```r
function(
 agr = 1 # This is an example of an inline comment
)
```

### Code Width

No line of **R code** should be longer than 80 characters (including R comments). Users can visualise the 80 characters line in selected IDE.

> **Note:** This 80-character limit applies to R source code only. Markdown prose  -  such as text in `.md` files, `.qmd` files, instruction files, README files, or any other documentation  -  is **not** subject to this limit. Let markdown text wrap naturally.

## Naming Conventions

```r
"There are only two hard things in Computer Science:
 cache invalidation and naming things."
```

### Object Names

Objects and functions should use `snake_style`. The `.` in names is somewhat popular but it causes issues with names of methods and should therefore be avoided. The names are preferred to be very descriptive, more expressive and more explicit. **Never abbreviate words in object names.** Write the full word every time  -  `config` not `cfg`, `column` not `col`, `parameter` not `param`, `function` not `fn`, `number` not `num`, `value` not `val`, `result` not `res` (the only permitted abbreviation objects are listed below). When in doubt, spell it out.

The names should be nouns and start with the type of object:

- `data_*` - for data
  - special subcategory is `table_*` for tables (mainly as an object for reference). Note that all tables can be data but not vice versa.
- `list_` - for lists
- `vec_` - for vectors
- `mod_*` - for statistical model
- `res_` - special category, which can be used within the function to name an object to be returned (`return(res_*)`)
- `flag_*` - for boolean/logical control flags (e.g. safety guards, feature switches). **Always use `snake_style`**  -  never `SCREAMING_SNAKE_CASE` even though that convention is common in other languages.

Examples of good names:

```r
# data
data_diversity_survey

# list
list_diversity_individual_plots

# vector
vec_region_names

# model
mod_diversity_linear

# result
res_estimated_weight

# flag (boolean / logical control variable)
flag_allow_overwrite <- FALSE
flag_use_parallel <- TRUE
```

### Function Names

Names of functions should be verbs and describe the expected functionality.

Examples of good function names:

```r
estimate_alpha_diversity()

get_first_value()

transform_into_character()
```

#### Internal Functions

It is possible to start a function with a `"."` (e.g., `.get_round_value()`) to flag internal functions.

### Column (Variable) Names in Data Frames

`snake_style` is preferred for column names in both `data.frames` and `tibbles`. Note that the [janitor](https://sfirke.github.io/janitor/) package can be used to edit this automatically.

#### Quantile / Interval Columns

Quantile summary columns must use `lwr` (lower) and `upr` (upper) as base names, optionally suffixed with the **interval coverage** as an integer:

- `lwr` / `upr` â€” when no specific interval is implied
- `lwr_<N>` / `upr_<N>` â€” where `N` is the interval coverage percentage

The 95 % interval uses the two-tailed 2.5th and 97.5th percentiles:

```r
lwr_95 = stats::quantile(x, probs = 0.025, na.rm = TRUE),
upr_95 = stats::quantile(x, probs = 0.975, na.rm = TRUE)
```

The 90 % interval uses the 5th and 95th percentiles:

```r
lwr_90 = stats::quantile(x, probs = 0.05, na.rm = TRUE),
upr_90 = stats::quantile(x, probs = 0.95, na.rm = TRUE)
```

**Never** use `p5`, `p95`, `p025`, `p975`, `q05`, `q95` or similar non-standard names.

## Syntax

Many of the syntax issues can be checked/fixed by [lintr](https://lintr.r-lib.org/) and [styler](https://styler.r-lib.org/index.html) packages, which can be used to automate lots of the tedious aspects.

### Spaces

Space (`" "`) should always be placed:

- after a comma
- before and after infix operators (`==`, `+`, `-`, `<-`, `~`, etc.)

Exceptions:

- No spaces inside or outside parentheses for regular function calls
- Operators with high precedence should not be surrounded by space: `:`, `::`, `:::`, `$`, `@`, `[`, `[[`, `^`, unary `-`

### New Lines

Prefer code that is more vertical than horizontal. Therefore, use quite a lot of new lines.

Usage of a semicolon (`;`) to indicate a new line is not preferred.

A new line should be:

#### 1. After an Object Assignment (`<-`)

Whenever the right-hand side is a **function call**, place a newline after `<-` and indent the expression by 2 spaces:

```r
data_diversity <-
  read_data(...)

data_coords <-
  tibble::tibble(x = vec_x, y = vec_y)

list_params <-
  base::list(a = 1, b = 2)

res <-
  my_function(
    arg1 = value1,
    arg2 = value2
  )
```

The **only** assignments that may stay on one line are scalar literals and `NULL` (i.e., when the RHS is a single literal value, not a function call):

```r
vec_center <- 50.0   # OK: numeric literal
name <- "triangle"   # OK: string literal
flag <- NULL         # OK: NULL
count <- 3L          # OK: integer literal
flag <- TRUE         # OK: logical literal
```

The **exception** for the newline rule is function *definitions*  -  those keep `<-` on the same line as `function`:

```r
get_data <- function(...) {
  ...
}
```

#### 2. After a Pipe Operator

Prefer the **native pipe `|>`** (R 4.1+). Note that there should be a space before a pipe.

```r
data_diversity <-
  get_data() |>
  transform_to_percentages()
```

Use the **magrittr pipe `%>%`** when the native pipe cannot be used cleanly:

- Piping into a function's **non-first argument** (`.` placeholder):
  ```r
  data_diversity %>%
    lm(diversity ~ region, data = .)
  ```
- Piping into **curly brackets** `{ }` to suppress the implicit first-argument rule:
  ```r
  vec_diversity %>%
    { . + 1 }
  ```
- Piping into `return()` or other special constructs inside a function body
  where `|>` would be ambiguous.

#### 3. After a Function Argument

> **Summary of rules 1â€“4**: prefer vertical code â€” newline after `<-` when RHS is a function call, after every pipe `|>`, after every function argument when there are two or more arguments, and inside every control-flow condition (see rule 5).

This should be true for both function declaration and usage. The exception is a single argument.

```r
get_data <- function(arg1 = foo,
                     arg2 = here::here()) {
  ...
}

data_diversity <-
  get_data(
    arg1 = foo,
    arg2 = here::here()
  )

vec_selected_regions <-
  get_regions(arg1 = foo)
```

#### 5. Inside `if()`, `for()`, and `while()` Conditions

**Always** place the condition / iterator on its own indented line, and put the closing `) {` on its own line at the same indent level as the keyword. This rule applies even when the condition is short and would fit on one line â€” **never write `if (condition) {` on a single line.**

```r
# Good
if (
  logical_test
) {
  ...
}

if (
  base::nrow(data_unmatched) > 0L
) {
  ...
}

for (
  col_name in vec_col_names
) {
  ...
}

while (
  condition
) {
  ...
}

# WRONG â€” never do this
if (condition) { ... }
if (base::nrow(x) > 0) { ... }
for (i in seq_len(n)) { ... }
while (condition) { ... }
```

#### 6. Parentheses

Each type of parentheses (brackets) has its own rules:

##### Round `( )`

- should not be placed on separate first and last line
- always space *before* the bracket (*unless* it's a function)
- new line after start if it is a multi-argument function

Examples:

```r
1 + (a + b)

get_data(arg = foo)

get_data(
  agr1 = foo,
  agr2 = here::here()
)
```

##### Square `[ ]`

- Never space before the bracket
- always space instead of missing value

Examples:

```r
list_diversity_for_each_plot[[1]]

data_cars[, 2]
```

##### Curly `{ }`

- Use only for functions and expressions
- `{` should be the last character on a line and should never be on its own
- `}` should be the first character on a line
- Always new brackets after else unless followed by if
- Not used for chunks of code

Examples:

```r
get_data <- function(agr1) {
  ...
}

if (
  logical_test
) {
  ...
} else {
  ...
}

try(
  expr = {
    ...
  }
)
```

##### `{targets}` `tar_target()` â€” `command` argument

When the `command` argument of `targets::tar_target()` is a **single function call**, write it directly â€” do **not** wrap it in `{ }`:

```r
# Good
targets::tar_target(
  name = data_traits_raw,
  command = dplyr::bind_rows(data_traits_continent)
)

# Bad â€” unnecessary braces around a single call
targets::tar_target(
  name = data_traits_raw,
  command = {
    dplyr::bind_rows(data_traits_continent)
  }
)
```

If the logic is complex enough to need multiple statements and `{ }`,
**extract it into a dedicated function** in `R/Functions/` and call that
function from `command` instead:

```r
# Bad â€” inline multi-statement block
targets::tar_target(
  name = data_processed,
  command = {
    raw <- load_data(path)
    clean_data(raw)
  }
)

# Good â€” logic lives in a named function
targets::tar_target(
  name = data_processed,
  command = load_and_clean_data(path = path_input)
)
```

This keeps the pipeline readable and the logic testable.

> See **New Lines Â§ 5** above for the mandatory multi-line style for `if()`, `for()`, and `while()` conditions.

### Assignment

Always use the left assignment `<-`.

Do **NOT** use:

- right assignment (`->`)
- equals (`=`)

**Do NOT use the Unicode arrow character `â†’` anywhere in an R script** â€” not in code, not in comments, and not in roxygen2 documentation blocks. Many R installations and CI environments do not handle non-ASCII characters in source files reliably, and the stray byte causes silent parse or execution failures. Use the plain ASCII two-character sequence `->` whenever you need to express a mapping or transformation in a comment (e.g. `# "Betula sp." -> "Betula"`).

There should be a new line after the assignment. Note that rarely single-line assignment can be used:

```r
data_diversity <-
  get_data()

preferred_shape <- "triangle"
```

#### Do Not Reassign Transformed Objects

When an object passes through sequential transformation stages, save each stage under a new descriptive name. Do not overwrite the earlier object with a transformed version of itself. Intermediate objects are local to the function or script and are released when their environment is removed; preserving distinct names makes execution order explicit and prevents partial interactive runs from using the wrong object state.

This rule also applies when coercing or normalising function arguments. Store the validated or converted value under a new name instead of overwriting the argument.

```r
# Good - each transformation stage has an explicit state
data_samples_aligned <-
  align_samples(data_samples_raw)

data_samples_filtered <-
  filter_samples(data_samples_aligned)

min_samples_integer <-
  base::as.integer(min_samples)

# Avoid - the meaning of the object changes with execution order
data_samples <-
  align_samples(data_samples)

data_samples <-
  filter_samples(data_samples)

min_samples <-
  base::as.integer(min_samples)
```

Stateful preallocated accumulators inside an inherently iterative algorithm may be updated in place when creating a new full copy on every iteration would be misleading or unnecessarily expensive. Name such objects clearly as accumulators or running counts.

### Logical Evaluation

Always use `TRUE` and `FALSE`, instead of `T` and `F`.

## Related Instruction Files

Detailed rules for specific topics are in separate files:

- [.ai/r-coding.md](.ai/r-coding.md)  -  Tidyverse preferences, namespace, modern dplyr/purrr patterns, data masking
- [.ai/r-functions.md](.ai/r-functions.md)  -  Creating functions, anonymous functions, error handling, documentation, testing
- [.ai/r-coding.md](.ai/r-coding.md)  -  Profiling, loop performance, parallel processing

## Tidyverse Conventions

# Tidyverse & Namespace Guidelines

## Prefer Tidyverse Over Base R

Use tidyverse functions over base R equivalents:

| Base R | Better Style, Performance, and Utility |
|--------|----------------------------------------|
| `read.csv()` | `readr::read_csv()` |
| `df$some_column` | `df |> dplyr::pull(some_column)` |
| `df$some_column = ...` | `df |> dplyr::mutate(some_column = ...)` |
| `list$element` | `list \|> purrr::chuck("element")` |
| `apply(m, 2, f)` | `purrr::map_dbl(colnames(m), ~ f(m[, .x]))` |
| `lapply(x, f)` | `purrr::map(x, f)` |
| `sapply(x, f)` | `purrr::map_dbl(x, f)` / `purrr::map_chr(x, f)` |
| `vapply(x, f, numeric(1))` | `purrr::map_dbl(x, f)` |
| `mapply(f, x, y)` | `purrr::map2(x, y, f)` |
| `grepl("p", x)` | `stringr::str_detect(x, "p")` |
| `gsub("a", "b", x)` | `stringr::str_replace_all(x, "a", "b")` |
| `paste0(a, b)` / `paste(a, b, sep = "")` | `stringr::str_glue("{a}{b}")` |
| `paste(x, collapse = ", ")` | `stringr::str_c(x, collapse = ", ")` |

**Never use `paste()` or `paste0()` for string construction.** Use `stringr::str_glue()` for interpolated strings and `stringr::str_c()` for collapsing vectors. `str_glue()` is more readable because variables and expressions sit inline inside `{}` without breaking the string apart into many arguments.

```r
# Good  -  str_glue for interpolation
base::message(stringr::str_glue("Loaded {nrow(data)} rows for {sel_taxon}."))

# Good  -  str_c for collapsing a vector
stringr::str_c(vec_domains, collapse = ", ")

# Avoid
base::paste0("Loaded ", nrow(data), " rows for ", sel_taxon, ".")
base::paste(vec_domains, collapse = ", ")
```

**Never use `$` for element access.** Use `dplyr::pull()` to extract a column from a data frame and `purrr::chuck()` to extract an element from a list. These are explicit, pipe-friendly, and raise a clear error when the element is missing.

```r
# Good  -  data frame column
data_diversity |>
  dplyr::pull(species_richness)

# Good  -  list element
list_params |>
  purrr::chuck("n_iter")

# Avoid
data_diversity$species_richness
list_params$n_iter
```

**Never use `base::attr()` to attach metadata to R objects.**
Attributes are invisible, not type-checked, and silently stripped by many tidyverse operations (e.g. `dplyr::mutate()`, `tibble::as_tibble()`). Keep every piece of information as an explicit, named object â€” a column in a data frame, a named element in a list, or, in a `{targets}` pipeline, a dedicated target (see the Pipeline Management section in `AGENTS.md`).

```r
# Avoid
base::attr(res_dist, "Labels") <- dplyr::pull(data_traits, taxon_name)

# Good  -  data frame: add as a column
data_dist <-
  dplyr::mutate(data_dist, taxon_name = data_traits[["taxon_name"]])

# Good  -  in a targets pipeline: expose as a separate target
targets::tar_target(
  name = vec_taxon_labels,
  command = dplyr::pull(data_traits, taxon_name)
)
```

**Never use the `apply` family** (`apply()`, `lapply()`, `sapply()`, `vapply()`, `mapply()`, `tapply()`). Use `purrr::map*()` equivalents instead  -  they are type-stable, pipe-friendly, and consistent with the rest of the tidyverse. This rule applies to all iteration and functional-programming patterns, not just data-frame operations.

## Namespace

Always use the full package namespace with a function call. This helps to track the source of a function in a script:

```r
data_diversity |>
  dplyr::mutate(
    beta_diversity = 0
  )
```

## Modern dplyr Patterns

### Superseded Verbs

Do not use `dplyr::transmute()`.

`transmute()` is superseded in dplyr and should not be suggested or introduced
in this repository. Use one of these patterns instead:

- Use `dplyr::mutate()` when you are adding or transforming columns and want
  to keep existing columns.
- Use `dplyr::mutate()` followed by `dplyr::select()` when you want to keep
  only a subset of columns.
- Use `dplyr::summarise()` for grouped reductions.

```r
# Good: keep all existing columns and add/transform
data_input |>
  dplyr::mutate(value_scaled = value / 100)

# Good: replace old transmute() intent with mutate() + select()
data_input |>
  dplyr::mutate(
    observation_id = base::as.character(id),
    component_share = base::as.numeric(share)
  ) |>
  dplyr::select(observation_id, component_share)

# Avoid (superseded)
data_input |>
  dplyr::transmute(
    observation_id = base::as.character(id),
    component_share = base::as.numeric(share)
  )
```

### Joins

Use `join_by()` instead of character vectors for joins (dplyr 1.1+):

```r
# Good
transactions |>
  dplyr::inner_join(companies, by = dplyr::join_by(company == id))

# Avoid
transactions |>
  dplyr::inner_join(companies, by = c("company" = "id"))
```

Use `multiple` and `unmatched` arguments in joins for data quality control:

```r
# Error on unexpected multiple matches
dplyr::inner_join(x, y, by = dplyr::join_by(id), multiple = "error")

# Error if any rows are unmatched
dplyr::inner_join(x, y, by = dplyr::join_by(id), unmatched = "error")
```

### Grouping

Use `dplyr::group_by()` for grouping operations. Always pair it with `dplyr::ungroup()` after the grouped computation to avoid unexpected behaviour in downstream steps:

```r
data_diversity |>
  dplyr::group_by(region) |>
  dplyr::summarise(mean_diversity = mean(diversity)) |>
  dplyr::ungroup()
```

Use `reframe()` for summaries that return more than one row per group:

```r
data_diversity |>
  dplyr::group_by(region) |>
  dplyr::reframe(
    quantiles = quantile(diversity, c(0.25, 0.5, 0.75))
  )
```

## Modern purrr Patterns

Use `map() |> list_rbind()` instead of the superseded `map_dfr()` (purrr 1.0+):

```r
# Good
list_results |>
  purrr::map(~ fit_model(.x)) |>
  purrr::list_rbind()

# Avoid (superseded)
list_results |>
  purrr::map_dfr(~ fit_model(.x))
```

Use `walk()` and `walk2()` for side effects (file writing, plotting) instead of `map()` or `for` loops when the return value is not needed:

```r
# Good
purrr::walk2(
  list_data,
  vec_file_paths,
  ~ readr::write_csv(.x, .y)
)
```

### Piping the input vector into `purrr::map()`

Prefer piping the input vector directly into `purrr::map()` over using the `.x` argument. This keeps the iteration subject at the top of the pipe chain and reads more naturally:

```r
# Good  -  input is the subject of the pipe
vec_ids |>
  rlang::set_names() |>
  purrr::map(
    .f = ~ compute(.x)
  )

# Avoid  -  .x = buries the input inside the call
purrr::map(
  .x = vec_ids,
  .f = ~ compute(.x)
)
```

Use `rlang::set_names()` (no argument) before `purrr::map()` to propagate vector names to the output list.

### Nested `purrr::map()` and `.x` disambiguation

When `purrr::map()` calls are nested, both lambdas share the `.x` pronoun, causing ambiguity. Resolve this by binding the outer `.x` to a named variable at the top of the outer function body:

```r
# Good  -  outer .x is captured as a named variable
vec_ages |>
  rlang::set_names() |>
  purrr::map(
    .f = ~ {
      age_i <- .x   # capture before .x is shadowed

      vec_vars |>
        rlang::set_names() |>
        purrr::map(
          .f = ~ compute(var = .x, age = age_i)
        )
    }
  )

# Avoid  -  inner .x silently shadows outer .x
purrr::map(
  .x = vec_ages,
  .f = function(age_i) {
    purrr::map(
      .x = vec_vars,
      .f = ~ compute(var = .x, age = age_i)
    )
  }
)
```

## Data Masking

When writing functions that pass column names to tidyverse data-masking functions (`dplyr::filter()`, `dplyr::mutate()`, `dplyr::summarise()`, etc.), use the correct forwarding mechanism to avoid ambiguity and masking bugs.

### Forwarding function arguments with `{{ }}`

Use the embrace operator `{{ }}` to forward a function argument into a data-masking context:

```r
# Good
calculate_group_mean <- function(data, group_var, value_var) {
  data |>
    dplyr::group_by({{ group_var }}) |>
    dplyr::summarise(
      mean_value = mean({{ value_var }})
    ) |>
    dplyr::ungroup()
}
```

### Accessing columns by name string with `.data[[]]`

When a column name is provided as a character string (e.g. in a loop), use `.data[[var]]` instead of `!!sym(var)` for clarity and safety:

```r
# Good - character vector column access
for (col_name in vec_col_names) {
  data_diversity |>
    dplyr::summarise(
      mean_val = mean(.data[[col_name]])
    )
}

# Applying a function across multiple named columns
purrr::map(
  .x = vec_col_names,
  .f = ~ data_diversity |>
    dplyr::summarise(mean_val = mean(.data[[.x]]))
)
```

### Forwarding `...`

When forwarding `...` to data-masking functions, no special syntax is needed:

```r
group_and_summarise <- function(.data, ...) {
  .data |> dplyr::group_by(...)
}
```

### Avoid dangerous patterns

```r
# Avoid - eval/parse is dangerous and fragile
eval(parse(text = paste("mean(", var, ")")))

# Avoid - get() causes name collisions in data masks
with(data, mean(get(var)))
```

## Prefer Pipes Over Nested Function Calls

Use the native pipe `|>` to chain operations instead of nesting function calls. Deeply nested calls are hard to read and must be parsed inside-out; pipes read left-to-right in execution order.

```r
# Good â€” pipe-based, reads in execution order
filter_data() |>
  fit_model() |>
  summarise_data() |> 
  plot_data()

# Avoid â€” nested, reads inside-out
plot_data(
  summarise_data(
    fit_model(
      filter_data()
    )
  )
)
```

This rule applies to `do.call()` wrappers, `Reduce()`, and any other function that accepts another function plus its inputs as separate arguments â€” prefer piping into `purrr::reduce()` or similar pipe-friendly equivalents instead.

## Performance Conventions

# Performance Guidelines

## Profile Before Optimising

Never attempt to optimise code without first measuring where time is actually spent. Use `profvis` for interactive profiling and `bench::mark()` for benchmarking alternatives:

```r
# Identify bottlenecks
profvis::profvis({
  your_analysis(data_full)
})

# Compare alternative implementations
bench::mark(
  approach_a = method_a(data),
  approach_b = method_b(data),
  min_iterations = 10
)
```

## Avoid Growing Objects in Loops

Pre-allocate or use `purrr::map()` instead of growing objects iteratively:

```r
# Avoid - very slow due to repeated copying
vec_result <- c()
for (i in seq_along(vec_ids)) {
  vec_result <- c(vec_result, compute(vec_ids[i]))
}

# Good - pre-allocate
vec_result <- vector("list", length(vec_ids))
for (i in seq_along(vec_ids)) {
  vec_result[[i]] <- compute(vec_ids[i])
}

# Better - use purrr
list_result <- purrr::map(
  .x = vec_ids,
  .f = ~ compute(.x)
)
```

## Parallel Processing

Use parallel processing only for CPU-intensive, independent operations where the computation cost clearly exceeds the parallelisation overhead. Avoid parallelising fast or memory-intensive operations.

## Visualisation Conventions

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

Sys.setenv(R_CONFIG_ACTIVE = "project_cz_paleo")

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
    subtitle = stringr::str_glue(
      "project: {Sys.getenv('R_CONFIG_ACTIVE')}"
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
| Layer order | Facets -> Scales -> Labs -> Theme -> Canvas -> Geoms | Geoms before setup layers |
