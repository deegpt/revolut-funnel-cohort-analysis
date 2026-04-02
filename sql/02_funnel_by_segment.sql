-- =============================================================
-- 02_funnel_by_segment.sql
-- Funnel conversion segmented by KYC Risk Band, Plan Tier,
-- Acquisition Channel, Region, and Device Type
-- =============================================================

WITH funnel_flags AS (

    SELECT
        u.user_id,
        u.region,
        u.country,
        u.acquisition_channel,
        u.kyc_risk_band,
        u.plan_tier,
        u.device_type,
        u.primary_use_case,

        MAX(CASE WHEN e.event_type = 'install_app'            THEN 1 ELSE 0 END) AS s1,
        MAX(CASE WHEN e.event_type = 'start_registration'     THEN 1 ELSE 0 END) AS s2,
        MAX(CASE WHEN e.event_type = 'kyc_document_uploaded'  THEN 1 ELSE 0 END) AS s3,
        MAX(CASE WHEN e.event_type = 'kyc_biometric_done'     THEN 1 ELSE 0 END) AS s4,
        MAX(CASE WHEN e.event_type = 'kyc_approved'           THEN 1 ELSE 0 END) AS s5,
        MAX(CASE WHEN e.event_type = 'first_top_up'           THEN 1 ELSE 0 END) AS s6,
        MAX(CASE WHEN e.event_type = 'first_card_payment'     THEN 1 ELSE 0 END) AS s7

    FROM revolut_users u
    LEFT JOIN revolut_events e ON u.user_id = e.user_id
    GROUP BY
        u.user_id, u.region, u.country, u.acquisition_channel,
        u.kyc_risk_band, u.plan_tier, u.device_type, u.primary_use_case
)

-- KYC Risk Band
SELECT 'kyc_risk_band' AS segment_dimension, kyc_risk_band AS segment_value,
    COUNT(*) AS total_users,
    ROUND(100.0 * SUM(s5) / NULLIF(COUNT(*), 0), 2) AS kyc_approval_rate,
    ROUND(100.0 * SUM(s6) / NULLIF(COUNT(*), 0), 2) AS first_topup_rate,
    ROUND(100.0 * SUM(s7) / NULLIF(COUNT(*), 0), 2) AS first_payment_rate,
    ROUND(100.0 * (COUNT(*) - SUM(s5)) / NULLIF(COUNT(*), 0), 2) AS kyc_dropoff_rate
FROM funnel_flags GROUP BY kyc_risk_band

UNION ALL
SELECT 'plan_tier', plan_tier, COUNT(*),
    ROUND(100.0 * SUM(s5) / NULLIF(COUNT(*), 0), 2),
    ROUND(100.0 * SUM(s6) / NULLIF(COUNT(*), 0), 2),
    ROUND(100.0 * SUM(s7) / NULLIF(COUNT(*), 0), 2),
    ROUND(100.0 * (COUNT(*) - SUM(s5)) / NULLIF(COUNT(*), 0), 2)
FROM funnel_flags GROUP BY plan_tier

UNION ALL
SELECT 'acquisition_channel', acquisition_channel, COUNT(*),
    ROUND(100.0 * SUM(s5) / NULLIF(COUNT(*), 0), 2),
    ROUND(100.0 * SUM(s6) / NULLIF(COUNT(*), 0), 2),
    ROUND(100.0 * SUM(s7) / NULLIF(COUNT(*), 0), 2),
    ROUND(100.0 * (COUNT(*) - SUM(s5)) / NULLIF(COUNT(*), 0), 2)
FROM funnel_flags GROUP BY acquisition_channel

UNION ALL
SELECT 'region', region, COUNT(*),
    ROUND(100.0 * SUM(s5) / NULLIF(COUNT(*), 0), 2),
    ROUND(100.0 * SUM(s6) / NULLIF(COUNT(*), 0), 2),
    ROUND(100.0 * SUM(s7) / NULLIF(COUNT(*), 0), 2),
    ROUND(100.0 * (COUNT(*) - SUM(s5)) / NULLIF(COUNT(*), 0), 2)
FROM funnel_flags GROUP BY region

UNION ALL
SELECT 'device_type', device_type, COUNT(*),
    ROUND(100.0 * SUM(s5) / NULLIF(COUNT(*), 0), 2),
    ROUND(100.0 * SUM(s6) / NULLIF(COUNT(*), 0), 2),
    ROUND(100.0 * SUM(s7) / NULLIF(COUNT(*), 0), 2),
    ROUND(100.0 * (COUNT(*) - SUM(s5)) / NULLIF(COUNT(*), 0), 2)
FROM funnel_flags GROUP BY device_type

ORDER BY segment_dimension, segment_value;
