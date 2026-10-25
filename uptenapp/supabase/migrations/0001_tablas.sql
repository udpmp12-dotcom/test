-- UpTen · Migración 1: tablas principales
-- Pega este archivo completo en Supabase > SQL Editor > Run.

-- Negocios (cada cafetería)
create table public.businesses (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  name text not null,
  brand_color text not null default '#6F4E37' check (brand_color ~ '^#[0-9A-Fa-f]{6}$'),
  text_color text not null default '#FFFFFF' check (text_color ~ '^#[0-9A-Fa-f]{6}$'),
  logo_url text,
  stamps_required int not null default 8 check (stamps_required between 2 and 20),
  reward_text text not null default 'Bebida gratis',
  terms_text text not null default '',
  contact_text text not null default '',
  cooldown_minutes int not null default 10 check (cooldown_minutes between 0 and 1440),
  status text not null default 'active' check (status in ('active', 'paused')),
  plan_status text not null default 'trial' check (plan_status in ('trial', 'paid', 'overdue')),
  next_payment_date date,
  admin_notes text not null default '',
  created_at timestamptz not null default now()
);

-- Dueños de cada negocio (usuarios de Supabase Auth)
create table public.business_members (
  business_id uuid not null references public.businesses(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'owner' check (role = 'owner'),
  primary key (business_id, user_id)
);
create index on public.business_members (user_id);

-- Empleados (entran al escáner con PIN)
create table public.employees (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  pin_hash text not null,
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create index on public.employees (business_id);

-- Clientes finales
create table public.customers (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  phone text not null check (phone ~ '^[0-9]{10}$'),
  created_at timestamptz not null default now(),
  unique (business_id, phone)
);

-- Tarjetas de sellos (una por cliente)
-- serial = lo que lleva el QR. Es largo y aleatorio: nadie lo puede adivinar.
create table public.cards (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_id uuid not null unique references public.customers(id) on delete cascade,
  serial text not null unique default replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''),
  auth_token text not null default replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''),
  stamps int not null default 0 check (stamps >= 0),
  updated_at timestamptz not null default now(),
  last_visit_at timestamptz,
  created_at timestamptz not null default now()
);
create index on public.cards (business_id);
create index on public.cards (business_id, updated_at);

-- Historial de sellos / canjes / deshacer
create table public.stamp_events (
  id uuid primary key default gen_random_uuid(),
  card_id uuid not null references public.cards(id) on delete cascade,
  employee_id uuid references public.employees(id) on delete set null,
  type text not null check (type in ('stamp', 'redeem', 'undo')),
  undoes_event_id uuid references public.stamp_events(id) on delete set null,
  created_at timestamptz not null default now()
);
create index on public.stamp_events (card_id, created_at desc);
create index on public.stamp_events (created_at);

-- iPhones que tienen el pase en Wallet (para mandarles avisos push)
create table public.device_registrations (
  id uuid primary key default gen_random_uuid(),
  card_id uuid not null references public.cards(id) on delete cascade,
  device_library_id text not null,
  push_token text not null,
  created_at timestamptz not null default now(),
  unique (device_library_id, card_id)
);
create index on public.device_registrations (card_id);

-- Intentos de PIN (para frenar a quien quiera adivinar un PIN)
create table public.login_attempts (
  id bigint generated always as identity primary key,
  key text not null,
  created_at timestamptz not null default now()
);
create index on public.login_attempts (key, created_at);

-- Cada vez que cambia una tarjeta, se actualiza su fecha (Wallet usa esto para saber si hay cambios)
create function public.touch_card() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

create trigger cards_touch before update on public.cards
for each row execute function public.touch_card();
