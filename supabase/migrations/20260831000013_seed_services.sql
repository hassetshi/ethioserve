-- Starter services per initial category. Category ids are looked up by
-- name_en rather than hard-coded, so this migration seeds correctly in any
-- environment regardless of the UUIDs that environment's category rows got.
insert into public.services (category_id, name_en, name_am)
select c.id, v.name_en, v.name_am
from (values
  ('Plumbing', 'Pipe Repair', 'የቧንቧ ጥገና'),
  ('Plumbing', 'Drain Cleaning', 'የፍሳሽ ማጽዳት'),
  ('Plumbing', 'Water Heater Installation', 'የውሃ ማሞቂያ ተከላ'),
  ('Electrical', 'Wiring Repair', 'የኤሌክትሪክ ሽቦ ጥገና'),
  ('Electrical', 'Outlet Installation', 'የኤሌክትሪክ መሰኪያ ተከላ'),
  ('Electrical', 'Lighting Installation', 'የመብራት ተከላ'),
  ('Cleaning', 'House Cleaning', 'የቤት ጽዳት'),
  ('Cleaning', 'Deep Cleaning', 'ጥልቅ ጽዳት'),
  ('Cleaning', 'Office Cleaning', 'የቢሮ ጽዳት'),
  ('Auto Repair', 'Oil Change', 'ዘይት መቀየር'),
  ('Auto Repair', 'Brake Repair', 'ብሬክ ጥገና'),
  ('Auto Repair', 'Engine Diagnostics', 'የሞተር ምርመራ'),
  ('Tutoring', 'Math Tutoring', 'የሂሳብ ትምህርት'),
  ('Tutoring', 'English Tutoring', 'የእንግሊዝኛ ትምህርት'),
  ('Tutoring', 'Science Tutoring', 'የሳይንስ ትምህርት')
) as v(category_name_en, name_en, name_am)
join public.categories c on c.name_en = v.category_name_en
where not exists (
  select 1 from public.services s
  where s.category_id = c.id and s.name_en = v.name_en
);
