-- Update recipe schema with enhanced fields
-- Adds price_cents, kcal, tags, chef_note, and other recipe attributes

-- Add new columns to recipes table
alter table public.recipes
  add column if not exists price_cents int,
  add column if not exists kcal int,
  add column if not exists prep_time_mins int,
  add column if not exists cook_time_mins int,
  add column if not exists serving_size int default 2,
  add column if not exists difficulty_level text check (difficulty_level in ('easy', 'medium', 'hard')),
  add column if not exists tags text[], -- array of tags like ['vegetarian', 'spicy', 'traditional']
  add column if not exists chef_note text,
  add column if not exists ingredients jsonb, -- structured ingredient list
  add column if not exists instructions jsonb, -- structured cooking instructions
  add column if not exists nutrition_info jsonb, -- detailed nutrition beyond kcal
  add column if not exists is_featured boolean default false,
  add column if not exists is_active boolean default true,
  add column if not exists priority int default 0; -- higher number = higher priority

-- Add constraints
alter table public.recipes
  add constraint recipes_price_cents_positive check (price_cents >= 0),
  add constraint recipes_kcal_positive check (kcal >= 0),
  add constraint recipes_prep_time_positive check (prep_time_mins >= 0),
  add constraint recipes_cook_time_positive check (cook_time_mins >= 0),
  add constraint recipes_serving_size_positive check (serving_size > 0);

-- Create indexes for common queries
create index if not exists idx_recipes_is_active on public.recipes(is_active);
create index if not exists idx_recipes_is_featured on public.recipes(is_featured);
create index if not exists idx_recipes_priority on public.recipes(priority desc);
create index if not exists idx_recipes_price on public.recipes(price_cents);
create index if not exists idx_recipes_kcal on public.recipes(kcal);
create index if not exists idx_recipes_tags on public.recipes using gin(tags);

-- Update trigger for updated_at
create or replace function update_updated_at_column()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

create trigger update_recipes_updated_at
    before update on public.recipes
    for each row
    execute function update_updated_at_column();

-- Function to calculate total time
create or replace function public.recipe_total_time(recipe_id uuid)
returns int as $$
declare
    prep_time int;
    cook_time int;
begin
    select prep_time_mins, cook_time_mins 
    into prep_time, cook_time
    from public.recipes 
    where id = recipe_id;
    
    return coalesce(prep_time, 0) + coalesce(cook_time, 0);
end;
$$ language plpgsql stable;

-- Function to check if recipe has tag
create or replace function public.recipe_has_tag(recipe_id uuid, tag_name text)
returns boolean as $$
declare
    recipe_tags text[];
begin
    select tags into recipe_tags from public.recipes where id = recipe_id;
    return tag_name = any(recipe_tags);
end;
$$ language plpgsql stable;