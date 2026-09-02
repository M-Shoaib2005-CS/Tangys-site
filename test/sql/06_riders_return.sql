-- Tangy's Order Management System — riders return
--
-- Riders are tracked again: name + phone, assigned to a delivery order
-- once it's sent out. Availability (whether a rider is already out on a
-- delivery) is worked out live from the orders table in the app — it's
-- not a stored field, so it can never go stale.

create table if not exists riders (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text not null,
  active boolean not null default true,
  created_at timestamptz default now()
);

alter table riders enable row level security;

create policy "admin manage riders" on riders for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

alter table orders add column if not exists rider_id uuid references riders(id) on delete set null;
