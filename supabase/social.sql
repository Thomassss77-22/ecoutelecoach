-- Écoute le Coach : profils, activités publiées, abonnements et bravos.
-- À exécuter une fois dans Supabase : SQL Editor → New query → coller → Run. Le script peut être relancé sans risque.
-- Les données de santé (VFC, FC, sommeil, check-in, douleur, maladie, poids) ne sont jamais publiées : elles ne sont pas dans ces tables.

-- Profil public : un par compte
create table if not exists public.profiles (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  handle     text not null unique check (handle ~ '^[a-z0-9_.-]{3,24}$'),
  name       text not null check (char_length(name) between 2 and 40),
  city       text check (city is null or char_length(city) <= 40),
  bio        text check (bio is null or char_length(bio) <= 200),
  club       text check (club is null or char_length(club) <= 32),
  sport      text,
  color      text,
  visibility text not null default 'public' check (visibility in ('public','following','private')),
  stats      jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists profiles_club_idx on public.profiles (club);

-- Abonnements : follower suit followee
create table if not exists public.follows (
  follower   uuid not null references auth.users(id) on delete cascade,
  followee   uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower, followee),
  check (follower <> followee)
);
create index if not exists follows_followee_idx on public.follows (followee);

-- Activités publiées : un résumé par séance (pas de fréquence cardiaque, pas de note personnelle)
create table if not exists public.activities (
  id         text primary key,
  user_id    uuid not null references auth.users(id) on delete cascade,
  date       date not null,
  sport      text not null,
  title      text not null,
  dur        integer not null default 0,
  km         numeric,
  gain       integer,
  kind       text,
  pts        integer not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists activities_user_date_idx on public.activities (user_id, date desc);

-- Bravos (équivalent des kudos)
create table if not exists public.kudos (
  activity_id text not null references public.activities(id) on delete cascade,
  user_id     uuid not null references auth.users(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (activity_id, user_id)
);

-- Qui peut voir le profil d'un compte : lui-même ; tout le monde si public ; si « following », seulement les personnes qu'il suit lui-même
create or replace function public.can_see(owner uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select owner = auth.uid() or exists (
    select 1 from public.profiles p where p.user_id = owner and (
      p.visibility = 'public'
      or (p.visibility = 'following' and exists (select 1 from public.follows f where f.follower = owner and f.followee = auth.uid()))
    ));
$$;

alter table public.profiles   enable row level security;
alter table public.follows    enable row level security;
alter table public.activities enable row level security;
alter table public.kudos      enable row level security;

drop policy if exists profiles_read   on public.profiles;
drop policy if exists profiles_write  on public.profiles;
drop policy if exists profiles_update on public.profiles;
drop policy if exists profiles_delete on public.profiles;
create policy profiles_read   on public.profiles for select to authenticated using (public.can_see(user_id));
create policy profiles_write  on public.profiles for insert to authenticated with check (auth.uid() = user_id);
create policy profiles_update on public.profiles for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy profiles_delete on public.profiles for delete to authenticated using (auth.uid() = user_id);

drop policy if exists follows_read   on public.follows;
drop policy if exists follows_write  on public.follows;
drop policy if exists follows_delete on public.follows;
create policy follows_read   on public.follows for select to authenticated using (true);
create policy follows_write  on public.follows for insert to authenticated with check (auth.uid() = follower);
create policy follows_delete on public.follows for delete to authenticated using (auth.uid() = follower);

drop policy if exists activities_read   on public.activities;
drop policy if exists activities_write  on public.activities;
drop policy if exists activities_update on public.activities;
drop policy if exists activities_delete on public.activities;
create policy activities_read   on public.activities for select to authenticated using (public.can_see(user_id));
create policy activities_write  on public.activities for insert to authenticated with check (auth.uid() = user_id);
create policy activities_update on public.activities for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy activities_delete on public.activities for delete to authenticated using (auth.uid() = user_id);

drop policy if exists kudos_read   on public.kudos;
drop policy if exists kudos_write  on public.kudos;
drop policy if exists kudos_delete on public.kudos;
create policy kudos_read   on public.kudos for select to authenticated using (true);
create policy kudos_write  on public.kudos for insert to authenticated with check (auth.uid() = user_id and exists (select 1 from public.activities a where a.id = activity_id and public.can_see(a.user_id)));
create policy kudos_delete on public.kudos for delete to authenticated using (auth.uid() = user_id);
