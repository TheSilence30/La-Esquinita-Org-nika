-- migrate:up

-- GET /sync/pull reads each replicated table by version (where version >
-- cursor order by version limit n): an index per table keeps every page
-- from scanning the whole table (user, 2026-11-25).
create index users_version on users (version);
create index roles_version on roles (version);
create index permissions_version on permissions (version);
create index role_permissions_version on role_permissions (version);
create index user_roles_version on user_roles (version);
create index devices_version on devices (version);
create index settings_version on settings (version);
create index categories_version on categories (version);
create index brands_version on brands (version);
create index units_version on units (version);
create index products_version on products (version);
create index product_costs_version on product_costs (version);
create index product_presentations_version on product_presentations (version);
create index barcodes_version on barcodes (version);
create index lots_version on lots (version);
create index stock_balances_version on stock_balances (version);

-- migrate:down
drop index if exists users_version;
drop index if exists roles_version;
drop index if exists permissions_version;
drop index if exists role_permissions_version;
drop index if exists user_roles_version;
drop index if exists devices_version;
drop index if exists settings_version;
drop index if exists categories_version;
drop index if exists brands_version;
drop index if exists units_version;
drop index if exists products_version;
drop index if exists product_costs_version;
drop index if exists product_presentations_version;
drop index if exists barcodes_version;
drop index if exists lots_version;
drop index if exists stock_balances_version;
