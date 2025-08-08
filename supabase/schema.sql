-- Core schema for Ethio Meal Kit
-- NOTE: Apply in Supabase SQL editor or via CLI after linking project

create table if not exists public.users_profile (
  id uuid primary key references auth.users on delete cascade,
  name text,
  phone text,
  created_at timestamp with time zone default now()
);

create table if not exists public.address (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  label text,
  line1 text not null,
  line2 text,
  city text,
  region text,
  latitude double precision,
  longitude double precision,
  instructions text,
  is_default boolean default false
);

create table if not exists public.subscription (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  meals_per_week int not null check (meals_per_week in (3,5,7)),
  auto_select boolean default true,
  delivery_window text,
  active boolean default true,
  preferences jsonb default '{}',
  cutoff_day text default 'Friday'
);

create table if not exists public.meal (
  id uuid primary key default gen_random_uuid(),
  slug text unique,
  title text not null,
  cuisine text,
  difficulty text,
  calories int,
  protein int,
  carbs int,
  fat int,
  cook_time_minutes int,
  price_cents int not null,
  is_veggie boolean default false,
  is_pescatarian boolean default false,
  has_beef boolean default false,
  has_fish boolean default false,
  has_shellfish boolean default false,
  tags text[] default '{}'
);

create table if not exists public.weekly_plan (
  id uuid primary key default gen_random_uuid(),
  subscription_id uuid not null references public.subscription(id) on delete cascade,
  week_start date not null,
  generated boolean default false,
  locked boolean default false
);

create unique index if not exists unique_plan_per_week on public.weekly_plan(subscription_id, week_start);

create table if not exists public.plan_item (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.weekly_plan(id) on delete cascade,
  meal_id uuid not null references public.meal(id),
  category text,
  swap_deadline timestamp with time zone
);

create table if not exists public.order (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete set null,
  address_id uuid references public.address(id),
  plan_id uuid references public.weekly_plan(id),
  status text default 'pending',
  delivery_date date,
  window text,
  total_cents int default 0
);

create table if not exists public.order_item (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.order(id) on delete cascade,
  meal_id uuid not null references public.meal(id),
  qty int not null default 1,
  unit_price_cents int not null
);

create table if not exists public.meal_rating (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  meal_id uuid not null references public.meal(id),
  order_id uuid references public.order(id),
  stars int check (stars between 1 and 5),
  comment text,
  created_at timestamp with time zone default now()
);

create table if not exists public.reward_transaction (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users_profile(id) on delete cascade,
  type text not null,
  points int not null,
  order_id uuid references public.order(id),
  created_at timestamp with time zone default now()
);

-- Basic RLS
alter table public.users_profile enable row level security;
alter table public.address enable row level security;
alter table public.subscription enable row level security;
alter table public.weekly_plan enable row level security;
alter table public.plan_item enable row level security;
alter table public.order enable row level security;
alter table public.order_item enable row level security;
alter table public.meal_rating enable row level security;
alter table public.reward_transaction enable row level security;

create policy if not exists "Users can manage own profile" on public.users_profile
  for all using (id = auth.uid()) with check (id = auth.uid());

create policy if not exists "Users own data" on public.address
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy if not exists "Users own subs" on public.subscription
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy if not exists "Users own plans" on public.weekly_plan
  for select using (
    exists (
      select 1 from public.subscription s where s.id = weekly_plan.subscription_id and s.user_id = auth.uid()
    )
  );

create policy if not exists "Users own plan items" on public.plan_item
  for select using (
    exists (
      select 1 from public.weekly_plan p join public.subscription s on p.subscription_id = s.id
      where p.id = plan_item.plan_id and s.user_id = auth.uid()
    )
  );

create policy if not exists "Users own orders" on public.order
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy if not exists "Users own order items" on public.order_item
  for select using (
    exists (
      select 1 from public.order o where o.id = order_item.order_id and o.user_id = auth.uid()
    )
  );

create policy if not exists "Users own ratings" on public.meal_rating
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy if not exists "Users own rewards" on public.reward_transaction
  for select using (user_id = auth.uid());


