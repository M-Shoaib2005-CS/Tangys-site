-- Tangy's Order Management System — RPC for public order creation
-- Run AFTER 01_orders_schema.sql (or the schema already in your project).
--
-- Why this exists: anonymous website visitors can INSERT into `orders`,
-- but they can't SELECT from it (that's locked to staff only, on purpose —
-- customer names/phones/addresses shouldn't be publicly readable).
-- Without SELECT, a plain insert can't hand back the new order_number to
-- show the customer a confirmation. This function inserts the order AND
-- its items in one transaction, running as its owner (security definer),
-- and returns just the id + order_number — nothing else leaks out.

create or replace function place_order(p_order jsonb, p_items jsonb)
returns table(order_id uuid, order_number int)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order_id uuid;
  v_order_number int;
  v_item_count int;
begin
  if p_items is null or jsonb_array_length(p_items) = 0 then
    raise exception 'An order needs at least one item';
  end if;

  insert into orders (
    order_type, source, payment_method,
    customer_name, customer_phone, delivery_address, notes,
    subtotal, discount, total
  ) values (
    coalesce(p_order->>'order_type', 'pickup'),
    'website',
    coalesce(p_order->>'payment_method', 'cash'),
    p_order->>'customer_name',
    p_order->>'customer_phone',
    p_order->>'delivery_address',
    p_order->>'notes',
    coalesce((p_order->>'subtotal')::numeric, 0),
    coalesce((p_order->>'discount')::numeric, 0),
    coalesce((p_order->>'total')::numeric, 0)
  )
  returning id, orders.order_number into v_order_id, v_order_number;

  insert into order_items (order_id, item_id, item_name, unit_price, quantity, addons, line_total)
  select
    v_order_id,
    nullif(item->>'item_id', '')::uuid,
    item->>'item_name',
    (item->>'unit_price')::numeric,
    coalesce((item->>'quantity')::int, 1),
    coalesce(item->'addons', '[]'::jsonb),
    (item->>'line_total')::numeric
  from jsonb_array_elements(p_items) as item;

  get diagnostics v_item_count = row_count;
  if v_item_count = 0 then
    raise exception 'Failed to save order items';
  end if;

  return query select v_order_id, v_order_number;
end;
$$;

-- Let both anonymous visitors (website) and logged-in staff (POS) call it.
grant execute on function place_order(jsonb, jsonb) to anon, authenticated;
