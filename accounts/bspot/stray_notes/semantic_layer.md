# Setting up the semantic layer
Step 1: Start the Docker container
From the gpn-dbt-warehouse root:


docker run -it \
  --entrypoint /bin/bash \
  --env-file /Users/mlacorte/dev/dotfiles/local/.env \
  -v ${PWD}:${PWD} \
  -v ~/.aws/credentials:/root/.aws/credentials \
  -w ${PWD} \
  gpn-dbt-warehouse

### Step 2: Install MetricFlow
The Docker image has dbt but not MetricFlow:


pip install dbt-metricflow[redshift]
### Step 3: Navigate to packman

cd sources/packman
### Step 4: Install dbt packages & parse the project

dbt deps      # pulls in the shared macros package
dbt parse     # builds the manifest.json that MetricFlow reads
dbt parse is lighter than dbt compile — it resolves all the refs and sources without generating SQL. If this fails with a connection error, the env vars aren't set correctly. If it fails with a YAML error, there's a config issue to fix first.

### Step 5: Validate the semantic layer config

mf validate-configs
This is where you'll likely see errors from the phantom columns I flagged earlier (e.g., submitted_at_pst in wagers, entered_state_at_pst in order_reserves). Those are real — the YAML references columns that don't exist in the SQL models.

If you want a clean validation, you have two options:

Fix them first (I can do this for you)
Focus on orders only — orders_semantic is clean and should validate fine. The other two will error but won't block you from querying orders metrics.
Step 6: See what's available

mf list metrics                    # all defined metrics
mf list dimensions --metrics packman_orders_total_placed   # what you can group by
mf list entities                   # join keys across semantic models
This is where it starts to feel real — you can see exactly what the semantic layer exposes.

### Step 7: Query a metric
Start simple:


#### Total orders placed, by month
mf query --metrics packman_orders_total_placed \
         --group-by metric_time__month

#### Total order value by player state, last 30 days
mf query --metrics packman_orders_total_value \
         --group-by player_residence_state \
         --where "{{ TimeDimension('metric_time', 'day') }} >= '2025-01-01'"

#### Completion rate by month (derived metric — this is the interesting one)
mf query --metrics packman_orders_completion_rate \
         --group-by metric_time__month
That last one is the payoff — it computes completed / total automatically from the derived metric definition. No SQL written.

### Step 8: See the generated SQL
Add --explain to any query to see what MetricFlow generates without running it:


mf query --metrics packman_orders_completion_rate \
         --group-by metric_time__month \
         --explain