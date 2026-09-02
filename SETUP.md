# Tangy's Website Manager — Setup

This connects your site's menu to a real database, so when you (or whoever
manages the site) add/edit/delete items in the admin panel, it shows up
live on the actual website for every visitor.

You'll use **Supabase** — free, no server to manage, takes about 15 minutes
to set up once.

## 1. Create the database

1. Go to https://supabase.com → sign up (free) → **New project**.
2. Name it anything (e.g. `tangys-site`), pick a password for the database
   (you won't need this again, just save it somewhere), pick the region
   closest to Pakistan (Singapore is usually fastest).
3. Wait ~2 minutes for it to spin up.

## 2. Create the tables

In your new project, go to **SQL Editor** (left sidebar) → **New query**,
paste this in, and click **Run**:

```sql
-- Categories (Best Sellers, Burgers, Wraps, Deals, etc.)
create table categories (
  id text primary key,           -- short slug, e.g. 'burgers'
  name text not null,            -- display name, e.g. 'Burgers'
  style text not null default 'grid',  -- 'grid' or 'deal'
  sort_order int not null default 0
);

-- Menu items
create table items (
  id uuid primary key default gen_random_uuid(),
  category_id text references categories(id) on delete cascade,
  name text not null,
  description text default '',
  price numeric not null default 0,
  tag text default '',
  is_signature boolean default false,
  is_placeholder boolean default true,
  sort_order int not null default 0
);

-- Anyone can READ (the public website needs this)
alter table categories enable row level security;
alter table items enable row level security;

create policy "public read categories" on categories for select using (true);
create policy "public read items" on items for select using (true);

-- Only logged-in admin users can WRITE
create policy "admin write categories" on categories for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "admin write items" on items for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
```

## 3. Create your admin login

1. Go to **Authentication** → **Users** → **Add user** → **Create new user**.
2. Enter the email/password you (the owner/manager) will log in with.
   This is the only account that can edit the site — keep it private.

## 4. Load starter menu data (optional but recommended)

Back in **SQL Editor**, run this to pre-fill the current menu so you're not
starting from a blank slate:

```sql
insert into categories (id, name, style, sort_order) values
  ('best', 'Best Sellers', 'grid', 1),
  ('burgers', 'Burgers', 'grid', 2),
  ('wraps', 'Wraps', 'grid', 3),
  ('fries', 'Fries & Sides', 'grid', 4),
  ('beverages', 'Beverages', 'grid', 5),
  ('shakes', 'Shakes', 'grid', 6),
  ('deals', 'Deals', 'deal', 7);

insert into items (category_id, name, description, price, tag, is_signature, is_placeholder, sort_order) values
  ('best', 'The Tangy''s', 'The double-stack everyone means when they say ''the big one''.', 750, 'Signature', true, true, 1),
  ('best', 'Zest Burger', 'Sharper sauce, same loaded build.', 480, 'Best seller', false, true, 2),
  ('best', 'Loaded Fries (Grill Piece)', 'Fries topped with a grill piece and house sauce.', 350, 'Best seller', false, true, 3),
  ('burgers', 'Grill Burger', 'Char-grilled patty, fresh veg, house sauce.', 450, 'Classic', false, true, 1),
  ('burgers', 'Zest Burger', 'The tangy, punchy version.', 480, 'Classic', false, true, 2),
  ('burgers', 'Fillet Burger', 'Crispy chicken fillet, slaw, mayo.', 500, 'Classic', false, true, 3),
  ('burgers', 'Jumbo Chilli Burger', 'Jumbo patty, chilli-forward sauce.', 550, 'Spiced', false, true, 4),
  ('burgers', 'The Tangy''s', 'The signature double-stack.', 750, 'Signature', true, true, 5),
  ('wraps', 'Chicken Zest Wrap', 'Grilled chicken, zest sauce, rolled tight.', 380, 'Wrap', false, true, 1),
  ('wraps', 'BBQ Grilled Wrap', 'Smoky BBQ chicken, fresh veg.', 400, 'Wrap', false, true, 2),
  ('wraps', 'Chicken Fillet Wrap', 'Crispy fillet strips, sauce, crunch.', 420, 'Wrap', false, true, 3),
  ('fries', 'Loaded Fries (Grill Piece)', 'Grill piece topped fries with house sauce.', 350, 'Sides', false, true, 1),
  ('fries', 'Loaded Fries (Fillet Piece)', 'Fillet piece topped fries with house sauce.', 380, 'Sides', false, true, 2),
  ('fries', 'Garlic Mayo', 'House dip, made for dunking.', 80, 'Dip', false, true, 3),
  ('fries', 'Greek Mayo', 'House dip, made for dunking.', 80, 'Dip', false, true, 4),
  ('fries', 'Chilli Mayo', 'House dip, made for dunking.', 80, 'Dip', false, true, 5),
  ('beverages', 'Soft Drink (Can)', 'Placeholder — confirm your actual drinks lineup.', 100, 'Placeholder', false, true, 1),
  ('beverages', 'Soft Drink (1.5L)', 'Placeholder — confirm your actual drinks lineup.', 250, 'Placeholder', false, true, 2),
  ('beverages', 'Mineral Water', 'Placeholder — confirm your actual drinks lineup.', 60, 'Placeholder', false, true, 3),
  ('shakes', 'Oreo Shake', 'Placeholder — confirm your actual shake flavors.', 350, 'Placeholder', false, true, 1),
  ('shakes', 'Nutella Shake', 'Placeholder — confirm your actual shake flavors.', 400, 'Placeholder', false, true, 2),
  ('shakes', 'Mango Shake', 'Placeholder — confirm your actual shake flavors.', 320, 'Placeholder', false, true, 3),
  ('deals', 'Tangy''s Box', 'Zest Burger, Fillet Burger, Grill Burger, Twisted Loaded Fries & a 1.5L drink.', 2299, 'Deal', false, false, 1),
  ('deals', 'Duo Deal', '2 burgers, 1 loaded fries, 2 drinks.', 1400, 'Deal', false, true, 2);
```

## 5. Connect the two HTML files

1. In Supabase, go to **Project Settings** → **API**.
2. Copy your **Project URL** and **anon public** key.
3. Open `index.html` and `admin.html`, find this near the top of the
   `<script>` section in each:
   ```js
   const SUPABASE_URL = 'YOUR_SUPABASE_URL';
   const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY';
   ```
4. Paste your real URL and key into both files. Save.

## 6. Use it

- Open `admin.html`, log in with the email/password from step 3.
- Add/edit/delete categories and items — changes save straight to the
  database.
- Open `index.html` (the real site) — it now loads the menu from that same
  database instead of a fixed list baked into the file.

## 7. New feature update — images, sale pricing, banners, site settings

If you already ran Steps 1–6, run this **once** in the SQL Editor to add the
new capability (photos, strikethrough sale pricing, a homepage carousel,
and a settings panel) without losing anything you already added:

```sql
-- New fields on items: a photo, an optional "was" price, and two badges
alter table items add column if not exists image_url text;
alter table items add column if not exists original_price numeric;
alter table items add column if not exists is_bestseller boolean default false;
alter table items add column if not exists is_new boolean default false;
alter table items add column if not exists addons jsonb default '[]'::jsonb;

-- Homepage carousel (the big rotating banner at the top of the site)
create table if not exists banners (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subtitle text default '',
  badge_text text default '',
  image_url text,
  sort_order int not null default 0
);
alter table banners enable row level security;
create policy "public read banners" on banners for select using (true);
create policy "admin write banners" on banners for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- Site-wide settings (one row) — announcement bar, tax %, promo code, WhatsApp number
create table if not exists site_settings (
  id text primary key default 'main',
  announcement_text text default '',
  tax_rate numeric default 0,
  promo_code text default '',
  promo_discount_percent numeric default 0,
  whatsapp_number text default '923181450075'
);
insert into site_settings (id) values ('main') on conflict (id) do nothing;
alter table site_settings enable row level security;
create policy "public read settings" on site_settings for select using (true);
create policy "admin write settings" on site_settings for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
```

## 8. Set up image storage (for food photos and banner photos)

1. In Supabase, go to **Storage** (left sidebar) → **Create a new bucket**.
2. Name it exactly `site-images`, and toggle **Public bucket** ON (so
   photos display on the live site without extra setup). Create it.
3. Go to **Storage → Policies** for that bucket, and add a policy allowing
   authenticated users to upload/update/delete — easiest way: click
   **New policy** → **For full customization** → allow `INSERT`, `UPDATE`,
   `DELETE` for role `authenticated`, and a separate `SELECT` policy for
   role `anon` (or `public`) so everyone can view images. If Supabase
   offers a one-click **"Get started quickly"** template like *"Allow
   authenticated uploads"* + *"Allow public read"*, use those.

That's it — no more SQL needed. From here on, all image uploads happen
through the admin panel itself (see below), not the Supabase dashboard.

## 9. What images to use, and how to add them

**Food item photos** — square-ish photos work best (roughly 800×800px).
Good lighting, the food filling most of the frame, on a plain or
warm-toned background if possible. Your phone camera is genuinely fine for
this — the boards you photographed for the menu are proof the food
photographs well. Avoid heavy filters; customers are ordering based on
what they see.

**Banner/carousel photos** — wide photos (roughly 1600×800px), since
these stretch full-width at the top of the site. The storefront photo
you sent is a good example of the mood these should have.

**To add a photo:** open `admin.html` → edit (or create) the item or
banner → there's now an **Upload photo** button in that form → pick the
file from your phone or computer → it uploads and previews immediately →
click **Save**. Nothing to do in Supabase itself once Step 8 is done.

Until a photo is uploaded, that item or banner shows a plain placeholder
on the site instead of a broken image — so it's safe to add items before
you have the photo ready, and add the photo later.

## 10. Add-ons (extra cheese, extra sauce, etc.)

Any item can have optional add-ons customers tap on before adding it to
their cart — each with its own name and price (e.g. "Extra Cheese +Rs.
100"). To set these up: open `admin.html` → edit an item → under
**Add-ons**, click **+ Add an add-on** for each one, fill in the name and
price, and Save. Leave an item's add-ons empty and it just won't show
an Add-Ons section on the site — nothing extra to configure.

## 11. Running a sale (the Discounts tab)

The **Discounts** tab in `admin.html` puts items on sale without editing
them one at a time. Pick a category (or "All categories"), tick the
items you want on sale — or use "Select all" — pick a percentage (10/15/
20%, or type your own), and click **Apply discount to selected**. That
sets each item's real price to the discounted amount and stores the
original price so the site shows it struck through with a % off badge
automatically. **Remove discount from selected** reverses it back to the
original price. Applying a new discount always calculates from the true
original price, so running two discounts in a row won't compound them.

## 12. Important fix — Best Sellers no longer duplicates items

**What was broken:** "Best Sellers" used to be a real category containing
its own *copies* of items also shown elsewhere (e.g. "Zest Burger" existed
as one row under Best Sellers and a second, separate row under Burgers).
Editing one row — like uploading a photo — had no way to update the other,
so changes looked like they "didn't save."

**The fix:** Best Sellers is now a *smart* category — it automatically
pulls in whichever items have "Best Seller" checked in their real
category, instead of needing its own copies. Every product now has
exactly one row, no matter how many places it's shown.

**Run this once** in the SQL Editor to apply the fix to your database:

```sql
alter table categories add column if not exists virtual text;
update categories set virtual = 'bestseller' where id = 'best';
```

**Then clean up the old duplicates by hand** (don't run a blind delete —
you want to keep whichever copy already has the right photo/price on it):

1. Open `admin.html` → **Menu** tab → open the **Best Sellers** category.
   You'll now see a note explaining items here are pulled automatically.
2. If you still see old duplicate rows sitting directly under Best
   Sellers from before this fix, for each one: find the *matching* item
   in its real category (Burgers, Fries & Sides, etc.), open that one,
   check the **Best Seller** box on it, and save. It'll now show up
   under Best Sellers automatically.
3. Once every real item is checked as a Best Seller correctly, delete
   the leftover old duplicate rows (the ones with no real category of
   their own) using the normal Delete button.

After that, editing an item's photo, price, or anything else — from
wherever you access it in the admin panel — updates it everywhere on
the site at once, since it's genuinely the same row.

