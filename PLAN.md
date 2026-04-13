# PLAN.md — Role Radar

## Read this first. Pick one unchecked task. Do nothing else.

---

## Rules for Claude Code

- Never start coding without reading CLAUDE.md first
- Pick the next unchecked task in the current phase
- Do not skip phases
- Do not work on two tasks at once
- Mark task done with [x] only after user confirms it works
- Every task ends with a git commit

---

## Phase 1 — Foundation
Goal: Next.js app running locally with Supabase connected.

- [ ] Install Next.js with TypeScript and Tailwind
- [ ] Install dependencies: @supabase/supabase-js @supabase/auth-helpers-nextjs
- [ ] Create src/db/client.ts — Supabase singleton, max 30 lines
- [ ] Create supabase/migrations/001_schema.sql — all 5 tables
- [ ] Run schema in Supabase dashboard and confirm tables exist
- [ ] Create .env.example with all variable names
- [ ] Confirm app runs with: npm run dev

---

## Phase 2 — Auth
Goal: User can log in via magic link and get redirected to feed.

- [ ] Configure Resend in Supabase dashboard as SMTP provider
- [ ] Create app/login/page.tsx — email input only, max 80 lines
- [ ] Create app/api/auth/callback/route.ts — handles magic link redirect
- [ ] Add middleware.ts — redirects unauthenticated users to /login
- [ ] Test: enter email, receive link, click it, land on feed

---

## Phase 3 — Job fetching
Goal: Real jobs from all 5 sources saved to database.

- [ ] Create src/scrapers/greenhouse.ts — fetches and returns jobs array
- [ ] Create src/scrapers/lever.ts
- [ ] Create src/scrapers/ashby.ts
- [ ] Create src/scrapers/workable.ts
- [ ] Create src/scrapers/smartrecruiters.ts
- [ ] Create src/jobs/filter.ts — applies role keyword rules
- [ ] Create src/jobs/dedup.ts — skips job IDs already in DB
- [ ] Create app/api/jobs/route.ts — runs all scrapers, saves to DB
- [ ] Test: call /api/jobs and confirm jobs appear in Supabase table

---

## Phase 4 — Job feed UI
Goal: User sees a list of jobs and can click into a detail page.

- [ ] Create app/page.tsx — fetches jobs from DB, renders list
- [ ] Each job card shows: title, company, location, source, posted date
- [ ] Create app/job/[id]/page.tsx — two panel layout
- [ ] Left panel: full job detail (title, company, description)
- [ ] Right panel: placeholder for rewrite feature (Phase 6)
- [ ] Test: jobs appear on feed, clicking opens detail page

---

## Phase 5 — Application tracking
Goal: User can move any job through Saved, Applied, Interviewing.

- [ ] Create app/api/track/route.ts — saves status to applications table
- [ ] Add three status buttons to job/[id]/page.tsx right panel
- [ ] Buttons show current state, clicking advances to next state
- [ ] Create app/tracker/page.tsx — three columns, jobs grouped by status
- [ ] Test: click saved on a job, check tracker page shows it

---

## Phase 6 — AI rewrite
Goal: User pastes a bullet, gets a rewritten version using their resume context.

- [ ] Create src/ai/prompts.ts — system prompt string only, max 40 lines
- [ ] Create src/lib/ratelimit.ts — checks and updates daily usage counter
- [ ] Create src/ai/rewrite.ts — calls Claude with prompt and context
- [ ] Create app/api/rewrite/route.ts — checks limit, calls rewrite, logs usage
- [ ] Wire up right panel in job/[id]/page.tsx — textarea input and output
- [ ] Test: paste a weak bullet, confirm rewrite comes back strong

---

## Phase 7 — User profile and PDF resume
Goal: User uploads PDF once, resume context used in all future rewrites.

- [ ] Install pdf-parse package
- [ ] Create src/lib/pdf.ts — extracts text from PDF buffer, max 60 lines
- [ ] Create app/api/profile/route.ts — receives PDF, parses, saves to profiles table
- [ ] Create app/profile/page.tsx — name, current role, target role, PDF upload button
- [ ] Update src/ai/rewrite.ts — fetch resume_text from profile and pass to Claude
- [ ] Test: upload PDF, trigger rewrite, confirm resume context improves output

---

## Phase 8 — Admin dashboard
Goal: Owner can monitor jobs, usage, spend, and rate limiter in one page.

- [ ] Create app/api/admin/stats/route.ts — protected by ADMIN_EMAIL, returns stats
- [ ] Create app/admin/page.tsx — displays all stats, max 200 lines
- [ ] Stats shown: jobs by source today, Claude calls today and month, estimated spend, active users, rate limit status
- [ ] Test: visit /admin as owner email, confirm real numbers show

---

## Phase 9 — Deploy
Goal: App live on Vercel, cron job running automatically.

- [ ] Push all code to GitHub
- [ ] Connect repo to Vercel
- [ ] Add all env vars in Vercel dashboard
- [ ] Add Vercel cron job in vercel.json to hit /api/jobs every 6 hours
- [ ] Test: trigger cron manually, confirm jobs appear in production DB

---

## Current phase: Phase 1 — start here