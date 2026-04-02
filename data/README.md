# Data

This folder contains the **data generation script** only.  
Raw CSV files are intentionally excluded from version control (see `.gitignore`).

---

## Generate the data locally

```bash
pip install pandas numpy faker
python data/generate_data.py
```

This produces four CSV files in the same folder:

| File | Rows (approx.) | Description |
|---|---|---|
| `revolut_users.csv` | 20,000 | One row per user — demographics, plan tier, acquisition channel, KYC risk band |
| `revolut_events.csv` | ~370,000 | Timestamped product events per user (install → KYC → payments → FX → vault → trading) |
| `revolut_support_tickets.csv` | ~28,000 | Support tickets with category, severity, SLA status, and CSAT score |
| `revolut_date_dim.csv` | 366 | Calendar dimension — ISO week, month, quarter, is_weekend flag |

---

## Schema Reference

### `revolut_users`

| Column | Type | Description |
|---|---|---|
| `user_id` | VARCHAR | Unique user identifier (`USR_000001` … `USR_020000`) |
| `signup_date` | DATE | Account registration date (2024-01-01 → 2024-12-31) |
| `country` | VARCHAR | ISO-2 country code — GB, DE, FR, PL, IE, NL, ES, IT, RO, LT |
| `region` | VARCHAR | EEA, UK, or Other |
| `acquisition_channel` | VARCHAR | paid_social, organic_search, referral, app_store, influencer |
| `device_type` | VARCHAR | ios, android |
| `plan_at_signup` | VARCHAR | Standard, Plus, Premium, Metal |
| `kyc_risk_band` | VARCHAR | low, medium, high |
| `primary_use_case` | VARCHAR | everyday_spend, travel_fx, p2p_only, savings, trading |
| `age_band` | VARCHAR | 18-24, 25-34, 35-44, 45-54, 55+ |

### `revolut_events`

| Column | Type | Description |
|---|---|---|
| `event_id` | VARCHAR | Unique event identifier |
| `user_id` | VARCHAR | FK → `revolut_users.user_id` |
| `event_name` | VARCHAR | One of: `install_app`, `start_registration`, `kyc_document_uploaded`, `kyc_biometric_done`, `kyc_approved`, `first_top_up`, `card_issued`, `card_activated`, `first_card_payment`, `p2p_payment_sent`, `first_fx_exchange`, `created_savings_vault`, `started_trading`, `upgraded_plan`, `downgraded_plan` |
| `event_timestamp` | DATETIME | UTC timestamp of the event |
| `session_id` | VARCHAR | Session grouping identifier |
| `platform` | VARCHAR | ios, android |

### `revolut_support_tickets`

| Column | Type | Description |
|---|---|---|
| `ticket_id` | VARCHAR | Unique ticket identifier |
| `user_id` | VARCHAR | FK → `revolut_users.user_id` |
| `created_at` | DATETIME | Ticket creation timestamp |
| `resolved_at` | DATETIME | Ticket resolution timestamp (NULL if unresolved) |
| `category` | VARCHAR | card_decline, kyc_issue, chargeback, app_bug, transfer_delay, account_freeze |
| `severity` | VARCHAR | P1, P2, P3 |
| `sla_breached` | BIT | 1 = SLA breached, 0 = resolved within SLA |
| `csat_score` | INT | 1–5 customer satisfaction score (NULL if not rated) |
| `days_to_first_ticket` | INT | Days from signup to this ticket |

### `revolut_date_dim`

| Column | Type | Description |
|---|---|---|
| `date_key` | DATE | Calendar date (2024-01-01 → 2024-12-31) |
| `iso_year` | INT | ISO year |
| `iso_week` | INT | ISO week number (1–53) |
| `month_num` | INT | Month number (1–12) |
| `month_name` | VARCHAR | January … December |
| `quarter` | INT | 1–4 |
| `is_weekend` | BIT | 1 = Saturday or Sunday |
| `day_of_week` | VARCHAR | Monday … Sunday |

---

## Loading into SQL Server

```sql
-- Example: bulk load users
BULK INSERT revolut_users
FROM 'C:\path\to\data\revolut_users.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', TABLOCK);
```

## Loading into DuckDB (fastest for local dev)

```sql
CREATE TABLE revolut_users      AS SELECT * FROM read_csv_auto('data/revolut_users.csv');
CREATE TABLE revolut_events     AS SELECT * FROM read_csv_auto('data/revolut_events.csv');
CREATE TABLE revolut_support    AS SELECT * FROM read_csv_auto('data/revolut_support_tickets.csv');
CREATE TABLE revolut_date_dim   AS SELECT * FROM read_csv_auto('data/revolut_date_dim.csv');
```
