---
name: plan-large-changes
description: >-
  Use when: planning large or complex changes to the codebase before implementation begins.
  Interviews the user with focused questions, generates a structured implementation plan,
  saves it to Data/Temp/plan_<topic>.md for other agents to pick up, and optionally
  produces a GitHub Issues scaffold for long-running projects.
argument-hint: >-
  Describe the change or feature you want to plan (e.g. "refactor the trait
  aggregation pipeline" or "add spatial resolution analysis").
tools: [vscode/askQuestions, read/readFile, search/fileSearch, search/listDirectory, search/textSearch, github/search_issues, github/list_issues, github/issue_read, github/issue_write, github/sub_issue_write, r-mcptools/btw_tool_files_write, r-mcptools/btw_tool_agent_subagent, todo]
---

# Plan Large Changes Agent

This Copilot custom-agent file is kept for Copilot discovery only.
The canonical agent definition lives in `.ai/agents/plan-large-changes.agent.md`.

When running this agent, follow `.ai/agents/plan-large-changes.agent.md`. Keep this file's YAML frontmatter intact so Copilot can still discover the custom agent.
