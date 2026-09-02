-- Tangy's Order Management System — Phase 1 schema
-- Run this once in Supabase → SQL Editor → New query.
-- Builds on the existing `categories` and `items` tables from the menu system.

-- ============================================================
-- Riders (simple list — no login, no app view for them)
-- ============================================================
create table if not exists riders (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  active boolean default true,
  created_at timestamptz default now()
);

-- ============================================================
-- Orders
-- ============================================================
create table if not exists orders (
  id uuid primary key default gen_random_uuid(),
  order_number serial,                          -- short human-friendly number, e.g. #1042

  order_type text not null default 'pickup'
    check (order_type in ('dine_in', 'pickup', 'delivery')),

  status text not null default 'pending'
    check (status in ('pending', 'preparing', 'ready', 'out_for_delivery', 'completed', 'cancelled')),

  source text not null default 'pos'
    check (source in ('website', 'pos', 'manual')),   -- 'manual' replaces the old WhatsApp orders

  payment_method text not null default 'cash'
    check (payment_method in ('cash', 'easypaisa', 'jazzcash')),

  payment_confirmed boolean default false,       -- ticked by staff/rider once they've seen the money

  rider_id uuid references riders(id),           -- only set when order_type = 'delivery'

  customer_name text,
  customer_phone text,
  delivery_address text,                          -- only used when order_type = 'delivery'

  subtotal numeric not null default 0,
  discount numeric not null default 0,
  total numeric not null default 0,

  notes text,

  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ============================================================
-- Order items (snapshot of item name/price at order time,
-- so a later menu edit never changes a past order's record)
-- ============================================================
create table if not exists order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references orders(id) on delete cascade,
  item_id uuid references items(id),
  item_name text not null,
  unit_price numeric not null,
  quantity int not null default 1,
  addons jsonb default '[]'::jsonb,
  line_total numeric not null
);

-- ============================================================
-- Keep updated_at current automatically
-- ============================================================
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists orders_set_updated_at on orders;
create trigger orders_set_updated_at
  before update on orders
  for each row execute function set_updated_at();

-- ============================================================
-- Row Level Security
-- ============================================================
alter table riders enable row level security;
alter table orders enable row level security;
alter table order_items enable row level security;

-- Riders: staff-only, both read and write
create policy "admin manage riders" on riders for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- Orders: anyone can INSERT (so the public website checkout can create an order
-- without logging in), but only staff can read/update/cancel orders.
create policy "public create orders" on orders for insert
  with check (true);
create policy "admin read orders" on orders for select
  using (auth.role() = 'authenticated');
create policy "admin update orders" on orders for update
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- Order items: same shape as orders — public can insert (as part of checkout),
-- only staff can read/manage.
create policy "public create order items" on order_items for insert
  with check (true);
create policy "admin read order items" on order_items for select
  using (auth.role() = 'authenticated');
create policy "admin manage order items" on order_items for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- Realtime: let the kitchen/admin dashboard subscribe to live order changes
alter publication supabase_realtime add table orders;
alter publication supabase_realtime add table order_items;
