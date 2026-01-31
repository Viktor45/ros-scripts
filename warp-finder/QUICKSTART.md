# Quick Start Guide

Get your WireGuard endpoint finder up and running in 5 minutes!

## Prerequisites

✅ MikroTik router with RouterOS 7.20 or higher  
✅ WireGuard interface already configured  
✅ Active internet connection  

---

## 5-Minute Setup

### Step 1: Download the Script (30 seconds)

**Option A: Direct Download**
```bash
wget https://raw.githubusercontent.com/Viktor45/ros-scripts/refs/heads/main/warp-finder/warp-finder.rsc
```

**Option B: Clone Repository**
```bash
git clone https://github.com/viktor45/ros-scripts/warp-finder.git
```

### Step 2: Upload to Router (1 minute)

**Via SCP (Recommended):**
```bash
scp warp-finder.rsc admin@192.168.88.1:/
```

**Via WebFig:**
1. Open http://192.168.88.1
2. Go to **Files**
3. Click **Upload**
4. Select `warp-finder.rsc`

### Step 3: Configure Interface Name (30 seconds)

Find your WireGuard interface name:
```routeros
/interface wireguard print
```

Edit the script (line 14):
```routeros
# Change "wgcf" to your interface name
:local wgInterface "wgcf"  # ← Change this
```

### Step 4: Run the Script (30 seconds)

**Via SSH:**
```bash
ssh admin@192.168.88.1
/import warp-finder.rsc
```

**Via WinBox:**
1. Open **New Terminal**
2. Type: `/import warp-finder.rsc`
3. Press **Enter**

### Step 5: Verify Success (1 minute)

Check the logs:
```routeros
/log print where message~"endpoint"
```

Look for: `SUCCESS: Endpoint X.X.X.X:YYYY is working!`

---

## That's It! 🎉

Your WireGuard connection is now using an optimized endpoint.

---

## Next Steps

### Make It Automatic

Run every 6 hours:
```routeros
/system scheduler add name="warp-finder" interval=6h \
  on-event="/import warp-finder.rsc"
```

### Run on Connection Failure

```routeros
/tool netwatch add host=1.1.1.1 interval=30s \
  down-script="/import warp-finder.rsc"
```

---

## Common First-Time Issues

### "No WireGuard peer found"
➜ **Fix:** Update interface name in the script

### "IP prefixes array is empty"  
➜ **Fix:** Ensure you copied the entire script

### "No working endpoint found"
➜ **Fix:** Increase `maxAttempts` to 50

---

## Get Help

📖 [Full Documentation](README.md)  
🐛 [Report Issue](https://github.com/viktor45/ros-scripts/warp-finder/issues)  

---

## Quick Reference

```routeros
# Check WireGuard status
/interface wireguard print

# View active endpoint
/interface wireguard peers print detail

# Check logs
/log print where message~"endpoint"

# Test connection
/ping 1.1.1.1 count=5 interface=wgcf

# Re-run script
/import warp-finder.rsc
```

---

**Happy routing! 🚀**
