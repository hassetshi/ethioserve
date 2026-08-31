-- public.users mirrors auth.users 1:1 and carries app-level identity fields
-- (role, phone, language, active flag). auth.users itself holds credentials.
create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  phone text unique,
  email text unique,
  role text not null default 'customer' check (role in ('customer', 'provider', 'admin')),
  language_code text not null default 'en' references public.languages(code),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint users_phone_or_email_required check (phone is not null or email is not null)
);

create index idx_users_role on public.users(role);

create trigger trg_users_updated_at
  before update on public.users
  for each row execute function public.set_updated_at();

-- Auto-provision a public.users row whenever a new auth.users row is created,
-- so the app never has to remember to do this itself.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, phone, email)
  values (new.id, new.phone, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger trg_handle_new_auth_user
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

-- Display profile, separate from the identity/role row above.
create table public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users(id) on delete cascade,
  first_name text not null,
  last_name text not null,
  profile_photo text,
  phone text,
  email text,
  preferred_language text not null default 'en' references public.languages(code),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();
