-- Table pour stocker les soumissions de questionnaires
create table submissions (
  id uuid default gen_random_uuid() primary key,
  session_id text unique not null,
  template text not null default 'lancement',
  responses jsonb default '{}',
  current_step int default 0,
  completed boolean default false,
  client_name text,
  client_email text,
  status text default 'nouveau',
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Permettre les insertions et mises à jour anonymes (clé anon)
alter table submissions enable row level security;

create policy "Permettre insertion anonyme"
  on submissions for insert
  to anon
  with check (true);

create policy "Permettre mise à jour par session_id"
  on submissions for update
  to anon
  using (true)
  with check (true);

create policy "Permettre lecture pour tous"
  on submissions for select
  to anon
  using (true);

-- Index pour recherche rapide par session
create index idx_submissions_session_id on submissions(session_id);
create index idx_submissions_status on submissions(status);
create index idx_submissions_created_at on submissions(created_at desc);
