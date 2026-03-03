begin;

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  first_name text not null,
  last_name text,
  birth_date date not null,
  gender text,
  blood_type text,
  allergies text,
  chronic_conditions text,
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz,
  constraint profiles_first_name_len check (char_length(first_name) between 1 and 80)
);

create table if not exists public.illness_templates (
  id uuid primary key default gen_random_uuid(),
  created_by uuid references auth.users(id) on delete set null,
  is_system boolean not null default false,
  name text not null,
  average_duration_days integer not null,
  common_symptoms jsonb not null default '[]'::jsonb,
  critical_notes text not null,
  metadata jsonb not null default '{}'::jsonb,
  version integer not null default 1,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint illness_templates_duration_check check (average_duration_days > 0),
  constraint illness_templates_symptoms_array check (jsonb_typeof(common_symptoms) = 'array')
);

create table if not exists public.illness_records (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  template_id uuid references public.illness_templates(id) on delete set null,
  started_at timestamptz not null,
  ended_at timestamptz,
  diagnosis text,
  status text not null default 'active',
  clinician_name text,
  notes text,
  created_by uuid not null default auth.uid() references auth.users(id) on delete restrict,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint illness_records_status_check check (status in ('active', 'resolved', 'cancelled')),
  constraint illness_records_date_check check (ended_at is null or ended_at >= started_at)
);

create table if not exists public.symptom_logs (
  id uuid primary key default gen_random_uuid(),
  illness_record_id uuid not null references public.illness_records(id) on delete cascade,
  logged_at timestamptz not null default timezone('utc', now()),
  fever_c numeric(4,1),
  cough_severity smallint,
  pain_severity smallint,
  energy_level smallint,
  appetite_level smallint,
  extra_metrics jsonb not null default '{}'::jsonb,
  note text,
  created_by uuid not null default auth.uid() references auth.users(id) on delete restrict,
  created_at timestamptz not null default timezone('utc', now()),
  constraint symptom_logs_fever_range check (fever_c is null or (fever_c >= 30 and fever_c <= 45)),
  constraint symptom_logs_cough_range check (cough_severity is null or (cough_severity >= 0 and cough_severity <= 10)),
  constraint symptom_logs_pain_range check (pain_severity is null or (pain_severity >= 0 and pain_severity <= 10)),
  constraint symptom_logs_energy_range check (energy_level is null or (energy_level >= 1 and energy_level <= 5)),
  constraint symptom_logs_appetite_range check (appetite_level is null or (appetite_level >= 1 and appetite_level <= 5)),
  constraint symptom_logs_extra_metrics_object check (jsonb_typeof(extra_metrics) = 'object')
);

create table if not exists public.medication_schedules (
  id uuid primary key default gen_random_uuid(),
  illness_record_id uuid not null references public.illness_records(id) on delete cascade,
  medication_name text not null,
  dosage text not null,
  route text not null default 'oral',
  frequency_interval_hours integer,
  custom_times jsonb not null default '[]'::jsonb,
  start_at timestamptz not null,
  end_at timestamptz,
  status text not null default 'active',
  intake_history jsonb not null default '[]'::jsonb,
  instructions text,
  created_by uuid not null default auth.uid() references auth.users(id) on delete restrict,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint medication_schedules_status_check check (status in ('active', 'paused', 'completed')),
  constraint medication_schedules_date_check check (end_at is null or end_at >= start_at),
  constraint medication_schedules_frequency_check check (
    frequency_interval_hours is null or frequency_interval_hours > 0
  ),
  constraint medication_schedules_times_array check (jsonb_typeof(custom_times) = 'array'),
  constraint medication_schedules_intake_history_array check (jsonb_typeof(intake_history) = 'array')
);

create unique index if not exists idx_profiles_owner_name
  on public.profiles (owner_user_id, first_name, birth_date)
  where deleted_at is null;

create index if not exists idx_illness_records_profile on public.illness_records (profile_id);
create index if not exists idx_illness_records_status_dates on public.illness_records (status, started_at desc);
create index if not exists idx_symptom_logs_record_logged_at on public.symptom_logs (illness_record_id, logged_at desc);
create index if not exists idx_medication_schedules_record on public.medication_schedules (illness_record_id);
create index if not exists idx_medication_schedules_status on public.medication_schedules (status, start_at);

create unique index if not exists idx_illness_templates_system_name
  on public.illness_templates (lower(name))
  where is_system = true;

create unique index if not exists idx_illness_templates_user_name
  on public.illness_templates (created_by, lower(name))
  where is_system = false and created_by is not null;

create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger trg_illness_templates_updated_at
before update on public.illness_templates
for each row execute function public.set_updated_at();

create trigger trg_illness_records_updated_at
before update on public.illness_records
for each row execute function public.set_updated_at();

create trigger trg_medication_schedules_updated_at
before update on public.medication_schedules
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.profiles force row level security;

alter table public.illness_templates enable row level security;
alter table public.illness_templates force row level security;

alter table public.illness_records enable row level security;
alter table public.illness_records force row level security;

alter table public.symptom_logs enable row level security;
alter table public.symptom_logs force row level security;

alter table public.medication_schedules enable row level security;
alter table public.medication_schedules force row level security;

create policy "profiles_select_own"
on public.profiles
for select
using (owner_user_id = auth.uid() and deleted_at is null);

create policy "profiles_insert_own"
on public.profiles
for insert
with check (owner_user_id = auth.uid());

create policy "profiles_update_own"
on public.profiles
for update
using (owner_user_id = auth.uid())
with check (owner_user_id = auth.uid());

create policy "profiles_delete_own"
on public.profiles
for delete
using (owner_user_id = auth.uid());

create policy "illness_records_select_own_children"
on public.illness_records
for select
using (
  exists (
    select 1
    from public.profiles p
    where p.id = illness_records.profile_id
      and p.owner_user_id = auth.uid()
      and p.deleted_at is null
  )
);

create policy "illness_records_insert_own_children"
on public.illness_records
for insert
with check (
  exists (
    select 1
    from public.profiles p
    where p.id = illness_records.profile_id
      and p.owner_user_id = auth.uid()
      and p.deleted_at is null
  )
);

create policy "illness_records_update_own_children"
on public.illness_records
for update
using (
  exists (
    select 1
    from public.profiles p
    where p.id = illness_records.profile_id
      and p.owner_user_id = auth.uid()
      and p.deleted_at is null
  )
)
with check (
  exists (
    select 1
    from public.profiles p
    where p.id = illness_records.profile_id
      and p.owner_user_id = auth.uid()
      and p.deleted_at is null
  )
);

create policy "illness_records_delete_own_children"
on public.illness_records
for delete
using (
  exists (
    select 1
    from public.profiles p
    where p.id = illness_records.profile_id
      and p.owner_user_id = auth.uid()
      and p.deleted_at is null
  )
);

create policy "symptom_logs_select_own_children"
on public.symptom_logs
for select
using (
  exists (
    select 1
    from public.illness_records ir
    join public.profiles p on p.id = ir.profile_id
    where ir.id = symptom_logs.illness_record_id
      and p.owner_user_id = auth.uid()
      and p.deleted_at is null
  )
);

create policy "symptom_logs_insert_own_children"
on public.symptom_logs
for insert
with check (
  exists (
    select 1
    from public.illness_records ir
    join public.profiles p on p.id = ir.profile_id
    where ir.id = symptom_logs.illness_record_id
      and p.owner_user_id = auth.uid()
      and p.deleted_at is null
  )
);

create policy "symptom_logs_update_own_children"
on public.symptom_logs
for update
using (
  exists (
    select 1
    from public.illness_records ir
    join public.profiles p on p.id = ir.profile_id
    where ir.id = symptom_logs.illness_record_id
      and p.owner_user_id = auth.uid()
      and p.deleted_at is null
  )
)
with check (
  exists (
    select 1
    from public.illness_records ir
    join public.profiles p on p.id = ir.profile_id
    where ir.id = symptom_logs.illness_record_id
      and p.owner_user_id = auth.uid()
      and p.deleted_at is null
  )
);

create policy "symptom_logs_delete_own_children"
on public.symptom_logs
for delete
using (
  exists (
    select 1
    from public.illness_records ir
    join public.profiles p on p.id = ir.profile_id
    where ir.id = symptom_logs.illness_record_id
      and p.owner_user_id = auth.uid()
      and p.deleted_at is null
  )
);

create policy "medication_schedules_select_own_children"
on public.medication_schedules
for select
using (
  exists (
    select 1
    from public.illness_records ir
    join public.profiles p on p.id = ir.profile_id
    where ir.id = medication_schedules.illness_record_id
      and p.owner_user_id = auth.uid()
      and p.deleted_at is null
  )
);

create policy "medication_schedules_insert_own_children"
on public.medication_schedules
for insert
with check (
  exists (
    select 1
    from public.illness_records ir
    join public.profiles p on p.id = ir.profile_id
    where ir.id = medication_schedules.illness_record_id
      and p.owner_user_id = auth.uid()
      and p.deleted_at is null
  )
);

create policy "medication_schedules_update_own_children"
on public.medication_schedules
for update
using (
  exists (
    select 1
    from public.illness_records ir
    join public.profiles p on p.id = ir.profile_id
    where ir.id = medication_schedules.illness_record_id
      and p.owner_user_id = auth.uid()
      and p.deleted_at is null
  )
)
with check (
  exists (
    select 1
    from public.illness_records ir
    join public.profiles p on p.id = ir.profile_id
    where ir.id = medication_schedules.illness_record_id
      and p.owner_user_id = auth.uid()
      and p.deleted_at is null
  )
);

create policy "medication_schedules_delete_own_children"
on public.medication_schedules
for delete
using (
  exists (
    select 1
    from public.illness_records ir
    join public.profiles p on p.id = ir.profile_id
    where ir.id = medication_schedules.illness_record_id
      and p.owner_user_id = auth.uid()
      and p.deleted_at is null
  )
);

create policy "illness_templates_select_system_or_own"
on public.illness_templates
for select
using (is_system = true or created_by = auth.uid());

create policy "illness_templates_insert_own"
on public.illness_templates
for insert
with check (
  (is_system = false and created_by = auth.uid())
  or auth.role() = 'service_role'
);

create policy "illness_templates_update_own"
on public.illness_templates
for update
using ((is_system = false and created_by = auth.uid()) or auth.role() = 'service_role')
with check ((is_system = false and created_by = auth.uid()) or auth.role() = 'service_role');

create policy "illness_templates_delete_own"
on public.illness_templates
for delete
using ((is_system = false and created_by = auth.uid()) or auth.role() = 'service_role');

commit;
