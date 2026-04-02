#!/usr/bin/env python3
"""
generate_data.py — Revolut-style Synthetic Dataset Generator
=============================================================
Run this script once to generate all 4 CSV files used in the
Funnel & Cohort Analysis project.

Usage:
    pip install pandas numpy
    python data/generate_data.py

Output (written to ./data/):
    revolut_users.csv            — 20,000 synthetic users
    revolut_events.csv           — ~60,000 onboarding + usage events
    revolut_support_tickets.csv  — ~8,000 support tickets
    revolut_date_dim.csv         — 366-row date dimension (2024)
"""

import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta
import os

random.seed(42)
np.random.seed(42)

# ── CONFIG ─────────────────────────────────────────────────────────────────────
N_USERS    = 20_000
START_DATE = datetime(2024, 1, 1)
END_DATE   = datetime(2024, 12, 31)

COUNTRIES  = ['GB','DE','FR','PL','RO','NL','ES','IT','SE','IE']
COUNTRY_W  = [0.25,0.15,0.12,0.10,0.08,0.08,0.07,0.06,0.05,0.04]
CHANNELS   = ['paid_social','organic_search','referral','app_store','direct']
CHANNEL_W  = [0.30,0.25,0.20,0.15,0.10]
DEVICES    = ['ios','android']
DEVICE_W   = [0.55,0.45]
PLANS      = ['Standard','Plus','Premium','Metal']
PLAN_W     = [0.60,0.20,0.12,0.08]
RISK_BANDS = ['low','medium','high']
RISK_W     = [0.65,0.25,0.10]
USE_CASES  = ['everyday_spend','travel_fx','p2p_only','savings','trading']
USE_CASE_W = [0.35,0.25,0.20,0.12,0.08]

FUNNEL_STEPS = [
    'install_app','start_registration','kyc_document_uploaded',
    'kyc_biometric_done','kyc_approved','first_top_up',
    'card_issued','card_activated','first_card_payment'
]
STEP_CONV = [1.0, 0.82, 0.71, 0.63, 0.55, 0.48, 0.47, 0.44, 0.40]

USAGE_EVENTS = [
    'p2p_payment_sent','p2p_payment_received','fx_exchange',
    'international_transfer','created_savings_vault','started_trading',
    'upgraded_plan','downgraded_plan','session_active'
]

TICKET_CATEGORIES = [
    'kyc_issue','card_decline','chargeback','fx_issue',
    'app_bug','account_locked','transfer_failed','general_query'
]
CAT_W = [0.22,0.20,0.10,0.10,0.15,0.08,0.10,0.05]


def rand_date(start, end):
    return start + timedelta(
        seconds=random.randint(0, int((end - start).total_seconds()))
    )


def generate_users():
    signup_dates = [rand_date(START_DATE, END_DATE) for _ in range(N_USERS)]
    return pd.DataFrame({
        'user_id':             [f'U{i:06d}' for i in range(1, N_USERS + 1)],
        'signup_date':         [d.strftime('%Y-%m-%d') for d in signup_dates],
        'signup_week':         [d.strftime('%Y-W%W') for d in signup_dates],
        'signup_month':        [d.strftime('%Y-%m') for d in signup_dates],
        'country':             random.choices(COUNTRIES, weights=COUNTRY_W, k=N_USERS),
        'region':              np.random.choice(['EEA','UK','Other'], N_USERS, p=[0.60,0.28,0.12]),
        'acquisition_channel': random.choices(CHANNELS, weights=CHANNEL_W, k=N_USERS),
        'device_type':         random.choices(DEVICES, weights=DEVICE_W, k=N_USERS),
        'plan_at_signup':      random.choices(PLANS, weights=PLAN_W, k=N_USERS),
        'kyc_risk_band':       random.choices(RISK_BANDS, weights=RISK_W, k=N_USERS),
        'primary_use_case':    random.choices(USE_CASES, weights=USE_CASE_W, k=N_USERS),
    })


def generate_events(users):
    rows = []
    for _, u in users.iterrows():
        uid    = u['user_id']
        signup = datetime.strptime(u['signup_date'], '%Y-%m-%d')
        risk   = u['kyc_risk_band']
        plan   = u['plan_at_signup']
        uc     = u['primary_use_case']
        risk_mod = {'low': 1.0, 'medium': 0.90, 'high': 0.72}[risk]

        t = signup
        reached_payment = False
        for i, step in enumerate(FUNNEL_STEPS):
            conv = STEP_CONV[i] * (risk_mod if i >= 2 else 1.0)
            if i > 0 and random.random() > conv:
                break
            offset = random.randint(0, 48) if i == 0 else random.randint(1, 72)
            t = t + timedelta(hours=offset)
            if t > END_DATE:
                break
            rows.append({'user_id': uid, 'event_type': step,
                         'event_date': t.strftime('%Y-%m-%d'),
                         'event_ts':   t.strftime('%Y-%m-%d %H:%M:%S')})
            if step == 'first_card_payment':
                reached_payment = True

        if reached_payment:
            n_sessions = max(1, int(np.random.poisson(
                {'Standard':8,'Plus':14,'Premium':22,'Metal':30}[plan]
            )))
            for _ in range(n_sessions):
                evt_date = t + timedelta(days=random.randint(1, 365))
                if evt_date > END_DATE:
                    break
                pool = {
                    'travel_fx':     ['fx_exchange','international_transfer','session_active','first_card_payment'],
                    'p2p_only':      ['p2p_payment_sent','p2p_payment_received','session_active'],
                    'savings':       ['created_savings_vault','session_active','p2p_payment_sent'],
                    'trading':       ['started_trading','session_active','fx_exchange'],
                    'everyday_spend': USAGE_EVENTS[:6],
                }.get(uc, USAGE_EVENTS[:6])
                rows.append({'user_id': uid, 'event_type': random.choice(pool),
                             'event_date': evt_date.strftime('%Y-%m-%d'),
                             'event_ts':   evt_date.strftime('%Y-%m-%d %H:%M:%S')})

    df = pd.DataFrame(rows).sort_values(['user_id','event_ts']).reset_index(drop=True)
    df.insert(0, 'event_id', [f'E{i:08d}' for i in range(1, len(df) + 1)])
    return df


def generate_support(events):
    ticketed = events[events['event_type']=='start_registration']['user_id'].tolist()
    ticket_users = random.sample(ticketed, int(len(ticketed) * 0.35))
    rows = []
    for uid in ticket_users:
        for _ in range(random.choices([1,2,3], weights=[0.65,0.25,0.10])[0]):
            created = rand_date(START_DATE, END_DATE)
            sev     = random.choices(['P1','P2','P3'], weights=[0.15,0.45,0.40])[0]
            sla_h   = {'P1':4,'P2':24,'P3':72}[sev]
            res_h   = max(1, int(np.random.exponential(sla_h * 0.9)))
            within  = res_h <= sla_h
            csat    = None
            if random.random() < 0.60:
                base = random.choices([1,2,3,4,5],[0.05,0.10,0.15,0.35,0.35])[0]
                csat = max(1, base - (random.randint(1,2) if not within else 0))
            rows.append({
                'ticket_id':           f'T{len(rows)+1:07d}',
                'user_id':             uid,
                'created_date':        created.strftime('%Y-%m-%d'),
                'category':            random.choices(TICKET_CATEGORIES, weights=CAT_W)[0],
                'severity':            sev,
                'resolution_hours':    res_h,
                'sla_target_hours':    sla_h,
                'resolved_within_sla': int(within),
                'csat_score':          csat,
            })
    return pd.DataFrame(rows)


def generate_date_dim():
    dates = pd.date_range('2024-01-01','2024-12-31')
    return pd.DataFrame({
        'date':        [d.strftime('%Y-%m-%d') for d in dates],
        'year':        [d.year for d in dates],
        'month':       [d.month for d in dates],
        'month_name':  [d.strftime('%B') for d in dates],
        'week':        [d.isocalendar().week for d in dates],
        'week_label':  [d.strftime('%Y-W%W') for d in dates],
        'quarter':     [f'Q{(d.month-1)//3+1}' for d in dates],
        'day_of_week': [d.strftime('%A') for d in dates],
        'is_weekend':  [int(d.weekday()>=5) for d in dates],
    })


if __name__ == '__main__':
    out = os.path.dirname(os.path.abspath(__file__))
    print('Generating users...')
    u = generate_users()
    u.to_csv(os.path.join(out, 'revolut_users.csv'), index=False)
    print(f'  revolut_users.csv — {len(u):,} rows')

    print('Generating events...')
    e = generate_events(u)
    e.to_csv(os.path.join(out, 'revolut_events.csv'), index=False)
    print(f'  revolut_events.csv — {len(e):,} rows')

    print('Generating support tickets...')
    s = generate_support(e)
    s.to_csv(os.path.join(out, 'revolut_support_tickets.csv'), index=False)
    print(f'  revolut_support_tickets.csv — {len(s):,} rows')

    print('Generating date dimension...')
    d = generate_date_dim()
    d.to_csv(os.path.join(out, 'revolut_date_dim.csv'), index=False)
    print(f'  revolut_date_dim.csv — {len(d):,} rows')

    print('\nDone! All 4 CSV files written to:', out)
