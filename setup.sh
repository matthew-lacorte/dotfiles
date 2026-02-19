#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
VENVS_DIR="$HOME/.venvs"

echo "=== dotfiles setup ==="

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
# 4. Create/update per-project venvs
# -----------------------------------------------------------
mkdir -p ~/dev/dotfiles/local

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

setup_venv "gpn-dbt-warehouse" "$DOTFILES_DIR/python/requirements-warehouse.txt"
setup_venv "gpn-marts-base"    "$DOTFILES_DIR/python/requirements-marts.txt"

# -----------------------------------------------------------
# 5. Summary
# -----------------------------------------------------------
echo ""
echo "=== Setup complete ==="
echo ""
echo "Virtual environments:"
echo "  gpn-dbt-warehouse: $VENVS_DIR/gpn-dbt-warehouse"
echo "  gpn-marts-base:    $VENVS_DIR/gpn-marts-base"
echo ""
echo "Shell aliases (restart your shell or 'source ~/.zshrc'):"
echo "  dbt-wh     - activate warehouse venv + cd to project"
echo "  dbt-marts  - activate marts venv + cd to project"
echo ""
echo "Don't forget to set your Redshift env vars:"
echo "  DBT_HOST, DBT_USER, DBT_PASSWORD, DBT_DATABASE, DBT_TARGET"
