-- Extend RPC: create order + intent + items atomically
create or replace function app.create_order_with_intent(
  total_cents int,
  currency text,
  provider_id text,
  method_id uuid,
  address_id uuid,
  delivery_window_id uuid,
  selected_recipes uuid[] default null,
  selected_quantities int[] default null,
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
  i int;
  rid uuid;
  q int;
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

  if selected_recipes is not null and array_length(selected_recipes,1) > 0 then
    for i in 1..array_length(selected_recipes,1) loop
      rid := selected_recipes[i];
      q   := coalesce(selected_quantities[i], 1);
      if rid is not null and q > 0 then
        insert into app.order_item(order_id, recipe_id, qty) values (v_order, rid, q);
      end if;
    end loop;
  end if;

  return query
  select v_order, v_intent, pi.client_secret, pi.redirect_url
  from app.payment_intent pi where pi.id = v_intent;
end $$;

-- Public wrapper for supabase.rpc(...)
create or replace function public.app_create_order_with_intent(
  total_cents int,
  currency text,
  provider_id text,
  method_id uuid,
  address_id uuid,
  delivery_window_id uuid,
  selected_recipes uuid[] default null,
  selected_quantities int[] default null,
  purpose text default 'weekly_box',
  idempotency_key text default null
) returns table(order_id uuid, intent_id uuid, client_secret text, redirect_url text)
language sql
security definer
as $$
  select *
  from app.create_order_with_intent(
    total_cents, currency, provider_id, method_id, address_id, delivery_window_id,
    selected_recipes, selected_quantities, purpose, idempotency_key
  );
$$;

-- Compat views to deprecate public.orders* without breaking readers
create or replace view public.orders as
select
  id, user_id, address_id, delivery_window_id, status,
  total_cents, currency, payment_intent_id, created_at
from app."order";

create or replace view public.order_items as
select
  id, order_id, recipe_id as meal_kit_id, qty as quantity
from app.order_item;




