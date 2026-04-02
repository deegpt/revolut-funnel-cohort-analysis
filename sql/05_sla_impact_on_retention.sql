-- =============================================================
-- 05_sla_impact_on_retention.sql
-- SLA Breach → Product Retention Bridge
-- THE SIGNATURE QUERY: connects operational support quality
-- to long-term user retention — inspired by patterns observed
-- in customer operations at Revolut
--
-- Logic:
--   For each user, check if they had a high/critical severity
--   support ticket in the first 30 days AND whether it was
--   resolved within SLA. Then track 30-day and 90-day activity.
-- =============================================================

WITH early_tickets AS (

    SELECT
        st.user_id,
        st.ticket_severity,
        st.ticket_category,
        st.raised_within_sla,
        st.csat_score,
        st.ticket_created_at,
        u.signup_date,
        DATEDIFF('day', u.signup_date, st.ticket_created_at) AS days_after_signup
    FROM revolut_support_tickets st
    INNER JOIN revolut_users u ON st.user_id = u.user_id
    WHERE DATEDIFF('day', u.signup_date, st.ticket_created_at) <= 30
),

user_support_profile AS (
    -- Classify each user by their WORST early support experience
    SELECT
        user_id,
        MAX(CASE WHEN ticket_severity IN ('High', 'Critical') THEN 1 ELSE 0 END) AS had_high_severity_ticket,
        MIN(CASE WHEN ticket_severity IN ('High', 'Critical') THEN raised_within_sla ELSE 1 END) AS sla_met_for_critical,
        ROUND(AVG(CAST(csat_score AS FLOAT)), 2) AS avg_early_csat
    FROM early_tickets
    GROUP BY user_id
),

all_users AS (
    SELECT
        u.user_id,
        u.plan_tier,
        u.region,
        u.acquisition_channel,
        u.kyc_risk_band,
        u.signup_date,
        COALESCE(sp.had_high_severity_ticket, 0)   AS had_high_severity_ticket,
        COALESCE(sp.sla_met_for_critical, 1)        AS sla_met_for_critical,
        COALESCE(sp.avg_early_csat, NULL)           AS avg_early_csat
    FROM revolut_users u
    LEFT JOIN user_support_profile sp ON u.user_id = sp.user_id
),

post_ticket_activity AS (
    SELECT
        e.user_id,
        COUNT(DISTINCT CASE
            WHEN DATEDIFF('day', u.signup_date, e.event_date) BETWEEN 0  AND 30  THEN e.event_date END) AS active_days_0_30,
        COUNT(DISTINCT CASE
            WHEN DATEDIFF('day', u.signup_date, e.event_date) BETWEEN 31 AND 90  THEN e.event_date END) AS active_days_31_90
    FROM revolut_events e
    INNER JOIN revolut_users u ON e.user_id = u.user_id
    WHERE e.event_type IN (
        'card_payment', 'p2p_payment_sent', 'p2p_payment_received',
        'first_fx_exchange', 'started_trading', 'created_savings_vault'
    )
    GROUP BY e.user_id
)

SELECT
    -- Support experience segment
    CASE
        WHEN au.had_high_severity_ticket = 0             THEN 'No High Severity Ticket'
        WHEN au.had_high_severity_ticket = 1
            AND au.sla_met_for_critical = 1              THEN 'High Severity — SLA Met'
        ELSE                                                  'High Severity — SLA Breached'
    END AS support_experience_segment,

    au.plan_tier,
    au.region,
    COUNT(*)                                                          AS users,
    ROUND(AVG(CAST(pta.active_days_0_30 AS FLOAT)), 2)               AS avg_active_days_30d,
    ROUND(AVG(CAST(pta.active_days_31_90 AS FLOAT)), 2)              AS avg_active_days_90d,
    ROUND(100.0 * SUM(CASE WHEN pta.active_days_0_30  > 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_active_30d,
    ROUND(100.0 * SUM(CASE WHEN pta.active_days_31_90 > 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_active_90d,
    ROUND(AVG(au.avg_early_csat), 2)                                  AS avg_early_csat

FROM all_users au
LEFT JOIN post_ticket_activity pta ON au.user_id = pta.user_id
GROUP BY 1, au.plan_tier, au.region
ORDER BY support_experience_segment, au.plan_tier;
