-- Chat images. Private (not public like provider-photos): only the two
-- participants in the booking a message belongs to should ever see them.
-- The path convention is '{booking_id}/{filename}', so
-- storage.foldername(name)[1] recovers the booking id for the RLS check.
insert into storage.buckets (id, name, public)
values ('chat-images', 'chat-images', false)
on conflict (id) do nothing;

create policy "booking participants can read chat images"
  on storage.objects for select
  using (
    bucket_id = 'chat-images'
    and public.is_booking_participant(((storage.foldername(name))[1])::uuid)
  );

create policy "booking participants can upload chat images"
  on storage.objects for insert
  with check (
    bucket_id = 'chat-images'
    and public.is_booking_participant(((storage.foldername(name))[1])::uuid)
  );

-- Live chat.
alter publication supabase_realtime add table public.messages;
