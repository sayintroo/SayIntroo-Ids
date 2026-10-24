-- =====================================================================
--  #AanshKiShaadi — Supabase setup (run ONCE in Supabase → SQL Editor)
--  Covers: Real Shagun (donations) + Party app (teams, polls, gossip,
--  aura, phere, Rishta Pakka).
--
--  👉 STEP 1: change the two passwords right below, then click "Run".
--  Safe to re-run: it will NOT delete your data, it only updates
--  functions/policies and the two passwords.
-- =====================================================================

create table if not exists app_secrets (key text primary key, value text not null);
alter table app_secrets enable row level security;   -- no policies = nobody can read it from the browser

insert into app_secrets (key, value) values
  ('shagun_admin', 'change-me-shagun'),   -- volunteers use this on /admin
  ('party_host',   'change-me-host')      -- host uses this on /party/admin
on conflict (key) do update set value = excluded.value;


-- ---------------------------------------------------------------------
--  Tables
-- ---------------------------------------------------------------------

-- Real Shagun
create table if not exists donations (
  id         bigint generated always as identity primary key,
  name       text not null check (char_length(name) between 1 and 60),
  amount     int  not null check (amount between 1 and 10000000),
  message    text check (char_length(message) <= 200),
  created_at timestamptz not null default now()
);

create table if not exists aashirwads (
  id         bigint generated always as identity primary key,
  name       text not null check (char_length(name) between 1 and 60),
  message    text not null check (char_length(message) between 2 and 200),
  approved   boolean not null default false,
  created_at timestamptz not null default now()
);

-- Party
create table if not exists guests (
  id         uuid primary key default gen_random_uuid(),
  name       text not null check (char_length(name) between 1 and 40),
  handle     text not null unique check (handle ~ '^[a-z0-9._]{1,30}$'),
  team       text not null check (team in ('ladkiwale', 'ladkewale')),
  aura       int  not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists guest_secrets (
  guest_id uuid primary key references guests (id) on delete cascade,
  token    uuid not null default gen_random_uuid()
);

create table if not exists teams (
  name  text primary key check (name in ('ladkiwale', 'ladkewale')),
  bonus int not null default 0
);
insert into teams (name) values ('ladkiwale'), ('ladkewale') on conflict do nothing;

create table if not exists polls (
  id         bigint generated always as identity primary key,
  question   text   not null check (char_length(question) between 2 and 160),
  options    text[] not null,
  counts     int[]  not null,
  status     text   not null default 'open' check (status in ('open', 'closed')),
  created_at timestamptz not null default now()
);

create table if not exists votes (
  poll_id    bigint not null references polls (id) on delete cascade,
  guest_id   uuid   not null references guests (id) on delete cascade,
  option_idx int    not null,
  created_at timestamptz not null default now(),
  primary key (poll_id, guest_id)
);

create table if not exists gossip (
  id         bigint generated always as identity primary key,
  text       text not null check (char_length(text) between 3 and 140),
  status     text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now()
);

create table if not exists aura_log (
  id         bigint generated always as identity primary key,
  guest_id   uuid references guests (id) on delete cascade,
  team       text check (team in ('ladkiwale', 'ladkewale')),
  points     int  not null,
  reason     text not null default '' check (char_length(reason) <= 80),
  created_at timestamptz not null default now(),
  check ((guest_id is null) <> (team is null))
);

create table if not exists phere (
  num    int primary key check (num between 1 and 7),
  title  text not null,
  winner text check (winner in ('ladkiwale', 'ladkewale'))
);
insert into phere (num, title) values
  (1, 'Joota chupai heist'),
  (2, 'Naagin dance-off'),
  (3, 'Antakshari showdown'),
  (4, 'Varmala lift challenge'),
  (5, 'Best baraat entry'),
  (6, 'Ring dhoondo'),
  (7, 'Bidaai acting (Oscar level)')
on conflict do nothing;

create table if not exists event_state (
  id            int primary key default 1 check (id = 1),
  picks_state   text not null default 'locked' check (picks_state in ('locked', 'open', 'revealed')),
  picks_open_at timestamptz
);
insert into event_state (id) values (1) on conflict do nothing;

-- Rishta Pakka picks: NO read policy at all → never readable from any browser.
create table if not exists picks (
  picker     uuid not null references guests (id) on delete cascade,
  picked     uuid not null references guests (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (picker, picked),
  check (picker <> picked)
);


-- ---------------------------------------------------------------------
--  Row level security: public can READ only what is meant to be public.
--  All writes go through the functions below (which check passwords /
--  guest tokens). Tables without a policy are invisible to the browser.
-- ---------------------------------------------------------------------
alter table donations     enable row level security;
alter table aashirwads    enable row level security;
alter table guests        enable row level security;
alter table guest_secrets enable row level security;
alter table teams         enable row level security;
alter table polls         enable row level security;
alter table votes         enable row level security;
alter table gossip        enable row level security;
alter table aura_log      enable row level security;
alter table phere         enable row level security;
alter table event_state   enable row level security;
alter table picks         enable row level security;

drop policy if exists "read" on donations;   create policy "read" on donations   for select using (true);
drop policy if exists "read" on aashirwads;  create policy "read" on aashirwads  for select using (approved);
drop policy if exists "read" on guests;      create policy "read" on guests      for select using (true);
drop policy if exists "read" on teams;       create policy "read" on teams       for select using (true);
drop policy if exists "read" on polls;       create policy "read" on polls       for select using (true);
drop policy if exists "read" on gossip;      create policy "read" on gossip      for select using (status = 'approved');
drop policy if exists "read" on aura_log;    create policy "read" on aura_log    for select using (true);
drop policy if exists "read" on phere;       create policy "read" on phere       for select using (true);
drop policy if exists "read" on event_state; create policy "read" on event_state for select using (true);


-- ---------------------------------------------------------------------
--  Internal helpers (not callable from the browser)
-- ---------------------------------------------------------------------
create or replace function _check_pw(k text, pw text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from app_secrets where key = k and value = pw) then
    raise exception 'Galat password 🙅';
  end if;
end $$;

create or replace function _check_guest(gid uuid, tok uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from guest_secrets where guest_id = gid and token = tok) then
    raise exception 'Session expire ho gaya — dobara join karo';
  end if;
end $$;

create or replace function _picks_phase() returns text
language sql stable security definer set search_path = public as $$
  select case
    when picks_state = 'locked' and picks_open_at is not null and now() >= picks_open_at then 'open'
    else picks_state end
  from event_state where id = 1;
$$;

revoke all on function _check_pw(text, text)     from public, anon, authenticated;
revoke all on function _check_guest(uuid, uuid)  from public, anon, authenticated;
revoke all on function _picks_phase()            from public, anon, authenticated;


-- ---------------------------------------------------------------------
--  Real Shagun functions
-- ---------------------------------------------------------------------
create or replace function check_password(kind text, pw text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from app_secrets where key = kind and value = pw);
$$;

create or replace function add_donation(pw text, p_name text, p_amount int, p_message text default null)
returns bigint language plpgsql security definer set search_path = public as $$
declare new_id bigint;
begin
  perform _check_pw('shagun_admin', pw);
  insert into donations (name, amount, message)
  values (trim(p_name), p_amount, nullif(trim(coalesce(p_message, '')), ''))
  returning id into new_id;
  return new_id;
end $$;

create or replace function delete_donation(pw text, p_id bigint) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform _check_pw('shagun_admin', pw);
  delete from donations where id = p_id;
end $$;

-- Anyone can send an aashirwad from the card generator; it waits for approval.
create or replace function submit_aashirwad(p_name text, p_message text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if (select count(*) from aashirwads where not approved) > 300 then
    raise exception 'Queue full hai, thodi der baad try karo';
  end if;
  insert into aashirwads (name, message) values (left(trim(p_name), 60), left(trim(p_message), 200));
end $$;

create or replace function admin_pending_aashirwads(pw text) returns setof aashirwads
language plpgsql security definer set search_path = public as $$
begin
  perform _check_pw('shagun_admin', pw);
  return query select * from aashirwads where not approved order by created_at limit 100;
end $$;

create or replace function moderate_aashirwad(pw text, p_id bigint, p_approve boolean) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform _check_pw('shagun_admin', pw);
  if p_approve then update aashirwads set approved = true where id = p_id;
  else delete from aashirwads where id = p_id; end if;
end $$;

create or replace function reset_shagun(pw text) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform _check_pw('shagun_admin', pw);
  delete from donations where true;
  delete from aashirwads where true;
end $$;


-- ---------------------------------------------------------------------
--  Party: guest functions
-- ---------------------------------------------------------------------
create or replace function join_party(p_name text, p_handle text) returns json
language plpgsql security definer set search_path = public as $$
declare
  h text := lower(regexp_replace(trim(p_handle), '^@+', ''));
  n text := trim(p_name);
  girls int; boys int; t text; g guests; tok uuid;
begin
  if n = '' then raise exception 'Naam toh daalo yaar'; end if;
  if h !~ '^[a-z0-9._]{1,30}$' then raise exception 'Insta handle sahi daalo (sirf letters, numbers, . _)'; end if;
  perform pg_advisory_xact_lock(424242);   -- one join at a time → teams stay balanced
  if exists (select 1 from guests where handle = h) then
    raise exception 'Ye handle already join ho chuka hai. Phone badla? Host ko bolo reset kare.';
  end if;
  select count(*) filter (where team = 'ladkiwale'), count(*) filter (where team = 'ladkewale')
    into girls, boys from guests;
  t := case when girls < boys then 'ladkiwale' when boys < girls then 'ladkewale'
            when random() < 0.5 then 'ladkiwale' else 'ladkewale' end;
  insert into guests (name, handle, team) values (left(n, 40), h, t) returning * into g;
  insert into guest_secrets (guest_id) values (g.id) returning token into tok;
  return json_build_object('id', g.id, 'token', tok, 'name', g.name, 'handle', g.handle, 'team', g.team);
end $$;

create or replace function whoami(gid uuid, tok uuid) returns json
language plpgsql security definer set search_path = public as $$
declare g guests;
begin
  perform _check_guest(gid, tok);
  select * into g from guests where id = gid;
  return row_to_json(g);
end $$;

create or replace function cast_vote(gid uuid, tok uuid, p_poll bigint, p_idx int) returns void
language plpgsql security definer set search_path = public as $$
declare p polls; inserted int;
begin
  perform _check_guest(gid, tok);
  select * into p from polls where id = p_poll for update;
  if p.id is null or p.status <> 'open' then raise exception 'Ye poll band ho gaya'; end if;
  if p_idx < 0 or p_idx >= array_length(p.options, 1) then raise exception 'Invalid option'; end if;
  insert into votes (poll_id, guest_id, option_idx) values (p_poll, gid, p_idx) on conflict do nothing;
  get diagnostics inserted = row_count;
  if inserted = 0 then raise exception 'Vote already de diya bestie 😌'; end if;
  update polls set counts[p_idx + 1] = counts[p_idx + 1] + 1 where id = p_poll;
end $$;

create or replace function my_votes(gid uuid, tok uuid) returns table (poll_id bigint, option_idx int)
language plpgsql security definer set search_path = public as $$
begin
  perform _check_guest(gid, tok);
  return query select v.poll_id, v.option_idx from votes v where v.guest_id = gid;
end $$;

-- Gossip is anonymous: we check you're a guest but never store who sent it.
create or replace function send_gossip(gid uuid, tok uuid, p_text text) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform _check_guest(gid, tok);
  if char_length(trim(p_text)) < 3 then raise exception 'Thoda aur masala daalo'; end if;
  insert into gossip (text) values (left(trim(p_text), 140));
end $$;

-- Rishta Pakka
create or replace function set_picks(gid uuid, tok uuid, p_picked uuid[]) returns void
language plpgsql security definer set search_path = public as $$
declare clean uuid[];
begin
  perform _check_guest(gid, tok);
  if _picks_phase() <> 'open' then raise exception 'Picks abhi open nahi hain'; end if;
  select coalesce(array_agg(distinct x), '{}') into clean
    from unnest(coalesce(p_picked, '{}')) x
    where x <> gid and exists (select 1 from guests where id = x);
  if array_length(clean, 1) > 3 then raise exception 'Max 3 log choose kar sakte ho'; end if;
  delete from picks where picker = gid;
  insert into picks (picker, picked) select gid, x from unnest(clean) x;
end $$;

create or replace function my_picks(gid uuid, tok uuid) returns uuid[]
language plpgsql security definer set search_path = public as $$
begin
  perform _check_guest(gid, tok);
  return coalesce((select array_agg(picked) from picks where picker = gid), '{}');
end $$;

-- Only returns MUTUAL matches, and only after the host reveals.
create or replace function my_rishtas(gid uuid, tok uuid) returns json
language plpgsql security definer set search_path = public as $$
declare ph text := _picks_phase();
begin
  perform _check_guest(gid, tok);
  if ph <> 'revealed' then
    return json_build_object('phase', ph, 'open_at', (select picks_open_at from event_state where id = 1), 'matches', '[]'::json);
  end if;
  return json_build_object('phase', ph, 'matches', coalesce((
    select json_agg(json_build_object('name', g.name, 'handle', g.handle))
    from picks a
    join picks b on b.picker = a.picked and b.picked = a.picker
    join guests g on g.id = a.picked
    where a.picker = gid), '[]'::json));
end $$;

-- Counts only. Never names.
create or replace function rishta_stats() returns json
language sql stable security definer set search_path = public as $$
  select json_build_object(
    'phase',   _picks_phase(),
    'open_at', (select picks_open_at from event_state where id = 1),
    'pickers', (select count(distinct picker) from picks),
    'pakke',   case when _picks_phase() = 'revealed' then
                 (select count(*) from picks a join picks b on b.picker = a.picked and b.picked = a.picker
                  where a.picker < a.picked) end);
$$;


-- ---------------------------------------------------------------------
--  Party: host functions (need the party_host password)
-- ---------------------------------------------------------------------
create or replace function host_create_poll(pw text, p_question text, p_options text[]) returns bigint
language plpgsql security definer set search_path = public as $$
declare opts text[]; new_id bigint;
begin
  perform _check_pw('party_host', pw);
  select array_agg(trim(o)) into opts from unnest(p_options) o where trim(o) <> '';
  if coalesce(array_length(opts, 1), 0) < 2 or array_length(opts, 1) > 6 then
    raise exception 'Poll mein 2 se 6 options chahiye';
  end if;
  insert into polls (question, options, counts)
  values (trim(p_question), opts, array_fill(0, array[array_length(opts, 1)]))
  returning id into new_id;
  return new_id;
end $$;

create or replace function host_set_poll(pw text, p_id bigint, p_status text) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform _check_pw('party_host', pw);
  if p_status = 'delete' then delete from polls where id = p_id;
  else update polls set status = p_status where id = p_id; end if;
end $$;

create or replace function host_list_gossip(pw text) returns setof gossip
language plpgsql security definer set search_path = public as $$
begin
  perform _check_pw('party_host', pw);
  return query select * from gossip where status <> 'rejected' order by created_at desc limit 200;
end $$;

create or replace function host_moderate_gossip(pw text, p_id bigint, p_status text) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform _check_pw('party_host', pw);
  update gossip set status = p_status where id = p_id;
end $$;

create or replace function host_give_aura(pw text, p_guest uuid, p_team text, p_points int, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform _check_pw('party_host', pw);
  if p_points = 0 or abs(p_points) > 5000 then raise exception 'Points sahi daalo'; end if;
  if p_guest is not null then
    update guests set aura = aura + p_points where id = p_guest;
    insert into aura_log (guest_id, points, reason) values (p_guest, p_points, left(coalesce(p_reason, ''), 80));
  else
    update teams set bonus = bonus + p_points where name = p_team;
    insert into aura_log (team, points, reason) values (p_team, p_points, left(coalesce(p_reason, ''), 80));
  end if;
end $$;

create or replace function host_undo_aura(pw text, p_log bigint) returns void
language plpgsql security definer set search_path = public as $$
declare l aura_log;
begin
  perform _check_pw('party_host', pw);
  delete from aura_log where id = p_log returning * into l;
  if l.id is null then return; end if;
  if l.guest_id is not null then update guests set aura = aura - l.points where id = l.guest_id;
  else update teams set bonus = bonus - l.points where name = l.team; end if;
end $$;

create or replace function host_set_phera(pw text, p_num int, p_winner text, p_title text) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform _check_pw('party_host', pw);
  update phere set winner = nullif(p_winner, ''), title = coalesce(nullif(trim(p_title), ''), title)
  where num = p_num;
end $$;

create or replace function host_set_picks(pw text, p_state text, p_open_at timestamptz default null) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform _check_pw('party_host', pw);
  update event_state set picks_state = p_state, picks_open_at = p_open_at where id = 1;
end $$;

create or replace function host_remove_guest(pw text, p_guest uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform _check_pw('party_host', pw);
  -- take their votes back out of the poll counts first
  update polls p set counts[v.option_idx + 1] = counts[v.option_idx + 1] - 1
    from votes v where v.poll_id = p.id and v.guest_id = p_guest;
  delete from guests where id = p_guest;
end $$;

create or replace function host_reset_party(pw text) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform _check_pw('party_host', pw);
  delete from picks where true;
  delete from votes where true;
  delete from polls where true;
  delete from gossip where true;
  delete from aura_log where true;
  delete from guests where true;
  update teams set bonus = 0 where true;
  update phere set winner = null where true;
  update event_state set picks_state = 'locked', picks_open_at = null where id = 1;
end $$;


-- ---------------------------------------------------------------------
--  Realtime: push changes of the public tables to every screen
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['donations','aashirwads','guests','teams','polls','gossip','aura_log','phere','event_state'] loop
    begin
      execute format('alter publication supabase_realtime add table %I', t);
    exception when duplicate_object then null;
    end;
  end loop;
end $$;

-- Done ✅  Now copy your Project URL + anon key into public/config.js
