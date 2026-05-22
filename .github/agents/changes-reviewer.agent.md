---
name: changes-reviewer
description: >-
  Use when: reviewing code changes made in this conversation for compliance with project coding conventions. Checks R code, functions, tests, and visualisation against all project instruction files, reports violations with suggested fixes, summarises the changes, and confirms the implementation with the user. Trigger phrases: "review changes", "validate implementation", "check my code", "review what was done", "check conventions".
argument-hint: >-
  List the files changed in this conversation (e.g. "R/Functions/foo.R and its  test file"), or just say "review everything changed in this session".
tools: [read, search, vscode]
---

# Changes Reviewer Agent

This Copilot custom-agent file is kept for Copilot discovery only.
The canonical agent definition lives in `.ai/agents/changes-reviewer.agent.md`.

When running this agent, follow `.ai/agents/changes-reviewer.agent.md`. Keep this file's YAML frontmatter intact so Copilot can still discover the custom agent.
