# 🛠️ ros-scripts

English version: [README.md](README.md) | Русская версия: [README_ru.md](README_ru.md)

A collection of useful scripts for MikroTik RouterOS.

[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![MikroTik](https://img.shields.io/badge/MikroTik-RouterOS%207.10+-blue.svg)](https://mikrotik.com)

---

## 📚 Table of Contents

<!-- TOC -->
* [🛠️ ros-scripts](#-ros-scripts)
  * [📚 Table of Contents](#-table-of-contents)
  * [📦 Scripts](#-scripts)
    * [🔍 anomalyze](#-anomalyze)
    * [🌐 asn-to-address-list](#-asn-to-address-list)
    * [☁️ cloudflare-ddns](#-cloudflare-ddns)
    * [🔄 resolve-address-lists](#-resolve-address-lists)
    * [📡 warp-finder](#-warp-finder)
  * [📋 Requirements](#-requirements)
  * [🚀 Installation](#-installation)
    * [Method 1: Via WebFig/WinBox (Recommended)](#method-1-via-webfigwinbox-recommended)
    * [Method 2: Via Terminal/SSH](#method-2-via-terminalssh)
    * [Method 3: File Upload](#method-3-file-upload)
  * [🤝 Contributing](#-contributing)
    * [How to Contribute](#how-to-contribute)
  * [📄 License](#-license)
  * [⚠️ Disclaimer](#-disclaimer)
  * [🔗 Useful Links](#-useful-links)
<!-- TOC -->
---

## 📦 Scripts

| Script                                               | Description                                         | Min. ROS Version |
|------------------------------------------------------|-----------------------------------------------------|------------------|
| [**anomalyze**](./anomalyze)                         | Anomaly detection and blocking                      | 7.20+            |
| [**asn-to-address-list**](./asn-to-address-list)     | Auto-update address lists by ASN                    | 7.10+            |
| [**cloudflare-ddns**](./cloudflare-ddns)             | Dynamic Cloudflare DNS updates                      | 7.20+            |
| [**resolve-address-lists**](./resolve-address-lists) | DNS resolution of IP addresses in comments          | 7.20+            |
| [**warp-finder**](./warp-finder)                     | Auto-discovery of working Cloudflare WARP endpoints | 7.20+            |

---

### 🔍 anomalyze

**Anomalous connection detection and automatic blocking**

This script monitors active connections and identifies suspicious patterns: asymmetric packet counts (high outgoing, low incoming). Useful for protection against port scans, DoS attacks, and TLS handshake timeouts.

**Features:**
- 🎯 Smart asymmetric connection detection
- 🚫 Automatic IP blocking
- ✅ Allowlist support for trusted IPs
- 🔒 Local router address protection
- 📊 Flexible logging (debug/info/warning/error)
- ⚡ Configurable detection thresholds

**Files:**
- [`anomalyze.rsc`](anomalyze/anomalyze.rsc) — main script
- [`README.md`](anomalyze/README.md) — detailed documentation

**Quick Start:**
```routeros
# Copy script to System → Scripts
# Run
/system script run connection-monitor
```

**Configuration:**
```routeros
:global cfgMonitoredPorts {443; 80; 8443}
:global cfgMinOrigPackets 3
:global cfgMaxReplPackets 2
:global cfgBlockTimeout "1d"
```

📖 [Full Documentation →](anomalyze/README.md)

---

### 🌐 asn-to-address-list

**Automatic address list updates by ASN number**

Fetches up-to-date IPv4/IPv6 prefix lists for any ASN from [ipverse/as-ip-blocks](https://github.com/ipverse/as-ip-blocks) and adds them to firewall address-list.

**Features:**
- ✅ Auto-update from ipverse GitHub
- 🌐 IPv4 and IPv6 support
- 🔢 Multiple ASN processing in a single run
- 🔄 Smart cleanup of old entries
- 💾 Flexible storage (USB/disk/tmpfs)

**Files:**
- [`update-asn-prefixes.rsc`](asn-to-address-list/update-asn-prefixes.rsc) — main script
- [`update-asn-cleaner.rsc`](asn-to-address-list/update-asn-cleaner.rsc) — list cleanup
- [`update-asn-runner-example.rsc`](asn-to-address-list/update-asn-runner-example.rsc) — batch update example
- [`README.md`](asn-to-address-list/README.md) — detailed documentation

**Quick Start:**
```routeros
# Update Cloudflare IPv4
:global UAPASN "13335"
:global UAPLIST "cloudflare-v4"
/system script run update-asn-prefixes

# Multiple ASNs at once
:global UAPASN "13335,16509,15169"
:global UAPLIST "cdn-networks"
/system script run update-asn-prefixes
```

**Popular ASNs:**
| Company | ASN | Description |
|---------|-----|-------------|
| Cloudflare | 13335 | CDN and security |
| Google | 15169 | Google infrastructure |
| Amazon | 16509 | AWS |
| Microsoft | 8075 | Azure |
| Meta | 32934 | Facebook, Instagram |

📖 [Full Documentation →](asn-to-address-list/README.md)

---

### ☁️ cloudflare-ddns

**Dynamic Cloudflare DNS record updates**

Automatically updates A/AAAA records in Cloudflare when your router's public IP address changes. Supports both IPv4 and IPv6.

**Features:**
- ✅ IPv4 and IPv6 support
- 🌐 Multiple domains simultaneously
- 🔶 Cloudflare Proxy toggle (orange/gray cloud)
- ⚡ IP change detection before updates
- 🔄 Scheduled automation

**Files:**
- [`cloudflare-ddns.rsc`](cloudflare-ddns/cloudflare-ddns.rsc) — main script
- [`README.md`](cloudflare-ddns/README.md) — detailed documentation

**Quick Start:**
```routeros
# 1. Enable IP Cloud
/ip cloud set ddns-enabled=yes

# 2. Configure script (specify token, Zone ID, Record ID)
# 3. Create scheduler
/system scheduler add \
  name=cloudflare-ddns-update \
  on-event=cloudflare-ddns \
  interval=5m \
  start-time=startup
```

**Domain Configuration:**
```routeros
:local domains {
    "example.com,ZONE_ID,RECORD_ID,true,v4";
    "ipv6.example.com,ZONE_ID,RECORD_ID,false,v6"
}
```

📖 [Full Documentation →](cloudflare-ddns/README.md)

---

### 🔄 resolve-address-lists

**DNS resolution of IP addresses in firewall address-list**

Automatically resolves IP addresses in specified address lists and stores hostnames in comments for easy identification.

**Features:**
- 🌐 IPv4 and IPv6 support
- 🔧 Custom DNS server selection (Cloudflare, Google, Quad9)
- 📝 Updates only empty comments
- ⚙️ Flexible list configuration

**Files:**
- [`resolve-address-lists.rsc`](resolve-address-lists/resolve-address-lists.rsc) — main script
- [`README.md`](resolve-address-lists/README.md) — detailed documentation

**Quick Start:**
```routeros
# Configure lists for resolution
:local dnsServer "1.1.1.1"
:local ipVersion "both"

:local ipv4ListsToResolve {
    "Trap";
    "MYDNS";
}

:local ipv6ListsToResolve {
    "Trap-v6";
    "MYDNS-v6";
}

# Run
/system script run resolve-address-lists
```

📖 [Full Documentation →](resolve-address-lists/README.md)

---

### 📡 warp-finder

**Automatic Cloudflare WARP endpoint discovery**

Automatically tests various IP:port combinations from Cloudflare's infrastructure to find a working WireGuard endpoint.

**Features:**
- 🔄 Automatic endpoint discovery
- 🎯 Random IP:port generation
- 🏥 Connectivity testing via ping
- 📊 Detailed logging
- 🛡️ Safe operation with rollback

**Files:**
- [`warp-finder.rsc`](warp-finder/warp-finder.rsc) — main script
- [`warp-finder-mini.rsc`](warp-finder/warp-finder-mini.rsc) — lightweight version
- [`README.md`](warp-finder/README.md) — detailed documentation
- [`QUICKSTART.md`](warp-finder/QUICKSTART.md) — quick start guide
- [`FAQ.md`](warp-finder/FAQ.md) — frequently asked questions
- [`CHANGELOG.md`](warp-finder/CHANGELOG.md) — changelog

**Quick Start:**
```routeros
# Configure interface
:local wgInterface "cloudflare-interface"
:local maxAttempts 10

# Run
/import warp-finder.rsc
```

**Scheduler for auto-run:**
```routeros
/system scheduler add \
  name="warp-finder" \
  interval=6h \
  on-event="/import warp-finder.rsc"
```

📖 [Full Documentation →](warp-finder/README.md)

---

## 📋 Requirements

| Script                | Minimum RouterOS Version |
|-----------------------|--------------------------|
| anomalyze             | 7.20+                    |
| asn-to-address-list   | 7.10+                    |
| cloudflare-ddns       | 7.20+                    |
| resolve-address-lists | 7.20+                    |
| warp-finder           | 7.20+                    |

**Common Requirements:**
- Administrative access to the router
- Internet connectivity
- `system` package enabled

---

## 🚀 Installation

### Method 1: Via WebFig/WinBox (Recommended)

1. Open **System → Scripts**
2. Click **+** (Add New)
3. Specify the script name
4. Copy the `.rsc` file contents into the **Source** field
5. Click **OK**

### Method 2: Via Terminal/SSH

```bash
# Connect to the router
ssh admin@192.168.88.1

# Import the script
/import script-name.rsc
```

### Method 3: File Upload

```bash
# Upload the script to the router
scp script.rsc admin@192.168.88.1:/

# Import
ssh admin@192.168.88.1
/import script.rsc
```

---

## 🤝 Contributing

Contributions are welcome:
- 🐛 Bug reports
- 💡 Feature suggestions
- 🔧 Pull requests with fixes
- 📖 Documentation improvements

### How to Contribute

1. Fork the repository
2. Create a branch (`git checkout -b feature/improvement`)
3. Make your changes
4. Test on RouterOS
5. Submit a Pull Request

---

## 📄 License

MIT License — see the [LICENSE](LICENSE) file for details.

---

## ⚠️ Disclaimer

Scripts are provided "as is" without any warranties. Use at your own risk. Testing in a non-production environment is recommended before deployment.

---

## 🔗 Useful Links

- [MikroTik Wiki](https://wiki.mikrotik.com/)
- [MikroTik Forum](https://forum.mikrotik.com/)
- [RouterOS Scripting](https://help.mikrotik.com/docs/display/ROS/Scripting)
- [ipverse/as-ip-blocks](https://github.com/ipverse/as-ip-blocks)
- [Cloudflare API](https://api.cloudflare.com/)

---

**Made with ❤️ for the MikroTik community**

[GitHub Issues](https://github.com/viktor45/ros-scripts/issues) • [Pull Requests](https://github.com/viktor45/ros-scripts/pulls)
