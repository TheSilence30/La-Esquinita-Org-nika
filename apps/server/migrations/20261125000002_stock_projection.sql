-- migrate:up

-- Stock projections, written by the database itself in the same transaction
-- as each stock movement (CLAUDE.md §6.1–§6.2), so no command can forget
-- one and a rolled-back transaction leaves none behind:
--   * stock_balances: the balance of the movement's product and lot;
--   * product_costs.on_hand_milli: the product's total stock, which the
--     moving average uses (docs/modelo-datos.md §3.4). It always equals the
--     sum of the product's stock_balances (user, 2026-11-25).
-- Movements never change: a correction is a new movement (CLAUDE.md §6.3).

create function apply_stock_movement() returns trigger
language plpgsql as $$
begin
  insert into stock_balances (product_id, lot_id, qty_milli, version)
  values (new.product_id, new.lot_id, new.qty_milli, 0)
  on conflict (product_id, lot_id)
  do update set qty_milli = stock_balances.qty_milli + excluded.qty_milli;

  insert into product_costs (product_id, on_hand_milli, version)
  values (new.product_id, new.qty_milli, 0)
  on conflict (product_id)
  do update set on_hand_milli = product_costs.on_hand_milli
                                + excluded.on_hand_milli;
  return new;
end
$$;

create trigger stock_movements_apply after insert on stock_movements
  for each row execute function apply_stock_movement();

create function forbid_change() returns trigger
language plpgsql as $$
begin
  raise exception '% rows never change: record a new one', tg_table_name
    using errcode = 'restrict_violation';
end
$$;

create trigger stock_movements_immutable
  before update or delete on stock_movements
  for each row execute function forbid_change();

-- migrate:down
-- cascade also drops their triggers (and works when the table is gone).
drop function if exists forbid_change() cascade;
drop function if exists apply_stock_movement() cascade;
