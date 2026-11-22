-- Classement d'Écoute le Coach : une ligne par utilisateur qui choisit d'apparaître.
-- À exécuter une fois dans Supabase : SQL Editor → New query → coller → Run.
create table if not exists public.board (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  pseudo     text not null check (char_length(pseudo) between 2 and 24),
  grp        text check (grp is null or char_length(grp) <= 32),
  week       date,
  pts_week   integer not null default 0 check (pts_week between 0 and 100000),
  pts_total  integer not null default 0 check (pts_total between 0 and 10000000),
  streak     integer not null default 0 check (streak between 0 and 1000),
  badges     integer not null default 0 check (badges between 0 and 1000),
  updated_at timestamptz not null default now()
);
create index if not exists board_grp_idx on public.board (grp);
alter table public.board enable row level security;
-- tout utilisateur connecté peut lire le classement ; chacun n'écrit que sa propre ligne
drop policy if exists "board_read"   on public.board;
drop policy if exists "board_insert" on public.board;
drop policy if exists "board_update" on public.board;
drop policy if exists "board_delete" on public.board;
create policy "board_read"   on public.board for select to authenticated using (true);
create policy "board_insert" on public.board for insert to authenticated with check (auth.uid() = user_id);
create policy "board_update" on public.board for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "board_delete" on public.board for delete to authenticated using (auth.uid() = user_id);
