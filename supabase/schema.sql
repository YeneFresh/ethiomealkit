-- Contracts-first minimal schema for MVP
-- Apply in Supabase SQL editor

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

-- Meals (for browsing; public readable)
create table if not exists public.meals (
  id uuid primary key default gen_random_uuid(),
  slug text unique,
  title text not null,
  description text,
  price_cents int not null,
  image_url text
);

-- Meal kits (what the app uses for MVP, seeded via tools/seed_meals.json)
create table if not exists public.meal_kits (
  id text primary key,
  title text not null,
  description text,
  price_cents int not null,
  image_url text
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
  created_at timestamptz default now()
);

-- Order items
create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  meal_kit_id text not null references public.meal_kits(id),
  qty int not null check (qty > 0),
  unit_price_cents int not null
);

-- RLS
alter table public.users enable row level security;
alter table public.addresses enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.meals enable row level security;
alter table public.meal_kits enable row level security;

-- Users can manage their own profile
create policy if not exists "own profile" on public.users
  for all using (id = auth.uid()) with check (id = auth.uid());

-- Users own addresses
create policy if not exists "own addresses" on public.addresses
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Users own orders
create policy if not exists "own orders" on public.orders
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Users can select their order items via their orders
create policy if not exists "order items via own orders" on public.order_items
  for select using (
    exists (select 1 from public.orders o where o.id = order_items.order_id and o.user_id = auth.uid())
  );

-- Public read policies for meals and meal_kits
create policy if not exists "public read meals" on public.meals for select using (true);
create policy if not exists "public read meal_kits" on public.meal_kits for select using (true);

-- RPC: create_order(user_id, items JSON, address_id, delivery_window_id)
create or replace function public.create_order(
  in p_user_id uuid,
  in p_items jsonb,
  in p_address_id uuid,
  in p_delivery_window_id text,
  out created_order_id uuid
) language plpgsql security definer as $$
declare
  v_total int := 0;
  v_order_id uuid;
  v_item jsonb;
  v_meal_kit_id text;
  v_qty int;
  v_unit int;
begin
  -- Insert order header
  insert into public.orders(user_id, address_id, delivery_window_id, status, total_cents)
  values (p_user_id, p_address_id, p_delivery_window_id, 'confirmed', 0)
  returning id into v_order_id;

  -- Insert items
  for v_item in select * from jsonb_array_elements(p_items)
  loop
    v_meal_kit_id := (v_item->>'meal_kit_id');
    v_qty := coalesce((v_item->>'qty')::int, 1);
    select price_cents into v_unit from public.meal_kits where id = v_meal_kit_id;
    if v_unit is null then
      raise exception 'Unknown meal_kit_id %', v_meal_kit_id;
    end if;
    insert into public.order_items(order_id, meal_kit_id, qty, unit_price_cents)
    values (v_order_id, v_meal_kit_id, v_qty, v_unit);
    v_total := v_total + (v_unit * v_qty);
  end loop;

  update public.orders set total_cents = v_total where id = v_order_id;
  created_order_id := v_order_id;
end; $$;


