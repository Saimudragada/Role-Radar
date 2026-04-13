# CLAUDE.md — Role Radar

## Read this before writing any code. No exceptions.

---

## Working process — mandatory

1. Read PLAN.md, state current phase and task
2. State your plan in plain English (3-5 lines max)
3. List every file you will touch
4. List assumptions
5. Write code only after steps 1-4
6. Tell user what to run or click to test
7. End every task with: git add . && git commit -m "message"

Rules:
- One task at a time, never combine
- No file longer than 600 lines — split into smaller files if needed
- One responsibility per file
- Never create files outside the folder structure
- Never install a package without saying why
- Never refactor code that was not part of the task
- Never guess — ask if unclear

---

## App summary

Role Radar fetches jobs posted in last 48 hours from 5 ATS portals,
filters to data/software/AI roles, lets users track application status,
upload a resume PDF, and rewrite bullets with AI.
Hard cost cap: $40/month.

---

## Tech stack

| Layer | Tool |
|---|---|
| Framework | Next.js 14 App Router |
| Language | TypeScript only |
| Database | Supabase |
| Auth | Supabase magic link + Resend |
| AI | claude-haiku-3 only |
| PDF | pdf-parse (server side) |
| Styling | Tailwind CSS only |
| Hosting | Vercel |

---

## Folder structure
role-radar/
├── src/
│   ├── scrapers/
│   │   ├── greenhouse.ts      (one ATS per file)
│   │   ├── lever.ts
│   │   ├── ashby.ts
│   │   ├── workable.ts
│   │   └── smartrecruiters.ts
│   ├── jobs/
│   │   ├── filter.ts          (role keyword filtering)
│   │   └── dedup.ts           (prevent duplicate jobs)
│   ├── ai/
│   │   ├── rewrite.ts         (Claude API call only)
│   │   └── prompts.ts         (all prompt strings live here)
│   ├── lib/
│   │   ├── ratelimit.ts       (daily Claude call counter)
│   │   └── pdf.ts             (PDF parse logic)
│   ├── email/
│   │   └── magic-link.ts
│   └── db/
│       ├── client.ts          (Supabase singleton)
│       └── queries.ts         (all DB queries)
├── app/
│   ├── page.tsx               (job feed)
│   ├── login/page.tsx
│   ├── job/[id]/page.tsx      (detail + rewrite panel)
│   ├── tracker/page.tsx       (Saved/Applied/Interviewing)
│   ├── profile/page.tsx       (name, role, PDF upload)
│   ├── admin/page.tsx         (owner dashboard)
│   └── api/
│       ├── jobs/route.ts
│       ├── rewrite/route.ts
│       ├── track/route.ts
│       ├── profile/route.ts
│       └── admin/stats/route.ts
├── supabase/
│   └── migrations/
│       └── 001_schema.sql
├── companies.json
├── .env.example
├── .env.local                 (never touch this file)
├── CLAUDE.md
└── PLAN.md

---

## ATS endpoints
Greenhouse:
GET https://api.greenhouse.io/v1/boards/{slug}/jobs?content=true
Freshness: updated_at (ISO 8601) — include if >= 48h ago
Lever:
GET https://api.lever.co/v0/postings/{slug}?mode=json
Freshness: createdAt (Unix ms) — include if >= Date.now() - 172800000
Ashby:
GET https://api.ashbyhq.com/posting-api/job-board/{slug}
Freshness: publishedAt (ISO 8601)
Workable:
GET https://apply.workable.com/api/v1/widget/accounts/{slug}
Freshness: created_at — if missing, use job ID dedup
SmartRecruiters:
GET https://api.smartrecruiters.com/v1/companies/{slug}/postings?status=PUBLIC
Freshness: updatedOn — always pass updatedAfter query param

---

## Role filter rules

Include if title contains:
data engineer, analytics engineer, software engineer,
software developer, backend engineer, frontend engineer,
full stack, fullstack, ml engineer, machine learning,
ai engineer, llm engineer, mlops, data platform,
data infrastructure

Exclude if title contains:
analyst, manager, director, vp, recruiter,
designer, product manager, pm, sales, marketing

---

## Database tables

```sql
-- jobs cache
create table jobs (
  id text primary key,
  source text not null,
  title text not null,
  company text not null,
  location text,
  url text not null,
  description text,
  posted_at timestamptz,
  fetched_at timestamptz default now()
);

-- application status per user
create table applications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  job_id text references jobs(id) not null,
  status text check (status in ('saved','applied','interviewing')) default 'saved',
  updated_at timestamptz default now(),
  unique(user_id, job_id)
);

-- user profiles
create table profiles (
  id uuid primary key references auth.users,
  name text,
  current_role text,
  target_role text,
  resume_text text,
  updated_at timestamptz default now()
);

-- rewrite history
create table rewrites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users,
  job_id text references jobs(id),
  original text not null,
  rewritten text not null,
  created_at timestamptz default now()
);

-- usage tracking for rate limit and admin
create table usage (
  id uuid primary key default gen_random_uuid(),
  event_type text not null,
  user_id uuid references auth.users,
  metadata jsonb,
  created_at timestamptz default now()
);
```

---

## Rate limiter

- Max 600 Claude calls per day across all users
- This keeps spend under $40/month
- Logic lives in src/lib/ratelimit.ts only
- Every call to /api/rewrite must check ratelimit.ts first
- If limit hit: return 429, message "Daily limit reached, resets midnight UTC"
- After successful call: insert row into usage table

---

## PDF resume flow

- User uploads PDF on profile page
- /api/profile/route.ts receives file
- src/lib/pdf.ts parses it using pdf-parse
- Extracted text saved to profiles.resume_text
- On rewrite: resume_text passed to Claude as context
- If no resume uploaded: rewrite still works without it

---

## AI rewrite rules

Model: claude-haiku-3
Max tokens: 150
Temperature: 0.3
Prompt lives in: src/ai/prompts.ts

Formula: Result + Metric + Context

System prompt:
Rewrite this resume bullet using: Result + Metric + Context.
Start with: Led, Built, Drove, Launched, Reduced, Increased, Designed, or Owned.
Include a specific number or percentage.
Keep under 20 words.
No passive voice.
No words: leveraged, utilized, spearheaded.
Return only the rewritten bullet. No explanation.

When available, append to user message:
- Target role from profile
- Relevant keywords from job description

---

## Admin dashboard

Protected by ADMIN_EMAIL env var.
If logged in user email != ADMIN_EMAIL, return 403.

Show:
- Jobs fetched today by source
- Claude calls today and this month
- Estimated spend (calls x $0.000263)
- Active users last 7 days
- Rate limiter: X of 600 used today

---

## Application tracking

Three states only: saved → applied → interviewing
One button per state on job detail page.
State saved to applications table.
Tracker page groups jobs by state.

---

## Environment variables
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
ANTHROPIC_API_KEY
RESEND_API_KEY
ADMIN_EMAIL
SERPER_API_KEY  (phase 2 only)

---

## Do not build in v1

- No Workday scraping
- No email digests
- No search or filters
- No payments
- No file formats other than PDF
- No animations or transitions