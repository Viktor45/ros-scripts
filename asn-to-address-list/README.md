# MikroTik ASN Prefix Updater

A robust RouterOS script that automatically fetches and updates firewall address lists with IPv4/IPv6 prefixes for any Autonomous System Number (ASN). Perfect for blocking, routing, or monitoring traffic from specific networks.

## Features

- ✅ **Automatic Updates** - Fetches latest prefix lists from [ipverse/as-ip-blocks](https://github.com/ipverse/as-ip-blocks)
- 🌐 **IPv4 & IPv6 Support** - Handle both protocol versions
- 🔄 **Smart Refresh** - Removes old entries before adding new ones
- 💾 **Configurable Storage** - Use USB, disk, or internal storage for temp files
- 📝 **Clean Logging** - Minimal, informative output
- ⚡ **Fast & Reliable** - Optimized for RouterOS 7.10+

## Requirements

- MikroTik RouterOS **7.10 or newer**
- Internet connectivity
- Storage location for temporary files (USB/disk recommended)

## Installation

1. **Create the script** in System > Scripts
   - Name: `update-asn-prefixes`
   - Copy the entire script content from `update-asn-prefixes.rsc`

2. **Set up temporary storage** (choose one option):

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

3. **Set up global variables** (see Configuration below)

4. **Run manually or schedule** (see Usage below)

## Configuration

The script uses global variables for configuration:

| Variable     | Required | Description                                     | Example                  |
| ------------ | -------- | ----------------------------------------------- | ------------------------ |
| `UAPASN`     | ✅ Yes    | ASN number (with or without "AS" prefix)        | `"13335"` or `"AS13335"` |
| `UAPLIST`    | ✅ Yes    | Name of the firewall address list               | `"cloudflare-ips"`       |
| `UAPTYPE`    | ❌ No     | IP version: `"v4"` or `"v6"` (default: `"v4"`)  | `"v4"`                   |
| `UAPTMPPATH` | ❌ No     | Temp file storage path (default: `"usb1/tmp/"`) | `"disk1/tmp/"`           |

## Usage

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

```routeros
# Update lists for multiple CDNs
:global UAPASN "13335"; :global UAPLIST "cdn-cloudflare"; /system script run update-asn-prefixes
:global UAPASN "16509"; :global UAPLIST "cdn-amazon"; /system script run update-asn-prefixes
:global UAPASN "15169"; :global UAPLIST "cdn-google"; /system script run update-asn-prefixes

# Add mangle rules for traffic marking
/ip firewall mangle add \
    chain=forward \
    dst-address-list=cdn-cloudflare \
    action=mark-connection \
    new-connection-mark=cdn-traffic \
    comment="Mark CDN traffic"
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

## Popular ASN Numbers

| Company       | ASN   | Description                        |
| ------------- | ----- | ---------------------------------- |
| Cloudflare    | 13335 | CDN and security services          |
| Google        | 15169 | Google services and infrastructure |
| Amazon        | 16509 | AWS and Amazon services            |
| Microsoft     | 8075  | Azure and Microsoft services       |
| Facebook/Meta | 32934 | Facebook, Instagram, WhatsApp      |
| Akamai        | 20940 | CDN and cloud services             |
| Netflix       | 2906  | Streaming services                 |

Find more ASNs at [bgp.he.net](https://bgp.he.net/)

## Output Example

```
update-asn-prefixes: SUCCESS - Added 777 v4 prefixes for ASN AS13335
```

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

## License

MIT License - Feel free to use and modify

## Credits

- ASN data provided by [ipverse/as-ip-blocks](https://github.com/ipverse/as-ip-blocks)
- Maintained for MikroTik RouterOS community

## Contributing

Issues, improvements, and pull requests are welcome!

## Changelog

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