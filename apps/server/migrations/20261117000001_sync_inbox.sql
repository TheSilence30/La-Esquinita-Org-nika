-- migrate:up

-- Every command a device pushed, once per op_id (ADR-0002). The stored
-- status and message are returned again to any resend.
create table sync_inbox (
  op_id             uuid primary key,
  device_id         uuid not null,
  user_id           uuid not null,
  type              text not null,
  payload           jsonb not null,
  device_created_at timestamptz not null, -- device clock, may be wrong
  received_at       timestamptz not null default now(), -- server clock
  status            text not null check (status in ('applied', 'rejected', 'conflict')),
  message           text
);

create index sync_inbox_device_idx on sync_inbox (device_id, received_at);

-- Spike 6 test operation (note + amount in cents).
create table spike_operations (
  op_id             uuid primary key references sync_inbox (op_id),
  device_id         uuid not null,
  note              text not null,
  amount_cents      bigint not null,
  device_created_at timestamptz not null,
  received_at       timestamptz not null
);

-- migrate:down
drop table if exists spike_operations;
drop table if exists sync_inbox;
