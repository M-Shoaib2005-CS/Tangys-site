// Tangy's print bridge
//
// Runs on the counter PC. The POS screen (pos.html), open in a browser on
// the same PC, sends receipt text to http://localhost:9100/print and this
// server forwards it straight to the thermal printer. Nothing here ever
// touches the internet — it only exists to bridge a web page to a printer,
// which browsers can't do directly.

const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const { ThermalPrinter, PrinterTypes } = require('node-thermal-printer');

const CONFIG_PATH = path.join(__dirname, 'config.json');
const DEFAULT_CONFIG = {
  port: 9100,
  printerType: 'EPSON',       // Fine for almost every generic 58mm/80mm thermal printer sold in Pakistan.
  interface: 'printer:POS-80', // See README.md — this must match your printer's exact Windows name, or a tcp:// address for network printers.
  receiptWidth: 32             // Characters per line — 32 for 58mm paper, 42-48 for 80mm paper.
};

function loadConfig() {
  try {
    const raw = fs.readFileSync(CONFIG_PATH, 'utf8');
    return { ...DEFAULT_CONFIG, ...JSON.parse(raw) };
  } catch (err) {
    console.warn('[print-bridge] No valid config.json found — using defaults.');
    console.warn('[print-bridge] Copy config.example.json to config.json and edit "interface" to match your printer.');
    return DEFAULT_CONFIG;
  }
}

const config = loadConfig();
const app = express();
app.use(cors());
app.use(express.json());

function resolveDriver(interfaceStr) {
  // Only "printer:Name" (an OS-registered printer — the common case for a
  // USB thermal printer on Windows) needs a native driver module. A
  // "tcp://ip:port" network printer needs none of this.
  if (!interfaceStr || !interfaceStr.startsWith('printer:')) return undefined;
  try {
    // eslint-disable-next-line global-require
    return require('printer');
  } catch (err) {
    throw new Error(
      'Using a "printer:" interface requires the optional "printer" package, which isn\'t installed ' +
      '(it failed to build, or "npm install" was run with it skipped). Run "npm install printer" — on ' +
      'Windows this also needs the "Desktop development with C++" workload from Visual Studio Build Tools. ' +
      'If that\'s not available, switch config.json to your printer\'s network address instead, e.g. ' +
      '"tcp://192.168.1.50:9100", which needs no extra install.'
    );
  }
}

app.get('/health', (req, res) => {
  res.json({ ok: true, interface: config.interface, printerType: config.printerType });
});

app.post('/print', async (req, res) => {
  const { text } = req.body || {};
  if (!text || typeof text !== 'string') {
    return res.status(400).json({ error: 'Request body must include a "text" string.' });
  }

  try {
    const driver = resolveDriver(config.interface);
    const thermalPrinter = new ThermalPrinter({
      type: PrinterTypes[config.printerType] || PrinterTypes.EPSON,
      interface: config.interface,
      driver,
      removeSpecialCharacters: false,
      lineCharacter: '-',
      width: config.receiptWidth
    });

    thermalPrinter.alignLeft();
    text.split('\n').forEach(line => thermalPrinter.println(line));
    thermalPrinter.newLine();
    thermalPrinter.newLine();
    thermalPrinter.cut();

    await thermalPrinter.execute();
    console.log(`[print-bridge] Printed receipt at ${new Date().toLocaleTimeString()}`);
    res.json({ ok: true });
  } catch (err) {
    console.error('[print-bridge] Print failed:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// Bound to 127.0.0.1 only — this should never be reachable from outside the
// counter PC itself.
app.listen(config.port, '127.0.0.1', () => {
  console.log(`[print-bridge] Listening on http://localhost:${config.port}`);
  console.log(`[print-bridge] Printer interface: ${config.interface}`);
  console.log('[print-bridge] Keep this window open — closing it stops printing from the POS.');
});
