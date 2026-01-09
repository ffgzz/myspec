#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Script: create-new-feature.sh
# Description: Automates the setup of a new feature for TDD workflow.
#              1. Calculates next feature number.
#              2. Creates specs directory.
#              3. Creates AND CHECKOUTS new git branch.
# -----------------------------------------------------------------------------

set -e

JSON_MODE=false
SHORT_NAME=""
BRANCH_NUMBER=""
ARGS=()

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) JSON_MODE=true; shift ;;
        --short-name) SHORT_NAME="$2"; shift 2 ;;
        --number) BRANCH_NUMBER="$2"; shift 2 ;;
        *) ARGS+=("$1"); shift ;;
    esac
done

FEATURE_DESCRIPTION="${ARGS[*]}"

# --- Helper Functions (Borrowed from speckit) ---
clean_branch_name() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//' | sed 's/-$//'
}

find_repo_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.git" ] || [ -d "$dir/.specify" ]; then echo "$dir"; return 0; fi
        dir="$(dirname "$dir")"
    done
    return 1
}

# --- Main Logic ---

# 1. Setup Paths
REPO_ROOT="$(find_repo_root)"
if [ -z "$REPO_ROOT" ]; then
    echo "Error: Not in a specify/git repository." >&2
    exit 1
fi
cd "$REPO_ROOT"
SPECS_DIR="$REPO_ROOT/specs"
mkdir -p "$SPECS_DIR"

# 2. Determine Branch Name & Number
if [ -n "$SHORT_NAME" ]; then
    BRANCH_SUFFIX=$(clean_branch_name "$SHORT_NAME")
else
    # Simple fallback: first 3 words joined by hyphens
    BRANCH_SUFFIX=$(echo "$FEATURE_DESCRIPTION" | awk '{print tolower($1"-"$2"-"$3)}' | sed 's/[^a-z0-9-]//g')
fi

if [ -z "$BRANCH_NUMBER" ]; then
    # Auto-increment logic (Simplified for robustness)
    HIGHEST_NUM=$(find "$SPECS_DIR" -maxdepth 1 -type d -name "[0-9][0-9][0-9]-*" | grep -oE '[0-9]{3}' | sort -rn | head -1)
    if [ -z "$HIGHEST_NUM" ]; then HIGHEST_NUM=0; fi
    # Remove leading zeros, increment, format back to 000
    NEXT_NUM=$((${HIGHEST_NUM#0} + 1))
    FEATURE_NUM=$(printf "%03d" "$NEXT_NUM")
else
    FEATURE_NUM=$(printf "%03d" "$BRANCH_NUMBER")
fi

BRANCH_NAME="${FEATURE_NUM}-${BRANCH_SUFFIX}"
FEATURE_DIR="$SPECS_DIR/$BRANCH_NAME"

# 3. Create Artifacts
mkdir -p "$FEATURE_DIR"
SPEC_FILE="$FEATURE_DIR/spec.md"
TEMPLATE="$REPO_ROOT/templates/spec-template.md"

if [ -f "$TEMPLATE" ]; then
    cp "$TEMPLATE" "$SPEC_FILE"
    # Optional: Pre-fill feature name in template if needed
else
    touch "$SPEC_FILE"
fi

# 4. Git Operations (Checkout Added)
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    # Check if branch exists
    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
        echo "Branch $BRANCH_NAME already exists. Checking out..." >&2
        git checkout "$BRANCH_NAME"
    else
        echo "Creating and checking out branch $BRANCH_NAME..." >&2
        git checkout -b "$BRANCH_NAME"
    fi
else
    echo "Warning: Not a git repository. Skipping branch creation." >&2
fi

# 5. Output
if $JSON_MODE; then
    # JSON Output for the Agent to consume
    printf '{"branch_name":"%s", "spec_file":"%s", "feature_num":"%s", "feature_dir":"%s"}\n' \
        "$BRANCH_NAME" "$SPEC_FILE" "$FEATURE_NUM" "$FEATURE_DIR"
else
    echo "✅ Feature Initialized:"
    echo "   Branch: $BRANCH_NAME"
    echo "   Spec:   $SPEC_FILE"
fi