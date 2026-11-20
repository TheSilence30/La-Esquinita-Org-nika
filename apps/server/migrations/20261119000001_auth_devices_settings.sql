-- migrate:up

-- Phase 1 foundations (docs/modelo-datos.md §2.8–§2.9, conventions §1).
-- Masters carry `active` (nothing is deleted) and `version`, taken from one
-- global sequence on every insert/update, so GET /sync/pull?since= can ask
-- for "everything changed after N" across tables.

create sequence sync_version_seq;

create function set_sync_version() returns trigger
language plpgsql as $$
begin
  new.version := nextval('sync_version_seq');
  return new;
end
$$;

-- Users, roles and permissions ------------------------------------------------

create table users (
  id                   uuid primary key,
  username             text not null check (btrim(username) <> ''),
  full_name            text not null,
  password_hash        text not null, -- Argon2id; never leaves the server
  pin_hash             text,          -- Argon2id of the PIN (quick/offline login)
  must_change_password boolean not null default false,
  active               boolean not null default true,
  version              bigint not null,
  created_at           timestamptz not null default now()
);
create unique index users_username_uq on users (lower(username));

create table roles (
  id        uuid primary key,
  code      text not null unique,
  name      text not null,
  home_view text not null, -- first screen of the role
  active    boolean not null default true,
  version   bigint not null
);

create table permissions (
  code        text primary key check (code ~ '^[a-z_]+\.[a-z_]+$'), -- modulo.accion
  description text not null,
  active      boolean not null default true,
  version     bigint not null
);

create table role_permissions (
  role_id         uuid not null references roles (id),
  permission_code text not null references permissions (code),
  active          boolean not null default true,
  version         bigint not null,
  primary key (role_id, permission_code)
);

create table user_roles (
  user_id uuid not null references users (id),
  role_id uuid not null references roles (id),
  active  boolean not null default true,
  version bigint not null,
  primary key (user_id, role_id)
);

-- Devices, series and settings ------------------------------------------------

create table devices (
  id            uuid primary key, -- the device_id the device generated
  name          text not null,
  platform      text not null check (platform in ('android', 'windows')),
  series_prefix text not null unique check (series_prefix ~ '^[A-Z][0-9]+$'), -- T1, P1
  barcode_digit int not null unique check (barcode_digit between 0 and 9),
  active        boolean not null default true,
  version       bigint not null,
  created_at    timestamptz not null default now()
);

-- Each device numbers only its own series, also offline (ADR-0002).
create table document_series (
  device_id   uuid not null references devices (id),
  doc_type    text not null check (doc_type in ('sale', 'order_note', 'barcode')),
  next_number bigint not null default 1 check (next_number >= 1),
  primary key (device_id, doc_type)
);

-- Server only: what each device last reported (cash close screen).
create table device_sync_status (
  device_id         uuid primary key references devices (id),
  last_push_at      timestamptz,
  last_pull_at      timestamptz,
  last_heartbeat_at timestamptz,
  pending_ops       int not null default 0,
  pending_sales     int not null default 0,
  reported_at       timestamptz
);

create table settings (
  key     text primary key,
  value   jsonb not null,
  active  boolean not null default true,
  version bigint not null
);

-- Server only ------------------------------------------------------------------

-- Written by the server in the same transaction that applies each command.
create table audit_log (
  id            uuid primary key default gen_random_uuid(),
  at            timestamptz not null default now(),
  user_id       uuid references users (id),
  device_id     uuid,
  action        text not null, -- sales.void, catalog.change_price, ...
  entity_type   text,
  entity_id     text,          -- text: settings use their key
  before        jsonb,
  after         jsonb,
  reason        text,
  authorized_by uuid references users (id), -- Administrador PIN on another role
  op_id         uuid references sync_inbox (op_id)
);
create index audit_log_at_idx on audit_log (at);
create index audit_log_entity_idx on audit_log (entity_type, entity_id);

-- Rotating refresh tokens: each refresh replaces the token; reusing a
-- replaced one revokes the whole family (stolen token).
create table refresh_tokens (
  id         uuid primary key,
  family_id  uuid not null,
  user_id    uuid not null references users (id),
  device_id  uuid not null, -- no FK: a device logs in before it registers
  token_hash text not null unique, -- SHA-256 of the token, never the token
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  revoked_at timestamptz
);
create index refresh_tokens_family_idx on refresh_tokens (family_id);

create table sync_conflicts (
  id          uuid primary key default gen_random_uuid(),
  type        text not null check (type in (
                'negative_stock', 'duplicate_barcode', 'duplicate_customer_doc',
                'stale_price', 'closed_cash_session',
                'unassigned_cash_movement', 'duplicate_cash_session')),
  op_id       uuid not null references sync_inbox (op_id),
  entity_type text,
  entity_id   text,
  details     jsonb not null default '{}',
  status      text not null default 'open' check (status in ('open', 'resolved')),
  created_at  timestamptz not null default now(),
  resolved_by uuid references users (id),
  resolved_at timestamptz,
  resolution  text,
  check ((status = 'resolved') = (resolved_at is not null))
);
create index sync_conflicts_open_idx on sync_conflicts (created_at) where status = 'open';

-- Errors while applying commands (the inbox keeps the command itself).
create table sync_log (
  id        uuid primary key default gen_random_uuid(),
  at        timestamptz not null default now(),
  op_id     uuid,
  device_id uuid,
  error     text not null,
  details   jsonb
);
create index sync_log_at_idx on sync_log (at);

-- Version triggers on every replicated master.
create trigger users_version before insert or update on users
  for each row execute function set_sync_version();
create trigger roles_version before insert or update on roles
  for each row execute function set_sync_version();
create trigger permissions_version before insert or update on permissions
  for each row execute function set_sync_version();
create trigger role_permissions_version before insert or update on role_permissions
  for each row execute function set_sync_version();
create trigger user_roles_version before insert or update on user_roles
  for each row execute function set_sync_version();
create trigger devices_version before insert or update on devices
  for each row execute function set_sync_version();
create trigger settings_version before insert or update on settings
  for each row execute function set_sync_version();

-- Seed: roles, permissions (docs/modelo-datos.md §4) and settings -------------
-- Users are created by the server on first start, from .env (their
-- passwords need Argon2id).

insert into roles (id, code, name, home_view, version) values
  ('019a9a00-0000-7000-8000-000000000001', 'admin', 'Administrador', 'dashboard', 0),
  ('019a9a00-0000-7000-8000-000000000002', 'staff', 'Trabajo', 'sales', 0);

insert into permissions (code, description, version) values
  ('dashboard.view',         'Ver el dashboard', 0),
  ('reports.view',           'Ver reportes', 0),
  ('reports.profit',         'Ver costos y utilidad en reportes', 0),
  ('sales.view',             'Ver ventas', 0),
  ('sales.create',           'Vender y cobrar', 0),
  ('sales.credit',           'Vender a crédito (solo clientes registrados)', 0),
  ('sales.return',           'Registrar devoluciones', 0),
  ('sales.discount',         'Aplicar descuentos (queda auditado)', 0),
  ('sales.change_price',     'Cambiar el precio en una venta', 0),
  ('sales.void',             'Anular ventas', 0),
  ('order_notes.create',     'Emitir notas de pedido', 0),
  ('cash.view',              'Ver la caja', 0),
  ('cash.open',              'Abrir caja', 0),
  ('cash.close',             'Cerrar caja', 0),
  ('cash.movement',          'Ingresos, egresos y retiros de caja', 0),
  ('cash.expense',           'Registrar gastos', 0),
  ('cash.reopen',            'Reabrir una caja cerrada', 0),
  ('catalog.view',           'Ver productos', 0),
  ('catalog.create',         'Dar de alta productos', 0),
  ('catalog.edit',           'Editar productos y precios', 0),
  ('catalog.view_cost',      'Ver costos', 0),
  ('inventory.view',         'Ver stock', 0),
  ('inventory.count',        'Anotar conteos físicos', 0),
  ('inventory.adjust',       'Ajustes de stock y mermas', 0),
  ('purchases.receive',      'Recibir compras (lotes y vencimientos, sin costos)', 0),
  ('purchases.manage',       'Crear y administrar compras', 0),
  ('customers.view',         'Ver clientes', 0),
  ('customers.create',       'Registrar clientes', 0),
  ('customers.payment',      'Registrar cobros a clientes', 0),
  ('customers.edit',         'Editar clientes', 0),
  ('customers.credit_limit', 'Cambiar el límite de crédito', 0),
  ('users.manage',           'Administrar usuarios', 0),
  ('settings.manage',        'Cambiar los ajustes del negocio', 0),
  ('sync.resolve_conflicts', 'Resolver conflictos de sincronización', 0);

-- Administrador: everything.
insert into role_permissions (role_id, permission_code, version)
  select '019a9a00-0000-7000-8000-000000000001', code, 0 from permissions;

-- Trabajo: selling, stock, orders, customers and the cash of the shift.
insert into role_permissions (role_id, permission_code, version)
  select '019a9a00-0000-7000-8000-000000000002', code, 0 from permissions
  where code in (
    'sales.view', 'sales.create', 'sales.credit', 'sales.return',
    'sales.discount', 'order_notes.create',
    'cash.view', 'cash.open', 'cash.close', 'cash.movement', 'cash.expense',
    'catalog.view', 'catalog.create',
    'inventory.view', 'inventory.count',
    'purchases.receive',
    'customers.view', 'customers.create', 'customers.payment');

-- Business data (user, 2026-11-19): RUC and the ticket's closing message;
-- no phone or WhatsApp on the ticket.
insert into settings (key, value, version) values
  ('business.name',     '"La Esquinita Orgánika"', 0),
  ('business.address',  '"Av. Famesa, Mz. C, Lt. 3, Paradero Famesa, Puente Piedra, Lima"', 0),
  ('business.ruc',      '"10409288419"', 0),
  ('business.phone',    'null', 0),
  ('business.whatsapp', 'null', 0),
  ('ticket.footer',     '"Gracias por su preferencia"', 0),
  ('sales.mixed_payments',         'true', 0),
  ('order_notes.reserve_stock',    'false', 0),
  ('inventory.expiry_warning_days', '30', 0),
  ('cash.backup_device_id',        'null', 0); -- set when the tablet registers

-- migrate:down
drop table if exists sync_log;
drop table if exists sync_conflicts;
drop table if exists refresh_tokens;
drop table if exists audit_log;
drop table if exists settings;
drop table if exists device_sync_status;
drop table if exists document_series;
drop table if exists devices;
drop table if exists user_roles;
drop table if exists role_permissions;
drop table if exists permissions;
drop table if exists roles;
drop table if exists users;
drop function if exists set_sync_version();
drop sequence if exists sync_version_seq;
