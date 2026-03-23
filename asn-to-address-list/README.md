# MikroTik ASN Prefix Updater

English version: [README.md](README.md) | Русская версия: [README_ru.md](README_ru.md)

A robust RouterOS script suite that automatically fetches and updates firewall address lists with IPv4/IPv6 prefixes for any Autonomous System Number (ASN). Perfect for blocking, routing, or monitoring traffic from specific networks.

<!-- TOC -->
* [MikroTik ASN Prefix Updater](#mikrotik-asn-prefix-updater)
  * [Scripts Included](#scripts-included)
  * [Features](#features)
  * [Requirements](#requirements)
  * [Installation](#installation)
    * [Main Script](#main-script)
    * [Helper Scripts (Optional)](#helper-scripts-optional)
    * [Storage Setup](#storage-setup)
  * [Configuration - Main Script (update-asn-prefixes)](#configuration---main-script-update-asn-prefixes)
  * [Usage](#usage)
    * [Main Script - Basic Examples](#main-script---basic-examples)
    * [Basic IPv4 Example](#basic-ipv4-example)
    * [IPv6 Example](#ipv6-example)
    * [Custom Storage Path](#custom-storage-path)
    * [Multiple ASNs (New in v2.0)](#multiple-asns-new-in-v20)
    * [Cleaner Script - Usage Examples](#cleaner-script---usage-examples)
    * [Runner Script - Batch Updates](#runner-script---batch-updates)
    * [Scheduled Updates](#scheduled-updates)
  * [Use Cases](#use-cases)
    * [Block Traffic from Specific ASN](#block-traffic-from-specific-asn)
    * [Allow Only Specific ASN Traffic](#allow-only-specific-asn-traffic)
    * [Monitor Traffic to CDN Networks](#monitor-traffic-to-cdn-networks)
    * [Prioritize Traffic for Specific Networks](#prioritize-traffic-for-specific-networks)
  * [Complete Workflow Examples](#complete-workflow-examples)
    * [Example 1: Manage Hosting Provider IPs](#example-1-manage-hosting-provider-ips)
    * [Example 2: Rotate ASN Lists](#example-2-rotate-asn-lists)
    * [Example 3: Temporary ASN Blocking](#example-3-temporary-asn-blocking)
  * [Popular ASN Numbers](#popular-asn-numbers)
  * [Output Example](#output-example)
  * [Troubleshooting](#troubleshooting)
    * ["Processing failed" Error](#processing-failed-error)
    * [Script Doesn't Update](#script-doesnt-update)
    * [Temp File Permission Issues](#temp-file-permission-issues)
    * [Cleaner Script Issues](#cleaner-script-issues)
  * [Advanced Configuration](#advanced-configuration)
    * [Using RAM Disk (tmpfs) for Better Performance](#using-ram-disk-tmpfs-for-better-performance)
    * [Multiple ASNs in One List](#multiple-asns-in-one-list)
    * [Cleanup Old Temp Files](#cleanup-old-temp-files)
    * [View Current ASN Entries](#view-current-asn-entries)
    * [Emergency Cleanup](#emergency-cleanup)
  * [License](#license)
  * [Credits](#credits)
  * [Contributing](#contributing)
  * [Changelog](#changelog)
    * [Version 2.0.1 (2026-01-18)](#version-201-2026-01-18)
    * [Version 1.4.0 (2026-01-18)](#version-140-2026-01-18)
    * [Version 1.3.1 (2026-01-18)](#version-131-2026-01-18)
    * [Version 1.2.0 (2026-01-18)](#version-120-2026-01-18)
    * [Version 1.0.0 (2026-01-18)](#version-100-2026-01-18)
<!-- TOC -->

## Scripts Included

- **update-asn-prefixes.rsc** - Main script for fetching and updating ASN prefixes
- **update-asn-cleaner.rsc** - Utility script for removing ASN entries from address lists
- **update-asn-runner-example.rsc** - Example wrapper script for batch updates (hosting providers)

## Features

- ✅ **Automatic Updates** - Fetches latest prefix lists from [ipverse/as-ip-blocks](https://github.com/ipverse/as-ip-blocks)
- 🌐 **IPv4 & IPv6 Support** - Handle both protocol versions
- 🔢 **Multiple ASNs** - Process multiple ASNs in a single run (comma-separated)
- 🔄 **Smart Refresh** - Removes old entries before adding new ones
- 💾 **Configurable Storage** - Use USB, disk, or RAM disk (tmpfs) for temp files
- 📝 **Clean Logging** - Minimal, informative output with per-ASN progress
- ⚡ **Fast & Reliable** - Optimized for RouterOS 7.10+

## Requirements

- MikroTik RouterOS **7.10 or newer**
- Internet connectivity
- Storage location for temporary files (USB/disk recommended)

## Installation

### Main Script

1. **Create the main script** in System > Scripts
   - Name: `update-asn-prefixes`
   - Copy the entire script content from [update-asn-prefixes.rsc](./update-asn-prefixes.rsc)

### Helper Scripts (Optional)

1. **Create the cleaner script** (optional but recommended)
   - Name: `update-asn-cleaner`
   - Copy the entire script content from [update-asn-cleaner.rsc](./update-asn-cleaner.rsc)

2. **Create example runner script** (optional - for batch updates)
   - Name: `update-asn-runner-example`
   - Copy the entire script content from [update-asn-runner-example.rsc](./update-asn-runner-example.rsc)
   - Customize the ASN list for your needs

### Storage Setup

1. **Set up temporary storage** (choose one option):

   **Option A: Use USB/Disk storage (recommended for scheduled updates)**
   ```routeros
   # Verify your USB/disk is mounted
   /file print
   # Look for usb1, disk1, etc.
   ```

   **Option B: Use RAM disk (tmpfs) for temporary files**

   RAM disk is faster and reduces wear on USB/disk storage, perfect for frequent updates:

   ```routeros
   # Create a tmpfs RAM disk (substitute with your available RAM size)
   /disk add slot=tmpfs type=tmpfs tmpfs-max-size=10M
   
   # Verify it was created
   /disk print
   
   # The tmpfs disk will appear as "tmpfs1"
   # Use it in your script configuration:
   :global UAPTMPPATH "tmpfs1/"
   ```

   **Note:** RAM disk contents are lost on reboot, but temporary files are cleaned up automatically by the script.

2. **Set up global variables** (see Configuration below)

3. **Run manually or schedule** (see Usage below)

---

## Configuration - Main Script (update-asn-prefixes)

The script uses global variables for configuration:

| Variable     | Required | Description                                     | Example                  |
|--------------|----------|-------------------------------------------------|--------------------------|
| `UAPASN`     | ✅ Yes    | ASN number (with or without "AS" prefix)        | `"13335"` or `"AS13335"` |
| `UAPLIST`    | ✅ Yes    | Name of the firewall address list               | `"cloudflare-ips"`       |
| `UAPTYPE`    | ❌ No     | IP version: `"v4"` or `"v6"` (default: `"v4"`)  | `"v4"`                   |
| `UAPTMPPATH` | ❌ No     | Temp file storage path (default: `"usb1/tmp/"`) | `"disk1/tmp/"`           |

## Usage

### Main Script - Basic Examples

### Basic IPv4 Example

```routeros
:global UAPASN "13335"
:global UAPLIST "cloudflare-v4"
/system script run update-asn-prefixes
```

### IPv6 Example

```routeros
:global UAPASN "13335"
:global UAPLIST "cloudflare-v6"
:global UAPTYPE "v6"
/system script run update-asn-prefixes
```

### Custom Storage Path

**Using disk storage:**
```routeros
:global UAPASN "15169"
:global UAPLIST "google-ips"
:global UAPTMPPATH "disk1/temp/"
/system script run update-asn-prefixes
```

**Using RAM disk (tmpfs):**
```routeros
:global UAPASN "15169"
:global UAPLIST "google-ips"
:global UAPTMPPATH "tmpfs1/"
/system script run update-asn-prefixes
```

### Multiple ASNs (New in v2.0)

**Process multiple ASNs in a single run:**
```routeros
:global UAPASN "174,8560,13335"
:global UAPLIST "multiple-providers"
/system script run update-asn-prefixes
```

**With spaces (also supported):**
```routeros
:global UAPASN "13335, 16509, 15169"
:global UAPLIST "major-cdn-networks"
/system script run update-asn-prefixes
```

**Mixed format (AS prefix optional):**
```routeros
:global UAPASN "AS174,8560,AS13335"
:global UAPLIST "transit-providers"
/system script run update-asn-prefixes
```

---

### Cleaner Script - Usage Examples

**Clean specific ASN from specific list:**
```routeros
:global UAPASN "13335"
:global UAPLIST "cloudflare-ips"
/system script run update-asn-cleaner
```

**Clean multiple ASNs from specific list:**
```routeros
:global UAPASN "174,8560,13335"
:global UAPLIST "hosters"
/system script run update-asn-cleaner
```

**Clean specific ASN(s) from ALL lists:**
```routeros
:global UAPASN "13335,16509"
# Don't set UAPLIST
/system script run update-asn-cleaner
```

**Clean ALL ASN entries from specific list:**
```routeros
# Don't set UAPASN
:global UAPLIST "hosters"
/system script run update-asn-cleaner
```

**Clean ALL ASN entries from ALL lists:**
```routeros
# Don't set either variable
/system script run update-asn-cleaner
```

---

### Runner Script - Batch Updates

The example runner script (`update-asn-runner-example.rsc`) demonstrates batch updates for hosting providers:

**Run the example (updates 47 hosting provider ASNs):**
```routeros
/system script run update-asn-runner-example
```

**Customize for your needs:**
Edit the script and change the ASN list:
```routeros
# Example: Update only major CDN providers
:local hosterASNs "13335,16509,15169"
```

**Schedule batch updates:**
```routeros
/system scheduler add \
    name=update-hosters-daily \
    start-time=02:00:00 \
    interval=1d \
    on-event="/system script run update-asn-runner-example" \
    comment="Daily hosting provider IP update"
```

---

### Scheduled Updates

Update Cloudflare IPs daily at 3 AM:

```routeros
/system scheduler add \
    name=update-cloudflare-ips \
    start-time=03:00:00 \
    interval=1d \
    on-event="/system script run update-asn-prefixes" \
    comment="Daily Cloudflare IP update"
```

**Note:** Set the global variables before adding the scheduler, or include them in the scheduler's `on-event`:

```routeros
/system scheduler add \
    name=update-cloudflare-ips \
    start-time=03:00:00 \
    interval=1d \
    on-event=":global UAPASN \"13335\"; :global UAPLIST \"cloudflare-v4\"; /system script run update-asn-prefixes" \
    comment="Daily Cloudflare IPv4 update"
```

---

## Use Cases

### Block Traffic from Specific ASN

```routeros
# Update the list
:global UAPASN "12345"
:global UAPLIST "blocked-asn"
/system script run update-asn-prefixes

# Add firewall rule to block
/ip firewall filter add \
    chain=input \
    src-address-list=blocked-asn \
    action=drop \
    comment="Block ASN 12345"
```

### Allow Only Specific ASN Traffic

```routeros
# Update the list
:global UAPASN "13335"
:global UAPLIST "allowed-asn"
/system script run update-asn-prefixes

# Add firewall rule to accept
/ip firewall filter add \
    chain=forward \
    src-address-list=allowed-asn \
    action=accept \
    comment="Allow ASN 13335"
```

### Monitor Traffic to CDN Networks

**Using multiple ASNs in single list (recommended):**
```routeros
# Update all CDN networks at once
:global UAPASN "13335,16509,15169"
:global UAPLIST "cdn-networks"
/system script run update-asn-prefixes

# Add mangle rule for traffic marking
/ip firewall mangle add \
    chain=forward \
    dst-address-list=cdn-networks \
    action=mark-connection \
    new-connection-mark=cdn-traffic \
    comment="Mark CDN traffic"
```

**Or using separate lists:**
```routeros
# Update lists for individual CDNs
:global UAPASN "13335"; :global UAPLIST "cdn-cloudflare"; /system script run update-asn-prefixes
:global UAPASN "16509"; :global UAPLIST "cdn-amazon"; /system script run update-asn-prefixes
:global UAPASN "15169"; :global UAPLIST "cdn-google"; /system script run update-asn-prefixes
```

### Prioritize Traffic for Specific Networks

```routeros
# Update the list
:global UAPASN "13335"
:global UAPLIST "priority-network"
/system script run update-asn-prefixes

# Mark packets for QoS
/ip firewall mangle add \
    chain=forward \
    dst-address-list=priority-network \
    action=mark-packet \
    new-packet-mark=priority \
    comment="Priority traffic to ASN 13335"

# Apply queue with priority
/queue simple add \
    name=priority-queue \
    packet-marks=priority \
    priority=1/1 \
    comment="Priority queue for marked traffic"
```

---

## Complete Workflow Examples

### Example 1: Manage Hosting Provider IPs

**Step 1 - Initial setup:**
```routeros
# Run the example script to populate the list
/system script run update-asn-runner-example
```

**Step 2 - Block hosting providers:**
```routeros
/ip firewall filter add \
    chain=input \
    src-address-list=hosters \
    action=drop \
    comment="Block hosting providers"
```

**Step 3 - Schedule weekly updates:**
```routeros
/system scheduler add \
    name=update-hosters-weekly \
    start-time=03:00:00 \
    interval=7d \
    on-event="/system script run update-asn-runner-example"
```

**Step 4 - Clean up when needed:**
```routeros
# Remove specific ASN
:global UAPASN "13335"
:global UAPLIST "hosters"
/system script run update-asn-cleaner

# Or remove all hosters
:global UAPLIST "hosters"
/system script run update-asn-cleaner
```

### Example 2: Rotate ASN Lists

**Replace old ASNs with new ones:**
```routeros
# Clean old list
:global UAPLIST "cdn-networks"
/system script run update-asn-cleaner

# Update with new ASNs
:global UAPASN "13335,16509,15169"
:global UAPLIST "cdn-networks"
/system script run update-asn-prefixes
```

### Example 3: Temporary ASN Blocking

**Add temporary block:**
```routeros
# Add ASN to block list
:global UAPASN "12345"
:global UAPLIST "temp-block"
/system script run update-asn-prefixes

# Create firewall rule
/ip firewall filter add \
    chain=input \
    src-address-list=temp-block \
    action=drop \
    comment="Temporary block"
```

**Remove when done:**
```routeros
# Clean the ASN
:global UAPASN "12345"
:global UAPLIST "temp-block"
/system script run update-asn-cleaner

# Remove firewall rule
/ip firewall filter remove [find comment="Temporary block"]
```

---

## Popular ASN Numbers

| Company       | ASN   | Description                        |
|---------------|-------|------------------------------------|
| Cloudflare    | 13335 | CDN and security services          |
| Google        | 15169 | Google services and infrastructure |
| Amazon        | 16509 | AWS and Amazon services            |
| Microsoft     | 8075  | Azure and Microsoft services       |
| Facebook/Meta | 32934 | Facebook, Instagram, WhatsApp      |
| Akamai        | 20940 | CDN and cloud services             |
| Netflix       | 2906  | Streaming services                 |

Find more ASNs at [bgp.he.net](https://bgp.he.net/)

## Output Example

**Single ASN:**
```
update-asn-prefixes: Processing 1 ASN(s)
update-asn-prefixes: AS13335 - Added 777 v4 prefixes
update-asn-prefixes: SUCCESS - Total 777 v4 prefixes added for 1 ASN(s)
```

**Multiple ASNs:**
```
update-asn-prefixes: Processing 3 ASN(s)
update-asn-prefixes: AS13335 - Added 777 v4 prefixes
update-asn-prefixes: AS16509 - Added 1234 v4 prefixes
update-asn-prefixes: AS15169 - Added 892 v4 prefixes
update-asn-prefixes: SUCCESS - Total 2903 v4 prefixes added for 3 ASN(s)
```

**Cleaner output:**
```
clean-asns: Removing entries for 1 ASN(s)
clean-asns: AS13335 - Removed 777 entries
clean-asns: SUCCESS - Removed 777 total entries
```

**Runner output:**
```
update-hoster-asns: Starting update for hosting providers
update-asn-prefixes: Processing 47 ASN(s)
update-asn-prefixes: AS174 - Added 234 v4 prefixes
update-asn-prefixes: AS8560 - Added 156 v4 prefixes
[... continues for all 47 ASNs ...]
update-asn-prefixes: SUCCESS - Total 12543 v4 prefixes added for 47 ASN(s)
update-hoster-asns: Update completed
```

---

## Troubleshooting

### "Processing failed" Error

- **Check internet connectivity**: Ensure the router can reach `raw.githubusercontent.com`
- **Verify ASN exists**: Visit `https://github.com/ipverse/as-ip-blocks/tree/master/as/[YOUR_ASN]`
- **Check storage path**: Ensure the temp path exists and is writable

### Script Doesn't Update

- **Verify global variables are set**: `/system script environment print`
- **Check logs**: `/log print where topics~"script"`
- **Test manually**: Run the script from terminal to see immediate output

### Temp File Permission Issues

- **Change storage location**: Use `UAPTMPPATH` to point to a writable location
- **Use RAM disk**: Create tmpfs for reliable temporary storage: `/disk add slot=tmpfs type=tmpfs tmpfs-max-size=10M`
- **Create directory**: `/file print` to verify the path exists
- **Check disk space**: Ensure sufficient space is available on your storage device

### Cleaner Script Issues

**"No entries found" for existing ASN:**
- **Verify comment format**: Check if entries have "ASN AS####" comment format
- **Check list name**: Ensure `UAPLIST` matches the list containing the entries
- **View existing entries**: `/ip firewall address-list print where comment~"ASN"`

**Accidental deletion:**
- The cleaner script doesn't ask for confirmation - be careful!
- Always verify with `UAPASN` set first before running without it

---

## Advanced Configuration

### Using RAM Disk (tmpfs) for Better Performance

For routers with sufficient RAM, using tmpfs provides faster file operations and reduces wear on physical storage:

```routeros
# Create tmpfs with appropriate size (adjust based on your needs)
# 10MB is usually enough for multiple ASN lists
/disk add slot=tmpfs type=tmpfs tmpfs-max-size=10M

# Verify creation
/disk print

# Set as default temp path
:global UAPTMPPATH "tmpfs1/"

# Now run your updates as usual
:global UAPASN "13335"
:global UAPLIST "cloudflare-v4"
/system script run update-asn-prefixes
```

**Advantages:**
- ✅ Faster read/write operations
- ✅ No wear on USB/disk storage
- ✅ Automatic cleanup on reboot
- ✅ Suitable for frequent scheduled updates

**Disadvantages:**
- ❌ Uses router RAM (ensure sufficient free memory)
- ❌ Contents lost on reboot (not an issue for temporary files)

### Multiple ASNs in One List

**Now built-in! Simply use comma-separated ASNs:**

```routeros
# Single command for multiple ASNs
:global UAPASN "13335,16509,15169"
:global UAPLIST "cdn-networks"
/system script run update-asn-prefixes
```

Each ASN will have its own comment tag (e.g., "ASN AS13335", "ASN AS16509"), allowing you to remove individual ASNs later if needed.

**Legacy method (still works):**
```routeros
# Create a wrapper script
:global UAPLIST "cdn-networks"

:global UAPASN "13335"
/system script run update-asn-prefixes

:global UAPASN "16509"
/system script run update-asn-prefixes

:global UAPASN "15169"
/system script run update-asn-prefixes
```

### Cleanup Old Temp Files

```routeros
/file remove [find name~"^asn-.*\\.txt\$"]
```

### View Current ASN Entries

**List all ASN entries:**
```routeros
/ip firewall address-list print where comment~"^ASN AS"
```

**Count entries per ASN:**
```routeros
# IPv4
:foreach entry in=[/ip firewall address-list find comment~"^ASN AS"] do={
    :local comment [/ip firewall address-list get $entry comment]
    :put $comment
}

# IPv6
:foreach entry in=[/ipv6 firewall address-list find comment~"^ASN AS"] do={
    :local comment [/ipv6 firewall address-list get $entry comment]
    :put $comment
}
```

### Emergency Cleanup

**Remove ALL ASN entries immediately:**
```routeros
/system script run update-asn-cleaner
```

**Remove all temp files:**
```routeros
/file remove [find name~"asn-"]
```

---

## License

MIT License - Feel free to use and modify

## Credits

- ASN data provided by [ipverse/as-ip-blocks](https://github.com/ipverse/as-ip-blocks)
- Maintained for MikroTik RouterOS community

## Contributing

Issues, improvements, and pull requests are welcome!

## Changelog

### Version 2.0.1 (2026-01-18)
- **Main script**: Added support for multiple ASNs in single run (comma-separated)
- **Main script**: Enhanced logging with per-ASN progress tracking
- **Main script**: Added rate limiting delay between ASN processing
- **Main script**: Improved error handling for invalid ASNs
- **Main script**: Each ASN gets individual comment tag for easy management
- **New**: Added cleaner script (update-asn-cleaner.rsc)
- **New**: Added example runner script (update-asn-runner-example.rsc)

### Version 1.4.0 (2026-01-18)
- Added IPv6 support via `UAPTYPE` variable
- Improved temp file naming with IP type suffix
- Enhanced success messages

### Version 1.3.1 (2026-01-18)
- Removed unnecessary debug output
- Cleaner log messages

### Version 1.2.0 (2026-01-18)
- Switched to manual line parsing for better compatibility
- Fixed deserialization issues with comment lines

### Version 1.0.0 (2026-01-18)
- Initial release
- IPv4 support
- Configurable storage path