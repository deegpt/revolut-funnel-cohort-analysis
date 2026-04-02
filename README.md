# 🔄 Revolut-Style User Funnel & Cohort Analysis Dashboard

> **A Tableau dashboard project built on a synthetic neobank dataset — modelled on real fintech product behaviour observed while working at Revolut.**

---

## 📌 Project Summary

This project builds a **production-grade Tableau dashboard** that analyses:

- **Onboarding funnel drop-off** — where users fall out of the KYC and activation journey
- **Weekly and monthly cohort retention** — who comes back, for how long, and why some cohorts stick better than others
- **Feature adoption depth** — how many users progress beyond their first card payment into FX, P2P, savings, and trading
- **SLA breach → retention impact** — connecting operational support quality to long-term product retention
- **Early churn risk** — identifying "one-and-done" users before they become irreversible churners

The dataset is **synthetic but behaviourally realistic** — event distributions, KYC drop-off rates, cohort decay curves, and plan-tier engagement patterns are designed to mirror how a European neobank like Revolut actually operates.

---

## 🧠 Why This Project Exists

I built this project at the intersection of two experiences:

**1. Revolut (Customer Operations)**  
During my time at Revolut, I regularly saw the same friction patterns from the customer side:
- Users getting stuck during KYC document upload or biometric capture — and escalating to support before completing registration
- New users who funded their accounts but never made a first transaction, then churning quietly
- High-severity support tickets in the first 30 days correlated strongly with drop-offs in future engagement
- Premium-plan users (Plus/Premium/Metal) showing markedly different support behaviours and feature usage vs Standard users

These are real operational patterns that live analysts and product teams investigate. This dashboard turns those observed patterns into a structured analytical framework.

**2. Operational SLA & CSAT Analytics (Portfolio Project)**  
My existing SLA Analysis project built SQL-backed dashboards for SLA breach rates and CSAT scores across support ticket categories. This project **extends that lens into product analytics**: rather than stopping at "was the ticket resolved on time?", it asks "what happened to that user's product engagement after the ticket?"

---

## 🏗️ Dataset Architecture

```
data/revolut_users.csv              — 20,000 synthetic users (star schema dimension)
data/revolut_events.csv             — ~370K events spanning Jan–Dec 2024
data/revolut_support_tickets.csv    — ~4,000 early-lifecycle support tickets
data/revolut_date_dim.csv           — calendar dimension for week/month cohort joins
```

### Design choices

| Feature | Rationale |
|---|---|
| KYC risk bands (Low/Medium/High) | Reflects real AML/KYC tiering used in EU-regulated neobanks |
| Plan tiers (Standard/Plus/Premium/Metal) | Maps to Revolut's actual pricing tiers |
| Primary use case (TravelFX/EverydaySpend/P2POnly/SavingsInvesting) | Segments users by intent — a common analytical lens in neobanks |
| SLA threshold by severity (4h/12h/24h) | Same thresholds used in prior SLA analysis project |
| Decaying weekly activity probability | Ensures cohort retention curves look like real data (exponential-ish decay) |
| Correlated CSAT and SLA breach | CSAT scores are deliberately worse for breached tickets — realistic signal |

---

## 🗂️ Folder Structure

```
revolut-funnel-cohort-analysis/
│
├── README.md
│
├── data/
│   ├── revolut_users.csv
│   ├── revolut_events.csv
│   ├── revolut_support_tickets.csv
│   └── revolut_date_dim.csv
│
├── sql/
│   ├── 01_onboarding_funnel.sql
│   ├── 02_funnel_by_segment.sql
│   ├── 03_weekly_cohort_retention.sql
│   ├── 04_monthly_cohort_retention.sql
│   ├── 05_sla_impact_on_retention.sql
│   ├── 06_feature_adoption_funnel.sql
│   ├── 07_time_to_activation.sql
│   ├── 08_sla_csat_summary.sql
│   ├── 09_plan_arpu_and_engagement.sql
│   └── 10_early_churn_risk.sql
│
├── tableau_notes/
│   └── TABLEAU_BUILD_GUIDE.md
│
└── docs/
    ├── INSIGHTS.md
    ├── BUSINESS_RECOMMENDATIONS.md
    └── METHODOLOGY.md
```

---

## ⚙️ How to Run

### Option A — Tableau Desktop (direct CSV)
1. Open Tableau Desktop → Connect to Text File → load `revolut_users.csv`
2. Add relationships: `revolut_events`, `revolut_support_tickets`, `revolut_date_dim`
3. Follow `tableau_notes/TABLEAU_BUILD_GUIDE.md` for sheet-by-sheet build instructions

### Option B — SQL + Tableau
1. Load all four CSVs into a SQL Server / DuckDB / PostgreSQL database
2. Run queries in `/sql/` to generate analysis views
3. Connect Tableau to your DB and use the views as data sources

### DuckDB (quickest local option)
```bash
pip install duckdb
duckdb -c "
  CREATE TABLE revolut_users AS SELECT * FROM read_csv_auto('data/revolut_users.csv');
  CREATE TABLE revolut_events AS SELECT * FROM read_csv_auto('data/revolut_events.csv');
  CREATE TABLE revolut_support_tickets AS SELECT * FROM read_csv_auto('data/revolut_support_tickets.csv');
  CREATE TABLE revolut_date_dim AS SELECT * FROM read_csv_auto('data/revolut_date_dim.csv');
"
```

---

## 📊 Dashboard Views

| View | Chart Type | Key Metric |
|---|---|---|
| Onboarding Funnel | Bar/Gantt funnel | Drop-off % at each KYC step |
| Funnel by Segment | Stacked bars | Conversion rate by risk band / plan / channel |
| Weekly Retention Heatmap | Colour-coded matrix | W0–W25 retention % |
| Monthly Cohort Curves | Line chart | M0–M11 retention by plan tier |
| SLA → Retention | Grouped bar | 30d/90d retention by support experience |
| Feature Adoption Funnel | Sequential bar | % adopting FX, P2P, savings, trading |
| Time to Activation | Distribution histogram | Days from install to first payment |
| Plan ARPU & Engagement | Scatter / bubble | Avg volume vs features used by plan |
| Early Churn Risk | Treemap / bar | One-and-done % by segment |

---

## 🏷️ Skills Demonstrated

`SQL` · `CTEs` · `Window Functions` · `Cohort Analysis` · `Funnel Analysis` · `Tableau` · `Data Modelling` · `Fintech Domain` · `SLA Analytics` · `CSAT Analysis` · `Synthetic Data Design` · `Product Analytics` · `Python`
