#!/bin/bash
# Ralph Loop Script - {{DOMAIN}} Domain
# Usage: ./loop.sh [--claude|--opencode] [plan] [max_iterations]
# Examples:
#   ./loop.sh                      # Claude, build mode, unlimited
#   ./loop.sh --opencode           # OpenCode, build mode, unlimited
#   ./loop.sh --claude plan        # Claude, plan mode, unlimited
#   ./loop.sh --opencode plan 5    # OpenCode, plan mode, max 5 iterations
#   ./loop.sh plan 5               # Claude (default), plan mode, max 5

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
DOMAIN_NAME="{{DOMAIN}}"

# Defaults
ENGINE="claude"
MODE="build"
MAX_ITERATIONS=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --claude)
            ENGINE="claude"
            shift
            ;;
        --opencode)
            ENGINE="opencode"
            shift
            ;;
        plan)
            MODE="plan"
            shift
            ;;
        [0-9]*)
            MAX_ITERATIONS=$1
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: ./loop.sh [--claude|--opencode] [plan] [max_iterations]"
            exit 1
            ;;
    esac
done

# Set prompt file based on mode and engine
if [ "$MODE" = "plan" ]; then
    PROMPT_FILE="$SCRIPT_DIR/PROMPT_plan_${ENGINE}.md"
else
    PROMPT_FILE="$SCRIPT_DIR/PROMPT_build_${ENGINE}.md"
fi

# Engine-specific AI command
run_ai() {
    local prompt_file="$1"
    case $ENGINE in
        claude)
            cat "$prompt_file" | claude -p \
                --dangerously-skip-permissions \
                --output-format=stream-json \
                --model opus \
                --verbose
            ;;
        opencode)
            OPENCODE_PERMISSION='{"*":"allow"}' opencode run \
                --format json \
                "$(cat "$prompt_file")"
            ;;
    esac
}

ITERATION=0
CURRENT_BRANCH=$(git -C "$PROJECT_ROOT" branch --show-current)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Ralph Loop - Domain: $DOMAIN_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Engine: $ENGINE"
echo "Mode:   $MODE"
echo "Prompt: $(basename $PROMPT_FILE)"
echo "Branch: $CURRENT_BRANCH"
[ $MAX_ITERATIONS -gt 0 ] && echo "Max:    $MAX_ITERATIONS iterations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Verify prompt file exists
if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: $PROMPT_FILE not found"
    exit 1
fi

while true; do
    if [ $MAX_ITERATIONS -gt 0 ] && [ $ITERATION -ge $MAX_ITERATIONS ]; then
        echo "Reached max iterations: $MAX_ITERATIONS"
        break
    fi

    ITERATION=$((ITERATION + 1))
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                    ║"
    echo "║   ██████╗  █████╗ ██╗     ██████╗ ██╗  ██╗    ██╗      ██████╗  ██████╗ ██████╗  ║"
    echo "║   ██╔══██╗██╔══██╗██║     ██╔══██╗██║  ██║    ██║     ██╔═══██╗██╔═══██╗██╔══██╗ ║"
    echo "║   ██████╔╝███████║██║     ██████╔╝███████║    ██║     ██║   ██║██║   ██║██████╔╝ ║"
    echo "║   ██╔══██╗██╔══██║██║     ██╔═══╝ ██╔══██║    ██║     ██║   ██║██║   ██║██╔═══╝  ║"
    echo "║   ██║  ██║██║  ██║███████╗██║     ██║  ██║    ███████╗╚██████╔╝╚██████╔╝██║      ║"
    echo "║   ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝    ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝      ║"
    echo "║                                                                    ║"
    echo "║   DOMAIN: $DOMAIN_NAME   ITERATION: $ITERATION   MODE: $MODE   ENGINE: $ENGINE     ║"
    echo "║   $(date '+%Y-%m-%d %H:%M:%S')                                                  ║"
    echo "║                                                                    ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo ""

    # Run from project root so paths like src/* and .ralph/* resolve correctly
    cd "$PROJECT_ROOT"
    run_ai "$PROMPT_FILE"

    # Push changes after each iteration
    git push origin "$CURRENT_BRANCH" || {
        echo "Failed to push. Creating remote branch..."
        git push -u origin "$CURRENT_BRANCH"
    }

    echo -e "\n======================== END LOOP $ITERATION ========================\n"
done

echo "Ralph loop complete. Total iterations: $ITERATION"
