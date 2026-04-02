-- =============================================================
-- 10_early_churn_risk.sql
-- Early Churn Risk: One-and-Done User Identification
-- Identifies users who activated (made first payment) but
-- showed zero subsequent activity within 30 days
-- =============================================================

WITH user_event_timeline AS (
    SELECT
        e.user_id,
        u.plan_tier,
        u.region,
        u.acquisition_channel,
        u.kyc_risk_band,
        u.primary_use_case,
        u.device_type,
        u.signup_date,
        MIN(CASE WHEN e.event_type = 'first_card_payment' THEN e.event_date END) AS first_payment_date,
        COUNT(DISTINCT CASE
            WHEN e.event_type NOT IN ('install_app', 'start_registration',
                'kyc_document_uploaded', 'kyc_biometric_done', 'kyc_approved',
                'first_top_up', 'card_issued', 'card_activated', 'first_card_payment')
            AND DATEDIFF('day', u.signup_date, e.event_date) BETWEEN 1 AND 30
            THEN e.event_date
        END) AS repeat_active_days_30d,
        COUNT(DISTINCT CASE
            WHEN e.event_type IN ('p2p_payment_sent', 'first_fx_exchange',
                'created_savings_vault', 'started_trading')
            THEN e.event_type
        END) AS product_features_used
    FROM revolut_events e
    INNER JOIN revolut_users u ON e.user_id = u.user_id
    GROUP BY
        e.user_id, u.plan_tier, u.region, u.acquisition_channel,
        u.kyc_risk_band, u.primary_use_case, u.device_type, u.signup_date
),

churn_classification AS (
    SELECT
        *,
        CASE
            WHEN first_payment_date IS NULL                  THEN 'Never Activated'
            WHEN repeat_active_days_30d = 0
                AND product_features_used = 0               THEN 'One-and-Done (High Risk)'
            WHEN repeat_active_days_30d <= 2
                AND product_features_used <= 1              THEN 'Low Engagement (Medium Risk)'
            WHEN repeat_active_days_30d BETWEEN 3 AND 9     THEN 'Moderate Engagement'
            ELSE                                                 'Highly Engaged'
        END AS churn_risk_segment
    FROM user_event_timeline
)

SELECT
    churn_risk_segment,
    plan_tier,
    region,
    acquisition_channel,
    kyc_risk_band,
    primary_use_case,
    device_type,
    COUNT(*)                                                             AS users,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)                   AS pct_of_total,
    ROUND(AVG(CAST(repeat_active_days_30d AS FLOAT)), 1)                 AS avg_active_days_30d,
    ROUND(AVG(CAST(product_features_used AS FLOAT)), 1)                  AS avg_features_used
FROM churn_classification
GROUP BY
    churn_risk_segment, plan_tier, region,
    acquisition_channel, kyc_risk_band,
    primary_use_case, device_type
ORDER BY
    CASE churn_risk_segment
        WHEN 'One-and-Done (High Risk)'  THEN 1
        WHEN 'Never Activated'           THEN 2
        WHEN 'Low Engagement (Medium Risk)' THEN 3
        WHEN 'Moderate Engagement'       THEN 4
        ELSE 5
    END,
    users DESC;
