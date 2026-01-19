# 🔄 MikroTik DNS Resolution Script

A powerful and flexible RouterOS script that automatically resolves IPv4 and IPv6 addresses in firewall address lists and stores the resolved hostnames in comments for easy identification and tracking.

## 📋 Table of Contents

- [Features](#-features)
- [Requirements](#-requirements)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [How It Works](#-how-it-works)
- [Examples](#-examples)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Features

- **Dual Stack Support**: Full IPv4 and IPv6 address resolution
- **Flexible IP Version Selection**: Process IPv4 only, IPv6 only, or both simultaneously
- **Automatic DNS Resolution**: Resolves IP addresses to hostnames automatically
- **Configurable DNS Server**: Use any DNS server of your choice (Cloudflare, Google, OpenDNS, etc.)
- **Separate List Configuration**: Independent configuration for IPv4 and IPv6 address lists
- **Error Handling**: Built-in error handling for failed DNS resolutions
- **Debug Logging**: Optional logging for troubleshooting (commented by default)
- **Easy Configuration**: All settings in a clear configuration section
- **Non-Destructive**: Only updates empty comments, preserving existing data
- **Reliable Processing**: Optimized script handles both IP versions with proven logic

## 🔧 Requirements

- MikroTik Router with RouterOS v7.20 or higher
- Administrative access to the router
- Network connectivity for DNS resolution
- IPv6 connectivity (if processing IPv6 addresses)

## 📥 Installation

1. Connect to your MikroTik router via Winbox, WebFig, or SSH

2. Navigate to **System → Scripts**

3. Click the **+** button to create a new script

4. Give it a meaningful name (e.g., `resolve-address-lists`)

5. Copy and paste the script code into the source field

6. Click **OK** to save

## ⚙️ Configuration

Edit the configuration section at the top of the script to customize its behavior:

### DNS Server Configuration

```routeros
:local dnsServer "1.1.1.1"
```

**Popular DNS Servers:**
- `1.1.1.1` - Cloudflare DNS (default, fast and privacy-focused)
- `8.8.8.8` - Google DNS (reliable and widely used)
- `208.67.222.222` - OpenDNS (family-friendly filtering available)
- `9.9.9.9` - Quad9 (security-focused)
- `2606:4700:4700::1111` - Cloudflare DNS (IPv6)
- `2001:4860:4860::8888` - Google DNS (IPv6)
- Your ISP's DNS server

### IP Version Selection

```routeros
:local ipVersion "both"
```

**Available Options:**
- `"ipv4"` - Process only IPv4 address lists
- `"ipv6"` - Process only IPv6 address lists
- `"both"` - Process both IPv4 and IPv6 address lists (default)

### IPv4 Address Lists Configuration

```routeros
:local ipv4ListsToResolve {
    "Trap";
    "MYDN";
    "MyCustomList";
}
```

Add or remove IPv4 address list names as needed. The script will only process entries from these lists.

### IPv6 Address Lists Configuration

```routeros
:local ipv6ListsToResolve {
    "Trap-v6";
    "MYDN-v6";
    "MyCustomList-v6";
}
```

Add or remove IPv6 address list names as needed. The script will only process entries from these lists.

## 🚀 Usage

### Manual Execution

Run the script manually from the terminal:

```
/system script run resolve-address-lists
```

### Scheduled Execution

Set up automatic execution at regular intervals:

1. Go to **System → Scheduler**
2. Click **+** to add a new schedule
3. Configure:
   - **Name**: `auto-resolve-addresses`
   - **Start Date/Time**: Set to current date/time
   - **Interval**: `1d 00:00:00` (runs daily)
   - **On Event**: `/system script run resolve-address-lists`

4. Click **OK**

### Integration with Other Scripts

You can call this script from other scripts:

```routeros
/system script run resolve-address-lists
```

## 🔍 How It Works

1. **Initialization**: Loads configuration (DNS server, IP version, and target address lists)

2. **Version Selection**: Determines which IP versions to process based on `ipVersion` setting

3. **IPv4 Processing** (if enabled):
   - Loops through all IPv4 firewall address list entries
   - Checks if the entry's list name matches configured IPv4 lists
   - Verifies if the comment field is empty
   - Attempts DNS resolution using the configured DNS server
   - Updates the comment field with the resolved hostname or "error"

4. **IPv6 Processing** (if enabled):
   - Loops through all IPv6 firewall address list entries
   - Checks if the entry's list name matches configured IPv6 lists
   - Verifies if the comment field is empty
   - Attempts DNS resolution using the configured DNS server
   - Updates the comment field with the resolved hostname or "error"

5. **Completion**: Both IP versions are processed independently based on configuration

## 📖 Examples

### Example 1: IPv4 Only Setup

Configure the script to resolve only IPv4 addresses:

```routeros
:local dnsServer "8.8.8.8"
:local ipVersion "ipv4"
:local ipv4ListsToResolve {
    "Denylist";
    "Allowlist";
}
```

### Example 2: IPv6 Only Setup

Configure the script to resolve only IPv6 addresses:

```routeros
:local dnsServer "2606:4700:4700::1111"
:local ipVersion "ipv6"
:local ipv6ListsToResolve {
    "Denylist-v6";
    "Allowlist-v6";
}
```

### Example 3: Dual Stack (IPv4 + IPv6)

Monitor both IPv4 and IPv6 addresses simultaneously:

```routeros
:local dnsServer "1.1.1.1"
:local ipVersion "both"

:local ipv4ListsToResolve {
    "Suspicious-IPs";
    "Failed-Logins";
    "Port-Scanners";
}

:local ipv6ListsToResolve {
    "Suspicious-IPs-v6";
    "Failed-Logins-v6";
    "Port-Scanners-v6";
}
```

### Example 4: Multi-Network Dual Stack

Resolve addresses across different network segments for both IP versions:

```routeros
:local dnsServer "208.67.222.222"
:local ipVersion "both"

:local ipv4ListsToResolve {
    "Guest-Network";
    "IoT-Devices";
    "Management-IPs";
    "VPN-Clients";
}

:local ipv6ListsToResolve {
    "Guest-Network-v6";
    "IoT-Devices-v6";
    "Management-IPs-v6";
    "VPN-Clients-v6";
}
```

### Example 5: Security Monitoring with Separate DNS

Use different DNS servers for IPv4 and IPv6 (requires running script twice with different configs):

**First run (IPv4):**
```routeros
:local dnsServer "8.8.8.8"
:local ipVersion "ipv4"
:local ipv4ListsToResolve { "Threats" }
```

**Second run (IPv6):**
```routeros
:local dnsServer "2001:4860:4860::8888"
:local ipVersion "ipv6"
:local ipv6ListsToResolve { "Threats-v6" }
```

## 🐛 Troubleshooting

### Enable Debug Logging

Uncomment the logging lines in the script to see detailed execution information:

```routeros
:log info ("*** Processing IPv4 addresses - DNS Server: " . $dnsServer);
:log info ("*** Processing IPv6 addresses - DNS Server: " . $dnsServer);
```

View logs in **Log** menu or via terminal:

```
/log print where topics~"script"
```

### Common Issues

**Issue**: Script doesn't process any entries

**Solution**: 
- Verify that your address list names exactly match the names in `ipv4ListsToResolve` or `ipv6ListsToResolve`
- Check that `ipVersion` is set correctly ("ipv4", "ipv6", or "both")
- Ensure you have entries in the appropriate address lists (`/ip firewall address-list` or `/ipv6 firewall address-list`)

---

**Issue**: IPv6 resolutions show "error"

**Solution**: 
- Verify your router has IPv6 connectivity
- Check that the DNS server supports IPv6 queries
- If using an IPv6 DNS server, ensure your router can reach it
- Test IPv6 connectivity: `/ipv6 route print` and `/ipv6 address print`

---

**Issue**: All resolutions show "error"

**Solution**: 
- Check DNS server connectivity
- Verify the DNS server IP address is correct
- Ensure firewall rules allow DNS queries (UDP port 53)
- Test DNS manually: `/tool fetch url=http://www.google.com`

---

**Issue**: Comments are not updating

**Solution**: The script only updates empty comments. To force re-resolution, clear existing comments first:

```routeros
# Clear IPv4 comments
/ip firewall address-list set [find list="YourListName"] comment=""

# Clear IPv6 comments
/ipv6 firewall address-list set [find list="YourListName-v6"] comment=""
```

---

**Issue**: Script takes too long to execute

**Solution**: 
- Reduce the number of lists in `ipv4ListsToResolve` and `ipv6ListsToResolve`
- Set `ipVersion` to "ipv4" or "ipv6" instead of "both" if you don't need dual stack
- Reduce the number of entries in your address lists
- Split processing into separate scheduled runs for IPv4 and IPv6

---

**Issue**: Different results for IPv4 vs IPv6

**Solution**: This is normal behavior. Some hosts may only have IPv4 (A records) or IPv6 (AAAA records), or may resolve to different hostnames depending on the IP version.

## 🌐 IPv6 Best Practices

### Naming Convention
Use consistent naming for IPv4 and IPv6 lists:
- IPv4: `Denylist`, `Allowlist`, `Suspicious-IPs`
- IPv6: `Denylist-v6`, `Allowlist-v6`, `Suspicious-IPs-v6`

### DNS Server Selection
- Use IPv4 DNS servers for general use (works for both IPv4 and IPv6 resolution)
- Use IPv6 DNS servers only if you have stable IPv6 connectivity
- Popular dual-stack DNS providers work well with both IP versions

### Address List Organization
Separate IPv4 and IPv6 address lists for:
- Easier management and troubleshooting
- Independent processing control
- Clear visibility in firewall rules

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Ideas for Contributions

- Automatic detection of IP version from address format
- Performance optimizations
- Support for custom DNS query types
- Integration with external threat intelligence feeds

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- MikroTik for their powerful RouterOS platform with dual-stack support
- The MikroTik community for inspiration and support
- Contributors to IPv6 adoption and standards

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/viktor45/ros-scripts/issues)
- **MikroTik Forum**: [forum.mikrotik.com](https://forum.mikrotik.com)
- **IPv6 Resources**: [ipv6.he.net](https://ipv6.he.net) for IPv6 learning

---

**Made with ❤️ for the MikroTik community**

*If you find this script useful, please consider giving it a ⭐ on GitHub!*

### Version History

- **v3.0** - Added IPv6 support with separate list configuration and independent processing blocks
- **v2.0** - Configurable DNS server and full list names
- **v1.0** - Initial release with basic IPv4 support