-- MiniTok backend starter schema for Supabase
-- Run in Supabase SQL Editor only after choosing/creating a dedicated MiniTok project.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null check (char_length(username) between 3 and 24),
  display_name text not null default '',
  bio text not null default '' check (char_length(bio) <= 160),
  avatar_url text,
  created_at timestamptz not null default now()
);
create table if not exists public.videos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  video_url text not null,
  caption text not null default '' check (char_length(caption) <= 300),
  created_at timestamptz not null default now()
);
create table if not exists public.likes (
  user_id uuid not null references public.profiles(id) on delete cascade,
  video_id uuid not null references public.videos(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(user_id, video_id)
);
create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  video_id uuid not null references public.videos(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 500),
  created_at timestamptz not null default now()
);
create table if not exists public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(follower_id, following_id),
  check(follower_id <> following_id)
);
create table if not exists public.live_rooms (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 100),
  status text not null default 'live' check (status in ('live','ended')),
  started_at timestamptz not null default now(),
  ended_at timestamptz
);
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.videos enable row level security;
alter table public.likes enable row level security;
alter table public.comments enable row level security;
alter table public.follows enable row level security;
alter table public.live_rooms enable row level security;
alter table public.messages enable row level security;

create policy "Profiles readable by everyone" on public.profiles for select using (true);
create policy "Users create own profile" on public.profiles for insert to authenticated with check ((select auth.uid()) = id);
create policy "Users update own profile" on public.profiles for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
create policy "Videos readable by everyone" on public.videos for select using (true);
create policy "Signed-in users upload own videos" on public.videos for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Owners delete own videos" on public.videos for delete to authenticated using ((select auth.uid()) = user_id);
create policy "Likes readable by everyone" on public.likes for select using (true);
create policy "Users add own likes" on public.likes for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Users remove own likes" on public.likes for delete to authenticated using ((select auth.uid()) = user_id);
create policy "Comments readable by everyone" on public.comments for select using (true);
create policy "Signed-in users comment as themselves" on public.comments for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Users delete own comments" on public.comments for delete to authenticated using ((select auth.uid()) = user_id);
create policy "Follows readable by everyone" on public.follows for select using (true);
create policy "Users follow as themselves" on public.follows for insert to authenticated with check ((select auth.uid()) = follower_id);
create policy "Users unfollow as themselves" on public.follows for delete to authenticated using ((select auth.uid()) = follower_id);
create policy "Live rooms readable by everyone" on public.live_rooms for select using (true);
create policy "Users start own live room" on public.live_rooms for insert to authenticated with check ((select auth.uid()) = host_id);
create policy "Hosts update own live room" on public.live_rooms for update to authenticated using ((select auth.uid()) = host_id) with check ((select auth.uid()) = host_id);
create policy "Participants read their messages" on public.messages for select to authenticated using ((select auth.uid()) = sender_id or (select auth.uid()) = receiver_id);
create policy "Users send messages as themselves" on public.messages for insert to authenticated with check ((select auth.uid()) = sender_id);
