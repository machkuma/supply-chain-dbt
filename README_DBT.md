# dbt Integration Guide

## Overview

This project uses **dbt (data build tool)** to transform data from Bronze → Silver → Gold layers in Snowflake. dbt provides version control, testing, documentation, and modularity for our SQL transformations.

## Architecture with dbt

```
┌─────────────────────────────────────────────────────────────┐
│                     Data Flow                                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  S3 → Snowflake Bronze (via COPY INTO)                     │
│         ↓                                                    │
│  dbt Sources (tests Bronze data quality)                    │
│         ↓                                                    │
│  dbt Snapshots (SCD Type 2 for dimensions)                  │
│         ↓                                                    │
│  dbt Models - Silver (incremental facts)                    │
│         ↓                                                    │
│  dbt Tests (data quality validation)                        │
│         ↓                                                    │
│  dbt Models - Gold (aggregations)                           │
│         ↓                                                    │
│  Analytics-Ready Tables                                     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Setup

### 1. Install dbt

```bash
# Install dbt-snowflake
pip install dbt-snowflake==1.7.0

# Verify installation
dbt --version
```

### 2. Configure Profile

Copy `dbt_project/profiles.yml` to `~/.dbt/profiles.yml` or set environment variables:

```bash
export SNOWFLAKE_ACCOUNT=your_account
export SNOWFLAKE_USER=your_user
export SNOWFLAKE_PASSWORD=your_password
export SNOWFLAKE_ROLE=ACCOUNTADMIN
```

### 3. Initialize dbt Project

```bash
cd dbt_project

# Install dependencies
dbt deps

# Test connection
dbt debug
```

## Project Structure

```
dbt_project/
├── dbt_project.yml        # Project configuration
├── profiles.yml           # Connection profile
├── packages.yml           # dbt package dependencies
│
├── models/
│   ├── bronze/
│   │   └── sources.yml    # Source definitions and tests
│   │
│   ├── silver/
│   │   ├── facts/
│   │   │   └── fact_orders.sql
│   │   ├── dimensions/    # (TBD - or use snapshots)
│   │   └── schema.yml     # Model documentation and tests
│   │
│   └── gold/
│       ├── metrics/
│       │   └── daily_sales_metrics.sql
│       └── aggregates/
│
├── snapshots/
│   └── dim_customer_snapshot.sql  # SCD Type 2
│
├── macros/                # Custom SQL macros
├── tests/                 # Custom data tests
└── analyses/              # Ad-hoc queries
```

## Key Concepts

### 1. Sources (Bronze Layer)

Sources define and test raw data quality:

```yaml
sources:
  - name: bronze
    tables:
      - name: raw_orders
        columns:
          - name: order_id
            tests:
              - unique
              - not_null
```

**Commands:**
```bash
# Test source freshness
dbt source freshness

# Run tests on sources
dbt test --select source:bronze
```

### 2. Snapshots (SCD Type 2)

Snapshots automatically track historical changes:

```sql
{% snapshot dim_customer_snapshot %}
{{
    config(
      unique_key='customer_id',
      strategy='timestamp',
      updated_at='load_timestamp'
    )
}}
SELECT * FROM {{ source('bronze', 'raw_orders') }}
{% endsnapshot %}
```

**Generated columns:**
- `dbt_valid_from`: Start date
- `dbt_valid_to`: End date (NULL = current)
- `dbt_scd_id`: Unique version ID

**Commands:**
```bash
# Run all snapshots
dbt snapshot

# Run specific snapshot
dbt snapshot --select dim_customer_snapshot
```

### 3. Models (Silver/Gold Layers)

Models are SQL SELECT statements with configuration:

```sql
{{
  config(
    materialized='incremental',
    unique_key='order_id'
  )
}}

SELECT * FROM {{ source('bronze', 'raw_orders') }}

{% if is_incremental() %}
WHERE load_timestamp > (SELECT MAX(created_at) FROM {{ this }})
{% endif %}
```

**Materialization types:**
- `view`: Virtual table (no storage)
- `table`: Persistent table (full refresh)
- `incremental`: Append/update new data only
- `ephemeral`: CTE (not materialized)

**Commands:**
```bash
# Run all models
dbt run

# Run specific model
dbt run --select fact_orders

# Run Silver layer only
dbt run --models tag:silver

# Full refresh (ignore incremental)
dbt run --full-refresh
```

### 4. Tests

Built-in tests + custom tests:

```yaml
columns:
  - name: sales
    tests:
      - not_null
      - dbt_utils.accepted_range:
          min_value: 0
```

**Commands:**
```bash
# Run all tests
dbt test

# Test specific model
dbt test --select fact_orders

# Test relationships
dbt test --select test_type:relationships
```

### 5. Documentation

Auto-generated docs with lineage:

```bash
# Generate documentation
dbt docs generate

# Serve docs locally
dbt docs serve
# Access at: http://localhost:8080
```

## Daily Workflow

### Development (Local)

```bash
# 1. Pull latest code
git pull

# 2. Install/update packages
dbt deps

# 3. Run models in dev
dbt run --target dev

# 4. Test data quality
dbt test

# 5. Generate docs
dbt docs generate
```

### Production (Airflow)

The `dbt_transformations` DAG handles:

1. **Source Freshness Check** → Verify Bronze data is recent
2. **Snapshots** → Update SCD Type 2 dimensions
3. **Silver Models** → Transform Bronze → Silver
4. **Silver Tests** → Validate Silver data quality
5. **Gold Models** → Aggregate Silver → Gold
6. **Gold Tests** → Validate Gold metrics
7. **Docs Generation** → Update documentation

**Schedule:** Daily at 3 AM (after Bronze ingestion)

## Common Commands

```bash
# Development
dbt run --target dev                    # Run in dev environment
dbt run --select fact_orders+          # Run model and downstream
dbt run --select +fact_orders          # Run model and upstream
dbt run --exclude tag:gold             # Skip Gold layer

# Testing
dbt test --select source:*             # Test all sources
dbt test --select fact_orders          # Test specific model
dbt test --store-failures              # Save test failures to tables

# Documentation
dbt docs generate                      # Generate docs
dbt docs serve --port 8001             # Serve on custom port

# Snapshots
dbt snapshot --select dim_customer_snapshot
dbt snapshot --vars '{start_date: "2024-01-01"}'

# Compilation
dbt compile                            # Compile without running
dbt ls                                 # List all resources

# Debug
dbt debug                              # Test connection
dbt show --select fact_orders --limit 10  # Preview results
```

## Benefits Over SQL Scripts

| Aspect | SQL Scripts | dbt |
|--------|-------------|-----|
| Version Control | Manual | Built-in |
| Testing | Manual | Automated |
| Documentation | External | Auto-generated |
| Lineage | Unknown | Visual DAG |
| Incremental Logic | Complex MERGE | Simple `is_incremental()` |
| SCD Type 2 | Manual MERGE | `dbt snapshot` |
| Dependencies | Manual order | Auto-resolved |
| Environment Management | Manual | Profiles |

## Migration Path

### Phase 1: Sources (Current)
- ✅ Define Bronze sources
- ✅ Add data quality tests
- ✅ Run `dbt source freshness`

### Phase 2: Snapshots
- ✅ Create SCD Type 2 snapshots
- ⚠️ TODO: Add more dimensions

### Phase 3: Silver Models
- ✅ Migrate fact_orders
- ⚠️ TODO: Migrate other facts
- ⚠️ TODO: Add comprehensive tests

### Phase 4: Gold Models
- ✅ Create daily_sales_metrics
- ⚠️ TODO: Add more aggregations
- ⚠️ TODO: Add time-series models

### Phase 5: Production
- ✅ Airflow DAG created
- ⚠️ TODO: Add monitoring
- ⚠️ TODO: Add alerts

## Best Practices

1. **Use refs, not hard-coded tables**
   ```sql
   -- ❌ Bad
   SELECT * FROM silver_db.core_schema.fact_orders
   
   -- ✅ Good
   SELECT * FROM {{ ref('fact_orders') }}
   ```

2. **Tag your models**
   ```yaml
   models:
     - name: fact_orders
       config:
         tags: ['facts', 'silver', 'daily']
   ```

3. **Use incremental materialization for large tables**
   ```sql
   {{ config(materialized='incremental') }}
   ```

4. **Add tests to all models**
   ```yaml
   columns:
     - name: order_id
       tests: [unique, not_null]
   ```

5. **Document your models**
   ```yaml
   description: "Silver layer fact table for orders"
   ```

## Troubleshooting

### Connection Issues
```bash
# Test connection
dbt debug

# Check profile
cat ~/.dbt/profiles.yml
```

### Model Failures
```bash
# Run with verbose logging
dbt run --select fact_orders --debug

# Compile to see generated SQL
dbt compile --select fact_orders
```

### Test Failures
```bash
# Store failures for inspection
dbt test --store-failures

# Query failures
SELECT * FROM silver_db.dbt_test__audit.unique_fact_orders_order_id
```

## Resources

- dbt Documentation: https://docs.getdbt.com
- dbt Discourse: https://discourse.getdbt.com
- Snowflake + dbt Guide: https://docs.getdbt.com/reference/warehouse-setups/snowflake-setup

---

**Next Steps:**
1. Run `dbt deps` to install packages
2. Run `dbt debug` to test connection
3. Run `dbt source freshness` to check Bronze data
4. Run `dbt snapshot` to create SCD Type 2 dimensions
5. Run `dbt run` to build Silver and Gold layers
