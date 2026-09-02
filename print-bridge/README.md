# Tangy's print bridge

This is a small program that runs on the counter PC and prints receipts to
your thermal printer. The POS screen (`pos.html`) runs in a browser, and
browsers can't talk to a printer directly — this bridge is what makes that
connection, entirely on the local machine, with **no internet required**.

It only listens on `localhost`, so nothing about it is reachable from
outside that PC.

## 1. Install Node.js (one-time)

If the counter PC doesn't already have it: download and install the
"LTS" version from https://nodejs.org — just click through the installer
with default options.

## 2. Install and configure

Open a Command Prompt in this folder (`print-bridge`) and run:

```
npm install
```

Then copy the example config and edit it:

```
copy config.example.json config.json
```

Open `config.json` in Notepad and set `"interface"` to match your printer:

- **USB printer already set up in Windows** (the common case — you print a
  test page from Windows normally): use `"printer:YourExactPrinterName"`.
  Find the exact name in *Settings → Bluetooth & devices → Printers &
  scanners* — copy it exactly, including spaces.
  This mode needs one extra install: `npm install printer` (on Windows this
  also needs the free "Desktop development with C++" component from
  [Visual Studio Build Tools](https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022)).
  If you'd rather skip installing build tools, use the network option below
  instead.

- **Network/WiFi printer** (has its own IP address): use
  `"tcp://192.168.1.50:9100"` with your printer's actual IP — check its
  self-test print or its label/manual for the address. Port `9100` is the
  standard raw-print port on almost every network thermal printer. This
  mode needs no extra install.

## 3. Run it

Double-click `start.bat`, or run `npm start` from the command line. You
should see:

```
[print-bridge] Listening on http://localhost:9100
[print-bridge] Printer interface: printer:POS-80
```

Leave that window open — closing it stops printing. Test it's working:

```
curl -X POST http://localhost:9100/print -H "Content-Type: application/json" -d "{\"text\":\"Test receipt\"}"
```

A receipt should print. If you get an error back instead, it tells you
exactly what's wrong (wrong printer name, driver not installed, etc.) —
fix that and try again.

## 4. Make it start automatically (recommended)

So nobody has to remember to open it every morning:

1. Press `Win + R`, type `shell:startup`, press Enter — this opens your
   Startup folder.
2. Right-click `start.bat` in this folder → **Create shortcut**.
3. Drag that shortcut into the Startup folder you just opened.

Now it starts automatically whenever the counter PC turns on.

## Troubleshooting

- **"Using a printer: interface requires the optional printer package..."**
  — you're using the USB/OS-printer mode without having run
  `npm install printer` successfully. Either install it (see step 2), or
  switch to the network/`tcp://` mode if your printer supports it.
- **Nothing prints, no error** — double check the printer is turned on,
  has paper, and is the *default* printer, or that the name in
  `config.json` exactly matches Windows' printer name.
- **POS shows "Saved locally"** but nothing seems wrong with the internet —
  that's fine, it means Supabase saved the order but this bridge wasn't
  reachable, so the POS fell back to the browser's print dialog instead.
  Check this bridge is running.
