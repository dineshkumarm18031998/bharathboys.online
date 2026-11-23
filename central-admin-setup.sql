-- =====================================================================
-- BHARATH BOYS – CENTRAL ADMIN SETUP v3  (safe to run more than once)
--
-- STEP 0: replace the ONE placeholder on the line marked  >>> EDIT HERE <<<
--         with your admin UUID (Supabase > Authentication > Users).
--         If you forget, the script stops immediately and changes NOTHING.
--
-- What it does (never deletes website content or participant data):
--   1. site-assets bucket: public, 10 MB, audio + images     (fixes "audio only")
--   2. drawing-submissions bucket: PRIVATE, 5 MB, images
--   3. annual_competitions: adds OPTIONAL nullable columns description, instructions
--   4. settings: RLS – public read (except admin_pwd_hash), writes only by the admin
--   5. participant tables: no anon/authenticated access at all (Edge Functions only)
--   6. storage policies: site-assets public read, admin-only write; NO policy for drawings
--   7. unique index on settings.key only if missing and no duplicates
-- =====================================================================

do $$
declare
  v text := 'YOUR_ADMIN_AUTH_USER_UUID';   -- >>> EDIT HERE <<<
  a uuid;
begin
  if v = 'YOUR_ADMIN_AUTH_USER_UUID' or v !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    raise exception 'STOP: replace YOUR_ADMIN_AUTH_USER_UUID with the admin user UUID first. Nothing was changed.';
  end if;
  a := v::uuid;
  if not exists (select 1 from auth.users where id = a) then
    raise exception 'STOP: no auth user with id %. Nothing was changed.', v;
  end if;

  -- 1) site-assets: PUBLIC bucket (anthem + public site images)
  insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values ('site-assets','site-assets', true, 10485760,
    array['audio/mpeg','audio/mp4','audio/aac','audio/wav','audio/x-wav','audio/ogg','audio/webm','image/jpeg','image/png','image/webp'])
  on conflict (id) do update set public = true, file_size_limit = 10485760,
    allowed_mime_types = excluded.allowed_mime_types;

  -- 2) drawing-submissions: PRIVATE bucket (participant artwork)
  insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values ('drawing-submissions','drawing-submissions', false, 5242880, array['image/jpeg','image/png','image/webp'])
  on conflict (id) do update set public = false, file_size_limit = 5242880,
    allowed_mime_types = excluded.allowed_mime_types;

  -- 3) Optional competition text + age/standard columns + allow multiple quiz questions per date
  alter table public.annual_competitions add column if not exists description text;
  alter table public.annual_competitions add column if not exists instructions text;
  alter table public.drawing_entries add column if not exists age smallint;
  alter table public.drawing_entries add column if not exists standard_category text;
  alter table public.contest_questions drop constraint if exists contest_questions_quiz_date_key;
  drop index if exists public.contest_questions_quiz_date_key;
  alter table public.annual_competitions drop constraint if exists unique_annual_competition;
  drop index if exists public.unique_annual_competition;

  -- 4) settings RLS & grants
  alter table public.settings enable row level security;
  execute 'drop policy if exists "public can read website settings" on public.settings';
  execute 'drop policy if exists "main admin can insert website settings" on public.settings';
  execute 'drop policy if exists "main admin can update website settings" on public.settings';
  execute 'drop policy if exists "main admin can delete website settings" on public.settings';
  execute 'create policy "public can read website settings" on public.settings for select to anon, authenticated using (key <> ''admin_pwd_hash'')';
  execute format('create policy "main admin can insert website settings" on public.settings for insert to authenticated with check (auth.uid() = %L::uuid)', a);
  execute format('create policy "main admin can update website settings" on public.settings for update to authenticated using (auth.uid() = %L::uuid) with check (auth.uid() = %L::uuid)', a, a);
  execute format('create policy "main admin can delete website settings" on public.settings for delete to authenticated using (auth.uid() = %L::uuid)', a);

  revoke all on public.settings from anon, authenticated;
  grant select on public.settings to anon, authenticated;
  grant insert, update, delete on public.settings to authenticated;
  delete from public.settings where key = 'admin_pwd_hash';

  -- 5) participant/contest tables: Edge Functions (service role) only
  alter table public.contest_questions   enable row level security;
  alter table public.contest_entries     enable row level security;
  alter table public.contest_winners     enable row level security;
  alter table public.annual_competitions enable row level security;
  alter table public.drawing_entries     enable row level security;
  revoke all on public.contest_questions, public.contest_entries, public.contest_winners,
                public.annual_competitions, public.drawing_entries from anon, authenticated;

  -- 6) storage policies
  execute 'drop policy if exists "public can read site assets" on storage.objects';
  execute 'drop policy if exists "main admin can upload site assets" on storage.objects';
  execute 'drop policy if exists "main admin can update site assets" on storage.objects';
  execute 'drop policy if exists "main admin can delete site assets" on storage.objects';
  execute 'create policy "public can read site assets" on storage.objects for select to anon, authenticated using (bucket_id = ''site-assets'')';
  execute format('create policy "main admin can upload site assets" on storage.objects for insert to authenticated with check (bucket_id = ''site-assets'' and auth.uid() = %L::uuid)', a);
  execute format('create policy "main admin can update site assets" on storage.objects for update to authenticated using (bucket_id = ''site-assets'' and auth.uid() = %L::uuid) with check (bucket_id = ''site-assets'' and auth.uid() = %L::uuid)', a, a);
  execute format('create policy "main admin can delete site assets" on storage.objects for delete to authenticated using (bucket_id = ''site-assets'' and auth.uid() = %L::uuid)', a);

  if exists (select 1 from pg_policies where schemaname='storage' and tablename='objects'
             and (coalesce(qual,'') ilike '%drawing-submissions%' or coalesce(with_check,'') ilike '%drawing-submissions%')) then
    raise exception 'STOP: a storage policy references drawing-submissions. Remove it – artwork must stay private.';
  end if;

  -- 7) settings.key unique (already exists on your project as settings_key_key – then this is skipped)
  if not exists (
    select 1 from pg_index i join pg_class c on c.oid = i.indrelid
    join pg_namespace n on n.oid = c.relnamespace
    join pg_attribute att on att.attrelid = c.oid and att.attnum = any(i.indkey)
    where n.nspname='public' and c.relname='settings' and att.attname='key' and i.indisunique and i.indnatts = 1) then
    if exists (select key from public.settings group by key having count(*) > 1) then
      raise notice 'settings has DUPLICATE keys - unique index NOT created. Clean duplicates first.';
    else
      create unique index settings_key_unique on public.settings(key);
    end if;
  end if;
end $$;

-- =====================================================================
-- READ-ONLY VERIFICATION – run after the script; all are SELECTs only.
-- =====================================================================
-- select id, public, file_size_limit, allowed_mime_types from storage.buckets;
-- select column_name from information_schema.columns where table_schema='public' and table_name='annual_competitions';
-- select schemaname, tablename, policyname, cmd, roles from pg_policies where schemaname in ('public','storage') order by 1,2,3;
-- select table_name, grantee, privilege_type from information_schema.role_table_grants where table_schema='public' and grantee in ('anon','authenticated') order by 1,2,3;
-- select competition_year, competition_name, status, is_enabled from public.annual_competitions;
-- select count(*) as settings_rows from public.settings;
