@echo off
cd /d %~dp0
echo Starting Tangy's print bridge...
echo Keep this window open while the counter is taking orders.
node server.js
pause
