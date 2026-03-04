

## What It Is

The dbt Semantic Layer lets you define metrics and dimensions once in YAML, then query them consistently across tools (Tableau, Hex, Metabase, notebooks, etc.) via the MetricFlow API — no duplicated SQL logic.

---

## CLI Commands

Most semantic layer work happens through **MetricFlow**, which ships with dbt Core 1.6+.

```bash
mf --help                          # See all MetricFlow commands
mf validate-configs                # Validate your semantic model YAML files
mf list metrics                    # List all defined metrics
mf list dimensions --metrics <metric_name>   # List available dimensions for a metric
mf list entities                   # List all entities (join keys)
```

---

## Querying Metrics

```bash
# Basic metric query
mf query --metrics <metric_name>

# With dimensions (group by)
mf query --metrics revenue --group-by metric_time__month

# Multiple metrics + dimensions
mf query --metrics revenue,orders --group-by metric_time__week,customer__region

# Filter
mf query --metrics revenue --group-by metric_time__month --where "customer__region = 'US'"

# Preview (limit rows)
mf query --metrics revenue --group-by metric_time__month --limit 10

# Save results to CSV
mf query --metrics revenue --group-by metric_time__month --csv output.csv
```

> `metric_time` is a reserved dimension — it maps to your measure's time spine and is how you handle date aggregation.

---

## Validating & Previewing

```bash
mf validate-configs               # Catch YAML errors before deploying
mf health-checks                  # Check your data platform connection
mf query ... --explain            # Print the compiled SQL without running it (very useful for debugging)
```

---

## Key YAML Concepts (not commands, but good to have handy)

|Concept|What it is|
|---|---|
|`semantic_model`|Defines the base table, entities, dimensions, and measures|
|`metric`|A named, reusable calculation built from measures|
|`measure`|An aggregation (sum, count, avg) defined on a semantic model|
|`entity`|A join key — how semantic models relate to each other|
|`dimension`|A column you can group/filter by (categorical or time)|

---

## Typical File Structure

```
models/
  semantic_models/
    orders.yml          # semantic_model definition
  metrics/
    revenue.yml         # metric definitions
```

Or you can co-locate semantic models with your model SQL files — either works.

---

## Minimal Example

```yaml
# semantic_models/orders.yml
semantic_models:
  - name: orders
    model: ref('fct_orders')
    entities:
      - name: order_id
        type: primary
    dimensions:
      - name: order_date
        type: time
        type_params:
          time_granularity: day
      - name: region
        type: categorical
    measures:
      - name: revenue
        agg: sum
        expr: amount

# metrics/revenue.yml
metrics:
  - name: revenue
    type: simple
    label: Revenue
    type_params:
      measure: revenue
```

Then query it:

```bash
mf query --metrics revenue --group-by metric_time__month,region
```