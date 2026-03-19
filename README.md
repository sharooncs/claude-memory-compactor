# Memory Compactor for Claude Code

Automatically monitors MEMORY.md size and warns Claude to compact it when it exceeds a configurable line threshold.

## Problem

Claude Code's auto-memory system uses `MEMORY.md` as an index loaded into every conversation — but **only the first 200 lines are read**. When detailed project notes are written inline instead of in dedicated topic files, the index silently overflows and memories become invisible.

## Installation

### Plugin Marketplace

```
/plugin add sharooncs/claude-memory-compactor
```

### Manual

Copy the skill folder to your Claude Code skills directory:

```bash
cp -r . ~/.claude/skills/memory-compactor
```

Then run the installer:

```bash
bash ~/.claude/skills/memory-compactor/scripts/install.sh
```

With a custom threshold (default is 30 lines):

```bash
bash ~/.claude/skills/memory-compactor/scripts/install.sh ~/.claude/settings.json 50
```

## How It Works

1. A **PostToolUse** hook fires after every `Write` or `Edit` operation
2. The hook extracts the file path from the tool payload
3. If the path is inside a `memory/` directory, it locates `MEMORY.md` and counts lines
4. When the line count exceeds the threshold, it injects a warning into Claude's context
5. Claude then compacts MEMORY.md by moving inline content to dedicated topic files

## Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `settings_file` | `~/.claude/settings.json` | Path to your Claude Code settings |
| `threshold` | `30` | Max lines in MEMORY.md before warning triggers |

Pass both as positional arguments to `install.sh`:

```bash
bash scripts/install.sh <settings_file> <threshold>
```

## Uninstallation

Remove the `Write|Edit` entry containing `MEMORY.md` from the `PostToolUse` array in your `settings.json`, or use `/hooks` in Claude Code to review and disable it.

## License

[MIT](LICENSE)

## Author

[sharooncs](https://github.com/sharooncs)
