# Workspaces

VS Code multi-root workspace files (`.code-workspace`), organized by project.

## Structure

```
workspaces/
  bspot/        # work projects (data platform, dbt, etc.)
  gef/          # GEF-related projects
  personal/     # personal projects
```

Each subdirectory holds `.code-workspace` files for that project group.

## Opening a workspace

From the terminal (requires `code` CLI on PATH):

```zsh
code ~/dev/dotfiles/accounts/bspot/workspaces/bspot/data.code-workspace
```

Or add a helper to your zshrc:

```zsh
ws() {
  local file=$(find ~/dev/dotfiles/accounts -name "${1}.code-workspace" 2>/dev/null | head -1)
  [[ -n "$file" ]] && code "$file" || echo "No workspace: $1"
}
```

Then: `ws data`, `ws gef`, etc.

## How paths work

Workspace `path` values are relative to the `.code-workspace` file's location. From
`workspaces/bspot/data.code-workspace`, the path `../../../../../data_platform` resolves
up to `~/dev/data_platform`. If you move the workspace file, update the relative paths.

## Workspaces vs profiles

These are separate VS Code concepts:

- **Workspace** = which folders open together + workspace-scoped settings. Stored here as `.code-workspace` files.
- **Profile** = extensions, UI settings, keybindings, snippets. Exportable as `.code-profile` files but not referenceable from workspace files.

You can associate a profile with a workspace via `Profiles > Associate Profile with Workspace` in VS Code, but that binding lives in VS Code's internal state, not in the workspace file.

## Conventions

- One `.code-workspace` per logical project grouping
- Workspace-level settings (formatter paths, venvs) go in the workspace file
- Project-specific settings shared with collaborators go in each repo's `.vscode/` directory
- No secrets or absolute paths (use `${userHome}` in settings values where supported; folder `path` fields don't support variables, so use relative paths)
