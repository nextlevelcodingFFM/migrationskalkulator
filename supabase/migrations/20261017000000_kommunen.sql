-- Migrationskalkulator Fachverfahren: Tabellen und Zugriffsregeln
-- Einmal im Supabase-Dashboard unter "SQL Editor" ausführen.
-- Danach eigene E-Mail-Adressen freischalten (siehe Abschnitt 4, NICHT in dieser Datei speichern).

-- 1. Kommunen: eine Zeile je Kommune, die Fachverfahren liegen als JSON im Feld "state"
create table if not exists public.kommunen (
  id          text primary key,
  name        text not null default '',
  created     bigint not null default 0,
  updated     bigint not null default 0,
  state       jsonb  not null default '{}'::jsonb,
  geaendert_von uuid default auth.uid(),
  geaendert_am  timestamptz not null default now()
);

-- 2. Freigeschaltete Personen: nur diese E-Mail-Adressen dürfen Daten sehen und ändern
create table if not exists public.zugelassene_nutzer (
  email text primary key
);

-- Hilfsfunktion: ist die angemeldete Person freigeschaltet?
create or replace function public.ist_zugelassen()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.zugelassene_nutzer z
    where lower(z.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

-- Änderungszeitpunkt und Bearbeiter automatisch setzen
create or replace function public.kommunen_stempel()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.geaendert_von := auth.uid();
  new.geaendert_am  := pg_catalog.now();
  return new;
end;
$$;
revoke execute on function public.kommunen_stempel() from public, anon, authenticated;

drop trigger if exists kommunen_stempel on public.kommunen;
create trigger kommunen_stempel
  before insert or update on public.kommunen
  for each row execute function public.kommunen_stempel();

-- 3. Zugriffsregeln (Row Level Security)
alter table public.kommunen enable row level security;
alter table public.zugelassene_nutzer enable row level security;

drop policy if exists "kommunen lesen"    on public.kommunen;
drop policy if exists "kommunen anlegen"  on public.kommunen;
drop policy if exists "kommunen aendern"  on public.kommunen;
drop policy if exists "kommunen loeschen" on public.kommunen;

create policy "kommunen lesen"    on public.kommunen for select to authenticated using (public.ist_zugelassen());
create policy "kommunen anlegen"  on public.kommunen for insert to authenticated with check (public.ist_zugelassen());
create policy "kommunen aendern"  on public.kommunen for update to authenticated using (public.ist_zugelassen()) with check (public.ist_zugelassen());
create policy "kommunen loeschen" on public.kommunen for delete to authenticated using (public.ist_zugelassen());

-- Jede angemeldete Person darf nur prüfen, ob ihre eigene Adresse freigeschaltet ist
drop policy if exists "eigene freischaltung lesen" on public.zugelassene_nutzer;
create policy "eigene freischaltung lesen" on public.zugelassene_nutzer
  for select to authenticated
  using (lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')));

-- Nicht angemeldete Besucher bekommen keinerlei Rechte
revoke all on public.kommunen from anon, authenticated;
revoke all on public.zugelassene_nutzer from anon, authenticated;
grant select, insert, update, delete on public.kommunen to authenticated;
grant select on public.zugelassene_nutzer to authenticated;
revoke execute on function public.ist_zugelassen() from public, anon;
grant execute on function public.ist_zugelassen() to authenticated;

-- Live-Aktualisierung für alle geöffneten Seiten
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'kommunen'
  ) then
    alter publication supabase_realtime add table public.kommunen;
  end if;
end $$;

-- 4. Personen freischalten: im SQL Editor separat ausführen, je Adresse eine Zeile.
--    Die Adressen gehören NICHT in diese Datei, weil das Repository öffentlich ist.
--
--    insert into public.zugelassene_nutzer (email) values ('vorname.nachname@kommune.de');
--
--    Freischaltung entziehen:
--    delete from public.zugelassene_nutzer where email = 'vorname.nachname@kommune.de';
