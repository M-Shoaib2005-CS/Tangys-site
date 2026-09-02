-- Tangy's Order Management System — delivery fee
--
-- Adds a per-order delivery_fee (so a specific order can have it added or
-- waived) plus a site-wide default: whether delivery fee is charged at
-- all, and how much. Staff can still override per order in the app; the
-- website checkout follows the site-wide default automatically.

alter table orders add column if not exists delivery_fee numeric not null default 0;

alter table site_settings add column if not exists delivery_fee_enabled boolean not null default false;
alter table site_settings add column if not exists delivery_fee_amount numeric not null default 0;
