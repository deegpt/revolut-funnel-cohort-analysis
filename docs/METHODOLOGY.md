# 🔬 Methodology & Data Design

---

## Why Synthetic Data?

This project uses a fully synthetic dataset rather than real Revolut data for the following reasons:

1. **Confidentiality:** Actual user-level event data from any financial services company is strictly confidential and subject to GDPR/FCA regulations. Publishing it would be a serious data protection violation.
2. **Demonstrability:** A synthetic dataset can be made fully public, cloned, run, and reproduced by any reviewer — making it ideal for a portfolio project.
3. **Control:** Synthetic data allows deliberate embedding of the analytical patterns being demonstrated (funnel drop-offs, retention curves, SLA-retention correlation) without relying on finding a public dataset that happens to contain all these signals.

> **Transparency:** The dataset is explicitly described as synthetic in this README and throughout the project. No claims are made that these figures represent Revolut’s actual metrics.

---

## How the Data Was Designed

### User Population (revolut_users.csv)

- 20,000 users generated with realistic distributions for:
  - **Country/Region:** EEA-weighted (UK, Germany, France, Ireland, Poland, Spain, others)
  - **Acquisition channel:** Referral ~25%, Organic ~30%, Paid Social ~25%, Paid Search ~12%, Partner ~8% — consistent with neobank growth literature
  - **Plan tier:** Standard ~65%, Plus ~18%, Premium ~12%, Metal ~5% — mirroring Revolut’s published tier distribution
  - **KYC risk band:** Low ~55%, Medium ~35%, High ~10%
  - **Primary use case:** EverydaySpend ~35%, TravelFX ~30%, P2POnly ~20%, SavingsInvesting ~15%

### Event Log (revolut_events.csv)

- ~370,000 events across Jan–2024 to Dec 2024
- **Funnel events:** Each user progresses through onboarding steps with stage-specific drop-off probabilities:
  - install → registration: 90%
  - registration → kyc_doc: 80%
  - kyc_doc → kyc_bio: 75%
  - kyc_bio → kyc_approved: 85% (lower for High-risk band: ~60%)
  - kyc_approved → first_top_up: 78%
  - first_top_up → first_card_payment: 92%
- **Retention events:** Post-activation event frequency decays exponentially by week, with plan-tier modifiers (Premium users have 1.4× the weekly activity probability of Standard users)
- **Seasonal patterns:** Q4 uplift for card_payment events; Q2/Q3 uplift for FX events (travel season)

### Support Tickets (revolut_support_tickets.csv)

- ~4,000 tickets, weighted towards the first 30 days of a user’s lifecycle (when escalation rates are highest in real operations)
- SLA breach probability is higher for: High severity tickets, High-risk KYC band users, and Paid-Social acquisition channel
- CSAT is deliberately correlated with SLA outcome (breached tickets score 0.8–1.2 points lower on average) to create the analytical signal in query 05

### Date Dimension (revolut_date_dim.csv)

- Standard calendar dimension table with: date, day_of_week, week_start (Monday), ISO week number, month, quarter, year_month, is_weekend
- Required for all cohort joins (DATEDIFF on week_start / year_month)

---

## Limitations

| Limitation | Impact |
|---|---|
| Synthetic data may not capture all real-world correlations | Analysis patterns are illustrative, not precise benchmarks |
| No payment amount variance by plan tier | ARPU proxy (query 09) uses a simplified uniform distribution |
| No device OS version or app version | Cannot model app-version-specific funnel differences |
| No inter-user social graph | Referral relationships are implied by channel label, not modelled as edges |
| Fixed calendar year (2024) | Seasonality effects are present but limited to one cycle |

---

## Tools Used

| Tool | Purpose |
|---|---|
| Python (pandas, numpy, faker) | Synthetic data generation |
| SQL (ANSI-compatible) | All analytical queries |
| DuckDB | Local query testing |
| Tableau Desktop | Dashboard visualisation |
| GitHub | Version control and portfolio hosting |
