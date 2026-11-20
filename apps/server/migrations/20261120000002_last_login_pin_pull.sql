-- migrate:up

-- Set on every password login. The update bumps the user's version, so the
-- device that just logged in gets the PIN hash in its next pull (ADR-0004).
alter table users add column last_login_at timestamptz;

-- migrate:down
alter table if exists users drop column if exists last_login_at;
