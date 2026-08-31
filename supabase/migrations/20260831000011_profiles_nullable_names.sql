-- Names are collected after first login (Profile screen), not at signup
-- time, so they can't be NOT NULL from the moment the row is created.
alter table public.profiles alter column first_name drop not null;
alter table public.profiles alter column last_name drop not null;
