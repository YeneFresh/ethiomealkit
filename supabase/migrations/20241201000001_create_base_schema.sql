-- Create base schema from schema.sql
-- This creates the fundamental tables needed by the app

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
  is_default boolean default false,
  notes text
);

-- Meals (for browsing; public readable)
create table if not exists public.meals (
  id uuid primary key default gen_random_uuid(),
  slug text unique,
  title text not null,
  description text,
  price_cents int not null,
  image_url text
);

-- Meal kits (what the app uses for MVP)
create table if not exists public.meal_kits (
  id text primary key,
  title text not null,
  description text,
  price_cents int not null,
  image_url text
);

-- Cart table for storing user's cart items
create table if not exists public.cart (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  meal_kit_id text not null references public.meal_kits(id),
  quantity int not null check (quantity > 0),
  created_at timestamptz default now(),
  unique(user_id, meal_kit_id)
);

-- Delivery windows
create table if not exists public.delivery_windows (
  id text primary key,
  label text not null,
  day_of_week text,
  start_time text,
  end_time text
);

-- Orders
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  address_id uuid not null references public.addresses(id),
  delivery_window_id text references public.delivery_windows(id),
  status text not null default 'pending',
  total_cents int not null default 0,
  cash_on_delivery boolean default false,
  created_at timestamptz default now()
);

-- Order items
create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  meal_kit_id text not null references public.meal_kits(id),
  quantity int not null check (quantity > 0),
  unit_price_cents int not null
);

-- RLS
alter table public.users enable row level security;
alter table public.addresses enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.meals enable row level security;
alter table public.meal_kits enable row level security;
alter table public.cart enable row level security;

-- Users can manage their own profile
DROP POLICY IF EXISTS "own profile" ON public.users;
CREATE POLICY "own profile" ON public.users
  FOR ALL USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- Users own addresses
DROP POLICY IF EXISTS "own addresses" ON public.addresses;
CREATE POLICY "own addresses" ON public.addresses
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Users own cart items
DROP POLICY IF EXISTS "own cart items" ON public.cart;
CREATE POLICY "own cart items" ON public.cart
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Users own orders
DROP POLICY IF EXISTS "own orders" ON public.orders;
CREATE POLICY "own orders" ON public.orders
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Users can select their order items via their orders
DROP POLICY IF EXISTS "order items via own orders" ON public.order_items;
CREATE POLICY "order items via own orders" ON public.order_items
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.orders o WHERE o.id = order_items.order_id AND o.user_id = auth.uid())
  );

-- Public read policies for meals and meal_kits
DROP POLICY IF EXISTS "public read meals" ON public.meals;
CREATE POLICY "public read meals" ON public.meals FOR SELECT USING (true);

DROP POLICY IF EXISTS "public read meal_kits" ON public.meal_kits;
CREATE POLICY "public read meal_kits" ON public.meal_kits FOR SELECT USING (true);
