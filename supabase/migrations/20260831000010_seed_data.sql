-- Languages: English and Amharic ship active; the others are pre-registered
-- so future rollout is a one-row UPDATE, not a schema change.
insert into public.languages (code, name_en, name_native, is_active) values
  ('en', 'English', 'English', true),
  ('am', 'Amharic', 'አማርኛ', true),
  ('om', 'Afaan Oromo', 'Afaan Oromoo', false),
  ('ti', 'Tigrinya', 'ትግርኛ', false),
  ('so', 'Somali', 'Soomaali', false)
on conflict (code) do nothing;

-- Cities: Addis Ababa is the only active launch city; the rest are
-- pre-registered inactive for future expansion.
insert into public.cities (name_en, name_am, is_active, display_order) values
  ('Addis Ababa', 'አዲስ አበባ', true, 1),
  ('Dire Dawa', 'ድሬ ዳዋ', false, 2),
  ('Bahir Dar', 'ባህር ዳር', false, 3),
  ('Hawassa', 'ሀዋሳ', false, 4),
  ('Mekelle', 'መቀሌ', false, 5),
  ('Adama', 'አዳማ', false, 6),
  ('Gondar', 'ጎንደር', false, 7)
on conflict do nothing;

-- Initial service categories (spec section 3).
insert into public.categories (name_en, name_am, display_order) values
  ('Plumbing', 'ቧንቧ ስራ', 1),
  ('Electrical', 'ኤሌክትሪክ ስራ', 2),
  ('Cleaning', 'ጽዳት', 3),
  ('Auto Repair', 'የመኪና ጥገና', 4),
  ('Tutoring', 'ትምህርት', 5)
on conflict do nothing;

-- Platform configuration. Commission is deliberately data, not code
-- (spec section 23: "Do not hard-code 10%").
insert into public.platform_settings (key, value, description) values
  ('booking_commission_rate', '0.10', 'Platform commission taken from each completed booking, as a fraction (0.10 = 10%).')
on conflict (key) do nothing;
