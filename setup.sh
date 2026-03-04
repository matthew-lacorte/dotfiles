#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
VENVS_DIR="$HOME/.venvs"
PROFILE="${1:-${DOTFILES_PROFILE:-}}"

echo "=== dotfiles setup ==="
if [ -n "$PROFILE" ]; then
    echo "    profile: $PROFILE"
fi

# -----------------------------------------------------------
# 1. Homebrew dependencies
# -----------------------------------------------------------
echo "--- Checking Homebrew dependencies ---"
if command -v brew &>/dev/null; then
    brew bundle --file="$DOTFILES_DIR/Brewfile"
else
    echo "ERROR: Homebrew not found. Install it first: https://brew.sh"
    exit 1
fi

# -----------------------------------------------------------
# 2. Install Python 3.12 via uv
# -----------------------------------------------------------
echo "--- Ensuring Python 3.12 ---"
uv python install 3.12

# -----------------------------------------------------------
# 3. Symlink zshrc
# -----------------------------------------------------------
echo "--- Linking zshrc ---"
if [ ! -L "$HOME/.zshrc" ] || [ "$(readlink "$HOME/.zshrc")" != "$DOTFILES_DIR/zshrc" ]; then
    ln -sf "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
    echo "  Linked ~/.zshrc -> $DOTFILES_DIR/zshrc"
else
    echo "  ~/.zshrc already linked"
fi

# -----------------------------------------------------------
# 4. Local overrides directory
# -----------------------------------------------------------
mkdir -p "$DOTFILES_DIR/local"

# -----------------------------------------------------------
# 5. Shared setup_venv helper (used by account setup scripts)
# -----------------------------------------------------------
mkdir -p "$VENVS_DIR"

setup_venv() {
    local name="$1"
    local requirements="$2"
    local venv_path="$VENVS_DIR/$name"

    echo "--- Setting up venv: $name ---"

    if [ ! -d "$venv_path" ]; then
        uv venv --python 3.12 "$venv_path"
        echo "  Created venv at $venv_path"
    else
        echo "  Venv already exists at $venv_path"
    fi

    echo "  Installing dependencies from $(basename "$requirements") ..."
    uv pip install --python "$venv_path/bin/python" --prerelease=allow -r "$requirements"
    echo "  Done."
}
export -f setup_venv
export VENVS_DIR

# -----------------------------------------------------------
# 6. Account-specific setup
# -----------------------------------------------------------
if [ -n "$PROFILE" ]; then
    ACCOUNT_SETUP="$DOTFILES_DIR/accounts/$PROFILE/setup.sh"
    if [ -f "$ACCOUNT_SETUP" ]; then
        echo ""
        echo "--- Running $PROFILE account setup ---"
        source "$ACCOUNT_SETUP"
    else
        echo ""
        echo "WARNING: No setup script found at $ACCOUNT_SETUP"
    fi
else
    echo ""
    echo "No profile specified. Run with a profile to set up account-specific tools:"
    echo "  ./setup.sh <profile>        (e.g. ./setup.sh bspot)"
    echo ""
    echo "Available profiles:"
    for d in "$DOTFILES_DIR"/accounts/*/; do
        [ -d "$d" ] && echo "  $(basename "$d")"
    done
fi

# -----------------------------------------------------------
# 7. Summary
# -----------------------------------------------------------
echo ""
echo "=== Setup complete ==="
