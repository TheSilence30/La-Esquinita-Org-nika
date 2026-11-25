-- migrate:up

-- Phase 2: catalog and inventory (docs/modelo-datos.md §2.1–§2.2, §3).
-- Masters carry `active` (nothing is deleted) and `version` from the global
-- sync sequence (set_sync_version, serialized). Stock only changes through
-- stock_movements; stock_balances is its projection, written in the same
-- transaction as each movement and never by hand.

-- Catalog ---------------------------------------------------------------------

create table categories (
  id         uuid primary key,
  name       text not null check (btrim(name) <> ''),
  sort_order int not null default 0,
  active     boolean not null default true,
  version    bigint not null
);
create unique index categories_name_uq on categories (lower(name));

create table brands (
  id      uuid primary key,
  name    text not null check (btrim(name) <> ''),
  active  boolean not null default true,
  version bigint not null
);
create unique index brands_name_uq on brands (lower(name));

create table units (
  id      uuid primary key,
  code    text not null unique, -- und, kg, l
  name    text not null,
  kind    text not null check (kind in ('count', 'weight', 'volume')),
  active  boolean not null default true,
  version bigint not null
);

create table products (
  id              uuid primary key,
  internal_code   text not null unique,
  name            text not null check (btrim(name) <> ''),
  description     text,
  image_path      text, -- images come after Phase 2 (user, 2026-11-25)
  category_id     uuid not null references categories (id),
  brand_id        uuid references brands (id),
  base_unit_id    uuid not null references units (id),
  tracks_lots     boolean not null default false,
  min_stock_milli bigint not null default 0 check (min_stock_milli >= 0),
  active          boolean not null default true,
  version         bigint not null,
  created_at      timestamptz not null default now()
);

-- The server alone recalculates the moving average (§3.4); devices replicate.
create table product_costs (
  product_id      uuid primary key references products (id),
  avg_cost_cents  bigint not null default 0 check (avg_cost_cents >= 0),
  last_cost_cents bigint not null default 0 check (last_cost_cents >= 0),
  on_hand_milli   bigint not null default 0,
  version         bigint not null
);

-- §3.1: the factor to the base unit is explicit, never assumed.
create table product_presentations (
  id                    uuid primary key,
  product_id            uuid not null references products (id),
  name                  text not null check (btrim(name) <> ''),
  factor_milli          bigint not null check (factor_milli > 0),
  is_base               boolean not null default false,
  retail_price_cents    bigint not null check (retail_price_cents >= 0),
  wholesale_price_cents bigint check (wholesale_price_cents >= 0),
  wholesale_min_milli   bigint check (wholesale_min_milli > 0),
  active                boolean not null default true,
  version               bigint not null,
  check (not is_base or factor_milli = 1000)
);
create unique index product_presentations_name_uq
  on product_presentations (product_id, lower(name));
-- Exactly one base presentation per product (at most one here; the
-- CreateProduct command always writes it).
create unique index product_presentations_base_uq
  on product_presentations (product_id) where is_base;

-- Unique across the whole system, presentations included (CLAUDE.md §6.12).
create table barcodes (
  code            text primary key,
  presentation_id uuid not null references product_presentations (id),
  format          text not null
    check (format in ('ean13', 'ean8', 'upca', 'upce', 'code128', 'code39')),
  generated       boolean not null default false, -- internal 29… (§3.6)
  active          boolean not null default true,
  version         bigint not null
);

-- Server only: audited price history.
create table price_changes (
  id                  uuid primary key,
  presentation_id     uuid not null references product_presentations (id),
  old_retail_cents    bigint not null,
  new_retail_cents    bigint not null,
  old_wholesale_cents bigint,
  new_wholesale_cents bigint,
  reason              text,
  user_id             uuid not null references users (id),
  device_id           uuid,
  at                  timestamptz not null default now()
);

-- Server only: each CSV bulk load (ESPECIFICACION §29.2).
create table product_import_batches (
  id           uuid primary key,
  user_id      uuid not null references users (id),
  device_id    uuid,
  file_name    text not null,
  rows_total   int not null,
  rows_created int not null,
  rows_failed  int not null,
  errors       jsonb not null default '[]', -- [{row, reason}]
  created_at   timestamptz not null default now()
);

-- Inventory -------------------------------------------------------------------

create table lots (
  id         uuid primary key,
  product_id uuid not null references products (id),
  lot_code   text not null check (btrim(lot_code) <> ''),
  expires_on date, -- null: the lot does not expire
  version    bigint not null,
  created_at timestamptz not null default now(),
  unique nulls not distinct (product_id, lot_code, expires_on)
);

-- The only source of stock (CLAUDE.md §6.1).
create table stock_movements (
  id              uuid primary key,
  product_id      uuid not null references products (id),
  lot_id          uuid references lots (id),
  qty_milli       bigint not null check (qty_milli <> 0), -- ± in base unit
  type            text not null check (type in ('initial', 'purchase_receipt',
                    'sale', 'sale_void', 'sale_return', 'adjustment', 'count',
                    'loss')),
  reason          text,
  unit_cost_cents bigint check (unit_cost_cents >= 0),
  source_type     text not null check (source_type in ('product',
                    'sale_item_lot', 'receipt_line', 'adjustment_line',
                    'count_line', 'return_item', 'void')),
  source_id       uuid not null,
  op_id           uuid references sync_inbox (op_id),
  device_id       uuid not null,
  user_id         uuid not null references users (id),
  occurred_at     timestamptz not null,
  created_at      timestamptz not null default now(),
  check (type not in ('adjustment', 'loss') or btrim(coalesce(reason, '')) <> '')
);
create index stock_movements_product_idx
  on stock_movements (product_id, lot_id, occurred_at);

-- Projection of stock_movements. May go negative (a conflict, never a
-- refusal: CLAUDE.md §7).
create table stock_balances (
  product_id uuid not null references products (id),
  lot_id     uuid references lots (id),
  qty_milli  bigint not null,
  version    bigint not null,
  unique nulls not distinct (product_id, lot_id)
);

create table stock_adjustments (
  id            uuid primary key,
  reason        text not null check (btrim(reason) <> ''),
  notes         text,
  authorized_by uuid references users (id), -- Administrador PIN (§4)
  op_id         uuid references sync_inbox (op_id),
  device_id     uuid not null,
  user_id       uuid not null references users (id),
  occurred_at   timestamptz not null
);

create table stock_adjustment_lines (
  id            uuid primary key,
  adjustment_id uuid not null references stock_adjustments (id),
  product_id    uuid not null references products (id),
  lot_id        uuid references lots (id),
  qty_milli     bigint not null check (qty_milli <> 0),
  is_loss       boolean not null default false,
  check (not is_loss or qty_milli < 0) -- a loss takes stock out
);

create table inventory_counts (
  id            uuid primary key,
  status        text not null check (status in ('open', 'closed')),
  scope         text not null, -- all / category / list
  authorized_by uuid references users (id),
  op_id         uuid references sync_inbox (op_id),
  device_id     uuid not null,
  user_id       uuid not null references users (id),
  opened_at     timestamptz not null,
  closed_at     timestamptz
);

create table inventory_count_lines (
  id             uuid primary key,
  count_id       uuid not null references inventory_counts (id),
  product_id     uuid not null references products (id),
  lot_id         uuid references lots (id),
  expected_milli bigint not null, -- local stock when counted
  counted_milli  bigint not null check (counted_milli >= 0),
  unique nulls not distinct (count_id, product_id, lot_id)
);

-- Losses, for reports and claims to the supplier. supplier_id gets its FK
-- with the suppliers table (Phase 4).
create table stock_losses (
  id              uuid primary key,
  product_id      uuid not null references products (id),
  lot_id          uuid references lots (id),
  qty_milli       bigint not null check (qty_milli > 0),
  unit_cost_cents bigint not null check (unit_cost_cents >= 0),
  reason          text not null
    check (reason in ('defective_return', 'damaged', 'expired', 'other')),
  source_type     text not null check (source_type in ('return_item',
                    'adjustment_line')),
  source_id       uuid not null,
  supplier_id     uuid,
  claim_status    text not null default 'none'
    check (claim_status in ('none', 'pending', 'claimed', 'credited')),
  occurred_at     timestamptz not null
);

-- Version triggers on every replicated table.
create trigger categories_version before insert or update on categories
  for each row execute function set_sync_version();
create trigger brands_version before insert or update on brands
  for each row execute function set_sync_version();
create trigger units_version before insert or update on units
  for each row execute function set_sync_version();
create trigger products_version before insert or update on products
  for each row execute function set_sync_version();
create trigger product_costs_version before insert or update on product_costs
  for each row execute function set_sync_version();
create trigger product_presentations_version
  before insert or update on product_presentations
  for each row execute function set_sync_version();
create trigger barcodes_version before insert or update on barcodes
  for each row execute function set_sync_version();
create trigger lots_version before insert or update on lots
  for each row execute function set_sync_version();
create trigger stock_balances_version before insert or update on stock_balances
  for each row execute function set_sync_version();

-- Seed ------------------------------------------------------------------------

insert into units (id, code, name, kind, version) values
  ('019abb00-0000-7000-8000-000000000001', 'und', 'Unidad', 'count', 0),
  ('019abb00-0000-7000-8000-000000000002', 'kg', 'Kilogramo', 'weight', 0),
  ('019abb00-0000-7000-8000-000000000003', 'l', 'Litro', 'volume', 0);

-- Examples from ESPECIFICACION §9; the store can rename or add more.
insert into categories (id, name, sort_order, version) values
  ('019abb00-0000-7000-8000-000000000011', 'Orgánicos', 1, 0),
  ('019abb00-0000-7000-8000-000000000012', 'Alimentos', 2, 0),
  ('019abb00-0000-7000-8000-000000000013', 'Bebidas', 3, 0),
  ('019abb00-0000-7000-8000-000000000014', 'Productos naturales', 4, 0),
  ('019abb00-0000-7000-8000-000000000015', 'Suplementos', 5, 0),
  ('019abb00-0000-7000-8000-000000000016', 'Otros', 6, 0);

-- migrate:down
drop table if exists stock_losses;
drop table if exists inventory_count_lines;
drop table if exists inventory_counts;
drop table if exists stock_adjustment_lines;
drop table if exists stock_adjustments;
drop table if exists stock_balances;
drop table if exists stock_movements;
drop table if exists lots;
drop table if exists product_import_batches;
drop table if exists price_changes;
drop table if exists barcodes;
drop table if exists product_presentations;
drop table if exists product_costs;
drop table if exists products;
drop table if exists units;
drop table if exists brands;
drop table if exists categories;
