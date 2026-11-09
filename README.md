# Malaysia Car Registrations & EV Market Analysis

Comparing Malaysia's car registrations and battery electric vehicle (EV) market in January–September 2025 and 2026.

**Tools:** PostgreSQL 18, SQL, VS Code

## Project Objective

Measure how EV registrations and market share changed year over year, then identify the months, brands and models contributing most to the increase.

## Market Overview

| Metric | Jan–Sep 2025 | Jan–Sep 2026 | Change |
|---|---:|---:|---:|
| Total car registrations | 613,952 | 640,875 | +4.39% |
| EV registrations | 26,928 | 53,537 | +26,609 (+98.82%) |
| EV share of car registrations | 4.39% | 8.35% | +3.97 percentage points |

EV registrations nearly doubled while total car registrations grew by 4.39%.

### Monthly Findings

- EV registrations increased year over year in all nine months.
- **August recorded the largest increase:** 5,372 additional EV registrations, from 3,461 to 8,833.
- **January had the highest growth rate:** 268.95%, from a smaller base of 1,691 registrations.
- The nine monthly increases total **26,609**, matching the period-level increase.

[View the market overview and monthly comparison SQL](sql/05_market_overview.sql)

## Data & Scope

Source: [JPJ Car Registration Transactions — data.gov.my](https://data.gov.my/data-catalogue/registration_transactions_car).

| Source file | Coverage | Records |
|---|---|---:|
| [cars_2025.csv](data/raw/cars_2025.csv) | January–December 2025 | 870,188 |
| [cars_2026.csv](data/raw/cars_2026.csv) | January–September 2026 | 640,875 |

- Comparisons use **January–September only** in both years.
- EV means `fuel = 'electric'`; hybrids are excluded.
- Each row counts as one registration. Identical public fields are not sufficient evidence to remove a record.
- EV share uses total EV registrations divided by total car registrations. Share changes are calculated before rounding.
- These figures measure registrations, not sales.

Quality checks found records in all 18 comparison months and no missing dates, fuel types, makers or models under the implemented checks. Fuel values had no leading/trailing ordinary spaces or case inconsistencies.

**Data limitation:** Results reflect the local CSV files. Monthly completeness has not yet been verified against official aggregates. The original download date was not recorded.

## SQL Files

| File | Purpose |
|---|---|
| [00_setup.psql](sql/00_setup.psql) | Create the database if needed, load data and run initial validation |
| [01_create_table.sql](sql/01_create_table.sql) | Define the raw registration table |
| [02_import_data.psql](sql/02_import_data.psql) | Reload both CSV files in one transaction |
| [03_validate_data.sql](sql/03_validate_data.sql) | Check database, record counts, date ranges and September 2026 totals |
| [04_data_quality.sql](sql/04_data_quality.sql) | Check month coverage, missing fields and fuel values |
| [05_market_overview.sql](sql/05_market_overview.sql) | Calculate period totals, annual changes and monthly EV comparisons |

## Run Locally

Requires a running PostgreSQL server and `psql`. Keep both CSV files in [data/raw](data/raw) and run these commands from the project root:

```powershell
psql -h localhost -p 5432 -U postgres -d postgres -W -f sql/00_setup.psql
psql -h localhost -p 5432 -U postgres -d malaysia_ev -W -v ON_ERROR_STOP=1 -f sql/04_data_quality.sql
psql -h localhost -p 5432 -U postgres -d malaysia_ev -W -v ON_ERROR_STOP=1 -f sql/05_market_overview.sql
```

Enter the database password when prompted. The setup script replaces the contents of `public.car_registrations_raw`; it does not append duplicate imports. SQL analysis files can also be run through a VS Code database connection to `malaysia_ev`.
