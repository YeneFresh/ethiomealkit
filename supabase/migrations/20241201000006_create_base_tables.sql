-- Base tables migration for EthioMealKit
-- Creates core tables: users, addresses, recipes, meal_kits, delivery_windows, orders

-- Ensure uuid generation
create extension if not exists pgcrypto;

-- Users profile referencing auth.users
create table if not exists public.users (
  id uuid primary key references auth.users on delete cascade,
  name text,
  phone text,
  created_at timestamptz default now()
);

-- Addresses
create table if not exists public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
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

-- Base recipes table (will be enhanced in later migrations)
create table if not exists public.recipes (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  image_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Meal kits (what the app uses for MVP, seeded via tools/seed_meals.json)
create table if not exists public.meal_kits (
  id text primary key,
  title text not null,
  description text,
  price_cents int not null,
  image_url text,
  created_at timestamptz default now()
);

-- Delivery windows
create table if not exists public.delivery_windows (
  id uuid primary key default gen_random_uuid(),
  start_time time not null,
  end_time time not null,
  weekdays int[] not null -- array of 0-6 (Sunday-Saturday)
);

-- Orders
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id),
  delivery_address_id uuid references public.addresses(id),
  delivery_window_id uuid references public.delivery_windows(id),
  total_cents int not null,
  status text not null default 'pending',
  created_at timestamptz default now()
);

-- Order items
create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  meal_kit_id text not null references public.meal_kits(id),
  quantity int not null check (quantity > 0),
  price_cents int not null
);

-- Auth events (for tracking auth flow)
create table if not exists public.auth_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id),
  event_type text not null,
  event_data jsonb,
  created_at timestamptz default now()
);

-- Enable RLS on all tables
alter table public.users enable row level security;
alter table public.addresses enable row level security;
alter table public.recipes enable row level security;
alter table public.meal_kits enable row level security;
alter table public.delivery_windows enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.auth_events enable row level security;

-- Basic RLS policies
create policy "Users can view own profile" on public.users
  for select using (auth.uid() = id);

create policy "Users can update own profile" on public.users
  for update using (auth.uid() = id);

create policy "Users can view own addresses" on public.addresses
  for all using (auth.uid() = user_id);

create policy "Anyone can view meal kits" on public.meal_kits
  for select using (true);

create policy "Anyone can view delivery windows" on public.delivery_windows
  for select using (true);

create policy "Users can view own orders" on public.orders
  for select using (auth.uid() = user_id);

create policy "Users can view own order items" on public.order_items
  for select using (
    auth.uid() = (select user_id from public.orders where id = order_id)
  );