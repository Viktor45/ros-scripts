# 🛡️ MikroTik Connection Anomaly Detection & Blocking Script

[![MikroTik](https://img.shields.io/badge/MikroTik-RouterOS%207.20+-blue.svg)](https://mikrotik.com)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/yourusername/mikrotik-connection-monitor/graphs/commit-activity)
[![Status](https://img.shields.io/badge/status-experimental-orange.svg)](https://github.com/yourusername/mikrotik-connection-monitor)

A robust, configurable MikroTik RouterOS script that automatically detects and blocks suspicious network connections based on asymmetric packet patterns. Perfect for mitigating port scans, TLS handshake timeouts, and other network anomalies.

> **⚠️ EXPERIMENTAL WARNING**  
> This script is currently in **experimental status**. While it has been tested and works as intended, it should be deployed with caution:
> - **Test in a non-production environment first**
> - **Monitor logs closely** after initial deployment
> - **Review blocked IPs regularly** to ensure no false positives
> - **Keep allowlist updated** with your trusted IPs and services
> - **Be prepared to adjust thresholds** based on your network's behavior
> - **Backup your configuration** before implementing
> 
> Use at your own risk. The authors are not responsible for any network disruptions or unintended blocking.

## 📋 Table of Contents

- [Features](#-features)
- [How It Works](#-how-it-works)
- [Requirements](#-requirements)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [Firewall Rules](#-firewall-rules)
- [Monitoring & Logs](#-monitoring--logs)
- [Troubleshooting](#-troubleshooting)
- [Performance Considerations](#-performance-considerations)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Features

- **🎯 Smart Detection**: Identifies connections with asymmetric packet counts (high outgoing, low/no incoming)
- **⚙️ Highly Configurable**: All parameters adjustable via global variables
- **🚫 Auto-Blocking**: Automatically adds suspicious IPs to firewall address-list
- **✅ Allowlist Support**: Protect trusted IPs from being blocked
- **🔒 Local IP Protection**: Prevents blocking your own router addresses
- **📊 Multi-Protocol**: Supports TCP, UDP, and other protocols
- **🎚️ Granular Logging**: Configurable log levels (debug, info, warning, error)
- **⚡ Performance Optimized**: Rate limiting and efficient connection processing
- **🔄 Self-Healing**: Automatic recovery from errors with detailed logging
- **📝 Detailed Comments**: Track blocking reasons with source information

## 🔍 How It Works

The script monitors active connections and identifies suspicious patterns:

1. **Connection Analysis**: Scans firewall connections for asymmetric packet counts
2. **Pattern Detection**: Flags connections with >3 outgoing packets but ≤2 incoming packets
3. **Validation**: Checks against allowlists, local addresses, and monitored ports
4. **Auto-Block**: Adds offending IPs to address-list with configurable timeout
5. **Cleanup**: Optionally removes TCP connections to free resources

**Common Use Cases:**
- Detecting failed TLS handshakes (port 443 timeouts)
- Identifying port scanning attempts
- Blocking DoS/DDoS sources
- Mitigating connection flood attacks

## 📦 Requirements

- **MikroTik RouterOS**: Version 7.20 or higher
- **Permissions**: Admin or script policy access
- **Resources**: Minimal CPU/memory overhead (configurable)

## 🚀 Installation

### Method 1: Web Interface (WinBox/WebFig)

1. Open your MikroTik router interface
2. Navigate to **System → Scripts**
3. Click **Add New** (+)
4. Set the following:
   - **Name**: `connection-monitor`
   - **Policy**: `read, write, policy, test`
   - **Source**: Paste the script code
5. Click **OK**

### Method 2: Terminal/SSH

```bash
# Connect to your router
ssh admin@192.168.88.1

# Create the script (paste the entire script, then Ctrl+D)
/system script add name=connection-monitor policy=read,write,policy,test source={
# Paste script here
}

# Run the script
/system script run connection-monitor
```

### Method 3: Scheduler (Auto-Start)

To run the script automatically on router startup:

```routeros
/system scheduler add \
    name=connection-monitor-startup \
    on-event="/system script run connection-monitor" \
    start-time=startup \
    interval=0
```

## ⚙️ Configuration

All configuration is done via global variables at the top of the script:

### Core Settings

```routeros
:global cfgEnabled true                          # Enable/disable script
:global cfgMonitoredPorts {443; 80; 8443}       # Ports to monitor
:global cfgProtocols {"tcp"; "udp"}             # Protocols to check
```

### Detection Thresholds

```routeros
:global cfgMinOrigPackets 3                      # Min outgoing packets to trigger
:global cfgMaxReplPackets 2                      # Max incoming packets allowed
```

### Blocking & Performance

```routeros
:global cfgBlockTimeout "1d"                     # How long to block IPs (1d, 12h, 30m)
:global cfgLoopDelay 2                           # Seconds between checks
:global cfgMaxConnPerCycle 50                    # Max connections per cycle
```

### Advanced Options

```routeros
:global cfgAddressList "tls_block"               # Name of blocking address-list
:global cfgAllowlistName "allowlist"             # Name of allowlist
:global cfgLogLevel "warning"                    # Log level: debug/info/warning/error
:global cfgRemoveTCPConn true                    # Remove blocked TCP connections
:global cfgCheckLocalAddr true                   # Skip local router IPs
```

### Configuration Examples

**Example 1: Monitor HTTPS and SSH**
```routeros
:global cfgMonitoredPorts {443; 22; 8443}
:global cfgBlockTimeout "2d"
```

**Example 2: Aggressive Blocking**
```routeros
:global cfgMinOrigPackets 2
:global cfgMaxReplPackets 1
:global cfgBlockTimeout "7d"
```

**Example 3: Debug Mode**
```routeros
:global cfgLogLevel "debug"
:global cfgLoopDelay 5
```

## 📖 Usage

### Start the Script

```routeros
/system script run connection-monitor
```

### Stop the Script

```routeros
# Find the script process
/system script job print

# Kill the job (replace X with job number)
/system script job remove X
```

### Create Allowlist

Prevent trusted IPs from being blocked:

```routeros
/ip firewall address-list add list=allowlist address=8.8.8.8 comment="Google DNS"
/ip firewall address-list add list=allowlist address=1.1.1.1 comment="Cloudflare DNS"
/ip firewall address-list add list=allowlist address=192.168.1.100 comment="Trusted Server"
```

### View Blocked IPs

```routeros
/ip firewall address-list print where list=tls_block
```

### Manually Remove Blocked IP

```routeros
/ip firewall address-list remove [find where address=1.2.3.4 and list=tls_block]
```

### Clear All Blocks

```routeros
/ip firewall address-list remove [find where list=tls_block]
```

## 🔥 Firewall Rules

The script only adds IPs to an address-list. You need firewall rules to actually block traffic:

### Recommended Rules

**Block in Forward Chain** (for router traffic):
```routeros
/ip firewall filter add \
    chain=forward \
    action=drop \
    src-address-list=tls_block \
    comment="Block detected anomalous connections" \
    place-before=0
```

**Block in Input Chain** (for router itself):
```routeros
/ip firewall filter add \
    chain=input \
    action=drop \
    src-address-list=tls_block \
    comment="Block attacks on router" \
    place-before=0
```

**Log Before Dropping** (optional):
```routeros
/ip firewall filter add \
    chain=forward \
    action=log \
    src-address-list=tls_block \
    log-prefix="BLOCKED-ANOMALY" \
    place-before=0

/ip firewall filter add \
    chain=forward \
    action=drop \
    src-address-list=tls_block \
    place-before=1
```

## 📊 Monitoring & Logs

### View Logs

```routeros
/log print where message~"ConnectionMonitor"
```

### Real-Time Log Monitoring

```routeros
/log print follow where message~"ConnectionMonitor"
```

### Example Log Output

```
warning: [ConnectionMonitor] Detected asymmetric tcp connection: 192.168.1.50:54321 -> 203.0.113.45:443 (orig>3, repl<=2)
info: [ConnectionMonitor] Added 203.0.113.45 to tls_block (timeout: 1d)
info: [ConnectionMonitor] Processed 5 suspicious connections
```

### Statistics

Check how many IPs are currently blocked:

```routeros
:put [/ip firewall address-list print count-only where list=tls_block]
```

## 🔧 Troubleshooting

### Script Not Running

**Check if script exists:**
```routeros
/system script print
```

**Check for syntax errors:**
```routeros
/system script run connection-monitor
# Look for error messages
```

**Verify scheduler (if using auto-start):**
```routeros
/system scheduler print
```

### No IPs Being Blocked

**Check log level:**
```routeros
:global cfgLogLevel "debug"
# Then check logs for "Skipping" messages
```

**Verify monitored ports:**
```routeros
# Make sure traffic is going to ports in cfgMonitoredPorts
/ip firewall connection print where dst-port=443
```

**Check thresholds:**
```routeros
# Lower thresholds for more sensitive detection
:global cfgMinOrigPackets 2
:global cfgMaxReplPackets 1
```

### High CPU Usage

**Increase loop delay:**
```routeros
:global cfgLoopDelay 5
```

**Reduce max connections:**
```routeros
:global cfgMaxConnPerCycle 20
```

**Change log level:**
```routeros
:global cfgLogLevel "error"
```

### Legitimate Traffic Being Blocked

**Add to allowlist:**
```routeros
/ip firewall address-list add list=allowlist address=X.X.X.X
```

**Adjust thresholds:**
```routeros
:global cfgMinOrigPackets 5
:global cfgMaxReplPackets 3
```

**Increase block timeout:**
```routeros
:global cfgBlockTimeout "1h"  # Shorter timeout for testing
```

## ⚡ Performance Considerations

### Resource Impact

| Connections | Loop Delay | CPU Impact            |
| ----------- | ---------- | --------------------- |
| < 1000      | 2s         | Minimal (~1-2%)       |
| 1000-5000   | 3s         | Low (~3-5%)           |
| 5000-10000  | 5s         | Moderate (~5-10%)     |
| > 10000     | 10s        | Consider optimization |

### Optimization Tips

1. **Adjust Loop Delay**: Increase `cfgLoopDelay` for busy routers
2. **Limit Port Monitoring**: Only monitor critical ports
3. **Reduce Max Connections**: Set `cfgMaxConnPerCycle` to 20-30
4. **Use Warning/Error Logs**: Avoid debug logging in production
5. **Clean Old Blocks**: Shorter `cfgBlockTimeout` reduces address-list size

### Memory Usage

- **Base Script**: ~10-20 KB
- **Per Blocked IP**: ~200 bytes
- **1000 Blocked IPs**: ~200 KB additional

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Test on MikroTik RouterOS 7.20+
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

### Reporting Issues

Please include:
- RouterOS version
- Script configuration (sanitized)
- Log output
- Steps to reproduce

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- MikroTik for RouterOS scripting capabilities
- Community members who tested and provided feedback
- Original inspiration from TLS timeout detection scripts

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/mikrotik-connection-monitor/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/mikrotik-connection-monitor/discussions)
- **MikroTik Forum**: [forum.mikrotik.com](https://forum.mikrotik.com)

---

**⭐ If this script helps secure your network, please star this repository!**

Made with ❤️ for the MikroTik community