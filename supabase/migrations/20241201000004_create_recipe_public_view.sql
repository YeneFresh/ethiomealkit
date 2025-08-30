-- Recipe public view
-- Creates optimized view for public recipe browsing with priority logic
-- Depends on: recipes.tags, chef_note, price_cents, kcal, priority

-- Create view for public recipe browsing
create or replace view public.recipes_public as
select 
    r.id,
    r.slug,
    r.title,
    r.description,
    r.image_url,
    r.price_cents,
    r.kcal,
    r.prep_time_mins,
    r.cook_time_mins,
    r.serving_size,
    r.difficulty_level,
    r.tags,
    r.chef_note,
    r.is_featured,
    r.priority,
    -- Calculated fields
    coalesce(r.prep_time_mins, 0) + coalesce(r.cook_time_mins, 0) as total_time_mins,
    case 
        when r.tags @> array['vegetarian'] then true
        else false
    end as is_vegetarian,
    case 
        when r.tags @> array['vegan'] then true
        else false
    end as is_vegan,
    case 
        when r.tags @> array['gluten-free'] then true
        else false
    end as is_gluten_free,
    case 
        when r.tags @> array['spicy'] then true
        else false
    end as is_spicy,
    -- Popularity score (can be enhanced later with actual metrics)
    r.priority as popularity_score,
    r.created_at,
    r.updated_at
from public.recipes r
where r.is_active = true
order by 
    r.is_featured desc,
    r.priority desc,
    r.created_at desc;

-- Grant access to the view
grant select on public.recipes_public to authenticated;
grant select on public.recipes_public to anon;

-- Function to get featured recipes
create or replace function public.get_featured_recipes(limit_count int default 6)
returns setof public.recipes_public as $$
begin
    return query
    select * from public.recipes_public
    where is_featured = true
    order by priority desc, created_at desc
    limit limit_count;
end;
$$ language plpgsql stable;

-- Function to get recipes by difficulty
create or replace function public.get_recipes_by_difficulty(difficulty text, limit_count int default 10)
returns setof public.recipes_public as $$
begin
    return query
    select * from public.recipes_public
    where difficulty_level = difficulty
    order by priority desc, created_at desc
    limit limit_count;
end;
$$ language plpgsql stable;

-- Function to get recipes by tags
create or replace function public.get_recipes_by_tags(tag_list text[], limit_count int default 10)
returns setof public.recipes_public as $$
begin
    return query
    select * from public.recipes_public
    where tags && tag_list  -- overlaps operator
    order by priority desc, created_at desc
    limit limit_count;
end;
$$ language plpgsql stable;

-- Function to search recipes
create or replace function public.search_recipes(
    search_term text,
    tag_filters text[] default null,
    min_kcal int default null,
    max_kcal int default null,
    max_prep_time int default null,
    difficulty_filter text default null,
    limit_count int default 20
)
returns setof public.recipes_public as $$
begin
    return query
    select * from public.recipes_public r
    where 
        -- Text search
        (search_term is null or 
         r.title ilike '%' || search_term || '%' or 
         r.description ilike '%' || search_term || '%' or
         r.chef_note ilike '%' || search_term || '%')
        -- Tag filters
        and (tag_filters is null or r.tags && tag_filters)
        -- Calorie range
        and (min_kcal is null or r.kcal >= min_kcal)
        and (max_kcal is null or r.kcal <= max_kcal)
        -- Prep time filter
        and (max_prep_time is null or r.prep_time_mins <= max_prep_time)
        -- Difficulty filter
        and (difficulty_filter is null or r.difficulty_level = difficulty_filter)
    order by 
        -- Boost exact title matches
        case when r.title ilike search_term then 1 else 0 end desc,
        -- Then by priority and recency
        r.priority desc, 
        r.created_at desc
    limit limit_count;
end;
$$ language plpgsql stable;

-- Function to get recipe recommendations (placeholder logic)
create or replace function public.get_recipe_recommendations(
    user_uuid uuid default auth.uid(),
    limit_count int default 8
)
returns setof public.recipes_public as $$
declare
    user_preferences text[];
begin
    -- Get user's preference tags from their selection history
    -- This is a simplified version - can be enhanced with ML later
    select array_agg(distinct tag) into user_preferences
    from (
        select unnest(r.tags) as tag
        from public.box_selections bs
        join public.recipes r on r.id = bs.recipe_id
        where bs.user_id = user_uuid
        and bs.week_start_date >= current_date - interval '8 weeks'
        and r.is_active = true
    ) t;
    
    -- If user has no history, return featured recipes
    if user_preferences is null then
        return query select * from public.get_featured_recipes(limit_count);
        return;
    end if;
    
    -- Return recipes matching user preferences, excluding recent selections
    return query
    select * from public.recipes_public r
    where 
        r.tags && user_preferences
        and not exists (
            select 1 from public.box_selections bs
            where bs.user_id = user_uuid
            and bs.recipe_id = r.id
            and bs.week_start_date >= current_date - interval '4 weeks'
        )
    order by r.priority desc, r.created_at desc
    limit limit_count;
end;
$$ language plpgsql stable security definer;

-- Grant execute permissions
grant execute on function public.get_featured_recipes(int) to authenticated, anon;
grant execute on function public.get_recipes_by_difficulty(text, int) to authenticated, anon;
grant execute on function public.get_recipes_by_tags(text[], int) to authenticated, anon;
grant execute on function public.search_recipes(text, text[], int, int, int, text, int) to authenticated, anon;
grant execute on function public.get_recipe_recommendations(uuid, int) to authenticated;

-- Index on view's commonly filtered columns (Postgres will use these for view queries)
create index if not exists idx_recipes_public_featured on public.recipes(is_featured, priority desc) where is_active = true;
create index if not exists idx_recipes_public_difficulty on public.recipes(difficulty_level, priority desc) where is_active = true;

-- Full text search index for better search performance
create index if not exists idx_recipes_fulltext 
on public.recipes using gin(
    to_tsvector('english', coalesce(title, '') || ' ' || coalesce(description, '') || ' ' || coalesce(chef_note, ''))
) where is_active = true;