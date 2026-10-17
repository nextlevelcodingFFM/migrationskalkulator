-- Zugang per Link: Wer den Link mit gültigem Schlüssel hat (…/migrationskalkulator/?zugang=<Schlüssel>),
-- darf Kommunen ohne Anmeldung sehen und ändern. Der Schlüssel liegt nur in der Datenbank (Bereich "privat"),
-- nie im Repository. Die Webseite schickt ihn als Kopfzeile "x-zugang" mit.

create schema if not exists privat;
revoke all on schema privat from public, anon, authenticated;

create table if not exists privat.zugangslinks (
  token       text primary key check (length(token) >= 32),
  bezeichnung text not null default '',
  aktiv       boolean not null default true,
  erstellt    timestamptz not null default now()
);
revoke all on privat.zugangslinks from public, anon, authenticated;

create or replace function public.link_gueltig()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from privat.zugangslinks z
    where z.aktiv
      and z.token = coalesce((nullif(current_setting('request.headers', true), '')::json) ->> 'x-zugang', '')
  );
$$;
revoke execute on function public.link_gueltig() from public;
grant execute on function public.link_gueltig() to anon, authenticated;

grant select, insert, update, delete on public.kommunen to anon;

create policy "link lesen"    on public.kommunen for select to anon using (public.link_gueltig());
create policy "link anlegen"  on public.kommunen for insert to anon with check (public.link_gueltig());
create policy "link aendern"  on public.kommunen for update to anon using (public.link_gueltig()) with check (public.link_gueltig());
create policy "link loeschen" on public.kommunen for delete to anon using (public.link_gueltig());

-- Neuen Zugangslink erzeugen (im SQL Editor ausführen, Ergebnis NICHT ins Repository schreiben):
--   insert into privat.zugangslinks (token, bezeichnung)
--   values (replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''), 'Bezeichnung')
--   returning token;
--
-- Link abschalten:
--   update privat.zugangslinks set aktiv = false where bezeichnung = 'Bezeichnung';
