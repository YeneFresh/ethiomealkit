-- Public wrapper for app.upsert_user_active_window to make it callable via REST
-- without exposing the entire app schema.

create or replace function public.upsert_user_active_window(
  window_id uuid,
  location_label text
)
returns void
security definer
set search_path = public, app, pg_temp
language sql as $$
  select app.upsert_user_active_window(upsert_user_active_window.window_id,
                                       upsert_user_active_window.location_label);
$$;

revoke all on function public.upsert_user_active_window(uuid, text) from public;
grant execute on function public.upsert_user_active_window(uuid, text) to authenticated;

comment on function public.upsert_user_active_window(uuid, text)
  is 'Public wrapper that delegates to app.upsert_user_active_window; authenticated only.';



