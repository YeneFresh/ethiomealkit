-- User week status tracking
-- Tracks user engagement and meal planning by week

create table if not exists public.user_week_status (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  week_start_date date not null,
  status text not null default 'active', -- active, paused, cancelled
  meals_selected int default 0,
  box_locked_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  
  -- Ensure one record per user per week
  unique(user_id, week_start_date)
);

-- Enable RLS
alter table public.user_week_status enable row level security;

-- RLS policies
create policy "Users can view own week status" on public.user_week_status
  for select using (auth.uid() = user_id);

create policy "Users can update own week status" on public.user_week_status
  for all using (auth.uid() = user_id);

-- Indexes for performance
create index if not exists idx_user_week_status_user_date 
  on public.user_week_status(user_id, week_start_date);

create index if not exists idx_user_week_status_week_start 
  on public.user_week_status(week_start_date);

-- Function to get current week start (Monday)
create or replace function public.current_week_start()
returns date as $$
begin
  return date_trunc('week', current_date)::date;
end;
$$ language plpgsql immutable;