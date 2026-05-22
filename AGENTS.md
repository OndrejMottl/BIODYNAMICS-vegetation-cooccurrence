# BIODYNAMICS Vegetation Co-occurrence Agent Guide

This file is the universal entry point for coding assistants working in this
repository. Canonical guidance lives in `.ai/`; this file routes tasks to the
correct source documents.

## Required Reading

| Task | Read first |
|---|---|
| Any repository work | `AGENTS.md` |
| R scripts, pipelines, modelling, data processing, visualisation | `.ai/r-coding.md` |
| R functions, roxygen2 docs, function tests | `.ai/r-functions.md` |
| Git, branches, worktrees, commits, review workflow | `.ai/git-workflow.md` |
| Quarto documents or website work | `.ai/quarto.md` |
| Debugging or bug fixes | `.ai/debugging.md` |
| Reviewing changed files | `.ai/review-checklist.md` |
| Reusable agent prompts | `.ai/agents/changes-reviewer.agent.md`, `.ai/agents/plan-large-changes.agent.md` |

## Tool Adapters

- GitHub Copilot keeps native files under `.github/` for `applyTo` routing and
  agent discovery.
- Claude and Gemini use root redirect files that point back here.
- Cursor uses `.cursor/rules/*.mdc` to route file globs to `.ai/`.
- Other tools should load this file first and then follow the relevant `.ai/`
  links.

## Expected Entry Files

| Tool | Fresh repo root | Nested working directory |
|---|---|---|
| Codex CLI | `AGENTS.md` | Nearest repo-root `AGENTS.md` |
| Claude Code | `CLAUDE.md` -> `AGENTS.md` | Repo-root `CLAUDE.md` -> `AGENTS.md` |
| Gemini | `GEMINI.md` -> `AGENTS.md` | Repo-root `GEMINI.md` -> `AGENTS.md` |
| Cursor | `.cursor/rules/*.mdc` | Repo-root `.cursor/rules/*.mdc` |
| GitHub Copilot | `.github/copilot-instructions.md` | `.github/instructions/*.instructions.md` by `applyTo` |

## Compatibility Notes

The `.ai/` files are canonical. Tool-native files are adapters and may not
provide identical runtime behavior across assistants. Do not add a new adapter
unless a real tool or collaborator needs it.
