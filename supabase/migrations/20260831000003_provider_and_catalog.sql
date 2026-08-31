-- Service categories (e.g. Plumbing). Localized via name_en/name_am.
create table public.categories (
  id uuid primary key default gen_random_uuid(),
  name_en text not null,
  name_am text not null,
  icon text,
  image text,
  display_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_categories_active on public.categories(is_active);

create trigger trg_categories_updated_at
  before update on public.categories
  for each row execute function public.set_updated_at();

-- Concrete services within a category (e.g. Pipe Repair under Plumbing).
create table public.services (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.categories(id) on delete cascade,
  name_en text not null,
  name_am text not null,
  description_en text,
  description_am text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_services_category on public.services(category_id);
create index idx_services_active on public.services(is_active);

create trigger trg_services_updated_at
  before update on public.services
  for each row execute function public.set_updated_at();

-- Provider business profile. city_id references the cities lookup table
-- (rather than a free-text city) so new launch cities never require a
-- schema change. location is a generated geography point kept in sync with
-- latitude/longitude by a trigger, and is what nearby-search queries use.
create table public.provider_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users(id) on delete cascade,
  business_name text not null,
  description_en text,
  description_am text,
  phone text not null,
  address text,
  city_id uuid references public.cities(id),
  latitude double precision,
  longitude double precision,
  location geography(Point, 4326),
  verification_status text not null default 'pending'
    check (verification_status in ('pending', 'verified', 'rejected', 'suspended')),
  verification_date timestamptz,
  rating numeric(3, 2) not null default 0 check (rating between 0 and 5),
  review_count integer not null default 0 check (review_count >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_provider_profiles_city on public.provider_profiles(city_id);
create index idx_provider_profiles_verification on public.provider_profiles(verification_status);
create index idx_provider_profiles_active on public.provider_profiles(is_active);
create index idx_provider_profiles_location on public.provider_profiles using gist(location);

create trigger trg_provider_profiles_updated_at
  before update on public.provider_profiles
  for each row execute function public.set_updated_at();

-- Keep the geography point in sync whenever lat/lng change.
create or replace function public.sync_provider_location()
returns trigger
language plpgsql
as $$
begin
  if new.latitude is not null and new.longitude is not null then
    new.location = ST_SetSRID(ST_MakePoint(new.longitude, new.latitude), 4326)::geography;
  else
    new.location = null;
  end if;
  return new;
end;
$$;

create trigger trg_provider_profiles_sync_location
  before insert or update of latitude, longitude on public.provider_profiles
  for each row execute function public.sync_provider_location();

-- Only admins (or the system, via security-definer functions) may change
-- verification/rating fields. Providers editing their own profile cannot
-- self-verify or inflate their own rating.
create or replace function public.guard_provider_profile_admin_fields()
returns trigger
language plpgsql
as $$
begin
  if (new.verification_status is distinct from old.verification_status
      or new.verification_date is distinct from old.verification_date
      or new.rating is distinct from old.rating
      or new.review_count is distinct from old.review_count)
     and not public.is_admin() then
    raise exception 'Only administrators may change verification status or rating fields';
  end if;
  return new;
end;
$$;

-- Note: created after public.is_admin() exists; see 20260831000008_rls_policies.sql
-- for the trigger attachment (kept there to keep function ordering simple).

-- Provider's offered services with pricing.
create table public.provider_services (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.provider_profiles(id) on delete cascade,
  service_id uuid not null references public.services(id) on delete cascade,
  min_price numeric(12, 2) check (min_price >= 0),
  max_price numeric(12, 2) check (max_price >= 0),
  pricing_type text not null default 'fixed'
    check (pricing_type in ('fixed', 'hourly', 'starting_from', 'quote')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_provider_service unique (provider_id, service_id),
  constraint chk_provider_service_price_range
    check (max_price is null or min_price is null or max_price >= min_price)
);

create index idx_provider_services_provider on public.provider_services(provider_id);
create index idx_provider_services_service on public.provider_services(service_id);

create trigger trg_provider_services_updated_at
  before update on public.provider_services
  for each row execute function public.set_updated_at();

-- Weekly recurring availability windows.
create table public.provider_availability (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.provider_profiles(id) on delete cascade,
  day_of_week smallint not null check (day_of_week between 0 and 6),
  start_time time not null,
  end_time time not null,
  is_available boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint chk_availability_time_order check (end_time > start_time)
);

create index idx_provider_availability_provider on public.provider_availability(provider_id);

create trigger trg_provider_availability_updated_at
  before update on public.provider_availability
  for each row execute function public.set_updated_at();

-- Portfolio photos.
create table public.provider_photos (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.provider_profiles(id) on delete cascade,
  storage_path text not null,
  caption text,
  display_order integer not null default 0,
  created_at timestamptz not null default now()
);

create index idx_provider_photos_provider on public.provider_photos(provider_id);

-- Verification documents. Storage bucket for these must be private; see
-- SECURITY.md for the bucket policy that pairs with the RLS below.
create table public.provider_documents (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.provider_profiles(id) on delete cascade,
  document_type text not null,
  storage_path text not null,
  verification_status text not null default 'pending'
    check (verification_status in ('pending', 'verified', 'rejected', 'suspended')),
  reviewed_by uuid references public.users(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create index idx_provider_documents_provider on public.provider_documents(provider_id);
