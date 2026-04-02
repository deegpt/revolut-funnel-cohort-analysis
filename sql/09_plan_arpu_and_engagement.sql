-- =============================================================
-- 09_plan_arpu_and_engagement.sql
-- Plan Tier ARPU Proxy & Engagement Depth
-- Measures average revenue proxy, features adopted, and
-- transaction volume by plan tier and primary use case
-- =============================================================

WITH user_event_summary AS (
    SELECT
        user_id,
        COUNT(*) AS total_events,
        COUNT(DISTINCT event_type) AS distinct_event_types,
        COUNT(DISTINCT event_date) AS active_days,
        SUM(COALESCE(transaction_amount_gbp, 0)) AS total_volume_gbp,
        COUNT(CASE WHEN event_type = 'card_payment'           THEN 1 END) AS card_payments,
        COUNT(CASE WHEN event_type = 'p2p_payment_sent'       THEN 1 END) AS p2p_sent,
        COUNT(CASE WHEN event_type = 'first_fx_exchange'      THEN 1 END) AS fx_transactions,
        COUNT(CASE WHEN event_type = 'created_savings_vault'  THEN 1 END) AS savings_events,
        COUNT(CASE WHEN event_type = 'started_trading'        THEN 1 END) AS trading_events,
        MAX(CASE WHEN event_type = 'upgraded_plan'   THEN 1 ELSE 0 END)   AS ever_upgraded
    FROM revolut_events
    GROUP BY user_id
)

SELECT
    u.plan_tier,
    u.primary_use_case,
    u.region,
    COUNT(*)                                                              AS total_users,
    ROUND(AVG(ues.total_volume_gbp), 2)                                   AS avg_volume_gbp,
    ROUND(AVG(CAST(ues.active_days AS FLOAT)), 1)                         AS avg_active_days,
    ROUND(AVG(CAST(ues.card_payments AS FLOAT)), 1)                       AS avg_card_payments,
    ROUND(AVG(CAST(ues.p2p_sent AS FLOAT)), 1)                            AS avg_p2p_sent,
    ROUND(AVG(CAST(ues.fx_transactions AS FLOAT)), 1)                     AS avg_fx_txns,
    ROUND(AVG(CAST(ues.distinct_event_types AS FLOAT)), 1)                AS avg_feature_breadth,
    ROUND(100.0 * SUM(ues.ever_upgraded) / NULLIF(COUNT(*), 0), 2)        AS plan_upgrade_rate_pct,

    -- Engagement tier classification
    ROUND(100.0 * SUM(CASE WHEN ues.active_days >= 15 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2)                                         AS pct_highly_engaged,
    ROUND(100.0 * SUM(CASE WHEN ues.active_days BETWEEN 5 AND 14 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2)                                         AS pct_moderately_engaged,
    ROUND(100.0 * SUM(CASE WHEN ues.active_days < 5 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2)                                         AS pct_low_engaged

FROM revolut_users u
LEFT JOIN user_event_summary ues ON u.user_id = ues.user_id
GROUP BY u.plan_tier, u.primary_use_case, u.region
ORDER BY u.plan_tier, u.primary_use_case;
