#!/bin/bash

# Script to list all open folders in VS Code
# This uses the VS Code CLI and jq to parse the workspace state

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Please install it with 'brew install jq'"
    exit 1
fi

# Path to VS Code storage
STORAGE_PATH="$HOME/Library/Application Support/Code/User/workspaceStorage"

# Check if the storage path exists
if [ ! -d "$STORAGE_PATH" ]; then
    echo "VS Code workspace storage not found at $STORAGE_PATH"
    exit 1
fi

echo "Open folders in VS Code:"
echo "------------------------"

# Loop through each workspace folder
for workspace in "$STORAGE_PATH"/*; do
    if [ -d "$workspace" ]; then
        # Check if workspace.json exists
        if [ -f "$workspace/workspace.json" ]; then
            # Extract folder paths from workspace.json
            folder_path=$(cat "$workspace/workspace.json" | jq -r '.folder' 2>/dev/null)
            
            # If folder path exists and is not null
            if [ ! -z "$folder_path" ] && [ "$folder_path" != "null" ]; then
                # Remove the file:// prefix and decode URL encoding
                folder_path=$(echo "$folder_path" | sed 's|file://||')
                echo "$folder_path"
            fi
        fi
    fi
done

echo "------------------------"
echo "Note: This lists all workspaces that have been opened, not just currently open ones."
echo "To see only currently open workspaces, check the VS Code window directly."