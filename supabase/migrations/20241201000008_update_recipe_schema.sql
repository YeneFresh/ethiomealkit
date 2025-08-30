-- Update recipe schema to match API contract specification
-- Aligns with JSON structure: id, slug, name, cuisine, tags, chef_note, price_cents, kcal, badges, protein

-- Rename title to name (if title exists)
do $$
begin
    if exists (
        select 1 from information_schema.columns 
        where table_name = 'recipes' and column_name = 'title'
    ) then
        alter table public.recipes rename column title to name;
    end if;
end $$;

-- Add new columns per JSON contract
alter table public.recipes
  add column if not exists name text not null default 'Untitled Recipe',
  add column if not exists cuisine text,
  add column if not exists price_cents int not null default 0,
  add column if not exists kcal int not null default 0,
  add column if not exists tags text[] not null default '{}', -- never NULL
  add column if not exists chef_note text,
  add column if not exists badges text[] not null default '{}', -- all prettified badges
  add column if not exists badges_top3 text[] not null default '{}', -- prioritized, length 0..3
  add column if not exists badges_overflow text[] not null default '{}', -- remainder
  add column if not exists protein int not null default 0, -- int grams if derived, else 0
  add column if not exists protein_label text not null default '0 g', -- short printable
  add column if not exists is_featured boolean default false,
  add column if not exists is_active boolean default true,
  add column if not exists priority int default 0; -- higher number = higher priority

-- Add constraints per specification
alter table public.recipes
  drop constraint if exists recipes_price_cents_positive,
  drop constraint if exists recipes_kcal_positive,
  drop constraint if exists recipes_protein_positive,
  drop constraint if exists recipes_badges_top3_length;

alter table public.recipes
  add constraint recipes_price_cents_positive check (price_cents >= 0),
  add constraint recipes_kcal_positive check (kcal >= 0),
  add constraint recipes_protein_positive check (protein >= 0),
  add constraint recipes_badges_top3_length check (array_length(badges_top3, 1) <= 3);

-- Create indexes per API contract fields
create index if not exists idx_recipes_is_active on public.recipes(is_active);
create index if not exists idx_recipes_is_featured on public.recipes(is_featured);
create index if not exists idx_recipes_priority on public.recipes(priority desc);
create index if not exists idx_recipes_price on public.recipes(price_cents);
create index if not exists idx_recipes_kcal on public.recipes(kcal);
create index if not exists idx_recipes_tags on public.recipes using gin(tags);
create index if not exists idx_recipes_cuisine on public.recipes(cuisine);
create index if not exists idx_recipes_protein on public.recipes(protein);
create index if not exists idx_recipes_badges on public.recipes using gin(badges);

-- Update trigger for updated_at
create or replace function update_updated_at_column()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

drop trigger if exists update_recipes_updated_at on public.recipes;
create trigger update_recipes_updated_at
    before update on public.recipes
    for each row
    execute function update_updated_at_column();

-- Function to check if recipe has tag (using API contract structure)
create or replace function public.recipe_has_tag(recipe_id uuid, tag_name text)
returns boolean as $$
declare
    recipe_tags text[];
begin
    select tags into recipe_tags from public.recipes where id = recipe_id;
    return tag_name = any(recipe_tags);
end;
$$ language plpgsql stable;

-- Function to update badge arrays (maintains top3 + overflow split)
create or replace function public.update_recipe_badges(
    recipe_id uuid, 
    new_badges text[]
)
returns void as $$
declare
    top_badges text[];
    overflow_badges text[];
begin
    -- Split badges into top3 and overflow
    if array_length(new_badges, 1) <= 3 then
        top_badges := new_badges;
        overflow_badges := '{}';
    else
        top_badges := new_badges[1:3];
        overflow_badges := new_badges[4:array_length(new_badges, 1)];
    end if;
    
    update public.recipes 
    set 
        badges = new_badges,
        badges_top3 = top_badges,
        badges_overflow = overflow_badges,
        updated_at = now()
    where id = recipe_id;
end;
$$ language plpgsql;

-- Function to format protein label
create or replace function public.format_protein_label(protein_grams int)
returns text as $$
begin
    if protein_grams = 0 then
        return '0 g';
    else
        return protein_grams || ' g';
    end if;
end;
$$ language plpgsql immutable;

-- Trigger to auto-update protein_label when protein changes
create or replace function update_protein_label()
returns trigger as $$
begin
    new.protein_label := public.format_protein_label(new.protein);
    return new;
end;
$$ language plpgsql;

drop trigger if exists update_recipe_protein_label on public.recipes;
create trigger update_recipe_protein_label
    before insert or update of protein on public.recipes
    for each row
    execute function update_protein_label();