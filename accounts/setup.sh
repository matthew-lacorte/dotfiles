#!/usr/bin/env bash
# bspot account setup: dbt virtual environments

ACCOUNT_DIR="$(cd "$(dirname "$0")" && pwd)"

setup_venv "gpn-dbt-warehouse" "$ACCOUNT_DIR/python/requirements-warehouse.txt"
setup_venv "gpn-marts-base"    "$ACCOUNT_DIR/python/requirements-marts.txt"

echo ""
echo "bspot virtual environments:"
echo "  gpn-dbt-warehouse: $VENVS_DIR/gpn-dbt-warehouse"
echo "  gpn-marts-base:    $VENVS_DIR/gpn-marts-base"
echo ""
echo "Shell aliases (restart your shell or 'source ~/.zshrc'):"
echo "  dbt-wh     - activate warehouse venv + cd to project"
echo "  dbt-marts  - activate marts venv + cd to project"
echo ""
echo "Don't forget to set your Redshift env vars in local/zshrc:"
echo "  DBT_HOST, DBT_USER, DBT_PASSWORD, DBT_DATABASE, DBT_TARGET"
