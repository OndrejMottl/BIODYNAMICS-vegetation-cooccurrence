---
description: >
  Rules for launching subagents: what instruction files and source code must
  be pasted into the prompt for each subagent type so the subagent has all
  context it needs to follow project conventions.
---

# Subagent Instruction Requirements

## Core Rule

Subagents have **no access** to project files, instruction files, or the parent conversation context unless the content is explicitly pasted into the subagent prompt. Always read the required instruction files with `read_file` and paste their **full text** into the prompt before launching. Never pass file paths alone  -  that is not sufficient.

---

## Instruction Files in This Project

Most reusable instruction files live in `.github/instructions/`. Project-wide
assistant guidance lives in `.github/copilot-instructions.md`, and reusable
agent prompts live in `.github/agents/`.

| File | Covers |
|------|--------|
| `r-coding.instructions.md` | Naming, syntax, 80-char limit, script structure |
| `r-coding-tidyverse.instructions.md` | Tidyverse preferences, namespace, dplyr/purrr |
| `r-coding-functions.instructions.md` | Function style, error handling with cli |
| `r-coding-performance.instructions.md` | Profiling, loops, parallel processing |
| `r-coding-visualisation.instructions.md` | ggview canvas, save_ggplot |
| `make_test_file_for_a_function.instructions.md` | Complete test-writing rules |
| `make_roxygen2_documentation.instructions.md` | Roxygen2 doc template & rules |
| `debugging.instructions.md` | Debug workflow |
| `git-workflow.instructions.md` | Branch, squash merge, worktree rules |
| `quarto.instructions.md` | Quarto website conventions |
| `.github/copilot-instructions.md` | Project-wide assistant rules |
| `.github/agents/*.agent.md` | Reusable agent-specific review prompts |

---

## Test-Tier Context to Pass

When a subagent is asked to implement, review, or verify changes, include this
testing rule in the prompt:

- Run the default fast suite with
  `Rscript R/03_Supplementary_analyses/Testing/Run_tests.R`.
- Also run the opt-in VegVault integration tier when the changed files touch
  `build_vegvault_plan()`, `extract_*_from_vegvault()` functions,
  `vaultkeepr::*` calls, VegVault-backed `testthat` files, pipeline targets or
  pipe segments that depend on VegVault extraction, or tests containing
  `RUN_VEGVAULT_INTEGRATION`.
- The opt-in VegVault command is:

```powershell
$env:RUN_VEGVAULT_INTEGRATION = "true"
Rscript R/03_Supplementary_analyses/Testing/Run_tests.R
```

For targeted verification, use the same environment variable before calling
`testthat::test_file()`.

---

## What to Pass Per Subagent Type

### Writing or editing an R function (`R/Functions/`)

Paste the full text of ALL of these into the prompt:

1. `r-coding.instructions.md`
2. `r-coding-tidyverse.instructions.md`
3. `r-coding-functions.instructions.md`
4. `make_roxygen2_documentation.instructions.md`
5. The current source of the function file (if editing an existing one)

### Writing or editing a test file (`testthat/`)

This project follows **TDD**: test files are written against the function **spec stub** before the implementation exists. Tests must describe intended behaviour and must all fail when run against the stub.

Paste the full text of ALL of these into the prompt:

1. `r-coding.instructions.md`
2. `r-coding-tidyverse.instructions.md`
3. `r-coding-functions.instructions.md`
4. `make_test_file_for_a_function.instructions.md`
5. The **complete source** of the function under test (stub or implementation)

Also tell the subagent explicitly whether this is:

- **New function (TDD step 2)**: the function body is a stub  -  write tests that capture all intended behaviour and will fail against the stub.
- **Editing existing function (TDD step 2 of edit cycle)**: provide the updated spec and the current test file  -  add/revise tests for the new behaviour.

If the test file uses `RUN_VEGVAULT_INTEGRATION` or tests real VegVault access,
also paste the Test-Tier Context above and make clear whether the subagent
should run only the fast tests or the opt-in VegVault integration tier too.

### Writing or editing a pipeline script or pipe segment

Paste the full text of:

1. `r-coding.instructions.md`
2. `r-coding-tidyverse.instructions.md`
3. `r-coding-performance.instructions.md`
4. Relevant existing pipeline files for context

### Writing or editing a visualisation script

Paste the full text of:

1. `r-coding.instructions.md`
2. `r-coding-tidyverse.instructions.md`
3. `r-coding-visualisation.instructions.md`

### Reviewing completed larger code changes

For any larger code change, run a read-only review subagent before finalising
the answer. If a native `changes-reviewer` subagent is unavailable, launch an
`explorer` subagent and make it act as the reviewer.

Paste the full text of:

1. `.github/agents/changes-reviewer.agent.md`
2. Every instruction file listed inside that agent file
3. The complete contents of every file created or edited during the session

Also pass the exact changed-file list and instruct the subagent that it must:

- Follow `.github/agents/changes-reviewer.agent.md` exactly
- Stay read-only
- Not edit files
- Not run terminal commands
- Report instruction violations with suggested fixes
- Summarise the reviewed changes

### Git operations

Paste the full text of:

1. `git-workflow.instructions.md`

### Quarto / website pages

Paste the full text of:

1. `quarto.instructions.md`
2. `r-coding.instructions.md` (if the page contains R chunks)

---

## How to Structure the Prompt

In the `runSubagent` prompt include a dedicated section, for example:

```
## Project coding conventions (follow these exactly)

### r-coding.instructions.md
<paste full file content>

### r-coding-tidyverse.instructions.md
<paste full file content>

### make_test_file_for_a_function.instructions.md
<paste full file content>

## Function under test
<paste full function source>

## Task
<describe what the subagent must do>
```

