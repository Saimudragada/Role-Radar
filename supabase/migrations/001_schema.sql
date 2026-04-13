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

create table applications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  job_id text references jobs(id) not null,
  status text check (status in ('saved','applied','interviewing')) default 'saved',
  updated_at timestamptz default now(),
  unique(user_id, job_id)
);

create table profiles (
  id uuid primary key references auth.users,
  name text,
  current_job_role text,
  target_role text,
  resume_text text,
  updated_at timestamptz default now()
);

create table rewrites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users,
  job_id text references jobs(id),
  original text not null,
  rewritten text not null,
  created_at timestamptz default now()
);

create table usage (
  id uuid primary key default gen_random_uuid(),
  event_type text not null,
  user_id uuid references auth.users,
  metadata jsonb,
  created_at timestamptz default now()
);