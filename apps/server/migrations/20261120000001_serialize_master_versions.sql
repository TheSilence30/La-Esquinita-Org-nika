-- migrate:up

-- GET /sync/pull must never skip a row. With a bare nextval(), a transaction
-- can take version 10, commit after another one took and committed 11, and a
-- pull that already answered "cursor 11" never sends 10. So every write to a
-- replicated master takes one transaction-level lock first: versions are
-- handed out in commit order, and every committed version is lower than any
-- version still in flight (user rule, docs/planes/fase-1.md).
-- Re-entrant within a transaction; released on commit or rollback.
create or replace function set_sync_version() returns trigger
language plpgsql as $$
begin
  perform pg_advisory_xact_lock(hashtext('sync_version_seq'));
  new.version := nextval('sync_version_seq');
  return new;
end
$$;

-- migrate:down
create or replace function set_sync_version() returns trigger
language plpgsql as $$
begin
  new.version := nextval('sync_version_seq');
  return new;
end
$$;
