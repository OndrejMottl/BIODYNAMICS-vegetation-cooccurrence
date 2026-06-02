# Plan: Agent Instruction Reorganisation for Multi-System Support

**Date:** 2026-05-13  
**Author:** plan-large-changes agent  
**Status:** Draft

---

## Goal

The current instruction and agent files live exclusively under `.github/`, which means
only GitHub Copilot can discover them automatically. Collaborators using other AI
coding assistants — OpenAI Codex CLI, Anthropic Claude Code, Google Gemini Code
Assist, Cursor, Windsurf, and future systems — either miss all guidance or must
manually point their tool at the right files. After this change, a shared `.ai/`
folder will be the single source of truth for all instruction content, and each AI
system will have a lightweight native entry-point file that routes to it. Copilot's
existing `applyTo` feature is preserved; no current functionality regresses.

---

## Background: AI System Conventions

Each system has a different native convention for discovering project-level
instructions. This is a summary of known standards:

| System | Native file(s) | Notes |
|--------|---------------|-------|
| **GitHub Copilot** | `.github/copilot-instructions.md` + `.github/instructions/*.instructions.md` (with `applyTo` YAML frontmatter) + `.github/agents/*.agent.md` | Supports per-file-type routing via `applyTo`, custom agent modes |
| **OpenAI Codex CLI** | `AGENTS.md` at repo root (and parent dirs) | De-facto universal convention; also checked by Aider and others |
| **Anthropic Claude Code** | `CLAUDE.md` at repo root | Supports `@import` for pulling in other files; also reads subdirectory `CLAUDE.md` files |
| **Google Gemini Code Assist** | `GEMINI.md` at repo root | Same pattern as CLAUDE.md/AGENTS.md |
| **Cursor** | `.cursor/rules/*.mdc` with YAML frontmatter (`globs`, `alwaysApply`) | Modern replacement for legacy `.cursorrules`; supports per-file-type routing parallel to Copilot `applyTo` |
| **Windsurf / Codeium** | `.windsurfrules` at repo root | Simple plain-text file; no per-file-type routing |
| **Antigravity / unknown systems** | Tool-specific (e.g. `.antigravity/rules.md`) | Recommended: follow the `AGENTS.md` fallback pattern; add a thin per-tool file pointing to `.ai/` when needed |
| **Aider** | Reads `AGENTS.md` if present; also respects `CONVENTIONS.md` | |

**Key insight**: `AGENTS.md` has emerged as the broadest-coverage universal
convention and should be the primary entry point. Each other native file is a thin
redirect that routes the tool to the same `.ai/` content.

---

## Scope

### In scope

- Create `.ai/` folder as the canonical shared source of instruction content
- Consolidate the 5 separate R coding instruction files into 2 `.ai/` files
  (moderate refactor — merge related content, do not rewrite from scratch)
- Move `.github/agents/` to `.ai/agents/` so agent definitions are system-agnostic
- Create `AGENTS.md` at repo root (universal lightweight index)
- Create `CLAUDE.md` at repo root (thin redirect for Claude Code)
- Create `GEMINI.md` at repo root (thin redirect for Gemini)
- Create `.cursor/rules/` with `.mdc` files for Cursor's native routing
- Update `.github/copilot-instructions.md` to be a thin redirect to `AGENTS.md` + `.ai/`
- Update `.github/instructions/*.instructions.md` files — keep `applyTo` frontmatter,
  update body to reference the relevant `.ai/` file (content stays in `.ai/`)
- Update all internal cross-references (subagent.instructions.md,
  changes-reviewer.agent.md, plan-large-changes.agent.md)

### Out of scope

- Changing any instruction *content* beyond what is needed for consolidation
  (this is a restructure, not a rewrite)
- Adding new rules, new workflows, or new test infrastructure
- Modifying pipeline files, R source, or analysis scripts
- Removing `.github/instructions/` — it is kept for Copilot's `applyTo` feature

### Affected files / components

**Files that will be created:**

| New file | Source content |
|----------|---------------|
| `AGENTS.md` | New (lightweight index) |
| `CLAUDE.md` | New (thin redirect) |
| `GEMINI.md` | New (thin redirect) |
| `.ai/r-coding.md` | Merged from `r-coding.instructions.md`, `r-coding-tidyverse.instructions.md`, `r-coding-performance.instructions.md`, `r-coding-visualisation.instructions.md` |
| `.ai/r-functions.md` | Merged from `r-coding-functions.instructions.md`, `make_roxygen2_documentation.instructions.md`, `make_test_file_for_a_function.instructions.md` |
| `.ai/git-workflow.md` | From `git-workflow.instructions.md` |
| `.ai/quarto.md` | From `quarto.instructions.md` |
| `.ai/debugging.md` | From `debugging.instructions.md` |
| `.ai/review-checklist.md` | Extracted from `changes-reviewer.agent.md` Step 4 (review rules) |
| `.ai/agents/changes-reviewer.agent.md` | Moved from `.github/agents/changes-reviewer.agent.md` |
| `.ai/agents/plan-large-changes.agent.md` | Moved from `.github/agents/plan-large-changes.agent.md` |
| `.cursor/rules/r-coding.mdc` | New (Cursor-specific, globs: `**/*.R`) |
| `.cursor/rules/r-functions.mdc` | New (Cursor-specific, globs: `**/Functions/**/*.R`) |
| `.cursor/rules/quarto.mdc` | New (Cursor-specific, globs: `**/*.qmd`) |
| `.cursor/rules/project.mdc` | New (Cursor-specific, alwaysApply: true) |

**Files that will be edited:**

| File | Change |
|------|--------|
| `.github/copilot-instructions.md` | Replace body with thin redirect to `AGENTS.md` + `.ai/` file index |
| `.github/instructions/r-coding.instructions.md` | Keep `applyTo`, update body to "See `.ai/r-coding.md`" |
| `.github/instructions/r-coding-tidyverse.instructions.md` | Keep `applyTo`, update body to "See `.ai/r-coding.md`" |
| `.github/instructions/r-coding-functions.instructions.md` | Keep `applyTo`, update body to "See `.ai/r-functions.md`" |
| `.github/instructions/r-coding-performance.instructions.md` | Keep `applyTo`, update body to "See `.ai/r-coding.md`" |
| `.github/instructions/r-coding-visualisation.instructions.md` | Keep `applyTo`, update body to "See `.ai/r-coding.md`" |
| `.github/instructions/make_roxygen2_documentation.instructions.md` | Keep `applyTo`, update body to "See `.ai/r-functions.md`" |
| `.github/instructions/make_test_file_for_a_function.instructions.md` | Keep `applyTo`, update body to "See `.ai/r-functions.md`" |
| `.github/instructions/git-workflow.instructions.md` | Keep `applyTo`, update body to "See `.ai/git-workflow.md`" |
| `.github/instructions/quarto.instructions.md` | Keep `applyTo`, update body to "See `.ai/quarto.md`" |
| `.github/instructions/debugging.instructions.md` | Keep `applyTo`, update body to "See `.ai/debugging.md`" |
| `.github/instructions/subagent.instructions.md` | Update path table to new `.ai/` and `.ai/agents/` locations |

**Files to keep unchanged:**

- `.github/commit-instructions.md` — Copilot-specific commit message rules; too
  short to merit moving
- All R source, pipeline, and analysis files — no changes

---

## Git Worktree Setup

Follow `.github/instructions/git-workflow.instructions.md`.
Create the GitHub issue first (see scaffold at the end of this plan) and name the
branch after that issue.

1. Verify `main` is current:
   ```powershell
   git checkout main
   git pull origin main
   ```
2. Create worktree (replace `<issue-number>` after issue is created):
   ```powershell
   git worktree add -b <issue-number>-agent-instruction-reorganisation `
     ..\BIODYNAMICS_agent_instruction_reorganisation
   ```
3. Verify:
   ```powershell
   git worktree list
   ```
4. Open in new VS Code window:
   ```powershell
   code -n ..\BIODYNAMICS_agent_instruction_reorganisation
   ```
5. Symlink VegVault (elevated cmd):
   ```cmd
   mklink "D:\GITHUB\BIODYNAMICS_agent_instruction_reorganisation\Data\Input\VegVault.sqlite" ^
          "D:\GITHUB\BIODYNAMICS_vegetation_cooccurrence\Data\Input\VegVault.sqlite"
   ```
6. Restore renv:
   ```r
   renv::restore()
   ```

---

## Refactoring Strategy

The five R coding instruction files contain related but complementary rules. With
**Moderate** refactor scope, the goal is to consolidate into a smaller number of
coherent files — not to rewrite content.

**`.ai/r-coding.md`** — general R conventions:
- Script structure, naming, syntax (from `r-coding.instructions.md`)
- Tidyverse preferences, namespace, dplyr/purrr (from `r-coding-tidyverse.instructions.md`)
- Performance: profiling, loops, parallel processing (from `r-coding-performance.instructions.md`)
- Visualisation: ggview canvas, save_ggplot, config options (from `r-coding-visualisation.instructions.md`)

**`.ai/r-functions.md`** — function design and testing:
- Function style, error handling with cli (from `r-coding-functions.instructions.md`)
- Roxygen2 documentation template and rules (from `make_roxygen2_documentation.instructions.md`)
- Complete test-writing rules via testthat (from `make_test_file_for_a_function.instructions.md`)

Both files use top-level `##` sections so any AI tool can navigate directly to the
relevant section by keyword. The merge order within each file should mirror the
natural authoring workflow (write → document → test).

---

## Implementation Phases

### Phase 1 — Create `.ai/` source-of-truth files

**Goal:** All instruction content exists in the new `.ai/` folder; no content is lost.

**Tasks:**
- [ ] Create `.ai/r-coding.md` by merging (in order): `r-coding.instructions.md`,
      `r-coding-tidyverse.instructions.md`, `r-coding-performance.instructions.md`,
      `r-coding-visualisation.instructions.md`. Strip YAML frontmatter; keep all body
      content. Add a clear `##` section heading for each former file.
- [ ] Create `.ai/r-functions.md` by merging (in order):
      `r-coding-functions.instructions.md`,
      `make_roxygen2_documentation.instructions.md`,
      `make_test_file_for_a_function.instructions.md`.
- [ ] Create `.ai/git-workflow.md` — copy body of `git-workflow.instructions.md`
      (strip YAML frontmatter).
- [ ] Create `.ai/quarto.md` — copy body of `quarto.instructions.md`.
- [ ] Create `.ai/debugging.md` — copy body of `debugging.instructions.md`.
- [ ] Create `.ai/review-checklist.md` — extract the review checklist rules from
      `changes-reviewer.agent.md` Step 4 into a standalone file so any agent (not
      just the changes-reviewer) can load them.
- [ ] Create `.ai/agents/` folder and copy both agent files:
      - `.ai/agents/changes-reviewer.agent.md`
      - `.ai/agents/plan-large-changes.agent.md`
      Update internal path references within those agent files to use `.ai/`
      (e.g. the instruction-file table in `changes-reviewer.agent.md` Step 2).

**Validation:**
- This phase is not complete until its validation passes.
- Manually diff each `.ai/` file against its source(s) to confirm no content was
  dropped.
- No test suite run needed — this phase creates documentation files only.
- For any larger code change, run the mandatory change-review workflow from
  `.github/copilot-instructions.md` before finalising. If subagent delegation
  requires explicit user permission, ask before finalising.

---

### Phase 2 — Add universal system entry-point files

**Goal:** `AGENTS.md`, `CLAUDE.md`, and `GEMINI.md` exist at the repo root, and
`.cursor/rules/` provides Cursor-native routing.

**Tasks:**
- [ ] Create `AGENTS.md` at repo root with the following sections:
  - One-paragraph project summary (pull from copilot-instructions.md "Overview")
  - **Required reading by task** routing table:
    ```markdown
    | Task | Read this file |
    |------|---------------|
    | R code (any `.R` file) | `.ai/r-coding.md` |
    | R functions, roxygen, testing | `.ai/r-functions.md` |
    | Quarto documents (`.qmd`) | `.ai/quarto.md` |
    | Git, branches, worktrees, PRs | `.ai/git-workflow.md` |
    | Debugging | `.ai/debugging.md` |
    | Reviewing code changes | `.ai/review-checklist.md` |
    | Agent/subagent workflows | `.ai/agents/` |
    ```
  - Key absolute rules section (3–5 bullet points covering the most critical
    project-wide constraints: `here::here()` for paths, `renv` for packages,
    `targets` for pipeline, TDD cycle, squash-merge policy)
- [ ] Create `CLAUDE.md` — thin redirect:
  ```markdown
  # CLAUDE.md
  Follow `AGENTS.md` for task routing.
  All detailed instructions live in `.ai/`.
  ```
- [ ] Create `GEMINI.md` — same thin redirect content as `CLAUDE.md`.
- [ ] Create `.cursor/rules/project.mdc` with `alwaysApply: true` and content
  matching the project overview + key absolute rules from `AGENTS.md`.
- [ ] Create `.cursor/rules/r-coding.mdc` with `globs: ["**/*.R"]` and content
  pointing to `.ai/r-coding.md`.
- [ ] Create `.cursor/rules/r-functions.mdc` with
  `globs: ["**/Functions/**/*.R", "**/Testing/**/*.R"]`.
- [ ] Create `.cursor/rules/quarto.mdc` with `globs: ["**/*.qmd"]`.

**Validation:**
- This phase is not complete until its validation passes.
- Verify `AGENTS.md` renders correctly: `cat AGENTS.md` in terminal.
- Verify `.cursor/rules/*.mdc` files have valid YAML frontmatter.
- No test suite run needed — documentation files only.
- For any larger code change, run the mandatory change-review workflow before finalising.

---

### Phase 3 — Update Copilot files to thin redirects

**Goal:** Copilot users see the same content via `.github/` as before, but the
authoritative source is now `.ai/`. No Copilot functionality is lost.

**Tasks:**
- [ ] Update `.github/copilot-instructions.md`:
  - Replace the full body with a brief project paragraph + explicit `.ai/` file index
  - Format:
    ```markdown
    # BIODYNAMICS Vegetation Co-occurrence Project

    Follow `AGENTS.md` for the full task-to-file routing.

    ## Quick reference for Copilot
    - R code: read `.ai/r-coding.md`
    - R functions/testing: read `.ai/r-functions.md`
    - Quarto: read `.ai/quarto.md`
    - Git workflow: read `.ai/git-workflow.md`
    - Debugging: read `.ai/debugging.md`
    - Code review: read `.ai/review-checklist.md`
    - Agent files: `.ai/agents/`
    ```
- [ ] For each `.github/instructions/*.instructions.md` file: keep the existing
  YAML frontmatter block unchanged (`applyTo`, `description`); replace the body
  with a one-liner redirect, e.g.:
  ```markdown
  See `.ai/r-coding.md` for all R coding conventions applicable to this file type.
  ```
- [ ] Update `.github/instructions/subagent.instructions.md`:
  - Update the instruction-file path table to show new `.ai/` paths
  - Update the `.github/agents/` references to `.ai/agents/`

**Validation:**
- This phase is not complete until its validation passes.
- Open a Copilot chat in VS Code and ask it to describe R coding conventions.
  Confirm it reads `.ai/r-coding.md` rather than returning empty/wrong content.
- Verify the `applyTo` frontmatter is intact on each `.github/instructions/` file.
- No test suite run needed — documentation files only.
- For any larger code change, run the mandatory change-review workflow before finalising.

---

### Phase 4 — Update internal cross-references and finalise

**Goal:** All path references inside agent files, instruction files, and the
copilot-instructions.md point to the new `.ai/` structure. Old `.github/agents/`
files can be removed once `.ai/agents/` is confirmed working.

**Tasks:**
- [ ] In `.ai/agents/changes-reviewer.agent.md`:
  - Update Step 2 instruction-file table — change all `.github/instructions/` paths
    to `.ai/r-coding.md`, `.ai/r-functions.md`, etc.
  - Update the reference to `.github/copilot-instructions.md` → `AGENTS.md`
- [ ] In `.ai/agents/plan-large-changes.agent.md`:
  - Update any `.github/instructions/` and `.github/agents/` path references
    to the new `.ai/` locations
- [ ] Verify `.github/copilot-instructions.md` skill/instruction `<file>` references
  in the VS Code workspace settings or `.vscode/settings.json` (if any) still
  resolve — adjust if needed
- [ ] Delete (after explicit user confirmation) the original `.github/agents/` files
  that have been superseded by `.ai/agents/`. **Do not delete without confirmation.**
- [ ] Add a note in `.ai/agents/plan-large-changes.agent.md` that the tool list
  should also reference `.ai/agents/` as the new location for agent files

**Validation:**
- This phase is not complete until its validation passes.
- Run `grep -r ".github/agents" .ai/ .github/` — should return zero matches.
- Run `grep -r ".github/instructions" .ai/ AGENTS.md CLAUDE.md GEMINI.md` — should
  return zero matches (all `.ai/` files should reference `.ai/` paths only).
- Run the full fast test suite to confirm no R code was accidentally affected:
  ```powershell
  Rscript R/03_Supplementary_analyses/Testing/Run_tests.R
  ```
- Run `targets::tar_manifest()` for the most recently used pipeline config to
  confirm the pipeline definition is unaffected.
- For any larger code change, run the mandatory change-review workflow from
  `.github/copilot-instructions.md` before finalising.

---

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|-----------|
| AI tools that cannot follow cross-file references miss content from thin `.github/instructions/` redirects | Medium | Keep full content in `.ai/` files; `AGENTS.md` explicitly routes to them. If a tool fails, add content inline to its native file. |
| Copilot `applyTo` silently breaks if frontmatter is malformed during editing | Low | Validate each `.github/instructions/` file with a Copilot chat immediately after Phase 3 |
| Agent files in `.ai/agents/` not discovered by Copilot's agent-mode registry | Low | Copilot agent registry only reads `.github/agents/`; keep thin stub files there pointing to `.ai/agents/` copies, or keep originals in `.github/agents/` and maintain `.ai/agents/` as mirrors |
| Cross-references inside agent files not updated → broken path lookups | Medium | Phase 4 grep check catches all residual old paths before merging |
| "Antigravity" or other unknown systems require a different convention | Low | Follow the same pattern: add a thin native config file pointing to `.ai/` content |

---

## Open Questions

1. **Copilot agent registry**: Copilot's `.github/agents/` is Copilot-proprietary. If we move agent files to `.ai/agents/`, Copilot's agent-mode UI may not pick them up automatically. Options:
   - Keep `.github/agents/` as stubs that `@import` from `.ai/agents/`
   - Keep originals in `.github/agents/` and copy to `.ai/agents/` (with risk of drift)
   - Keep `.github/agents/` as primary and symlink (but symlinks don't work on all OS)
   - **Recommended**: Keep `.github/agents/` as the Copilot-native location; copy files to `.ai/agents/` and note in `AGENTS.md` that these are mirrors. Confirm this is acceptable before implementing.

2. **Windsurf**: Does the project or any collaborator use Windsurf? If yes, add `.windsurfrules` (thin redirect) in Phase 2.

3. **AGENTS.md depth**: Should `AGENTS.md` duplicate any of the absolute-rule bullets from `copilot-instructions.md` (e.g. the targets/pipeline rules), or strictly be a routing table with a project overview paragraph only?

---

## GitHub Issue Scaffold

> This issue is self-contained. Anyone reading it without this plan file should have
> all context needed to act on it.

**Title:** Reorganise AI instruction files for multi-system support (AGENTS.md + .ai/)

**Body:**
```
## Background

All current instruction files live under `.github/`, which means only GitHub Copilot
discovers them automatically. Collaborators using Codex CLI, Claude Code, Gemini Code
Assist, Cursor, or other AI tools either miss all project guidance or must manually
point their tool at the right files.

## Goal

Create a system-agnostic `.ai/` folder as the single source of truth for all
instruction content, add a universal `AGENTS.md` entry point plus thin system-specific
redirect files (`CLAUDE.md`, `GEMINI.md`, `.cursor/rules/`), and keep Copilot's
existing `applyTo` feature working via updated `.github/instructions/` thin wrappers.

## Scope

- New `.ai/` folder with consolidated instruction files
- `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` at repo root
- `.cursor/rules/` for Cursor-native routing
- `.github/copilot-instructions.md` and `.github/instructions/*.instructions.md`
  updated to thin redirects (Copilot `applyTo` preserved)
- Agent files mirrored to `.ai/agents/`
- All internal cross-references updated

No R source, pipeline, or analysis files are changed.

## Planned phases

1. **Phase 1 — Create `.ai/` source-of-truth files**: Consolidate 10 instruction files
   into 6 `.ai/` files; move agent files to `.ai/agents/`.
2. **Phase 2 — Universal entry-point files**: Create `AGENTS.md`, `CLAUDE.md`,
   `GEMINI.md`, `.cursor/rules/*.mdc`.
3. **Phase 3 — Copilot thin redirects**: Update `.github/copilot-instructions.md`
   and `.github/instructions/*.instructions.md` to reference `.ai/` as the source.
4. **Phase 4 — Cross-reference cleanup and final validation**: Update all path
   references inside agent and instruction files; run grep checks and full test suite.

## Validation expectations

- Each phase has its own validation gate (no standalone final-validation phase).
- Full test suite (`Rscript R/03_Supplementary_analyses/Testing/Run_tests.R`) run in
  Phase 4 to confirm no R code was accidentally affected.
- `targets::tar_manifest()` run to confirm pipeline definition is unaffected.
- Mandatory change-review subagent workflow run for any larger code change.

## Acceptance Criteria

- [ ] `AGENTS.md` exists at repo root and routes correctly to `.ai/` files
- [ ] `.ai/r-coding.md` contains merged content of all 4 general R coding files
- [ ] `.ai/r-functions.md` contains merged content of the 3 function/test/doc files
- [ ] `CLAUDE.md` and `GEMINI.md` exist as thin redirects
- [ ] `.cursor/rules/` contains at least 4 `.mdc` files with valid frontmatter
- [ ] All `.github/instructions/` files retain their `applyTo` frontmatter
- [ ] A Copilot chat correctly reads `.ai/r-coding.md` when a `.R` file is open
- [ ] `grep -r ".github/instructions" .ai/` returns zero matches
- [ ] Full test suite passes
- [ ] `targets::tar_manifest()` passes for at least one active config
```
