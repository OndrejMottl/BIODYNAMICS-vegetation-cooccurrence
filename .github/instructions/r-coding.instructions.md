---
applyTo: "**/*.R"
description: >
  R coding conventions and style guidelines for this project, covering
  script structure, naming conventions, syntax rules, function documentation
  with roxygen2, and testing with testthat.
---

# R Coding Conventions and Style Guide

## Coding Style

This coding style is a combination of various sources
([Tidyverse](https://style.tidyverse.org/index.html),
[Google](https://google.github.io/styleguide/Rguide.html), and others).
Style should be consistent within a project.

## Script Structure

One script should serve one purpose and that should be obvious from its name.
Scripts are always partitioned into clearly readable chunks.

### Script Header

The script header should contain the name of the project, objectives (purpose)
of that script, authors, and rough date (year of the project).

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

Each section of a script should begin with a header which consists of a name
wrapped by two lines. The name of a header should start with a capital letter.
Each header name should be followed by `-----` so that it is automatically
picked by IDE as a section header.

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

Adding comments to code plays a pivotal role in ensuring reproducibility and
preserving code knowledge for future reference. When things change or break,
the user will be thankful for comments. There's no need to comment excessively
or unnecessarily, but a comment describing what a large or complex chunk of
code does is always helpful. The first letter of a comment is capitalized and
spaced away from the pound sign (`#`).

Example of a single-line comment:

```r
# This is a comment.
```

#### Multi-line comment

Multi-line comments should start with a capital letter and the new line should
start with one tab.

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

No line of code should be longer than 80 characters (including comments).
Users can visualise the 80 characters line in selected IDE.

## Naming Conventions

```r
"There are only two hard things in Computer Science:
 cache invalidation and naming things."
```

### Object Names

Objects and functions should use `snake_style`. The `.` in names is somewhat
popular but it causes issues with names of methods and should be therefore
avoided. The names are preferred to be very descriptive, more expressive and
more explicit.

The names should be nouns and start with the type of object:

- `data_*` - for data
  - special subcategory is `table_*` for tables (mainly as an object for
    reference). Note that all tables can be data but not vice versa.
- `list_` - for lists
- `vec_` - for vectors
- `mod_*` - for statistical model
- `res_` - special category, which can be used within the function to name an
  object to be returned (`return(res_*)`).

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

It is possible to start a function with a `"."` (e.g., `.get_round_value()`)
to flag internal functions.

### Column (Variable) Names in Data Frames

`snake_style` is preferred for column names in both `data.frames` and
`tibbles`. Note that the [janitor](https://sfirke.github.io/janitor/) package
can be used to edit this automatically.

## Syntax

Many of the syntax issues can be checked/fixed by
[lintr](https://lintr.r-lib.org/) and
[styler](https://styler.r-lib.org/index.html) packages, which can be used to
automate lots of the tedious aspects.

### Spaces

Space (`" "`) should always be placed:

- after a comma
- before and after infix operators (`==`, `+`, `-`, `<-`, `~`, etc.)

Exceptions:

- No spaces inside or outside parentheses for regular function calls
- Operators with high precedence should not be surrounded by space:
  `:`, `::`, `:::`, `$`, `@`, `[`, `[[`, `^`, unary `-`

### New Lines

Prefer code that is more vertical than horizontal. Therefore, use quite a lot
of new lines.

Usage of a semicolon (`;`) to indicate a new line is not preferred.

A new line should be:

#### 1. After an Object Assignment (`<-`)

```r
data_diversity <-
  read_data(...)
```

An exception is an assignment of function.

```r
get_data <- function(...) {
  ...
}
```

#### 2. After a Pipe Operator (`%>%`)

Note that there should be a space before a pipe.

```r
data_diversity <-
  get_data() %>%
  transform_to_percentages()
```

#### 3. After a Function Argument

This should be true for both function declaration and usage. The exception is
a single argument.

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

#### 4. Parentheses

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

For `for()`, `if()`, and `while()` loops, the iterator or condition is placed on its
own indented line, and the closing `) {` is indented to the same level:

```r
for (
  col_name in vec_col_names
  ) {
  ...
}

if (
  logical_test
) {
  ...
}

while (
  condition
  ) {
  ...
}
```

### Assignment

Always use the left assignment `<-`.

Do **NOT** use:

- right assignment (`->`)
- equals (`=`)

There should be a new line after the assignment. Note that rarely single-line
assignment can be used:

```r
data_diversity <-
  get_data()

preferred_shape <- "triangle"
```

### Logical Evaluation

Always use `TRUE` and `FALSE`, instead of `T` and `F`.

## Functions

For function calls, always state the arguments even though R can have anonymous
arguments. The only exception is for functions where arguments are not known
(i.e. `...` argument).

### Tidyverse

It is preferred to use the Tidyverse version of functions over base ones:

| Base R | Better Style, Performance, and Utility |
|--------|----------------------------------------|
| `read.csv()` | `readr::read_csv()` |
| `df$some_column` | `df %>% dplyr::pull(some_column)` |
| `df$some_column = ...` | `df %>% dplyr::mutate(some_column = ...)` |

### Namespace

Always use the full package namespace with a function call. This helps to
track the source of function in a script:

```r
data_diversity %>%
  dplyr::mutate(
    beta_diversity = 0
  )
```

### Creating Functions

Specific rules apply for making custom functions:

- For naming of functions see function names section above
- Each function (declaration) should be placed in a separate script named
  after the function. Therefore, there should be only a single function
  in each function script
- Function should always return (`return(res_value)`)

#### Anonymous Functions

In various instances, it might be better to not create a new function but to
use an anonymous function (e.g. inside of `purrr::map_*()`).

In that case, use tilde (`~`) for change in map default values in the function:

```r
purrr::map(
  .f = ~ {
    mean(.x)
  }
)
```

For `purrr::pmap_*()`, use `..1`, `..2`, etc:

```r
purrr::pmap(
  .l = list(
    list_1,
    list_2,
    list_3,
    .f = ~ {
      ..1 + ..2 + ..3
    }
  )
)
```

#### Function Documentation

Each function should have documentation at the beginning of the function using
the [roxygen2](https://roxygen2.r-lib.org/) package. This can be useful also
for project-specific functions (not just within the package) as it is easier
to transition to a custom package.

The roxygen2 documentation should be placed before the function declaration
but keep the line limit of 80 characters. The documentation should be in the
following format:

```R
#' @title Title of the function
#' @description Description of the function
#' @param arg1 Description of the first argument
#' @param arg2 Description of the second argument
#' @param arg3 Description of the third argument
#' @return Description of the return value
#' @details Details about the function
#' @seealso Related functions or references
#' @export
```

#### Testing Functions

All tests are done using the [testthat](https://testthat.r-lib.org/) package.
Each function should have its own test file, which is named after the function
(e.g., `test-<function_name>.R`).

Generally, the function should be tested for:

- output of correct type
- output of correct data
- handling of input errors

**Reproducibility:**
- When randomness is involved, always use `set.seed(900723)` as the standard
  seed value for this project
