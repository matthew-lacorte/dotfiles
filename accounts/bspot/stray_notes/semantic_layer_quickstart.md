# dbt Semantic Layer — Quickstart (packman)

## Prerequisites

- Docker image `gpn-dbt-warehouse` built locally
- `.env` file with Redshift credentials (`DBT_HOST`, `DBT_USER`, `DBT_PASSWORD`, `DBT_DATABASE`, `DBT_TARGET_SCHEMA`, `DBT_TARGET`)
- AWS credentials at `~/.aws/credentials`

## Step 1: Start the Docker container

Run from the `gpn-dbt-warehouse` root:

```bash
docker run -it \
  --entrypoint /bin/bash \
  --env-file /Users/mlacorte/dev/dotfiles/local/.env \
  -v ${PWD}:${PWD} \
  -v ~/.aws/credentials:/root/.aws/credentials \
  -w ${PWD} \
  gpn-dbt-warehouse
```

## Step 2: Install MetricFlow

The Docker image has dbt-core but not MetricFlow. Install it inside the container each session (doesn't persist between runs):

```bash
pip install dbt-metricflow[redshift]
```

> **Note:** This downgrades dbt-core from 1.11.2 to 1.10.19 due to a dependency constraint. This is fine for testing — production runs use the original image without metricflow.

## Step 3: Navigate to packman and install dependencies

```bash
cd sources/packman
dbt deps    # installs shared macros + packages
dbt parse   # builds manifest.json — lighter than dbt compile, no SQL generation
# Or just
cd sources/packman && dbt deps && dbt parse
```

If `dbt parse` fails with a connection error, check your `.env` vars. If it fails with a YAML error, there's a config issue to fix before proceeding.

## Step 3.5: Build tables in dev (first time only)

`mf validate-configs` and `mf query` both run SQL against the warehouse, so the underlying tables need to exist first. If this is a fresh dev environment:

```bash
dbt build    # materializes all models + runs tests — takes a while the first time
```

You can skip this if you point at an existing environment (`export DBT_TARGET=sandbox`) or if you only want to validate YAML structure (`mf validate-configs --skip-dw`).

## Step 4: Validate the semantic layer config

```bash
mf validate-configs            # full validation (requires tables to exist in warehouse)
mf validate-configs --skip-dw  # YAML-only — skips warehouse column checks
```

All three semantic models should validate cleanly after the phantom column fixes (see changelog below). If full validation hangs on "Validating dimensions against data warehouse...", the tables likely don't exist in your target schema yet — see step 3.5.

## Step 5: Explore what's available

```bash
mf list metrics                                              # all defined metrics
mf list dimensions --metrics packman_reserves_total_count    # groupable dimensions
mf list entities                                             # join keys across models
```

## Step 6: Query metrics

### Basics — single metric, one group-by

```bash
# Total reserves by month
mf query --metrics packman_reserves_total_count \
         --group-by metric_time__month \
         --order -metric_time__month

# Total target reserve value by reserve state
mf query --metrics packman_reserves_total_target_value \
         --group-by reserve__aasm_state

# Average reserve value by recommender type
mf query --metrics packman_reserves_avg_target_value \
         --group-by reserve__recommender_type
```

### Time granularity — day, week, month, quarter, year

```bash
# Daily reserves (most granular)
mf query --metrics packman_reserves_total_count \
         --group-by metric_time__day

# Quarterly reserves
mf query --metrics packman_reserves_total_count \
         --group-by metric_time__quarter
         --order metric_time__quarter
```

%% There is no ASC or DESC  %%

### Multiple group-bys

```bash
# Reserves by month AND state
mf query --metrics packman_reserves_total_count \
         --group-by metric_time__month,reserve__aasm_state

# Reserves by type and recommender
mf query --metrics packman_reserves_total_count \
         --group-by reserve__type,reserve__recommender_type
```

### Filtering with --where

```bash
# Reserves created in 2025 only
mf query --metrics packman_reserves_total_count \
         --group-by metric_time__month \
         --where "{{ TimeDimension('metric_time', 'day') }} >= '2025-01-01'"

# Only active reserves
mf query --metrics packman_reserves_total_count \
         --group-by metric_time__month \
         --where "{{ Dimension('reserve__aasm_state') }} = 'active'"
```

### Sorting and limiting

```bash
# Top 10 months by reserve count
mf query --metrics packman_reserves_total_count \
         --group-by metric_time__month \
         --order -packman_reserves_total_count \
         --limit 10

# Most recent 5 months
mf query --metrics packman_reserves_total_count \
         --group-by metric_time__month \
         --order -metric_time__month \
         --limit 5
```

### Multiple metrics at once

```bash
# Count + value side by side
mf query --metrics packman_reserves_total_count,packman_reserves_total_target_value \
         --group-by metric_time__month \
         --order -metric_time__month \
         --limit 12

# All five metrics by state
mf query --metrics packman_reserves_total_count,packman_reserves_total_target_value,packman_reserves_avg_target_value,packman_reserves_unique_players,packman_reserves_active_count \
         --group-by reserve__aasm_state
```

### Inspect generated SQL (doesn't execute)

```bash
mf query --metrics packman_reserves_total_count \
         --group-by metric_time__month \
         --explain
```

> **Note:** `orders_semantic` and `wagers_semantic` are commented out — those tables are too large for a first dev build. Uncomment in `orders.yml` / `wagers.yml` after running `dbt run -s orders wagers`. Once enabled, you'll also have access to order metrics like `packman_orders_completion_rate`.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `dbt parse` connection error | Env vars missing or Redshift unreachable | Check `.env` has all required vars |
| `mf validate-configs` hangs on "Validating dimensions..." | Tables not materialized in target schema | Run `dbt build` first, use `--skip-dw`, or switch to a populated target |
| `mf validate-configs` column errors | Phantom columns in YAML not matching SQL model | Remove dimension or add `expr:` mapping to correct column |
| `mf query` returns no data | Cached tables empty in dev | Check `DBT_TARGET` — dev tables may not be populated |
| `mf query` schema not found | Dev schema hasn't been created yet | Need at least one `dbt run`, or point at prod/sandbox |

---

## Changelog

### 2026-02-27 — Parse warning fixes
- **metricflow_time_spine.yml**: Updated time spine config from deprecated `config.time_spine` format to top-level `time_spine` model property (dbt >= 1.10)
- **orders.yml / wagers.yml**: Moved `accepted_values` test `values` under `arguments` key (dbt >= 1.10 test syntax)
- **dbt_project.yml**: Removed unused `disabled: +enabled: false` config block (no `models/disabled/` directory exists)

### 2026-02-27 — Phantom column fixes
- **wagers.yml**: Removed 6 phantom dimensions that don't exist in `wagers.sql`:
  - `submitted_at_pst`, `results_finalized_at_pst` — timestamps not in SQL SELECT
  - `buyer_merchant_name`, `beneficiary_player_state`, `beneficiary_player_country_code`, `wager_placed_state` — no corresponding columns
- **wagers.yml**: Remapped 3 dimensions to correct column names via `expr`:
  - `pool_type` → `pool_type_id`
  - `buyer_player_state` → `player_residence_state`
  - `buyer_player_country_code` → `player_residence_country_code`
- **wagers.yml**: Fixed trailing whitespace in `packman_wagers_winning_wagers` measure expr
- **order_reserves.yml**: Removed 2 phantom dimensions: `entered_state_at_pst`, `merchant_reference_type`

### 2026-02-27 — Dev-friendly slim-down
- **orders.yml**: Commented out `orders_semantic` + all metrics — orders table too large to build in dev
- **wagers.yml**: Commented out `wagers_semantic` — wagers table too large to build in dev
- **order_reserves.yml**: Added 5 metrics (`packman_reserves_total_count`, `packman_reserves_total_target_value`, `packman_reserves_avg_target_value`, `packman_reserves_unique_players`, `packman_reserves_active_count`) so `order_reserves_semantic` is fully queryable end-to-end
- Updated quickstart steps 5-7 to use `order_reserves` examples

### Known issues (not yet fixed)
- **orders.yml** — Measure/metric name collision: `packman_orders_unique_players` used for both (visible when uncommented)

