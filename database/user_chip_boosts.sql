-- User chip boost preferences table
create table if not exists user_chip_boosts(
  user_id uuid references profiles(id) on delete cascade,
  chip text not null check (chip in ('rapid','family','veggie')),
  is_active boolean not null default false,
  updated_at timestamptz default now(),
  primary key (user_id, chip)
);

-- helper to set a chip on/off
create or replace function set_chip_boost(_user uuid, _chip text, _active boolean)
returns void language sql security definer as $$
  insert into user_chip_boosts(user_id, chip, is_active, updated_at)
  values (_user, _chip, _active, now())
  on conflict (user_id, chip)
  do update set is_active = excluded.is_active, updated_at = now();
$$;
