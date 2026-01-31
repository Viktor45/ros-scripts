# WireGuard Endpoint Finder for MikroTik RouterOS

<div align="center">

**Automatically discover and configure optimal WireGuard endpoints for Cloudflare WARP on MikroTik routers**

[Features](#features) • [Installation](#installation) • [Usage](#usage) • [Configuration](#configuration) • [Troubleshooting](#troubleshooting)

</div>

---

## 📋 Table of Contents

- [WireGuard Endpoint Finder for MikroTik RouterOS](#wireguard-endpoint-finder-for-mikrotik-routeros)
  - [📋 Table of Contents](#-table-of-contents)
  - [🌟 Overview](#-overview)
    - [Why This Script?](#why-this-script)
  - [✨ Features](#-features)
    - [Core Functionality](#core-functionality)
    - [Technical Features](#technical-features)
  - [📦 Requirements](#-requirements)
    - [Hardware](#hardware)
    - [Software](#software)
    - [Prerequisites](#prerequisites)
  - [🚀 Installation](#-installation)
    - [Step 1: Download the Script](#step-1-download-the-script)
    - [Step 2: Upload to MikroTik](#step-2-upload-to-mikrotik)
      - [Method 1: WebFig/WinBox](#method-1-webfigwinbox)
      - [Method 2: FTP/SFTP](#method-2-ftpsftp)
      - [Method 3: Copy-Paste](#method-3-copy-paste)
    - [Step 3: Verify Installation](#step-3-verify-installation)
  - [⚙️ Configuration](#️-configuration)
    - [Basic Configuration](#basic-configuration)
    - [Finding Your WireGuard Interface Name](#finding-your-wireguard-interface-name)
  - [🎯 Usage](#-usage)
    - [One-Time Execution](#one-time-execution)
      - [Via Terminal (Recommended)](#via-terminal-recommended)
      - [Via WinBox](#via-winbox)
    - [Scheduled Execution](#scheduled-execution)
    - [Run on Connection Failure](#run-on-connection-failure)
  - [🔍 How It Works](#-how-it-works)
    - [Workflow Diagram](#workflow-diagram)
    - [Step-by-Step Process](#step-by-step-process)
  - [🔧 Advanced Configuration](#-advanced-configuration)
    - [Custom IP Prefix List](#custom-ip-prefix-list)
    - [Custom Port List](#custom-port-list)
    - [Adjust Testing Parameters](#adjust-testing-parameters)
    - [Production Mode (Disable Debug)](#production-mode-disable-debug)
  - [🐛 Troubleshooting](#-troubleshooting)
    - [Common Issues](#common-issues)
      - [1. "No WireGuard peer found"](#1-no-wireguard-peer-found)
      - [2. "IP prefixes array is empty"](#2-ip-prefixes-array-is-empty)
      - [3. No working endpoint found](#3-no-working-endpoint-found)
      - [4. Script runs but no connection](#4-script-runs-but-no-connection)
    - [Debug Mode](#debug-mode)
    - [Manual Testing](#manual-testing)
  - [🚀 Performance Tips](#-performance-tips)
    - [Optimize for Speed](#optimize-for-speed)
    - [Optimize for Reliability](#optimize-for-reliability)
    - [Scheduled Optimization](#scheduled-optimization)
  - [📊 Monitoring](#-monitoring)
    - [View Active Endpoint](#view-active-endpoint)
    - [Check Script History](#check-script-history)
    - [Create Dashboard](#create-dashboard)
  - [🤝 Contributing](#-contributing)
    - [Reporting Issues](#reporting-issues)
    - [Submitting Changes](#submitting-changes)
    - [Code Style](#code-style)
  - [📄 License](#-license)
  - [🙏 Acknowledgments](#-acknowledgments)
  - [📞 Support](#-support)
    - [Get Help](#get-help)
    - [Useful Links](#useful-links)
  - [🗺️ Roadmap](#️-roadmap)
    - [Planned Features](#planned-features)
    - [Version History](#version-history)
      - [v1.0.0 (Current)](#v100-current)
  - [⚠️ Disclaimer](#️-disclaimer)


---

## 🌟 Overview

This RouterOS script automates the process of finding and configuring working WireGuard endpoints for Cloudflare WARP connections on MikroTik routers. It intelligently tests multiple IP/port combinations from Cloudflare's infrastructure to establish the most reliable connection.

### Why This Script?

- **Automatic Failover**: No manual endpoint configuration needed
- **Optimal Performance**: Tests and selects working endpoints automatically
- **Network Resilience**: Quickly recovers from endpoint failures
- **Time Saving**: Eliminates manual trial-and-error configuration
- **Production Ready**: Comprehensive error handling and logging

---

## ✨ Features

### Core Functionality
- 🔄 **Automatic Endpoint Discovery** - Tests random IP:port combinations until a working endpoint is found
- 🎯 **Smart Random Selection** - Uses system entropy for truly random endpoint generation
- 🏥 **Health Checking** - Validates connectivity with ICMP ping tests
- 📊 **Comprehensive Logging** - Detailed debug output and operational logs
- 🛡️ **Safe Operation** - Automatic cleanup and rollback on failure

### Technical Features
- ⚡ **Optimized Performance** - Efficient RouterOS scripting with minimal resource usage
- 🔧 **Highly Configurable** - Easy customization of all parameters
- 🚀 **Production Grade** - Error handling, validation, and recovery mechanisms
- 📝 **Well Documented** - Extensive inline comments and documentation
- 🎨 **Clean Code** - Professional structure following RouterOS best practices

---

## 📦 Requirements

### Hardware
- **MikroTik Router** with WireGuard support
  - Any RouterOS v7.x compatible device
  - Sufficient CPU/RAM for WireGuard encryption

### Software
- **RouterOS Version**: 7.20 or higher
- **WireGuard Package**: Enabled and configured
- **Active Internet Connection**: For endpoint testing

### Prerequisites
- Cloudflare WARP account and credentials
- WireGuard interface already created and configured
- Basic understanding of MikroTik RouterOS

---

## 🚀 Installation

### Step 1: Download the Script

```bash
# Clone the repository
git clone https://github.com/Viktor45/ros-scripts
cd warp-finder
```

Or download directly:
- [warp-finder.rsc](warp-finder.rsc)

### Step 2: Upload to MikroTik

#### Method 1: WebFig/WinBox
1. Open **WebFig** or **WinBox**
2. Navigate to **Files**
3. Upload `warp-finder.rsc`

#### Method 2: FTP/SFTP
```bash
# Using SCP (recommended)
scp warp-finder.rsc admin@192.168.88.1:/

# Or using FTP
ftp 192.168.88.1
> put warp-finder.rsc
```

#### Method 3: Copy-Paste
1. Open the script in a text editor
2. Copy the entire content
3. Paste into **Terminal** in WinBox/WebFig
4. Press Enter

### Step 3: Verify Installation

```bash
# SSH into your router
ssh admin@192.168.88.1

# Import the script
/import warp-finder.rsc
```

---

## ⚙️ Configuration

### Basic Configuration

Edit the following variables in the script before running:

```routeros
# WireGuard interface name (must match your existing interface)
:local wgInterface "cloudflare-interface"

# Address to ping for connectivity testing
:local checkAddress "1.1.1.1"

# Maximum number of endpoint attempts
:local maxAttempts 10

# Number of ping packets to send per test
:local pingCount 2

# Delay in seconds after changing endpoint
:local delayTime 2

# Enable debug logging (0=disabled, 1=enabled)
:global DEBUG 1
```

### Finding Your WireGuard Interface Name

```routeros
# List all WireGuard interfaces
/interface wireguard print

# Output example:
# 0  name="wgcf" mtu=1420 listen-port=51820
```

Use the `name` value for the `wgInterface` variable.

---

## 🎯 Usage

### One-Time Execution

#### Via Terminal (Recommended)
```routeros
# SSH into your router
ssh admin@192.168.88.1

# Run the script
/import warp-finder.rsc
```

#### Via WinBox
1. Open **New Terminal**
2. Type: `/import warp-finder.rsc`
3. Press Enter

### Scheduled Execution

Create a scheduler to run the script automatically:

```routeros
# Create a scheduler to run every 6 hours
/system scheduler add \
  name="warp-finder" \
  interval=6h \
  on-event="/import warp-finder.rsc" \
  comment="Auto-find working WARP endpoint"
```

### Run on Connection Failure

```routeros
# Create a netwatch entry to trigger on connection loss
/tool netwatch add \
  host=1.1.1.1 \
  interval=30s \
  timeout=1s \
  down-script="/import warp-finder.rsc" \
  comment="Run endpoint finder if connection fails"
```

---

## 🔍 How It Works

### Workflow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│  1. Initialize Script & Load Configuration                  │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Validate Arrays & Create Temporary Route                │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Generate Random Endpoint (IP:Port)                      │
│     • Random IP prefix from list                            │
│     • Random last octet (1-254)                             │
│     • Random port from list                                 │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Configure WireGuard Peer                                │
│     • Disable peer                                          │
│     • Update listen port                                    │
│     • Set endpoint address & port                           │
│     • Re-enable peer                                        │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│  5. Test Connectivity (Ping Test)                           │
└─────────────────┬───────────────────────────────────────────┘
                  │
          ┌───────┴────────┐
          │                │
          ▼                ▼
    ┌─────────┐      ┌─────────┐
    │ Success │      │ Failure │
    └────┬────┘      └────┬────┘
         │                │
         │                └──► Repeat (max attempts)
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│  6. Cleanup & Report                                        │
│     • Remove temporary route                                │
│     • Log final status                                      │
└─────────────────────────────────────────────────────────────┘
```

### Step-by-Step Process

1. **Initialization**
   - Loads IP prefixes and port lists
   - Validates configuration
   - Creates temporary routing entry

2. **Random Generation**
   - Uses system time and uptime for entropy
   - Generates random IP from Cloudflare's address space
   - Selects random port from known working ports

3. **Configuration**
   - Temporarily disables WireGuard peer
   - Updates endpoint settings
   - Changes listen port to avoid conflicts
   - Re-enables peer

4. **Testing**
   - Waits for WireGuard handshake
   - Sends ping packets through tunnel
   - Validates connectivity

5. **Decision**
   - If successful: Exits and logs success
   - If failed: Tries next random endpoint
   - Repeats until success or max attempts reached

6. **Cleanup**
   - Removes temporary routes
   - Provides detailed status report

---

## 🔧 Advanced Configuration

### Custom IP Prefix List

Update the `ipPrefixes` array with your own list:

```routeros
:global ipPrefixes [:toarray "162.159.192.,162.159.193.,188.114.96.,188.114.97."]
```

### Custom Port List

Modify the `ports` array:

```routeros
:global ports [:toarray "500,854,1701,2408,4500,8854"]
```

### Adjust Testing Parameters

```routeros
# Increase attempts for better success rate
:local maxAttempts 50

# More thorough ping testing
:local pingCount 5

# Longer wait for slower connections
:local delayTime 5
```

### Production Mode (Disable Debug)

```routeros
# Set DEBUG to 0 to reduce log verbosity
:global DEBUG 0
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. "No WireGuard peer found"

**Cause**: WireGuard interface name doesn't match or peer not configured

**Solution**:
```routeros
# Check your WireGuard configuration
/interface wireguard print
/interface wireguard peers print

# Update the script with correct interface name
:local wgInterface "your-interface-name"
```

#### 2. "IP prefixes array is empty"

**Cause**: Array initialization failed

**Solution**:
```routeros
# Manually verify array syntax
:global ipPrefixes [:toarray "8.6.112.,162.159.192."]
:put [:len $ipPrefixes]
# Should output: 2
```

#### 3. No working endpoint found

**Cause**: Network issues, firewall blocking, or outdated endpoints

**Solution**:
```routeros
# Check firewall rules
/ip firewall filter print

# Ensure UDP is allowed
/ip firewall filter add chain=output action=accept protocol=udp

# Try increasing maxAttempts
:local maxAttempts 50

# Update IP/port lists with current Cloudflare endpoints
```

#### 4. Script runs but no connection

**Cause**: Routing or firewall configuration

**Solution**:
```routeros
# Verify WireGuard interface is up
/interface print stats

# Check routing table
/ip route print

# Test manual ping
/ping 1.1.1.1 interface=wgcf
```

### Debug Mode

Enable detailed logging:

```routeros
:global DEBUG 1
```

Check logs:

```routeros
# View recent logs
/log print where topics~"script"

# Filter warning logs
/log print where message~"DEBUG"
```

### Manual Testing

Test endpoint manually:

```routeros
# Set specific endpoint
/interface wireguard peers set [find interface=wgcf] \
  endpoint-address=162.159.192.1 \
  endpoint-port=500

# Test connectivity
/ping 1.1.1.1 count=10 interface=wgcf
```

---

## 🚀 Performance Tips

### Optimize for Speed

```routeros
# Reduce delay for faster testing (if network is fast)
:local delayTime 1

# Use fewer ping packets
:local pingCount 1

# Reduce max attempts if endpoints usually work
:local maxAttempts 10
```

### Optimize for Reliability

```routeros
# Increase delay for slower networks
:local delayTime 3

# More thorough testing
:local pingCount 5

# More attempts to find working endpoint
:local maxAttempts 50
```

### Scheduled Optimization

```routeros
# Run during low-traffic hours
/system scheduler add \
  name="warp-finder-night" \
  start-time=03:00:00 \
  interval=1d \
  on-event="/import warp-finder.rsc"
```

---

## 📊 Monitoring

### View Active Endpoint

```routeros
# Check current WireGuard configuration
/interface wireguard peers print detail

# Output includes:
# endpoint-address: 162.159.192.123
# endpoint-port: 500
# last-handshake: 2m30s ago
```

### Check Script History

```routeros
# View script execution logs
/log print where message~"endpoint"

# Count successful runs
/log print where message~"SUCCESS"
```

### Create Dashboard

```routeros
# Add to system notes
/system note set note="Last WARP endpoint: 162.159.192.123:500 ($([:tostr [/system clock get date]])"
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

### Reporting Issues

1. Check existing issues first
2. Provide RouterOS version
3. Include relevant logs
4. Describe expected vs actual behavior

### Submitting Changes

1. Fork the repository
2. Create a feature branch
3. Follow RouterOS scripting conventions
4. Add comments for complex logic
5. Test on actual hardware
6. Submit pull request with description

### Code Style

- Use descriptive variable names
- Add comments for complex operations
- Follow existing indentation (4 spaces)
- Use lowercase for local variables
- Use `:global` only when necessary
- Include error handling

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

```
MIT License

Copyright (c) 2025 Viktor45

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

## 🙏 Acknowledgments

- **MikroTik** - For RouterOS and WireGuard implementation
- **Cloudflare** - For WARP infrastructure
- **WireGuard** - For the amazing VPN protocol
- **Community Contributors** - For testing and feedback

---

## 📞 Support

### Get Help

- 📖 [MikroTik Wiki](https://wiki.mikrotik.com/)
- 💬 [MikroTik Forum](https://forum.mikrotik.com/)
- 🐛 [GitHub Issues](https://github.com/Viktor45/ros-scripts/issues)


### Useful Links

- [RouterOS Scripting Manual](https://help.mikrotik.com/docs/display/ROS/Scripting)
- [WireGuard Documentation](https://www.wireguard.com/)
- [Cloudflare WARP](https://1.1.1.1/)

---

## 🗺️ Roadmap

### Planned Features

- [ ] IPv6 support
- [ ] Automatic endpoint list updates
- [ ] Failover to backup endpoints

### Version History

#### v1.0.0 (Current)
- Initial release
- Basic endpoint discovery
- Ping-based health checking
- Comprehensive logging

---

## ⚠️ Disclaimer

This script is provided "as-is" without warranty. Use at your own risk. Always test in a non-production environment first. The authors are not responsible for any network disruptions or data loss.

---


<div align="center">

**Made with ❤️ for the MikroTik community**

[⬆ Back to Top](#wireguard-endpoint-finder-for-mikrotik-routeros)

</div>
