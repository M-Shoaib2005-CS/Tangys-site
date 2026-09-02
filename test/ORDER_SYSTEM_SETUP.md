# Tangy's Order Management System — Setup

One combined app now runs the counter, the kitchen view, the menu editor,
and reports — replacing the separate POS/dashboard/admin files from the
earlier version. Everything shares the one Supabase project from
`SETUP.md` — there's no second database or second login system.

If you haven't done the original `SETUP.md` yet (Supabase project +
`categories`/`items` tables + your admin login), do that first. This guide
assumes it's done.

## 1. Run the SQL files, in order

In Supabase → **SQL Editor** → **New query**, run these **in this exact
order**. If you already ran `01`–`04` from an earlier version, you only
need `05`–`07` now — they're safe to run on top of what's already there.

1. `sql/01_orders_schema.sql` — adds the `orders` and `order_items` tables.
2. `sql/02_orders_rpc.sql` — lets the website checkout save an order and
   get back an order number, without needing broad read access.
3. `sql/03_remove_riders.sql` — an earlier version removed rider tracking
   entirely. Riders are back now (see step 4 below) — this step is kept
   only so the sequence still runs cleanly for a brand-new setup.
4. `sql/04_order_tracking.sql` — adds the two narrow functions that power
   the customer tracking page (see step 6). Each only ever reveals the one
   order matching the link a customer already has — never a list, never
   anyone else's order.
5. `sql/05_delivery_fee.sql` — adds a delivery fee to orders and a
   site-wide default (on/off + amount).
6. `sql/06_riders_return.sql` — riders are tracked again: name and phone,
   assigned to a delivery order once it heads out.
7. `sql/07_update_functions.sql` — updates the two functions from step 4
   so they also carry delivery fee and rider info through to the customer
   tracking page.
8. `sql/08_extra_charges.sql` — adds a spot for one-off named charges on
   an order (e.g. "Packing — Rs. 20"), settable per order on Take Order.

## 2. Give staff their own logins

Each person using the app should have their own login —
**Authentication → Users → Add user** in Supabase, same as before.
Everyone signed in this way can see and manage all orders; there's no
separate "cashier vs manager" permission level in this version.

## 3. Open the app

`app/index.html` is the whole thing — sign in, and you'll see:

- **Dashboard** — today's sales, order count, and a live feed of today's
  orders.
- **Take Order** — the counter screen. Tap items (with photos) to build an
  order — items with add-ons (like Extra Cheese) open a quick picker so
  staff can select them and set quantity before adding to the ticket. Pick
  Dine-in / Pickup / Delivery, choose a payment method, add a discount,
  named extra charges (like a packing fee), or a delivery fee if this
  order needs one, and hit **Place & print**. Works with no internet — it
  queues locally and prints immediately either way, syncing to Supabase
  once the connection's back.
- **Orders** — every order, grouped by status, with the single next action
  ("Start preparing", "Mark ready", etc.) and a **Cancel** option for
  anything not yet out for delivery or completed. For delivery orders,
  "Ready — send with rider" assigns a rider automatically if only one is
  free, or asks you to pick if more than one is — a rider already out on
  a delivery is flagged as busy rather than picked silently.
- **Menu** — the full menu editor: categories, items (with photos and
  add-ons), bulk discounts, and homepage banners — everything that used to
  be in the separate manager page.
- **Riders** — add/edit riders (name, phone, active/inactive). No login
  for them — this is just so the app knows who's available to assign.
- **Reports** — today's sales, order count, and best sellers.
- **Settings** — announcement bar text, WhatsApp fallback number, tax
  rate, promo codes, and whether to charge a delivery fee by default (plus
  the amount).

Bookmark it on the counter PC (and anywhere else staff need it — a kitchen
tablet, your own laptop). One app, one login, works everywhere.

## 4. Set up the printer

Same as before — see `print-bridge/README.md` for the full walkthrough:
install Node.js once, `npm install` in that folder, point `config.json` at
your printer, then run `start.bat` (ideally set to launch automatically
with Windows). The counter app talks to this bridge on `localhost` to
print — nothing here needs the internet.

## 5. Discounts and delivery fees

- **On the website**, the delivery fee (if you've turned it on in
  Settings) is applied automatically whenever a customer picks Delivery —
  shown as its own line before the total. There's no manual discount on
  the website; that's a Take Order/counter thing.
- **On Take Order**, staff can type in a one-off discount (Rs.) for that
  order, and for deliveries, tick "Add delivery fee" on or off per order
  — it defaults to whatever Settings says, but can be overridden right
  there if you want to waive it for a particular customer.

## 6. Customer order tracking

`track.html` is a page — after checkout, the customer gets a "Track your
order" link straight to it. It shows a simple status tracker (Order placed
→ Preparing → Out for delivery/Ready for pickup → Delivered) that updates
on its own as staff move the order along in the app. Once a rider's
assigned, the tracking page shows their name and a tap-to-call button —
the same way Foodpanda shows a delivery partner.

## 7. The website itself

`index.html` is already updated — checkout saves a real order and shows
the customer an order number plus the tracking link. If saving fails
(customer has no internet, or Supabase is briefly down), it falls back to
the old "send it on WhatsApp" link automatically, so an order never just
disappears.

Payment options are Cash, Easypaisa, and JazzCash — all confirmed in
person (at pickup, or by the rider on delivery). Nothing here processes an
online payment; that was a deliberate choice for this version.

## How it all fits together

- **One database, three front doors**: `index.html` (customers),
  `app/index.html` (staff — counter, kitchen, menu, riders, reports, all
  in one), and `track.html` (a customer checking their own order) all read
  the same `orders`/`order_items` tables. An order looks identical no
  matter which door it came through.
- **Offline is only a Take Order/printing concern.** The website, the
  tracking page, and most of the staff app need internet by nature. Only
  the counter needs to keep working with no internet, and that's what the
  local queue + print bridge handle.
- **Rider availability is worked out live, not stored.** A rider is
  "busy" if they currently have an order sitting at "out for delivery" —
  nothing needs manual updating for this to stay accurate.
- **Nothing here processes payment.** Cash/Easypaisa/JazzCash are all
  confirmed by a human, not by any software. That was a deliberate
  phase-1 decision — the `payment_method` field is already there for
  when/if that changes later.
- **Cancelled orders are kept** (visible in the app's Cancelled tab, for
  your records) **but never counted** in Sales, Orders today, Average
  order, or Best sellers.
