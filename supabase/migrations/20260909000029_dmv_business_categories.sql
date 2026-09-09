-- The DC-area Ethiopian business lead list (73 businesses) is mostly
-- restaurants, grocers, and general professional services - none of which
-- match today's 5 categories (Plumbing/Electrical/Cleaning/Auto
-- Repair/Tutoring), which are all home-services trades. This is a genuine
-- taxonomy expansion, not a workaround: it extends EthioServe from
-- home-services trades into general Ethiopian business discovery, matching
-- every one of the 73 leads' real category with zero fallback needed (see
-- scripts/import-dc-lead-list.mjs's category-mapping table). 'Other
-- Services' is seeded anyway as a safety net for future imports whose
-- categories don't fit this list.
insert into public.categories (name_en, name_am, display_order) values
  ('Restaurant', 'ምግብ ቤት', 6),
  ('Grocery', 'ግሮሰሪ', 7),
  ('Coffee Shop & Bakery', 'ቡና ቤት እና ዳቦ ቤት', 8),
  ('Beauty & Salon', 'ውበት እና ሳሎን', 9),
  ('Legal & Immigration Services', 'ህግ እና ኢሚግሬሽን አገልግሎት', 10),
  ('Accounting & Tax', 'አካውንቲንግ እና ታክስ', 11),
  ('Driving School', 'የመንዳት ትምህርት ቤት', 12),
  ('Travel Agency', 'የጉዞ ወኪል', 13),
  ('Real Estate', 'ሪል እስቴት', 14),
  ('Catering', 'ኬተሪንግ', 15),
  ('Insurance', 'መድን', 16),
  ('Ethiopian Products & Home Goods', 'የኢትዮጵያ ምርቶች እና የቤት እቃዎች', 17),
  ('Other Services', 'ሌሎች አገልግሎቶች', 18)
on conflict do nothing;

-- One generic placeholder service per new category so a seeded provider
-- (which has no owner-picked services yet - see provider_leads/
-- provider_claim_requests in 20260909000030) has at least one
-- provider_services row and remains visible when a customer browses via a
-- category filter: search_providers's p_category_id/p_service_id filters
-- both require an `exists` join through provider_services, so a provider
-- with zero rows there is invisible to category browsing specifically
-- (though still findable by name search) until the real owner claims the
-- listing and adds real services.
insert into public.services (category_id, name_en, name_am)
select c.id, 'General ' || c.name_en || ' Services', 'አጠቃላይ ' || c.name_am || ' አገልግሎት'
from public.categories c
where c.name_en in (
  'Restaurant', 'Grocery', 'Coffee Shop & Bakery', 'Beauty & Salon',
  'Legal & Immigration Services', 'Accounting & Tax', 'Driving School',
  'Travel Agency', 'Real Estate', 'Catering', 'Insurance',
  'Ethiopian Products & Home Goods', 'Other Services'
)
and not exists (
  select 1 from public.services s
  where s.category_id = c.id and s.name_en = 'General ' || c.name_en || ' Services'
);
