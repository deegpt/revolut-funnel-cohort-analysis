-- =============================================================
-- 08_sla_csat_summary.sql
-- SLA Breach Rate & CSAT Summary by Ticket Category/Severity
-- Mirrors the operational SLA analytics project and extends it
-- to measure customer experience quality by segment
-- =============================================================

WITH ticket_metrics AS (
    SELECT
        st.ticket_id,
        st.user_id,
        st.ticket_category,
        st.ticket_severity,
        st.raised_within_sla,
        st.csat_score,
        st.ticket_created_at,
        u.plan_tier,
        u.region,
        u.kyc_risk_band,
        u.acquisition_channel,
        DATEDIFF('day', u.signup_date, st.ticket_created_at) AS days_after_signup,

        -- SLA threshold by severity (hours)
        CASE st.ticket_severity
            WHEN 'Critical' THEN 4
            WHEN 'High'     THEN 12
            WHEN 'Medium'   THEN 24
            ELSE 48
        END AS sla_threshold_hours

    FROM revolut_support_tickets st
    INNER JOIN revolut_users u ON st.user_id = u.user_id
)

SELECT
    ticket_category,
    ticket_severity,
    plan_tier,
    region,
    COUNT(*)                                                                AS total_tickets,
    SUM(CASE WHEN raised_within_sla = 1 THEN 1 ELSE 0 END)                 AS tickets_within_sla,
    SUM(CASE WHEN raised_within_sla = 0 THEN 1 ELSE 0 END)                 AS tickets_breached,
    ROUND(100.0 * SUM(CASE WHEN raised_within_sla = 0 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2)                                           AS sla_breach_rate_pct,
    ROUND(AVG(CAST(csat_score AS FLOAT)), 2)                                AS avg_csat,
    ROUND(AVG(CASE WHEN raised_within_sla = 1 THEN CAST(csat_score AS FLOAT) END), 2) AS avg_csat_sla_met,
    ROUND(AVG(CASE WHEN raised_within_sla = 0 THEN CAST(csat_score AS FLOAT) END), 2) AS avg_csat_sla_breached,
    ROUND(AVG(CASE WHEN days_after_signup <= 7  THEN CAST(csat_score AS FLOAT) END), 2) AS avg_csat_first_week,
    ROUND(AVG(CASE WHEN days_after_signup <= 30 THEN CAST(csat_score AS FLOAT) END), 2) AS avg_csat_first_month
FROM ticket_metrics
GROUP BY ticket_category, ticket_severity, plan_tier, region
ORDER BY sla_breach_rate_pct DESC, avg_csat ASC;
