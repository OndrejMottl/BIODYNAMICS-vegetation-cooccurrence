# BIODYNAMICS Vegetation Co-occurrence Agent Guide

This file is the universal entry point for coding assistants working in this repository. Canonical guidance lives in `.ai/`; this file routes tasks to the correct source documents.

## Required Reading

| Task | Read first |
|---|---|
| Any repository work | `AGENTS.md` |
| R scripts, pipelines, modelling, data processing, visualisation, package dependencies, `{renv}`, or `renv.lock` | `.ai/r-coding.md` |
| R functions, roxygen2 docs, function tests | `.ai/r-functions.md`, `.ai/r-coding.md` |
| Creating or renaming R functions, files, objects, targets, keys, or persisted contracts | `.ai/r-coding.md`, then `Documentation/Implementation_inventories/R_architecture/r_naming_decisions_v1.md` |
| Git, branches, worktrees, commits, review workflow | `.ai/git-workflow.md` |
| Suggesting or writing a commit message | `.ai/git-workflow.md`, then `.github/commit-instructions.md` |
| Quarto documents or website work | `.ai/quarto.md` |
| Debugging or bug fixes | `.ai/debugging.md` |
| Reviewing changed files | `.ai/review-checklist.md` |
| Reusable agent prompts | `.ai/agents/changes-reviewer.agent.md`, `.ai/agents/plan-large-changes.agent.md` |

## Tool Adapters

- GitHub Copilot keeps native files under `.github/` for `applyTo` routing and agent discovery.
- Claude and Gemini use root redirect files that point back here.
- Cursor uses `.cursor/rules/*.mdc` to route file globs to `.ai/`.
- Other tools should load this file first and then follow the relevant `.ai/` links.

## Expected Entry Files

| Tool | Fresh repo root | Nested working directory |
|---|---|---|
| Codex CLI | `AGENTS.md` | Nearest repo-root `AGENTS.md` |
| Claude Code | `CLAUDE.md` -> `AGENTS.md` | Repo-root `CLAUDE.md` -> `AGENTS.md` |
| Gemini | `GEMINI.md` -> `AGENTS.md` | Repo-root `GEMINI.md` -> `AGENTS.md` |
| Cursor | `.cursor/rules/*.mdc` | Repo-root `.cursor/rules/*.mdc` |
| GitHub Copilot | `.github/copilot-instructions.md` | `.github/instructions/*.instructions.md` by `applyTo` |

## Compatibility Notes

The `.ai/` files are canonical. Tool-native files are adapters and may not provide identical runtime behavior across assistants. Do not add a new adapter unless a real tool or collaborator needs it.

## Markdown Source Formatting

The 80-character line limit applies only to R source code, including R comments and roxygen2 lines. It does not apply to Markdown or GitHub text.

- Never hard-wrap prose in `.md` files, README files, instruction files, issue descriptions, pull-request descriptions, or comments at 80 characters or any other fixed width.
- Keep each Markdown paragraph and each list item on one source line, and let the editor or renderer wrap it visually.
- Add source line breaks only when Markdown structure or meaning requires them, such as headings, blank lines between paragraphs, separate list items, tables, code fences, blockquotes, or intentional hard breaks.
- In `.qmd` files, follow the sentence-per-line prose convention in `.ai/quarto.md`; complete sentences may be any length and must never be split to satisfy a column limit.

## Runtime Environment

The project is pinned to the R version recorded in `renv.lock` (R 4.5.1), which may differ from the machine's default R. `{sjSDM}` also needs a dedicated Python env with PyTorch; setup and the reasons behind it are in `Documentation/Materials/sjSDM_installation_guide.md`.

- Run R scripts from the repository root with the pinned version, for example `rig run -r 4.5.1 R/03_Supplementary_analyses/Testing/Run_tests.R`. A bare `Rscript` starts the default R, whose renv library may be empty. The `Rscript` commands elsewhere in this guidance assume the pinned R.
- Quarto renders need `QUARTO_R` set to the pinned R's `bin` folder (for example `C:/Program Files/R/R-4.5.1/bin`) for the same reason.
- reticulate finds the Python env through `RETICULATE_PYTHON` in the git-ignored project `.Renviron`. Do not change it, and do not run `sjSDM::install_sjSDM()`, `renv::restore()`, `renv::snapshot()`, or pip/uv installs unless the user asks.
- Check the setup with `diagnose_sjsdm_setup()` after `source("R/___setup_project___.R")`.

## Private Material

Keep private project material inside the repository in a git-ignored folder, never outside the project. Co-author correspondence (cover emails, per-person questions, replies that include contact details or personal circumstances) goes in `Documentation/Manuscript/Coauthor_feedback/Round_N/Private/`, which `.gitignore` excludes. `Data/Temp/` is disposable by convention and must not hold anything worth keeping.

## Repository Architecture Contract

- `R/Functions/` contains reusable capability-owned functions with exactly one top-level function per matching file and an inventoried test.
- `R/Pipelines/` contains active pipeline definitions and pipe segments.
- `R/02_Main_analyses/` contains only allowlisted production runners.
- `R/03_Supplementary_analyses/` contains documented non-main workflows; mirrored test directories are not workflow roots.
- `Configuration/` contains human-authored fragments. Root `config.yml` and `Configuration/Generated/profile_catalog.md` are generated artifacts.
- All new or renamed R functions, files, objects, targets, keys, and persisted contracts must follow `Documentation/Implementation_inventories/R_architecture/r_naming_decisions_v1.md`. Existing names and inventory rows record the current state; they are not naming precedent or blanket approval for reuse.

After changing R paths, symbols, workflow documentation, configuration, or persisted contracts, run the generators and blocking validator documented in `R/03_Supplementary_analyses/Validation/Architecture/README.md`. Naming and nested-helper exceptions must match the maintained ledger exactly, name an owner and expiry issue, and be removed when that issue closes. The final map is `Documentation/Reports/R_architecture/r_architecture_dependency_map.md`.
