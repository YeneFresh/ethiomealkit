-- Payments, subscriptions, invoices, orders, and RPCs
-- Safe to re-run: uses IF NOT EXISTS where appropriate; functions are create or replace

create schema if not exists app;
create extension if not exists pgcrypto;

-- PROVIDERS
create table if not exists app.payment_provider (
  id text primary key,
  kind text not null,
  enabled boolean not null default true
);

insert into app.payment_provider (id,kind,enabled) values
  ('telebirr','local_wallet',true),
  ('chapa','local_wallet',true),
  ('arifpay','local_wallet',true),
  ('cbe','local_wallet',false),
  ('cod','cod',true)
on conflict (id) do nothing;

-- METHODS
create table if not exists app.payment_method (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  provider_id text not null references app.payment_provider(id),
  display_label text,
  status text not null default 'active',
  provider_ref jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
alter table app.payment_method enable row level security;
do $$ begin
  if not exists (
    select 1 from pg_policies where schemaname = 'app' and tablename = 'payment_method' and policyname = 'pm_owner'
  ) then
    create policy pm_owner on app.payment_method for all using (auth.uid() = user_id);
  end if;
end $$;

-- INTENT
create table if not exists app.payment_intent (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  provider_id text not null references app.payment_provider(id),
  amount_cents int not null,
  currency text not null,
  purpose text not null,
  status text not null default 'created',
  method_id uuid references app.payment_method,
  provider_payload jsonb default '{}'::jsonb,
  provider_response jsonb default '{}'::jsonb,
  client_secret text,
  redirect_url text,
  idempotency_key text unique,
  created_at timestamptz not null default now()
);
alter table app.payment_intent enable row level security;
do $$ begin
  if not exists (
    select 1 from pg_policies where schemaname = 'app' and tablename = 'payment_intent' and policyname = 'pi_owner'
  ) then
    create policy pi_owner on app.payment_intent for select using (auth.uid() = user_id);
  end if;
end $$;

-- PAYMENT
create table if not exists app.payment (
  id uuid primary key default gen_random_uuid(),
  intent_id uuid not null references app.payment_intent on delete cascade,
  amount_cents int not null,
  currency text not null,
  status text not null,
  provider_txn_id text,
  posted_at timestamptz
);

-- SUBS
create table if not exists app.subscription (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  cadence text not null default 'weekly',
  status text not null default 'active',
  default_method uuid references app.payment_method,
  shipping_window jsonb,
  next_invoice_date date not null,
  created_at timestamptz not null default now()
);

-- INVOICES
create table if not exists app.invoice (
  id uuid primary key default gen_random_uuid(),
  subscription_id uuid not null references app.subscription on delete cascade,
  user_id uuid not null references auth.users on delete cascade,
  amount_cents int not null,
  currency text not null,
  status text not null default 'open',
  due_at timestamptz not null,
  closed_at timestamptz
);

-- SIMPLE ORDER HEADER AND ITEMS (app schema)
create table if not exists app."order" (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  address_id uuid,
  delivery_window_id uuid,
  total_cents int not null,
  currency text not null default 'ETB',
  payment_intent_id uuid references app.payment_intent,
  status text not null default 'pending',
  created_at timestamptz not null default now()
);

create table if not exists app.order_item (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references app."order" on delete cascade,
  recipe_id uuid not null,
  qty int not null default 1
);

-- CORE RPCS (app schema)
create or replace function app.create_order_with_intent(
  total_cents int,
  currency text,
  provider_id text,
  method_id uuid,
  address_id uuid,
  delivery_window_id uuid,
  purpose text default 'weekly_box',
  idempotency_key text default null
) returns table(order_id uuid, intent_id uuid, client_secret text, redirect_url text)
language plpgsql
security definer
as $$
declare
  v_user uuid := auth.uid();
  v_order uuid;
  v_intent uuid;
begin
  if v_user is null then
    raise exception 'not authenticated';
  end if;

  insert into app.payment_intent(user_id, provider_id, amount_cents, currency, purpose, status, method_id, idempotency_key)
  values (v_user, provider_id, total_cents, currency, purpose, 'created', method_id, idempotency_key)
  returning id into v_intent;

  insert into app."order"(user_id, address_id, delivery_window_id, total_cents, currency, payment_intent_id, status)
  values (v_user, address_id, delivery_window_id, total_cents, currency, v_intent, 'pending')
  returning id into v_order;

  return query
  select v_order, v_intent, pi.client_secret, pi.redirect_url
  from app.payment_intent pi where pi.id = v_intent;
end $$;

create or replace function app.mark_intent_status(
  intent uuid,
  new_status text,
  provider_response jsonb default '{}'::jsonb,
  provider_txn_id text default null
) returns void
language plpgsql
security definer
as $$
begin
  update app.payment_intent
    set status = new_status,
        provider_response = coalesce(provider_response, '{}'::jsonb) || provider_response
  where id = intent;

  if new_status = 'succeeded' then
    insert into app.payment(intent_id, amount_cents, currency, status, provider_txn_id, posted_at)
    select id, amount_cents, currency, 'succeeded', provider_txn_id, now()
    from app.payment_intent where id = intent;

    update app."order" set status = 'paid'
    where payment_intent_id = intent;
  end if;
end $$;

-- PUBLIC WRAPPERS for RPC (so supabase.rpc('app_create_*') works)
create or replace function public.app_create_order_with_intent(
  total_cents int,
  currency text,
  provider_id text,
  method_id uuid,
  address_id uuid,
  delivery_window_id uuid,
  purpose text default 'weekly_box',
  idempotency_key text default null
) returns table(order_id uuid, intent_id uuid, client_secret text, redirect_url text)
language sql
security definer
as $$
  select * from app.create_order_with_intent(total_cents, currency, provider_id, method_id, address_id, delivery_window_id, purpose, idempotency_key);
$$;

create or replace function public.app_mark_intent_status(
  intent uuid,
  new_status text,
  provider_response jsonb default '{}'::jsonb,
  provider_txn_id text default null
) returns void
language sql
security definer
as $$
  select app.mark_intent_status(intent, new_status, provider_response, provider_txn_id);
$$;




