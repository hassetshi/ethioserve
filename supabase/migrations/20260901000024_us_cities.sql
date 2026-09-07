-- Product pivot: initial market is Ethiopian-American businesses/customers
-- in the US, not Ethiopia itself (a planned expansion back to Ethiopia
-- comes later, which is why the Ethiopian cities are deactivated rather
-- than deleted - the eventual reversal is a data change, not a migration).
-- Washington, DC / Silver Spring, MD is the single active launch city
-- (largest Ethiopian-American population in the US), matching the original
-- "one active launch city" pattern from 20260831000010_seed_data.sql. The
-- rest are pre-registered inactive for expansion to other major
-- Ethiopian-American population centers.
update public.cities set is_active = false;

insert into public.cities (name_en, name_am, region, is_active, display_order) values
  ('Washington, DC', 'ዋሽንግተን ዲሲ', 'DC', true, 1),
  ('Silver Spring, MD', 'ሲልቨር ስፕሪንግ', 'MD', false, 2),
  ('Los Angeles, CA', 'ሎስ አንጀለስ', 'CA', false, 3),
  ('Seattle, WA', 'ሲያትል', 'WA', false, 4),
  ('Minneapolis, MN', 'ሚኒያፖሊስ', 'MN', false, 5),
  ('Atlanta, GA', 'አትላንታ', 'GA', false, 6),
  ('Dallas, TX', 'ዳላስ', 'TX', false, 7),
  ('Denver, CO', 'ዴንቨር', 'CO', false, 8),
  ('Las Vegas, NV', 'ላስ ቬጋስ', 'NV', false, 9);
