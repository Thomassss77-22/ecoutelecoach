-- Écoute le Coach : partage avec les abonnés (plan de la semaine et détail des sorties).
-- À exécuter une fois dans Supabase, après social.sql : SQL Editor → New query → coller → Run. Le script peut être relancé sans risque.
-- Ces données ne sont lisibles que par le compte lui-même et par les personnes qui le suivent (et qui peuvent voir son profil).
-- Chacun choisit dans Mon profil s'il partage ou non ; s'il arrête, ses lignes sont effacées.

-- Plan de la semaine en cours et de la suivante, et réglages utiles à l'analyse (FTP, FC max, FC seuil, poids pour les W/kg)
create table if not exists public.shares (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  plan       jsonb not null default '{}'::jsonb check (octet_length(plan::text) < 200000),
  settings   jsonb not null default '{}'::jsonb check (octet_length(settings::text) < 5000),
  updated_at timestamptz not null default now()
);

-- Détail d'une sortie publiée : résumé, zones, courbe minute par minute, montées, blocs, efforts
create table if not exists public.activity_details (
  id         text primary key references public.activities(id) on delete cascade,
  user_id    uuid not null references auth.users(id) on delete cascade,
  data       jsonb not null check (octet_length(data::text) < 250000),
  updated_at timestamptz not null default now()
);
create index if not exists activity_details_user_idx on public.activity_details (user_id);

-- Qui peut lire le partage d'un compte : lui-même, ou quelqu'un qui le suit et qui a le droit de voir son profil
create or replace function public.can_see_share(owner uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select owner = auth.uid() or (
    exists (select 1 from public.follows f where f.follower = auth.uid() and f.followee = owner)
    and public.can_see(owner));
$$;

alter table public.shares           enable row level security;
alter table public.activity_details enable row level security;

drop policy if exists shares_read   on public.shares;
drop policy if exists shares_write  on public.shares;
drop policy if exists shares_update on public.shares;
drop policy if exists shares_delete on public.shares;
create policy shares_read   on public.shares for select to authenticated using (public.can_see_share(user_id));
create policy shares_write  on public.shares for insert to authenticated with check (auth.uid() = user_id);
create policy shares_update on public.shares for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy shares_delete on public.shares for delete to authenticated using (auth.uid() = user_id);

drop policy if exists details_read   on public.activity_details;
drop policy if exists details_write  on public.activity_details;
drop policy if exists details_update on public.activity_details;
drop policy if exists details_delete on public.activity_details;
create policy details_read   on public.activity_details for select to authenticated using (public.can_see_share(user_id));
create policy details_write  on public.activity_details for insert to authenticated with check (auth.uid() = user_id and exists (select 1 from public.activities a where a.id = activity_details.id and a.user_id = auth.uid()));
create policy details_update on public.activity_details for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy details_delete on public.activity_details for delete to authenticated using (auth.uid() = user_id);
