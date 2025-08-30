-- Slug hardening for recipes
-- Adds slug column, unique constraints, format validation, and immutable triggers

-- Create app schema for internal functions
create schema if not exists app;

-- Add slug column to recipes
alter table public.recipes 
  add column if not exists slug text;

-- Create unique index on slug (excluding null values)
create unique index if not exists recipes_slug_unique 
  on public.recipes(slug) where slug is not null;

-- Add slug format constraint (lowercase, alphanumeric + hyphens, no leading/trailing hyphens)
alter table public.recipes 
  add constraint recipes_slug_format 
  check (slug ~ '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$');

-- Function to generate slug from title
create or replace function app.generate_slug(title text)
returns text as $$
declare
    base_slug text;
    final_slug text;
    counter int := 1;
begin
    -- Convert title to slug format
    base_slug := lower(trim(title));
    base_slug := regexp_replace(base_slug, '[^a-z0-9]+', '-', 'g');
    base_slug := regexp_replace(base_slug, '^-+|-+$', '', 'g');
    
    -- Ensure it's not empty
    if base_slug = '' then
        base_slug := 'recipe';
    end if;
    
    final_slug := base_slug;
    
    -- Check for uniqueness and append counter if needed
    while exists (select 1 from public.recipes where slug = final_slug) loop
        counter := counter + 1;
        final_slug := base_slug || '-' || counter;
    end loop;
    
    return final_slug;
end;
$$ language plpgsql;

-- Flag to control slug immutability (useful for migrations and admin operations)
create table if not exists app.slug_config (
    key text primary key,
    value boolean not null default true
);

-- Insert default config
insert into app.slug_config (key, value) 
values ('enforce_slug_immutability', true)
on conflict (key) do nothing;

-- Function to check if slug changes are allowed
create or replace function app.slug_immutability_enabled()
returns boolean as $$
declare
    enabled boolean;
begin
    select value into enabled 
    from app.slug_config 
    where key = 'enforce_slug_immutability';
    
    return coalesce(enabled, true);
end;
$$ language plpgsql stable;

-- Trigger function for slug management
create or replace function app.handle_recipe_slug()
returns trigger as $$
begin
    -- Generate slug if not provided on INSERT
    if tg_op = 'INSERT' then
        if new.slug is null then
            new.slug := app.generate_slug(new.title);
        end if;
        return new;
    end if;
    
    -- Handle UPDATE
    if tg_op = 'UPDATE' then
        -- Prevent slug changes if immutability is enforced
        if app.slug_immutability_enabled() and old.slug is not null and new.slug != old.slug then
            raise exception 'Slug cannot be changed after creation. Current slug: %, attempted slug: %', 
                old.slug, new.slug;
        end if;
        
        -- Generate slug if it was null and now title changed
        if old.slug is null and new.slug is null and new.title != old.title then
            new.slug := app.generate_slug(new.title);
        end if;
        
        return new;
    end if;
    
    return new;
end;
$$ language plpgsql;

-- Create trigger
drop trigger if exists recipe_slug_trigger on public.recipes;
create trigger recipe_slug_trigger
    before insert or update on public.recipes
    for each row
    execute function app.handle_recipe_slug();

-- Function to temporarily disable slug immutability (for admin use)
create or replace function app.disable_slug_immutability()
returns void as $$
begin
    update app.slug_config 
    set value = false 
    where key = 'enforce_slug_immutability';
end;
$$ language plpgsql;

-- Function to re-enable slug immutability
create or replace function app.enable_slug_immutability()
returns void as $$
begin
    update app.slug_config 
    set value = true 
    where key = 'enforce_slug_immutability';
end;
$$ language plpgsql;

-- Grant necessary permissions
grant usage on schema app to authenticated;
grant execute on function app.generate_slug(text) to authenticated;
grant execute on function app.slug_immutability_enabled() to authenticated;

-- Index for slug lookups
create index if not exists idx_recipes_slug on public.recipes(slug);

-- Add helpful comment
comment on column public.recipes.slug is 'URL-friendly identifier, auto-generated from title, immutable after creation';