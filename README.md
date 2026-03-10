# Supply Chain Analytics - Data Warehouse Project

## 🎯 Project Overview

End-to-end supply chain analytics platform built using modern data stack principles. Implements medallion architecture (Bronze/Silver/Gold) with automated data quality testing and SCD Type 2 dimension tracking.

## 🏗️ Architecture
```
Data Sources → AWS S3 → Snowflake (Bronze) → dbt (Silver/Gold) → Analytics
```

### Tech Stack
- **Data Warehouse**: Snowflake
- **Transformation**: dbt Cloud
- **Storage**: AWS S3
- **Version Control**: GitHub
- **Orchestration**: dbt Cloud Jobs

## 📊 Data Model

### Bronze Layer (Raw Data)
- `raw_orders` - Order transactions
- `raw_shipments` - Shipping & logistics data
- `raw_inventory` - Stock levels
- `raw_suppliers` - Supplier information
- `raw_products` - Product catalog

### Silver Layer (Cleansed & Conformed)
- `fact_orders` - Order fact table with business logic
- `dim_customer_snapshot` - Customer dimension with SCD Type 2 tracking
- `dim_date` - Date dimension

### Gold Layer (Analytics-Ready)
- `daily_sales_metrics` - Aggregated daily metrics with running totals
- Customer lifetime value calculations
- 7-day moving averages

## ✨ Key Features

- **Medallion Architecture**: Organized Bronze → Silver → Gold data flow
- **SCD Type 2**: Automatic historical tracking using dbt snapshots
- **Data Quality**: 37 automated tests ensuring data integrity
- **Incremental Loading**: Efficient processing of only new/changed data
- **Documentation**: Auto-generated with full data lineage
- **Version Control**: All transformation logic in Git

## 🔧 Technical Highlights

### dbt Models
- **Snapshots**: Automatic SCD Type 2 for dimension tables
- **Incremental materialization**: Optimized for large datasets
- **Window functions**: Running totals and moving averages
- **Data quality tests**: Not null, unique, relationships, accepted values

### Snowflake Features
- External stages (S3 integration)
- File formats (CSV with compression)
- Virtual warehouses with auto-suspend
- Time travel enabled
- Clustering keys for performance

## 📈 Metrics & Results

- **37 data quality tests** - 100% passing
- **5 source tables** monitored for freshness
- **3 fact/dimension tables** in Silver layer
- **1 analytics table** in Gold layer
- **Automated SCD Type 2** tracking customer changes

## 🚀 Setup Instructions

### Prerequisites
- Snowflake account
- dbt Cloud account
- AWS S3 bucket
- GitHub repository

### Quick Start

1. **Clone repository**
```bash
   git clone https://github.com/YOUR_USERNAME/supply-chain-dbt.git
   cd supply-chain-dbt
```

2. **Install dbt packages**
```bash
   dbt deps
```

3. **Test connection**
```bash
   dbt debug
```

4. **Run models**
```bash
   dbt snapshot  # SCD Type 2
   dbt run       # All transformations
   dbt test      # Data quality checks
```

## 📚 Documentation

Auto-generated documentation with data lineage available in dbt Cloud.

View the interactive lineage graph showing data flow from Bronze → Silver → Gold layers.

## 🎓 Learning Outcomes

- Implemented modern data warehouse design patterns
- Built production-grade ELT pipelines with dbt
- Applied SCD Type 2 for historical tracking
- Created automated data quality frameworks
- Designed dimensional models (star schema)
- Optimized queries for performance

## 🔄 Future Enhancements

- [ ] Add more dimension tables (product, warehouse, supplier)
- [ ] Implement incremental snapshots for all dimensions
- [ ] Add time-series forecasting models
- [ ] Create additional Gold layer aggregations
- [ ] Integrate with visualization tools (Tableau/PowerBI)
- [ ] Set up Airflow for orchestration
- [ ] Add ML models for demand prediction

## 👤 Author

**Pradeep Machiraju**
- Senior Data Engineer
- LinkedIn: https://www.linkedin.com/in/pradeep-kumar-machiraju-30773055
- GitHub: https://github.com/machkuma

## 📝 License

MIT License