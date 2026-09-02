-- Tangy's Order Management System — remove riders
-- Run this after 01_orders_schema.sql / 02_orders_rpc.sql if you already
-- ran those. The system no longer tracks who the rider is — delivery
-- orders just move straight from "preparing" to "out_for_delivery" to
-- "completed" with no named rider attached.

alter table orders drop column if exists rider_id;
drop table if exists riders;
