-- =============================================================
-- 06_feature_adoption_funnel.sql
-- Feature Adoption Depth Funnel (Post-Activation)
-- Tracks the % of active users who progress through each
-- product feature: card → P2P → FX → savings → trading
-- =============================================================

WITH activated_users AS (
    -- Base: users who completed card activation (active base)
    SELECT DISTINCT user_id
    FROM revolut_events
    WHERE event_type = 'first_card_payment'
),

feature_flags AS (
    SELECT
        u.user_id,
        u.plan_tier,
        u.region,
        u.primary_use_case,
        u.acquisition_channel,

        MAX(CASE WHEN e.event_type = 'first_card_payment'       THEN 1 ELSE 0 END) AS used_card,
        MAX(CASE WHEN e.event_type IN
            ('p2p_payment_sent', 'p2p_payment_received')         THEN 1 ELSE 0 END) AS used_p2p,
        MAX(CASE WHEN e.event_type = 'first_fx_exchange'         THEN 1 ELSE 0 END) AS used_fx,
        MAX(CASE WHEN e.event_type = 'created_savings_vault'     THEN 1 ELSE 0 END) AS used_savings,
        MAX(CASE WHEN e.event_type = 'started_trading'           THEN 1 ELSE 0 END) AS used_trading,
        MAX(CASE WHEN e.event_type = 'upgraded_plan'             THEN 1 ELSE 0 END) AS upgraded_plan

    FROM activated_users au
    INNER JOIN revolut_users u  ON au.user_id = u.user_id
    LEFT  JOIN revolut_events e ON u.user_id  = e.user_id
    GROUP BY
        u.user_id, u.plan_tier, u.region,
        u.primary_use_case, u.acquisition_channel
)

-- Overall feature adoption funnel
SELECT
    'overall' AS dimension,
    'all' AS dimension_value,
    COUNT(*)                                                AS base_users,
    ROUND(100.0 * SUM(used_card)    / COUNT(*), 2)         AS pct_card,
    ROUND(100.0 * SUM(used_p2p)     / COUNT(*), 2)         AS pct_p2p,
    ROUND(100.0 * SUM(used_fx)      / COUNT(*), 2)         AS pct_fx,
    ROUND(100.0 * SUM(used_savings) / COUNT(*), 2)         AS pct_savings,
    ROUND(100.0 * SUM(used_trading) / COUNT(*), 2)         AS pct_trading,
    ROUND(100.0 * SUM(upgraded_plan)/ COUNT(*), 2)         AS pct_upgraded,
    ROUND(AVG(
        CAST(used_card + used_p2p + used_fx +
             used_savings + used_trading AS FLOAT)
    ), 2)                                                  AS avg_features_adopted
FROM feature_flags

UNION ALL

-- By plan tier
SELECT
    'plan_tier', plan_tier, COUNT(*),
    ROUND(100.0 * SUM(used_card)    / COUNT(*), 2),
    ROUND(100.0 * SUM(used_p2p)     / COUNT(*), 2),
    ROUND(100.0 * SUM(used_fx)      / COUNT(*), 2),
    ROUND(100.0 * SUM(used_savings) / COUNT(*), 2),
    ROUND(100.0 * SUM(used_trading) / COUNT(*), 2),
    ROUND(100.0 * SUM(upgraded_plan)/ COUNT(*), 2),
    ROUND(AVG(CAST(used_card + used_p2p + used_fx + used_savings + used_trading AS FLOAT)), 2)
FROM feature_flags GROUP BY plan_tier

UNION ALL

-- By primary use case
SELECT
    'primary_use_case', primary_use_case, COUNT(*),
    ROUND(100.0 * SUM(used_card)    / COUNT(*), 2),
    ROUND(100.0 * SUM(used_p2p)     / COUNT(*), 2),
    ROUND(100.0 * SUM(used_fx)      / COUNT(*), 2),
    ROUND(100.0 * SUM(used_savings) / COUNT(*), 2),
    ROUND(100.0 * SUM(used_trading) / COUNT(*), 2),
    ROUND(100.0 * SUM(upgraded_plan)/ COUNT(*), 2),
    ROUND(AVG(CAST(used_card + used_p2p + used_fx + used_savings + used_trading AS FLOAT)), 2)
FROM feature_flags GROUP BY primary_use_case

ORDER BY dimension, dimension_value;
