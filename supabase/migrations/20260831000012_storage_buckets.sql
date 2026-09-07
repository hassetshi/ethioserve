-- provider-photos: public (portfolio images are marketing material, meant
-- to be seen by anyone browsing providers). provider-documents: private
-- (verification documents — spec section 9/10: "Documents must be protected
-- and accessible only to authorized users/admins").
insert into storage.buckets (id, name, public)
values
  ('provider-photos', 'provider-photos', true),
  ('provider-documents', 'provider-documents', false)
on conflict (id) do nothing;

-- provider-photos: anyone can view (bucket is public); only the uploading
-- provider can manage their own files.
create policy "provider-photos are publicly readable"
  on storage.objects for select
  using (bucket_id = 'provider-photos');

create policy "providers manage their own photos"
  on storage.objects for all
  using (bucket_id = 'provider-photos' and owner = auth.uid())
  with check (bucket_id = 'provider-photos' and owner = auth.uid());

-- provider-documents: never publicly readable. Owner (the provider) can
-- upload/view their own; admins can view for verification review.
create policy "providers manage their own documents"
  on storage.objects for all
  using (bucket_id = 'provider-documents' and owner = auth.uid())
  with check (bucket_id = 'provider-documents' and owner = auth.uid());

create policy "admins can read provider documents"
  on storage.objects for select
  using (bucket_id = 'provider-documents' and public.is_admin());
