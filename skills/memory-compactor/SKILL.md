---
name: memory-compactor
description: Use when the user wants to automatically keep MEMORY.md compact. Installs a PostToolUse hook that warns Claude when MEMORY.md exceeds a line threshold after any Write or Edit to a memory directory, prompting automatic compaction into topic files.
---

# Memory Compactor

> **Author:** [sharooncs](https://github.com/sharooncs)

Automatically monitors MEMORY.md size and warns Claude to compact it when it grows too large. Keeps the memory index slim by enforcing a line threshold via a PostToolUse hook.

## Problem

Claude Code's auto-memory system uses `MEMORY.md` as an index that's loaded into every conversation — but only the first 200 lines are read. When detailed project notes are written inline instead of in topic files, the index silently overflows and memories become invisible.

## Solution

A PostToolUse hook that fires after every `Write` or `Edit` to a `memory/` directory. It counts MEMORY.md lines and injects a warning into Claude's context when the threshold is exceeded, prompting immediate compaction.

## Requirements

- Python 3.x (for JSON parsing from hook stdin)
- Claude Code with hooks support

## Installation

Run this in your terminal:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/install.sh"
```

With custom settings file and threshold:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/install.sh" ~/.claude/settings.json 50
```

**Default threshold:** 30 lines

This will add a `PostToolUse` hook entry to your `settings.json`. The installer is idempotent — running it again skips if already installed.

> See [`scripts/install.sh`](scripts/install.sh) for the full installation script.

## How It Works

1. After any `Write` or `Edit`, the hook reads the stdin JSON payload
2. Extracts the file path from `tool_input.file_path` or `tool_response.filePath`
3. Checks if the path contains `memory/` (forward or backslash)
4. If yes, finds `MEMORY.md` in the same directory and counts lines
5. If over threshold, injects a warning into Claude's context via `hookSpecificOutput`
6. Claude then compacts MEMORY.md by moving inline content to dedicated topic files

## MEMORY.md Best Practice

Keep MEMORY.md as a **slim index table** with one-line pointers to topic files:

```markdown
# Project Index

| Topic | Memory File |
|-------|------------|
| My Project | `project_my_project.md` |
| Git workflow | `feedback_git.md` |
```

All detail goes in the individual `memory/*.md` files, which Claude reads on demand.

## Uninstallation

Remove the `Write|Edit` entry containing `MEMORY.md` from the `PostToolUse` array in your `settings.json`, or use `/hooks` to review and disable.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Hook never fires | Check `/hooks` — ensure PostToolUse has a `Write\|Edit` matcher |
| No warning when MEMORY.md is large | Verify Python is on PATH: `python --version` |
| Warning fires too often | Increase threshold in the hook command (change the number after `-gt`) |
| Hook errors on non-memory files | Expected — the `case` pattern silently skips non-memory paths |
