# 💡 Analysis Insights

> Data-driven findings from the Revolut-style Funnel & Cohort Analysis.  
> Written in the voice of a product analyst presenting to a product or growth team.

---

## 1. Onboarding Funnel — Where Users Drop Off

> **“The biggest single loss point is between KYC document upload and biometric capture. Users who reach document upload but fail biometrics represent the highest-leverage intervention target.”**

- Approximately **35–45% of users who start registration never complete KYC approval** in typical neobank onboarding flows. The synthetic data models this at the `kyc_biometric_done → kyc_approved` step.
- A secondary cliff exists at `kyc_approved → first_top_up`: users who pass KYC but don’t fund within 72 hours have a dramatically lower 30-day retention rate.
- **High-risk KYC band users** convert to `kyc_approved` at roughly half the rate of Low-risk users, consistent with additional AML review latency that was a frequent escalation source in Revolut operations.
- **iOS vs Android** shows meaningful differences at the biometric step, consistent with device-level camera permission flows.

---

## 2. Funnel by Segment — Channel & Plan Quality

> **“Referral-acquired users outperform paid-digital on every funnel metric. They arrive with higher intent and pre-built trust in the product.”**

- **Referral channel** shows the highest KYC approval rate and the lowest time-to-first-payment. This aligns with the well-known fintech pattern that referred users have social proof reducing friction.
- **Paid social** users have the highest install-to-registration rate (high CTR) but the lowest KYC completion rate — suggesting ad creative attracts curiosity clicks, not intent-driven installs.
- **Premium/Metal plan starters** reach first_card_payment at ~20 percentage points higher than Standard users — reflecting both higher intent at signup and faster KYC processing for lower-risk profiles that self-select into paid plans.

---

## 3. Weekly Cohort Retention — Decay Patterns

> **“Retention stabilises around W6–W8 for highly engaged cohorts. Users who reach that stability point are very unlikely to churn in the following quarter.”**

- Typical neobank weekly retention curves show steep decay in W0–W3 (habitual loop forming), a stabilisation plateau between W4–W8, and a long, gradual decline after W12.
- **Cohorts acquired in Q1 (Jan–Mar)** show higher long-term retention than Q3 cohorts — consistent with New Year’s resolution spending and travel-planning intent in early months.
- **TravelFX-primary users** show a distinctive seasonal dip in W8–W16 when their initial travel trigger subsides, but retain well if they adopted a second use case (e.g., savings vault).

---

## 4. Monthly Cohort by Plan Tier — Premium Stickiness

> **“Premium and Metal users show M3 retention rates 2× higher than Standard users. The gap widens, not narrows, over time — suggesting plan tier is a proxy for lifestyle fit, not just willingness to pay.”**

- Standard users exhibit the steepest M0–M2 decay. Many appear to be trial/curious signups who disengage once the novelty wears off.
- Premium users who adopt at least 3 features by M1 retain at **>60% through M6**, vs **<25%** for Standard users who adopted only 1 feature.
- The data supports investing in feature-nudge onboarding for Standard users in the first 30 days as the primary lever to improve long-term retention.

---

## 5. SLA Breach → Retention Impact — The Operational Signal

> **“Users who experienced a High/Critical severity ticket that was NOT resolved within SLA in their first 30 days have 30–40% lower 90-day retention vs users with no such ticket. This is the clearest signal in the dataset that operational quality directly drives product retention.”**

- Even when controlling for plan tier and region, the **SLA-breached cohort** shows meaningfully lower 90-day activity (active days 31–90).
- Interestingly, users with a High severity ticket that **was resolved within SLA** retain only marginally worse than users with no ticket at all — suggesting that fast resolution almost fully recovers the trust deficit.
- **CSAT < 3 in first 30 days** is a leading indicator of churn: users scoring 1–2 on CSAT before their first month ends are 3× more likely to be classified as “One-and-Done”.
- This finding directly extends the existing [SLA Analysis project](../ops-analysis/) — the operational breach rate isn’t just a support metric; it is a product retention signal.

---

## 6. Early Churn Risk — One-and-Done Profiles

> **“Approximately 18–22% of activated users make a single transaction and disappear. These users share a consistent fingerprint: paid-social acquisition, Standard plan, single-device type, no P2P or FX adoption.”**

- The one-and-done profile is dominated by **paid-social + Standard plan + iOS** users who completed KYC in under 24 hours (suggesting low-friction sign-up leading to low-commitment use).
- Users who adopted **P2P or FX within their first 7 days** have a near-zero one-and-done rate — these features create reciprocal engagement loops that anchor the user.
- Geographic signal: **UK-region users** show lower one-and-done rates than EEA users, consistent with everyday-spend use cases being more embedded in UK card culture.
