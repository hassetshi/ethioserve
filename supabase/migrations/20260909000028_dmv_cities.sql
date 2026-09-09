-- The DC-area Ethiopian business lead list (73 businesses, imported via
-- scripts/import-dc-lead-list.mjs) spans far more of the DMV region than
-- the single active launch city: only 23 of 73 leads are in Washington, DC
-- itself. Silver Spring, MD already exists (20260901000024_us_cities.sql)
-- but was left inactive by that migration's blanket
-- `update cities set is_active = false` - its own comment already treats
-- Silver Spring as part of the same launch metro area, it just never got
-- reactivated. The other 9 cities below don't exist at all yet.
update public.cities set is_active = true where name_en = 'Silver Spring, MD';

insert into public.cities (name_en, name_am, region, is_active, display_order) values
  ('Hyattsville, MD', 'ሃያትስቪል', 'MD', true, 10),
  ('Takoma Park, MD', 'ታኮማ ፓርክ', 'MD', true, 11),
  ('Wheaton, MD', 'ዊተን', 'MD', true, 12),
  ('Mount Rainier, MD', 'ማውንት ሬይኒየር', 'MD', true, 13),
  ('Rockville, MD', 'ሮክቪል', 'MD', true, 14),
  ('Alexandria, VA', 'አሌክሳንድሪያ', 'VA', true, 15),
  ('Arlington, VA', 'አርሊንግተን', 'VA', true, 16),
  ('Falls Church, VA', 'ፎልስ ቸርች', 'VA', true, 17),
  ('Herndon, VA', 'ኸርንደን', 'VA', true, 18),
  ('Woodbridge, VA', 'ውድብሪጅ', 'VA', true, 19);
