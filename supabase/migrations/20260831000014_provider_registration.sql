-- Registering as a provider requires promoting the caller's own
-- users.role to 'provider' — something RLS deliberately forbids from a
-- plain client UPDATE (spec section 31: never trust the client for role).
-- This SECURITY DEFINER function is the one sanctioned way to do it: it
-- only ever acts on auth.uid()'s own row (no user_id parameter to abuse),
-- and only inserts/promotes, it never touches anyone else's data.
create or replace function public.register_as_provider(
  p_business_name text,
  p_description_en text,
  p_description_am text,
  p_phone text,
  p_address text,
  p_city_id uuid,
  p_latitude double precision,
  p_longitude double precision
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_provider_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Must be authenticated to register as a provider';
  end if;

  if exists (select 1 from public.provider_profiles where user_id = auth.uid()) then
    raise exception 'This account is already registered as a provider';
  end if;

  insert into public.provider_profiles (
    user_id, business_name, description_en, description_am,
    phone, address, city_id, latitude, longitude,
    verification_status, is_active
  ) values (
    auth.uid(), p_business_name, p_description_en, p_description_am,
    p_phone, p_address, p_city_id, p_latitude, p_longitude,
    'pending', true
  )
  returning id into v_provider_id;

  update public.users set role = 'provider' where id = auth.uid();

  return v_provider_id;
end;
$$;

grant execute on function public.register_as_provider(
  text, text, text, text, text, uuid, double precision, double precision
) to authenticated;
