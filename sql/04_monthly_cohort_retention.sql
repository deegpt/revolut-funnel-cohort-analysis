-- =============================================================
-- 04_monthly_cohort_retention.sql
-- Monthly Cohort Retention (M0 – M11) by Plan Tier & Use Case
-- Cohort = signup_month
-- Active = performed any transaction in that calendar month
-- =============================================================

WITH transaction_events AS (
    SELECT e.user_id, d.year_month
    FROM revolut_events e
    INNER JOIN revolut_date_dim d ON e.event_date = d.date
    WHERE e.event_type IN (
        'first_top_up', 'first_card_payment', 'card_payment',
        'p2p_payment_sent', 'p2p_payment_received',
        'first_fx_exchange', 'started_trading'
    )
    GROUP BY e.user_id, d.year_month
),

user_cohorts AS (
    SELECT
        u.user_id,
        u.plan_tier,
        u.primary_use_case,
        u.region,
        d.year_month AS cohort_month
    FROM revolut_users u
    INNER JOIN revolut_date_dim d ON u.signup_date = d.date
),

cohort_sizes AS (
    SELECT cohort_month, plan_tier, primary_use_case,
        COUNT(DISTINCT user_id) AS cohort_size
    FROM user_cohorts
    GROUP BY cohort_month, plan_tier, primary_use_case
),

user_activity AS (
    SELECT
        uc.user_id,
        uc.cohort_month,
        uc.plan_tier,
        uc.primary_use_case,
        DATEDIFF('month', uc.cohort_month, te.year_month) AS months_since_signup
    FROM user_cohorts uc
    INNER JOIN transaction_events te ON uc.user_id = te.user_id
    WHERE DATEDIFF('month', uc.cohort_month, te.year_month) BETWEEN 0 AND 11
),

retention_counts AS (
    SELECT
        cohort_month, plan_tier, primary_use_case,
        months_since_signup,
        COUNT(DISTINCT user_id) AS active_users
    FROM user_activity
    GROUP BY cohort_month, plan_tier, primary_use_case, months_since_signup
)

SELECT
    r.cohort_month,
    r.plan_tier,
    r.primary_use_case,
    r.months_since_signup,
    r.active_users,
    cs.cohort_size,
    ROUND(100.0 * r.active_users / NULLIF(cs.cohort_size, 0), 2) AS retention_pct
FROM retention_counts r
INNER JOIN cohort_sizes cs
    ON r.cohort_month   = cs.cohort_month
    AND r.plan_tier     = cs.plan_tier
    AND r.primary_use_case = cs.primary_use_case
ORDER BY r.cohort_month, r.plan_tier, r.months_since_signup;
