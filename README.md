# dotfiles

Personal dotfiles for shell config, editor setup, and Python/dbt environment management.

## Quick Start

```bash
git clone https://github.com/matthew-lacorte/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles
./setup.sh
source ~/.zshrc
```

`setup.sh` is idempotent — safe to re-run anytime (e.g. after editing requirements).

## What's Here

```
dotfiles/
├── zshrc                    # Oh My Zsh + Powerlevel10k + project aliases
├── Brewfile                 # Homebrew dependencies (uv)
├── setup.sh                 # Idempotent setup: brew, Python 3.12, venvs, symlinks
├── python/
│   ├── requirements-warehouse.txt   # dbt-core 1.10.19, dbt-redshift, dbt-metricflow
│   └── requirements-marts.txt       # dbt-core 1.11.6, dbt-redshift, sqlfluff
├── vscode/
│   └── workspaces/
│       └── data.code-workspace      # Multi-root workspace with editor + extension settings
└── local/                   # (gitignored) Machine-specific overrides
```

## Shell Aliases

| Alias | What it does |
|-------|-------------|
| `dbt-wh` | Activate warehouse venv + `cd` to project |
| `dbt-marts` | Activate marts venv + `cd` to project |
| `dbt-source <name> <cmd>` | Run a dbt command in a warehouse source sub-project (e.g. `dbt-source auth run`) |
| `dev` | `cd ~/dev` |

## Python Environments

Virtual environments live at `~/.venvs/` (outside all repos). Managed by [uv](https://docs.astral.sh/uv/).

| Venv | Python | dbt-core | Key extras |
|------|--------|----------|------------|
| `gpn-dbt-warehouse` | 3.12 | 1.10.19 | dbt-metricflow 0.11.0 (semantic layer) |
| `gpn-marts-base` | 3.12 | 1.11.6 | sqlfluff 4.0.4 |

To rebuild a venv from scratch:
```bash
rm -rf ~/.venvs/gpn-dbt-warehouse
./setup.sh
```

## VSCode

Open the workspace: **File > Open Workspace from File > `~/dev/dotfiles/vscode/workspaces/data.code-workspace`**

The workspace configures Python interpreters, jinja-sql file associations, sqlfluff linting, and recommends extensions (dbt Power User, Python, sqlfluff, YAML, Jinja).

For per-folder interpreter selection: click the Python version in the bottom status bar and pick the right venv for whichever folder you're working in.

## Local Overrides

The `local/` directory is gitignored. Use it for anything private:

```bash
mkdir -p ~/dev/dotfiles/local
```

Put a `local/zshrc` file there for private aliases, env vars, or work credentials — it gets sourced automatically at the end of your shell init:

```bash
# local/zshrc (example — never committed)
export DBT_HOST="your-redshift-cluster.amazonaws.com"
export DBT_USER="mlacorte"
export DBT_PASSWORD="..."
export DBT_DATABASE="analytics"
export DBT_TARGET="dev"
```
