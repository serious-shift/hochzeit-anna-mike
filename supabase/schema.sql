create table if not exists public.rsvp_responses (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  full_name text not null check (char_length(trim(full_name)) >= 2),
  email text not null check (position('@' in email) > 1),
  phone text,
  attendance_status text not null check (attendance_status in ('attending', 'declined')),
  has_plus_one boolean not null default false,
  plus_one_name text,
  song_request text,
  message text,
  client_timestamp timestamptz,
  constraint plus_one_name_consistency check (
    (has_plus_one = true and char_length(trim(coalesce(plus_one_name, ''))) > 0)
    or has_plus_one = false
  )
);

create index if not exists rsvp_responses_created_at_desc_idx
  on public.rsvp_responses (created_at desc);

create index if not exists rsvp_responses_email_lower_idx
  on public.rsvp_responses ((lower(email)));

alter table public.rsvp_responses enable row level security;

drop policy if exists rsvp_responses_anon_insert on public.rsvp_responses;
create policy rsvp_responses_anon_insert
on public.rsvp_responses
for insert
to anon
with check (true);

revoke select, update, delete on public.rsvp_responses from anon;
revoke select, update, delete on public.rsvp_responses from authenticated;
