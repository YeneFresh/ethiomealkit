-- Box summary and locking functions
-- Creates app.current_box_summary, app.lock_integrity, app.checkout_lock

-- Ensure app schema exists (created in slug hardening migration)
create schema if not exists app;

-- Box selections table (tracks user meal selections)
create table if not exists public.box_selections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  recipe_id uuid not null references public.recipes(id),
  week_start_date date not null,
  selected_at timestamptz default now(),
  quantity int default 1 check (quantity > 0),
  
  -- Prevent duplicate selections
  unique(user_id, recipe_id, week_start_date)
);

-- Enable RLS
alter table public.box_selections enable row level security;

-- RLS policies
create policy "Users can manage own box selections" on public.box_selections
  for all using (auth.uid() = user_id);

-- Indexes
create index if not exists idx_box_selections_user_week 
  on public.box_selections(user_id, week_start_date);

create index if not exists idx_box_selections_recipe 
  on public.box_selections(recipe_id);

-- Function to get current box summary for a user
create or replace function app.current_box_summary(user_uuid uuid default auth.uid())
returns jsonb as $$
declare
    current_week date;
    week_status record;
    selections record;
    result jsonb;
begin
    -- Get current week start
    current_week := public.current_week_start();
    
    -- Get week status
    select * into week_status
    from public.user_week_status
    where user_id = user_uuid and week_start_date = current_week;
    
    -- If no week status, create default
    if week_status is null then
        insert into public.user_week_status (user_id, week_start_date)
        values (user_uuid, current_week)
        returning * into week_status;
    end if;
    
    -- Get selections with recipe details
    select 
        jsonb_agg(
            jsonb_build_object(
                'recipe_id', r.id,
                'title', r.title,
                'slug', r.slug,
                'image_url', r.image_url,
                'price_cents', r.price_cents,
                'kcal', r.kcal,
                'quantity', bs.quantity,
                'selected_at', bs.selected_at
            ) order by bs.selected_at
        ) as selections_data
    into selections
    from public.box_selections bs
    join public.recipes r on r.id = bs.recipe_id
    where bs.user_id = user_uuid 
      and bs.week_start_date = current_week
      and r.is_active = true;
    
    -- Calculate totals
    with selection_totals as (
        select 
            count(*) as total_meals,
            coalesce(sum(r.price_cents * bs.quantity), 0) as total_price_cents,
            coalesce(sum(r.kcal * bs.quantity), 0) as total_kcal
        from public.box_selections bs
        join public.recipes r on r.id = bs.recipe_id
        where bs.user_id = user_uuid 
          and bs.week_start_date = current_week
          and r.is_active = true
    )
    select jsonb_build_object(
        'week_start_date', current_week,
        'status', week_status.status,
        'is_locked', week_status.box_locked_at is not null,
        'locked_at', week_status.box_locked_at,
        'total_meals', st.total_meals,
        'total_price_cents', st.total_price_cents,
        'total_kcal', st.total_kcal,
        'selections', coalesce(selections.selections_data, '[]'::jsonb),
        'can_modify', week_status.box_locked_at is null and week_status.status = 'active'
    )
    into result
    from selection_totals st;
    
    return result;
end;
$$ language plpgsql security definer;

-- Function to check lock integrity
create or replace function app.lock_integrity(user_uuid uuid default auth.uid())
returns jsonb as $$
declare
    current_week date;
    week_status record;
    issues text[] := '{}';
    result jsonb;
begin
    current_week := public.current_week_start();
    
    select * into week_status
    from public.user_week_status
    where user_id = user_uuid and week_start_date = current_week;
    
    if week_status is null then
        issues := array_append(issues, 'No week status found');
        return jsonb_build_object(
            'has_issues', true,
            'issues', issues
        );
    end if;
    
    -- Check if locked but no selections
    if week_status.box_locked_at is not null then
        if not exists (
            select 1 from public.box_selections
            where user_id = user_uuid and week_start_date = current_week
        ) then
            issues := array_append(issues, 'Box is locked but has no selections');
        end if;
        
        -- Check if selections reference inactive recipes
        if exists (
            select 1 from public.box_selections bs
            join public.recipes r on r.id = bs.recipe_id
            where bs.user_id = user_uuid 
              and bs.week_start_date = current_week
              and r.is_active = false
        ) then
            issues := array_append(issues, 'Box contains inactive recipes');
        end if;
    end if;
    
    -- Check meal count consistency
    declare
        actual_count int;
        recorded_count int;
    begin
        select count(*) into actual_count
        from public.box_selections
        where user_id = user_uuid and week_start_date = current_week;
        
        recorded_count := week_status.meals_selected;
        
        if actual_count != recorded_count then
            issues := array_append(issues, 
                format('Meal count mismatch: recorded=%s, actual=%s', recorded_count, actual_count));
        end if;
    end;
    
    return jsonb_build_object(
        'has_issues', array_length(issues, 1) > 0,
        'issues', issues,
        'week_start_date', current_week,
        'is_locked', week_status.box_locked_at is not null
    );
end;
$$ language plpgsql security definer;

-- Function to lock box for checkout
create or replace function app.checkout_lock(user_uuid uuid default auth.uid())
returns jsonb as $$
declare
    current_week date;
    week_status record;
    selection_count int;
    result jsonb;
begin
    current_week := public.current_week_start();
    
    -- Get current week status
    select * into week_status
    from public.user_week_status
    where user_id = user_uuid and week_start_date = current_week;
    
    if week_status is null then
        return jsonb_build_object(
            'success', false,
            'error', 'No week status found'
        );
    end if;
    
    -- Check if already locked
    if week_status.box_locked_at is not null then
        return jsonb_build_object(
            'success', false,
            'error', 'Box is already locked',
            'locked_at', week_status.box_locked_at
        );
    end if;
    
    -- Check if user has selections
    select count(*) into selection_count
    from public.box_selections
    where user_id = user_uuid and week_start_date = current_week;
    
    if selection_count = 0 then
        return jsonb_build_object(
            'success', false,
            'error', 'Cannot lock empty box'
        );
    end if;
    
    -- Lock the box
    update public.user_week_status
    set 
        box_locked_at = now(),
        meals_selected = selection_count,
        updated_at = now()
    where user_id = user_uuid and week_start_date = current_week;
    
    return jsonb_build_object(
        'success', true,
        'locked_at', now(),
        'meals_selected', selection_count
    );
end;
$$ language plpgsql security definer;

-- Grant permissions
grant execute on function app.current_box_summary(uuid) to authenticated;
grant execute on function app.lock_integrity(uuid) to authenticated;
grant execute on function app.checkout_lock(uuid) to authenticated;