# 🎯 Business Recommendations

> Six prioritised, evidence-based recommendations derived from the funnel and cohort analysis.  
> Each recommendation includes the data signal, the proposed intervention, the target metric, and an effort/impact estimate.

---

## Priority Matrix

| # | Recommendation | Impact | Effort | Time Horizon |
|---|---|---|---|---|
| 1 | Biometric KYC friction reduction | 🔴 High | 🟡 Medium | 4–8 weeks |
| 2 | Post-KYC funding nudge sequence | 🔴 High | 🟢 Low | 1–2 weeks |
| 3 | First-30-day SLA escalation fast lane | 🔴 High | 🟡 Medium | 6–12 weeks |
| 4 | Feature-nudge onboarding for Standard users | 🟠 Medium-High | 🟡 Medium | 4–6 weeks |
| 5 | TravelFX off-season re-engagement campaign | 🟠 Medium | 🟢 Low | 2–4 weeks |
| 6 | Referral channel investment increase | 🟠 Medium | 🟢 Low | Ongoing |

---

## Recommendation 1 — Reduce Biometric KYC Friction

**Data signal:** The largest single funnel drop-off occurs at `kyc_biometric_done → kyc_approved`, with High-risk band users converting at roughly half the rate of Low-risk users.

**Intervention:**
- Implement in-app guided biometric capture with real-time quality feedback (e.g., “Move to better lighting”)
- Add a “try again in 24 hours” re-engagement push for users who fail biometrics on first attempt
- Introduce async document review for edge-case high-risk users rather than auto-rejection

**Target metric:** Increase `kyc_biometric_done → kyc_approved` conversion rate by 8–12 percentage points.

**Owner:** Product (Onboarding squad) + Compliance

---

## Recommendation 2 — Post-KYC Funding Nudge Sequence

**Data signal:** Users who pass KYC but do not top up within 72 hours have dramatically lower 30-day retention. This cliff represents a recoverable cohort — they’ve invested in KYC but haven’t yet formed a usage habit.

**Intervention:**
- Trigger a 3-step push/email sequence: T+1h (welcome + first top-up CTA), T+24h (social proof: “X people topped up today”), T+72h (incentive: e.g., fee-free first FX exchange on funding)
- For High-risk band users: route to a “KYC approved — what’s next” in-app walkthrough immediately post-approval

**Target metric:** Increase `kyc_approved → first_top_up` conversion by 10 percentage points within 72 hours.

**Owner:** Growth / CRM

---

## Recommendation 3 — First-30-Day SLA Escalation Fast Lane

**Data signal:** Users with a High/Critical severity SLA breach in the first 30 days show 30–40% lower 90-day retention. Users whose tickets were resolved within SLA retain almost as well as users with no ticket at all. The intervention is **speed of resolution**, not suppression of ticket volume.

**Intervention:**
- Create a dedicated “New User Critical” queue in the support tool that auto-prioritises tickets from users with account age ≤ 30 days and severity = High or Critical
- Set a tighter SLA for this cohort: 2-hour first response vs the standard 4-hour threshold
- Track CSAT for this cohort as a leading indicator in the weekly ops review

**Target metric:** Reduce SLA breach rate for new-user High/Critical tickets by 50%; measure uplift in 90-day retention for affected cohort.

**Owner:** Customer Operations + Product (Support tooling)

---

## Recommendation 4 — Feature-Nudge Onboarding for Standard Users

**Data signal:** Standard users who adopt ≥3 features by M1 retain at rates comparable to Premium users. The majority of Standard users adopt ≤1 feature and follow the steep decay curve.

**Intervention:**
- Build a “Explore Revolut” in-app checklist surfaced after first card payment: (1) Send £10 to a friend, (2) Exchange currency, (3) Create a savings vault
- Gamify with a progress indicator and a milestone reward (e.g., one month of Revolut Plus free)
- Trigger the checklist only for Standard users who have made ≥1 payment but haven’t adopted P2P or FX

**Target metric:** Increase avg features adopted by Standard users in M0 from ~1.2 to ~2.5; measure M3 retention uplift.

**Owner:** Product (Growth / Activation squad)

---

## Recommendation 5 — TravelFX Off-Season Re-engagement

**Data signal:** TravelFX-primary cohorts show a clear retention dip at W8–W16, corresponding to post-holiday deactivation. Users who adopted a second use case do not show this dip.

**Intervention:**
- Segment TravelFX-primary users who have not transacted in 21+ days and send a personalised re-engagement email: “You saved £X on FX — here’s what else Revolut can do for everyday life”
- Surface a savings vault creation prompt in-app for dormant TravelFX users (savings is the highest cross-use-case adoption path for this cohort)

**Target metric:** Recover 15% of TravelFX-primary dormant users to at least one transaction within 30 days of campaign.

**Owner:** CRM / Marketing

---

## Recommendation 6 — Increase Referral Channel Investment

**Data signal:** Referral-acquired users show the highest KYC approval rate, lowest time-to-first-payment, and highest M3 retention of any acquisition channel. Paid-social delivers high install volume but the weakest downstream quality metrics.

**Intervention:**
- Rebalance UA budget: reduce paid-social spend by 10–15%; redeploy into referral programme incentives (both referrer and referee)
- A/B test referral reward timing: immediate reward vs milestone-based (reward unlocks after referee makes first payment)
- Build a referral leaderboard for Premium/Metal users who refer frequently — these users have the strongest networks and highest LTV

**Target metric:** Increase referral channel share of new activations from current baseline; measure blended CAC vs LTV across channels at 6-month horizon.

**Owner:** Growth / Finance
