-- Tangy's Order Management System — carry delivery fee + rider info
-- through the two public-facing functions.
--
-- Run this AFTER 05_delivery_fee.sql and 06_riders_return.sql.

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
    subtotal, discount, delivery_fee, total
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
    coalesce((p_order->>'delivery_fee')::numeric, 0),
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

grant execute on function place_order(jsonb, jsonb) to anon, authenticated;

create or replace function get_order_status(p_order_id uuid)
returns table(
  order_number int,
  order_type text,
  status text,
  payment_method text,
  payment_confirmed boolean,
  delivery_address text,
  delivery_fee numeric,
  total numeric,
  created_at timestamptz,
  updated_at timestamptz,
  rider_name text,
  rider_phone text
)
language sql
security definer
set search_path = public
as $$
  select
    o.order_number,
    o.order_type,
    o.status,
    o.payment_method,
    o.payment_confirmed,
    case when o.order_type = 'delivery' then o.delivery_address else null end,
    o.delivery_fee,
    o.total,
    o.created_at,
    o.updated_at,
    r.name,
    r.phone
  from orders o
  left join riders r on r.id = o.rider_id
  where o.id = p_order_id;
$$;

grant execute on function get_order_status(uuid) to anon, authenticated;
