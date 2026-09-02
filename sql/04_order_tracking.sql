-- Tangy's Order Management System — order tracking for customers
--
-- The website checkout gives each customer a private link containing their
-- order's id (a random UUID — effectively a token; nobody can guess it).
-- These two functions let that link show live status WITHOUT opening up
-- read access to the whole orders table to the public. Each only ever
-- returns the one order matching the id you already have — there's no way
-- to list, browse, or guess your way into anyone else's order this way.

create or replace function get_order_status(p_order_id uuid)
returns table(
  order_number int,
  order_type text,
  status text,
  payment_method text,
  payment_confirmed boolean,
  delivery_address text,
  total numeric,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    order_number,
    order_type,
    status,
    payment_method,
    payment_confirmed,
    case when order_type = 'delivery' then delivery_address else null end,
    total,
    created_at,
    updated_at
  from orders
  where id = p_order_id;
$$;

create or replace function get_order_items_public(p_order_id uuid)
returns table(item_name text, quantity int, line_total numeric)
language sql
security definer
set search_path = public
as $$
  select item_name, quantity, line_total
  from order_items
  where order_id = p_order_id;
$$;

grant execute on function get_order_status(uuid) to anon, authenticated;
grant execute on function get_order_items_public(uuid) to anon, authenticated;
