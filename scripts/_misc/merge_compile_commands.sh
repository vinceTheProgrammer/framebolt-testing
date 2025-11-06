#!/usr/bin/env bash
set -e

# Find all compile_commands.json files recursively
FILES=$(find . -type f -name "compile_commands.json")

# Check if we found any
if [ -z "$FILES" ]; then
    echo "No compile_commands.json files found."
    exit 1
fi

# Merge them using jq
jq -s 'add' $FILES > compile_commands_merged.json

echo "✅ Merged $(echo "$FILES" | wc -l) compile_commands.json files into compile_commands_merged.json"
