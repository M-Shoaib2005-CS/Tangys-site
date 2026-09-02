-- Tangy's Order Management System — named extra charges
--
-- A free-form list of small named charges on an order (e.g. "Packing —
-- Rs. 20", "Container — Rs. 30") — distinct from delivery_fee, which is
-- its own dedicated field. This is Take Order/counter-only for now; the
-- website checkout doesn't set it.

alter table orders add column if not exists extra_charges jsonb not null default '[]'::jsonb;
