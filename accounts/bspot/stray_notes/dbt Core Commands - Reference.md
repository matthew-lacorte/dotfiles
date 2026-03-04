## Setup & Connection

```bash
dbt init <project_name>       # Scaffold a new dbt project
dbt debug                     # Test your connection and config
dbt deps                      # Install packages from packages.yml
```

---

## Running Models

```bash
dbt run                        # Run all models
dbt run --select <model>       # Run a specific model
dbt run --select +<model>      # Run model + all its upstream deps
dbt run --select <model>+      # Run model + all downstream dependents
dbt run --select tag:finance   # Run models with a specific tag
dbt run --exclude <model>      # Run everything except this model
dbt run --full-refresh         # Rebuild incremental models from scratch
```

---

## Testing

```bash
dbt test                        # Run all tests
dbt test --select <model>       # Test a specific model
dbt build                       # Run + test all models in dependency order
dbt build --select <model>+     # Build a model and everything downstream
```

> `dbt build` is usually preferred over running `dbt run` + `dbt test` separately — it runs, tests, seeds, and snapshots together.

---

## Compiling & Inspecting

```bash
dbt compile                    # Compile SQL without executing (check target/ folder)
dbt show --select <model>      # Preview model output (first 5 rows)
dbt ls                         # List all resources in your project
dbt ls --select tag:marketing  # Filter the list
```

---

## Seeds & Snapshots

```bash
dbt seed                       # Load CSV files from seeds/ into your warehouse
dbt snapshot                   # Run snapshot models (SCD Type 2 tracking)
```

---

## Documentation

```bash
dbt docs generate              # Build the docs site
dbt docs serve                 # Open docs locally in browser
```

---

## Source Freshness

```bash
dbt source freshness           # Check if source tables are up to date
```

---

## Helpful Flags (work with most commands)

|Flag|What it does|
|---|---|
|`--select` / `-s`|Target specific models, tags, paths, or selectors|
|`--exclude`|Exclude specific models|
|`--full-refresh`|Force full rebuild of incremental models|
|`--vars '{"key": "val"}'`|Pass variables into your project at runtime|
|`--target <env>`|Use a specific target from profiles.yml (e.g. `dev`, `prod`)|
|`--threads <n>`|Override parallelism|
|`--no-partial-parse`|Clear the parse cache (useful when things get weird)|

---

## Node Selection Syntax Cheatsheet

```
dbt run --select my_model              # Exact model
dbt run --select models/finance/       # All models in a folder
dbt run --select +my_model+            # Model + all ancestors + all descendants
dbt run --select state:modified+       # Only models changed since last run (CI use case)
dbt run --select tag:daily             # Models tagged "daily"
```