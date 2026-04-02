-- =============================================================
-- 07_time_to_activation.sql
-- Time-to-Activation Analysis
-- How long does it take from install to first card payment?
-- Bucketed by speed segment and sliced by acquisition channel
-- =============================================================

WITH user_first_events AS (
    SELECT
        user_id,
        MIN(CASE WHEN event_type = 'install_app'        THEN event_date END) AS install_date,
        MIN(CASE WHEN event_type = 'kyc_approved'       THEN event_date END) AS kyc_date,
        MIN(CASE WHEN event_type = 'first_top_up'       THEN event_date END) AS topup_date,
        MIN(CASE WHEN event_type = 'first_card_payment' THEN event_date END) AS payment_date
    FROM revolut_events
    GROUP BY user_id
),

time_metrics AS (
    SELECT
        ufe.user_id,
        u.plan_tier,
        u.acquisition_channel,
        u.region,
        u.kyc_risk_band,
        u.device_type,
        DATEDIFF('day', ufe.install_date, ufe.kyc_date)     AS days_to_kyc,
        DATEDIFF('day', ufe.kyc_date,    ufe.topup_date)    AS days_kyc_to_topup,
        DATEDIFF('day', ufe.install_date, ufe.payment_date) AS days_to_first_payment,

        CASE
            WHEN DATEDIFF('day', ufe.install_date, ufe.payment_date) = 0  THEN 'Same Day'
            WHEN DATEDIFF('day', ufe.install_date, ufe.payment_date) <= 2  THEN '1-2 Days'
            WHEN DATEDIFF('day', ufe.install_date, ufe.payment_date) <= 7  THEN '3-7 Days'
            WHEN DATEDIFF('day', ufe.install_date, ufe.payment_date) <= 14 THEN '8-14 Days'
            WHEN DATEDIFF('day', ufe.install_date, ufe.payment_date) <= 30 THEN '15-30 Days'
            ELSE '30+ Days'
        END AS activation_speed_bucket

    FROM user_first_events ufe
    INNER JOIN revolut_users u ON ufe.user_id = u.user_id
    WHERE ufe.payment_date IS NOT NULL
)

SELECT
    activation_speed_bucket,
    acquisition_channel,
    plan_tier,
    kyc_risk_band,
    device_type,
    COUNT(*)                                                   AS users,
    ROUND(AVG(CAST(days_to_kyc AS FLOAT)), 1)                  AS avg_days_to_kyc,
    ROUND(AVG(CAST(days_kyc_to_topup AS FLOAT)), 1)            AS avg_days_kyc_to_topup,
    ROUND(AVG(CAST(days_to_first_payment AS FLOAT)), 1)        AS avg_days_to_first_payment,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)         AS pct_of_activated_users
FROM time_metrics
GROUP BY
    activation_speed_bucket, acquisition_channel,
    plan_tier, kyc_risk_band, device_type
ORDER BY
    CASE activation_speed_bucket
        WHEN 'Same Day'   THEN 1
        WHEN '1-2 Days'   THEN 2
        WHEN '3-7 Days'   THEN 3
        WHEN '8-14 Days'  THEN 4
        WHEN '15-30 Days' THEN 5
        ELSE 6
    END,
    acquisition_channel;
