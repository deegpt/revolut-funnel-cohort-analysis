-- =============================================================
-- 03_weekly_cohort_retention.sql
-- Weekly Cohort Retention (W0 – W25)
-- Cohort = signup_week (ISO week)
-- Active = performed any transaction event in a given week
-- =============================================================

WITH transaction_events AS (
    SELECT e.user_id, d.week_start
    FROM revolut_events e
    INNER JOIN revolut_date_dim d ON e.event_date = d.date
    WHERE e.event_type IN (
        'first_top_up', 'first_card_payment', 'card_payment',
        'p2p_payment_sent', 'p2p_payment_received',
        'first_fx_exchange', 'started_trading'
    )
    GROUP BY e.user_id, d.week_start
),

user_cohorts AS (
    SELECT u.user_id, d.week_start AS cohort_week
    FROM revolut_users u
    INNER JOIN revolut_date_dim d ON u.signup_date = d.date
),

cohort_sizes AS (
    SELECT cohort_week, COUNT(DISTINCT user_id) AS cohort_size
    FROM user_cohorts
    GROUP BY cohort_week
),

user_activity AS (
    SELECT
        uc.user_id,
        uc.cohort_week,
        DATEDIFF('week', uc.cohort_week, te.week_start) AS weeks_since_signup
    FROM user_cohorts uc
    INNER JOIN transaction_events te ON uc.user_id = te.user_id
    WHERE DATEDIFF('week', uc.cohort_week, te.week_start) BETWEEN 0 AND 25
),

retention_counts AS (
    SELECT cohort_week, weeks_since_signup, COUNT(DISTINCT user_id) AS active_users
    FROM user_activity
    GROUP BY cohort_week, weeks_since_signup
)

SELECT
    r.cohort_week,
    r.weeks_since_signup,
    r.active_users,
    cs.cohort_size,
    ROUND(100.0 * r.active_users / cs.cohort_size, 2) AS retention_pct
FROM retention_counts r
INNER JOIN cohort_sizes cs ON r.cohort_week = cs.cohort_week
ORDER BY r.cohort_week, r.weeks_since_signup;
