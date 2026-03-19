#!/usr/bin/env bash
# Memory Compactor — installs a PostToolUse hook into Claude Code settings
# that warns when MEMORY.md exceeds a configurable line threshold.
#
# Usage: bash install.sh [settings_file] [threshold]
#   settings_file: path to settings.json (default: ~/.claude/settings.json)
#   threshold:     max lines before warning (default: 30)

set -euo pipefail

SETTINGS="${1:-$HOME/.claude/settings.json}"
THRESHOLD="${2:-30}"

# The hook command — extracts file path from stdin JSON, checks if it's in a
# memory/ directory, counts MEMORY.md lines, warns if over threshold.
HOOK_CMD="bash -c 'FILE=\$(python -c \"import sys,json;d=json.load(sys.stdin);i=d.get(\\\"tool_input\\\",{});r=d.get(\\\"tool_response\\\",{});print(i.get(\\\"file_path\\\",\\\"\\\") or r.get(\\\"filePath\\\",\\\"\\\"))\" 2>/dev/null); case \"\$FILE\" in *memory[\\\\/]*) DIR=\$(dirname \"\$FILE\"); MEMFILE=\"\$DIR/MEMORY.md\"; if [ -f \"\$MEMFILE\" ]; then LINES=\$(wc -l < \"\$MEMFILE\" | tr -d \" \"); if [ \"\$LINES\" -gt ${THRESHOLD} ]; then echo \"{\\\"hookSpecificOutput\\\":{\\\"hookEventName\\\":\\\"PostToolUse\\\",\\\"additionalContext\\\":\\\"WARNING: MEMORY.md is \$LINES lines (limit: ${THRESHOLD}). Compact it now: move inline content to topic files, keep MEMORY.md as a slim table index.\\\"}}\"; fi; fi;; esac'"

# Build the new hook entry as JSON
HOOK_ENTRY=$(python -c "
import json
entry = {
    'matcher': 'Write|Edit',
    'hooks': [{
        'type': 'command',
        'command': '''$HOOK_CMD''',
        'statusMessage': 'Checking MEMORY.md size...'
    }]
}
print(json.dumps(entry))
")

# Read existing settings or start fresh
if [ -f "$SETTINGS" ]; then
    CURRENT=$(cat "$SETTINGS")
else
    CURRENT='{}'
fi

# Merge: add hook entry to PostToolUse array (skip if already present)
UPDATED=$(python -c "
import json, sys

settings = json.loads('''$CURRENT''')
new_entry = json.loads('''$HOOK_ENTRY''')

hooks = settings.setdefault('hooks', {})
post = hooks.setdefault('PostToolUse', [])

# Check if a memory-compactor hook already exists
for existing in post:
    if existing.get('matcher') == 'Write|Edit':
        for h in existing.get('hooks', []):
            if 'MEMORY.md' in h.get('command', ''):
                print('ALREADY_INSTALLED')
                sys.exit(0)

post.append(new_entry)
print(json.dumps(settings, indent=2))
")

if [ "$UPDATED" = "ALREADY_INSTALLED" ]; then
    echo "Memory compactor hook is already installed in $SETTINGS"
    exit 0
fi

echo "$UPDATED" > "$SETTINGS"
echo "Installed memory compactor hook (threshold: ${THRESHOLD} lines) in $SETTINGS"
echo "The hook will warn Claude when MEMORY.md exceeds ${THRESHOLD} lines after any Write or Edit to a memory/ directory."
