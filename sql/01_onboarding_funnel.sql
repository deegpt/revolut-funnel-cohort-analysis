-- =============================================================
-- 01_onboarding_funnel.sql
-- Onboarding Funnel Drop-off Analysis
-- Shows count and cumulative conversion % at each KYC step
-- =============================================================

WITH funnel_steps AS (

    SELECT
        u.user_id,
        u.country,
        u.region,
        u.acquisition_channel,
        u.kyc_risk_band,
        u.plan_tier,
        u.device_type,

        MAX(CASE WHEN e.event_type = 'install_app'            THEN 1 ELSE 0 END) AS reached_install,
        MAX(CASE WHEN e.event_type = 'start_registration'     THEN 1 ELSE 0 END) AS reached_registration,
        MAX(CASE WHEN e.event_type = 'kyc_document_uploaded'  THEN 1 ELSE 0 END) AS reached_kyc_doc,
        MAX(CASE WHEN e.event_type = 'kyc_biometric_done'     THEN 1 ELSE 0 END) AS reached_kyc_bio,
        MAX(CASE WHEN e.event_type = 'kyc_approved'           THEN 1 ELSE 0 END) AS reached_kyc_approved,
        MAX(CASE WHEN e.event_type = 'first_top_up'           THEN 1 ELSE 0 END) AS reached_first_topup,
        MAX(CASE WHEN e.event_type = 'card_issued'            THEN 1 ELSE 0 END) AS reached_card_issued,
        MAX(CASE WHEN e.event_type = 'card_activated'         THEN 1 ELSE 0 END) AS reached_card_activated,
        MAX(CASE WHEN e.event_type = 'first_card_payment'     THEN 1 ELSE 0 END) AS reached_first_payment

    FROM revolut_users u
    LEFT JOIN revolut_events e ON u.user_id = e.user_id
    GROUP BY
        u.user_id, u.country, u.region,
        u.acquisition_channel, u.kyc_risk_band,
        u.plan_tier, u.device_type
),

funnel_summary AS (

    SELECT
        COUNT(*)                        AS users_at_install,
        SUM(reached_registration)       AS users_at_registration,
        SUM(reached_kyc_doc)            AS users_at_kyc_doc,
        SUM(reached_kyc_bio)            AS users_at_kyc_bio,
        SUM(reached_kyc_approved)       AS users_at_kyc_approved,
        SUM(reached_first_topup)        AS users_at_first_topup,
        SUM(reached_card_issued)        AS users_at_card_issued,
        SUM(reached_card_activated)     AS users_at_card_activated,
        SUM(reached_first_payment)      AS users_at_first_payment
    FROM funnel_steps
)

SELECT 'install_app' AS funnel_step, 1 AS step_order,
    users_at_install AS users,
    ROUND(100.0 * users_at_install / users_at_install, 2) AS pct_of_top,
    0.00 AS drop_off_pct
FROM funnel_summary

UNION ALL SELECT 'start_registration', 2, users_at_registration,
    ROUND(100.0 * users_at_registration / users_at_install, 2),
    ROUND(100.0 * (users_at_install - users_at_registration) / users_at_install, 2)
FROM funnel_summary

UNION ALL SELECT 'kyc_document_uploaded', 3, users_at_kyc_doc,
    ROUND(100.0 * users_at_kyc_doc / users_at_install, 2),
    ROUND(100.0 * (users_at_registration - users_at_kyc_doc) / users_at_install, 2)
FROM funnel_summary

UNION ALL SELECT 'kyc_biometric_done', 4, users_at_kyc_bio,
    ROUND(100.0 * users_at_kyc_bio / users_at_install, 2),
    ROUND(100.0 * (users_at_kyc_doc - users_at_kyc_bio) / users_at_install, 2)
FROM funnel_summary

UNION ALL SELECT 'kyc_approved', 5, users_at_kyc_approved,
    ROUND(100.0 * users_at_kyc_approved / users_at_install, 2),
    ROUND(100.0 * (users_at_kyc_bio - users_at_kyc_approved) / users_at_install, 2)
FROM funnel_summary

UNION ALL SELECT 'first_top_up', 6, users_at_first_topup,
    ROUND(100.0 * users_at_first_topup / users_at_install, 2),
    ROUND(100.0 * (users_at_kyc_approved - users_at_first_topup) / users_at_install, 2)
FROM funnel_summary

UNION ALL SELECT 'card_issued', 7, users_at_card_issued,
    ROUND(100.0 * users_at_card_issued / users_at_install, 2),
    ROUND(100.0 * (users_at_first_topup - users_at_card_issued) / users_at_install, 2)
FROM funnel_summary

UNION ALL SELECT 'card_activated', 8, users_at_card_activated,
    ROUND(100.0 * users_at_card_activated / users_at_install, 2),
    ROUND(100.0 * (users_at_card_issued - users_at_card_activated) / users_at_install, 2)
FROM funnel_summary

UNION ALL SELECT 'first_card_payment', 9, users_at_first_payment,
    ROUND(100.0 * users_at_first_payment / users_at_install, 2),
    ROUND(100.0 * (users_at_card_activated - users_at_first_payment) / users_at_install, 2)
FROM funnel_summary

ORDER BY step_order;
