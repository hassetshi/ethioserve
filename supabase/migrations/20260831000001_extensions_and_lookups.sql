-- Extensions
create extension if not exists pgcrypto;
create extension if not exists postgis;

-- Generic updated_at trigger function, reused by every table below.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Languages lookup. New languages (Afaan Oromo, Tigrinya, Somali) are added
-- as rows, not schema changes, per the localization architecture requirement.
create table public.languages (
  code text primary key,
  name_en text not null,
  name_native text not null,
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_languages_updated_at
  before update on public.languages
  for each row execute function public.set_updated_at();

-- Cities lookup. New launch cities are added as rows, not schema changes.
create table public.cities (
  id uuid primary key default gen_random_uuid(),
  name_en text not null,
  name_am text not null,
  region text,
  is_active boolean not null default true,
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_cities_active on public.cities(is_active);

create trigger trg_cities_updated_at
  before update on public.cities
  for each row execute function public.set_updated_at();

-- Platform-wide configuration (e.g. booking commission rate). Admin-managed,
-- so the commission percentage is never hard-coded in application code.
create table public.platform_settings (
  key text primary key,
  value jsonb not null,
  description text,
  updated_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_platform_settings_updated_at
  before update on public.platform_settings
  for each row execute function public.set_updated_at();
