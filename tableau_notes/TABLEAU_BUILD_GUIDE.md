# Tableau Dashboard Build Guide
## Revolut-Style Funnel & Cohort Analysis

---

## 1. Data Source Setup

### Connect the 4 CSVs as separate data sources:

| File | Role in Tableau |
|---|---|
| `revolut_users.csv` | Primary — drag to canvas first |
| `revolut_events.csv` | Join to users on `user_id` |
| `revolut_support_tickets.csv` | Join to users on `user_id` |
| `revolut_date_dim.csv` | Blend on `event_date = date` for calendar filters |

### Relationship setup (Data Model tab):
- **users ↔ events** : `users.user_id = events.user_id` (1:Many)
- **users ↔ support_tickets** : `users.user_id = support_tickets.user_id` (1:Many)
- Do NOT join events and support directly — keep them as separate logical tables.

---

## 2. Calculated Fields

### Funnel Step Number (for ordering)
```
// Field name: Funnel Step Order
CASE [Event Type]
  WHEN 'install_app'             THEN 1
  WHEN 'start_registration'      THEN 2
  WHEN 'kyc_document_uploaded'   THEN 3
  WHEN 'kyc_biometric_done'      THEN 4
  WHEN 'kyc_approved'            THEN 5
  WHEN 'first_top_up'            THEN 6
  WHEN 'card_issued'             THEN 7
  WHEN 'card_activated'          THEN 8
  WHEN 'first_card_payment'      THEN 9
  ELSE 99
END
```

### Users Reaching Each Step
```
// Field name: Users at Step
COUNTD(IF [Funnel Step Order] <= WINDOW_MAX(MAX([Funnel Step Order])) THEN [User Id] END)
```

### Step Conversion Rate (%)
```
// Field name: Step Conversion %
SUM([Users Reaching Step]) / LOOKUP(SUM([Users Reaching Step]), -1)
```

### Cohort Week Number
```
// Field name: Weeks Since Signup
DATEDIFF('week',
  {FIXED [User Id] : MIN(IF [Event Type] = 'install_app' THEN [Event Date] END)},
  [Event Date]
)
```

### Monthly Cohort Number
```
// Field name: Months Since Signup
DATEDIFF('month',
  {FIXED [User Id] : MIN(IF [Event Type] = 'install_app' THEN [Event Date] END)},
  [Event Date]
)
```

### Active User Flag
```
// Field name: Is Active
[Event Type] IN (
  'first_card_payment','p2p_payment_sent','fx_exchange',
  'international_transfer','created_savings_vault','started_trading'
)
```

### Cohort Size (FIXED LOD)
```
// Field name: Cohort Size
{FIXED [Signup Month] : COUNTD([User Id])}
```

### Retention Rate %
```
// Field name: Retention Rate %
COUNTD(IF [Is Active] THEN [User Id] END) / [Cohort Size]
```

### SLA Breach Flag
```
// Field name: SLA Breached
[Resolved Within Sla] = 0
```

### Days to First Payment
```
// Field name: Days to First Payment
DATEDIFF('day',
  {FIXED [User Id] : MIN(IF [Event Type] = 'install_app' THEN [Event Date] END)},
  {FIXED [User Id] : MIN(IF [Event Type] = 'first_card_payment' THEN [Event Date] END)}
)
```

---

## 3. Dashboard Sheets — 8 Sheets

### Sheet 1: Onboarding Funnel Bar Chart
- **Rows**: `Funnel Step Order` (discrete), `Event Type`
- **Columns**: `COUNTD(User Id)`
- **Mark type**: Bar
- **Color**: Revolut teal `#00B9C6` — faded bars for low-conversion steps
- **Label**: Show `Step Conversion %` on each bar
- **Filter**: `Funnel Step Order <= 9`

### Sheet 2: Funnel Drop-Off % by Segment
- **Rows**: `Acquisition Channel` (swap via Parameter)
- **Columns**: `Step Conversion %`
- **Mark type**: Heatmap / Text table
- **Color**: Diverging — red (low) to green (high)
- **Segment Parameter**: Switch between `acquisition_channel`, `country`, `kyc_risk_band`, `plan_at_signup`

### Sheet 3: Weekly Cohort Retention Heatmap
- **Rows**: `Signup Week` (discrete, sorted ASC)
- **Columns**: `Weeks Since Signup` (0–25)
- **Mark type**: Square
- **Color**: Sequential teal
- **Text**: Show retention % inside each cell

### Sheet 4: Monthly Cohort Retention by Plan Tier
- **Rows**: `Plan At Signup`
- **Columns**: `Months Since Signup` (0–11)
- **Mark type**: Square heatmap
- **Tooltip**: Show cohort size + retained count + %

### Sheet 5: Retention Curves (Line)
- **Rows**: `Retention Rate %`
- **Columns**: `Weeks Since Signup`
- **Mark type**: Line
- **Color**: `Plan At Signup` (4 lines)
- **Reference Line**: Average retention at Week 4 and Week 12

### Sheet 6: Feature Adoption Funnel (Post-Activation)
- **Rows**: Feature step order (card → P2P → FX → vault → trading)
- **Columns**: `COUNTD(User Id)` reaching each feature
- **Mark type**: Bar (horizontal)

### Sheet 7: SLA Impact on Retention
- **Rows**: `SLA Breached` (True / False)
- **Columns**: 30d retention %, 90d retention %
- **Mark type**: Bar with reference line
- **Color**: Red (breached) vs Teal (within SLA)

### Sheet 8: Plan ARPU & Engagement Depth
- **Rows**: `Plan At Signup`
- **Columns**: `AVG(transaction_count)`, `AVG(feature_count_adopted)`
- **Mark type**: Bar + Circle (dual axis)

---

## 4. Dashboard Layout (1366 × 768 px)

```
┌─────────────────────────────────────────────────────────────────────────┐
│  HEADER: Revolut-Style User Funnel & Cohort Analysis    [Filter Bar]   │
│  Filters: Region | Plan Tier | Channel | Risk Band | Date Range         │
├────────────────────────┬────────────────────────────────────────────────┤
│  Sheet 1               │  Sheet 3                                       │
│  Onboarding Funnel     │  Weekly Cohort Heatmap (W0–W25)                │
├────────────────────────┼────────────────────────────────────────────────┤
│  Sheet 5               │  Sheet 7                                       │
│  Retention Curves      │  SLA Impact on Retention                       │
├────────────────────────┴────────────────────────────────────────────────┤
│  KEY INSIGHT CALLOUTS (text objects)                                    │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Colour Palette (Revolut-Inspired)

| Purpose | Hex | Usage |
|---|---|---|
| Primary teal | `#00B9C6` | Main bars, primary lines |
| Deep teal | `#0075A3` | Headers, dark accents |
| Coral/alert | `#E84855` | SLA breach, drop-off highlight |
| Warm amber | `#F4A621` | Mid-tier metrics |
| Neutral grey | `#F7F7F7` | Background surfaces |
| Text dark | `#1A1A2E` | All labels |

---

## 6. Parameters

| Parameter Name | Type | Values | Used In |
|---|---|---|---|
| `Segment Dimension` | String | channel, country, risk_band, plan | Sheet 2 |
| `Cohort Grain` | String | Weekly, Monthly | Sheets 3 & 4 |
| `Retention Window` | Integer | 1–12 (months) | Sheet 4 KPI |
| `Funnel Filter` | String | All, KYC only, Post-activation | Sheet 1 |

---

## 7. Global Filters (Apply to All Worksheets)

1. `Region` — EEA / UK / Other
2. `Plan At Signup` — Standard / Plus / Premium / Metal
3. `Acquisition Channel`
4. `KYC Risk Band` — low / medium / high
5. `Signup Month` (date range slider)

---

## 8. Dashboard Actions

| Action | Trigger | Source Sheet | Target Sheet |
|---|---|---|---|
| Filter by cohort | Click heatmap row | Sheet 3 | Sheet 5 |
| Highlight plan tier | Click legend | Sheet 5 | Sheet 8 |
| Show ticket detail | Hover SLA bar | Sheet 7 | Tooltip |

---

## 9. Publishing Checklist

- [ ] Tooltips enabled and formatted on every sheet
- [ ] Every calculated field has an explanatory comment
- [ ] Dashboard title includes "Synthetic Data — Revolut-Inspired"
- [ ] README link added to dashboard description
- [ ] Workbook saved as `.twbx` (packaged with extract)
- [ ] PDF export of finished dashboard added to `/docs/`
