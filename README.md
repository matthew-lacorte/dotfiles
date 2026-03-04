# dotfiles

Personal dotfiles for shell config, editor setup, and environment management across multiple accounts.

## Quick Start

```bash
git clone https://github.com/matthew-lacorte/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles

# Set your profile in local/zshrc (created automatically)
mkdir -p local
echo 'export DOTFILES_PROFILE="bspot"' >> local/zshrc

# Run setup (shared + account-specific)
./setup.sh bspot
source ~/.zshrc
```

`setup.sh` is idempotent — safe to re-run anytime.

## Structure

```
dotfiles/
├── zshrc                        # Shared: Oh My Zsh, Powerlevel10k, profile loader
├── setup.sh                     # Shared: brew, Python 3.12, symlinks + delegates to profile
├── Brewfile                     # Shared Homebrew dependencies
├── gitignore_global             # Global git ignore rules
├── scripts/                     # Shared utility scripts (added to PATH)
├── accounts/
│   └── bspot/                   # Account-specific config
│       ├── zshrc                # bspot aliases (dbt-wh, dbt-marts, etc.)
│       ├── setup.sh             # bspot venv creation
│       ├── python/              # Python requirements per project
│       ├── scripts/             # bspot-specific scripts (added to PATH)
│       ├── stray_notes/         # Documentation / notes
│       └── vscode/workspaces/   # VSCode workspace files
├── vscode/                      # Shared VSCode config (if any)
└── local/                       # (gitignored) Machine-specific: secrets, DOTFILES_PROFILE
```

## Profiles

Each machine sets `DOTFILES_PROFILE` in `local/zshrc`. The profile controls which account's zshrc, setup script, and scripts directory are loaded.

```bash
# local/zshrc (never committed)
export DOTFILES_PROFILE="bspot"
export DBT_HOST="your-cluster.amazonaws.com"
# ... other secrets
```

Running setup without a profile runs only shared setup (brew, Python, symlinks):

```bash
./setup.sh              # shared only
./setup.sh bspot        # shared + bspot account
```

## Shell Aliases

**Shared** (always available):

| Alias | What it does |
|-------|-------------|
| `dev` | `cd ~/dev` |

**bspot profile**:

| Alias | What it does |
|-------|-------------|
| `dbt-wh` | Activate warehouse venv + `cd` to project |
| `dbt-marts` | Activate marts venv + `cd` to project |
| `dbt-source <name> <cmd>` | Run dbt in a warehouse source sub-project |
| `gef` | `cd ~/dev/gef && code .` |

## Scripts

Utility scripts live in two places, both added to `PATH`:

- `scripts/` — shared across all profiles
- `accounts/<profile>/scripts/` — account-specific

## Python Environments (bspot)

Virtual environments live at `~/.venvs/`. Managed by [uv](https://docs.astral.sh/uv/).

| Venv | Python | dbt-core | Key extras |
|------|--------|----------|------------|
| `gpn-dbt-warehouse` | 3.12 | 1.10.19 | dbt-metricflow 0.11.0 (semantic layer) |
| `gpn-marts-base` | 3.12 | 1.11.6 | sqlfluff |

To rebuild a venv from scratch:
```bash
rm -rf ~/.venvs/gpn-dbt-warehouse
./setup.sh bspot
```

## VSCode (bspot)

Open the workspace: **File > Open Workspace from File > `~/dev/dotfiles/accounts/bspot/vscode/workspaces/data.code-workspace`**

## Local Overrides

The `local/` directory is gitignored. It holds `DOTFILES_PROFILE`, secrets, and any machine-specific config:

```bash
# local/zshrc (example — never committed)
export DOTFILES_PROFILE="bspot"
export DBT_HOST="your-redshift-cluster.amazonaws.com"
export DBT_USER="mlacorte"
export DBT_PASSWORD="..."
export DBT_DATABASE="analytics"
export DBT_TARGET="dev"
```

## GEF Coexistence

This repo shares a machine with the GEF research environment (`~/dev/gef/ops/`). They're mostly isolated but a few things to be aware of:

- **Python runtimes differ.** Dotfiles uses Python 3.12 via `uv`; GEF ops uses Python 3.11 via `conda`. The venvs live in separate locations (`~/.venvs/` vs `ops/envs/gef/`) so they don't collide.
- **Don't mix conda and uv venvs in one shell.** Deactivate conda before using `dbt-wh` or `dbt-marts`.
- **Env var bleed.** GEF's `activate.sh` exports research-specific vars. No overlap with dbt vars today.
- **Git hooks are repo-scoped.** GEF sets `core.hooksPath` inside its own repo — won't affect dotfiles.
