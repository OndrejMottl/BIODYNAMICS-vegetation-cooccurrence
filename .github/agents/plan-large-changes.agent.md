---
name: plan-large-changes
description: >-
  Use when: planning large or complex changes to the codebase before implementation begins.
  Interviews the user with focused questions, generates a structured implementation plan,
  saves it to Documentation/Implementation_plans/plan_<topic>.md for other agents to pick up, and optionally
  produces a GitHub Issues scaffold for long-running projects.
argument-hint: >-
  Describe the change or feature you want to plan (e.g. "refactor the trait
  aggregation pipeline" or "add spatial resolution analysis").
tools: [vscode/askQuestions, read/readFile, search/fileSearch, search/listDirectory, search/textSearch, browser/openBrowserPage, browser/readPage, browser/screenshotPage, browser/navigatePage, browser/clickElement, browser/dragElement, browser/hoverElement, browser/typeInPage, browser/runPlaywrightCode, browser/handleDialog, github/add_issue_comment, github/get_commit, github/get_file_contents, github/get_label, github/get_latest_release, github/get_me, github/get_release_by_tag, github/get_tag, github/issue_read, github/issue_write, github/list_issue_types, github/list_issues, github/list_releases, github/pull_request_read, github/search_code, github/search_commits, github/search_issues, github/search_pull_requests, github/sub_issue_write, r-mcptools/btw_tool_agent_subagent, r-mcptools/btw_tool_cran_package, r-mcptools/btw_tool_cran_search, r-mcptools/btw_tool_docs_available_vignettes, r-mcptools/btw_tool_docs_help_page, r-mcptools/btw_tool_docs_package_help_topics, r-mcptools/btw_tool_docs_package_news, r-mcptools/btw_tool_docs_vignette, r-mcptools/btw_tool_env_describe_data_frame, r-mcptools/btw_tool_env_describe_environment, r-mcptools/btw_tool_files_edit, r-mcptools/btw_tool_files_list, r-mcptools/btw_tool_files_read, r-mcptools/btw_tool_files_replace, r-mcptools/btw_tool_files_search, r-mcptools/btw_tool_files_write, r-mcptools/btw_tool_github, r-mcptools/btw_tool_ide_read_current_editor, r-mcptools/btw_tool_pkg_check, r-mcptools/btw_tool_pkg_coverage, r-mcptools/btw_tool_pkg_document, r-mcptools/btw_tool_pkg_load_all, r-mcptools/btw_tool_pkg_test, r-mcptools/btw_tool_sessioninfo_is_package_installed, r-mcptools/btw_tool_sessioninfo_package, r-mcptools/btw_tool_sessioninfo_platform, r-mcptools/btw_tool_web_read_url, r-mcptools/list_r_sessions, r-mcptools/select_r_session, gitkraken/git_blame, gitkraken/git_status, gitkraken/git_worktree, gitkraken/issues_assigned_to_me, gitkraken/issues_get_detail, gitkraken/pull_request_assigned_to_me, gitkraken/pull_request_get_comments, gitkraken/pull_request_get_detail, gitkraken/repository_get_file_content, todo]
---

# Plan Large Changes Agent

This Copilot custom-agent file is kept for Copilot discovery only.
The canonical agent definition lives in `.ai/agents/plan-large-changes.agent.md`.

When running this agent, follow `.ai/agents/plan-large-changes.agent.md`. Keep this file's YAML frontmatter intact so Copilot can still discover the custom agent.
