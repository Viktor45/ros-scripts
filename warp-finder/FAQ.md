# Frequently Asked Questions (FAQ)

Common questions and answers about the WireGuard Endpoint Finder script.

---

## General Questions

### What does this script do?

The script automatically finds and configures working Cloudflare WARP endpoints for your MikroTik WireGuard connection. It tests random IP:port combinations until it finds one that works.

### Why do I need this?

WARP endpoints can become unreachable due to:
- Network routing changes
- ISP blocking specific IPs
- Regional connectivity issues
- Cloudflare infrastructure changes

This script automatically finds alternatives without manual intervention.

### Is this safe to use?

Yes! The script:
- Only modifies WireGuard peer settings
- Creates temporary routes with automatic cleanup
- Includes comprehensive error handling
- Logs all actions for transparency
- Can be easily reversed

### Will this interrupt my connection?

Briefly, yes. During testing:
- WireGuard peer is disabled/re-enabled (1-2 seconds per test)
- Typical total runtime: 10-60 seconds depending on attempts
- Existing connections will drop and reconnect
- Schedule during maintenance windows if concerned

---

## Installation & Configuration

### What RouterOS version do I need?

**Minimum:** RouterOS 7.20  
**Recommended:** Latest stable 7.x release  
**Not supported:** RouterOS 6.x (lacks native WireGuard)

### Do I need WireGuard already configured?

Yes. The script requires:
- WireGuard interface created
- At least one peer configured
- Basic WireGuard setup complete

See [WireGuard Setup Guide](https://help.mikrotik.com/docs/display/ROS/WireGuard) for configuration.

### How do I find my WireGuard interface name?

```routeros
/interface wireguard print
```

The output shows your interface name:
```
0  name="wgcf" mtu=1420 listen-port=51820
       ^^^^
    This is your interface name
```

### Can I use this with non-WARP WireGuard?

The script is optimized for Cloudflare WARP but can be adapted:
1. Replace IP prefixes with your provider's endpoint IPs
2. Update port list with your provider's ports
3. Adjust test parameters as needed

### How do I update the IP and port lists?

Edit these arrays in the script:

```routeros
:global ipPrefixes [:toarray "8.6.112.,162.159.192.,188.114.96."]
:global ports [:toarray "500,854,1701,2408,4500"]
```

---

## Operation & Performance

### How long does it take to find an endpoint?

**Typical:** 10-30 seconds  
**Maximum:** 2-5 minutes (depends on `maxAttempts`)

Factors affecting speed:
- Network latency
- Number of attempts needed
- `delayTime` setting
- Router CPU speed

### How many attempts before giving up?

Default: **25 attempts**

Customize:
```routeros
:local maxAttempts 50  # Try more endpoints
```

Success rate is typically 70-90% within 25 attempts.

### Can I run this on a schedule?

Yes! Recommended schedule:

```routeros
# Every 6 hours
/system scheduler add name="warp-finder" interval=6h \
  on-event="/import warp-finder.rsc"

# Daily at 3 AM
/system scheduler add name="warp-finder-nightly" \
  start-time=03:00:00 interval=1d \
  on-event="/import warp-finder.rsc"
```

### Should I run this constantly?

No. Recommendations:
- **Every 6-12 hours:** Proactive maintenance
- **On connection failure:** Reactive recovery via netwatch
- **After router reboot:** Via startup script

Avoid running more frequently than every hour.

### How much resources does it use?

**CPU:** Minimal (brief spikes during testing)  
**Memory:** < 1 MB  
**Network:** ~100 KB per test (ping packets)  
**Disk:** None (script runs in memory)

Safe for resource-constrained routers.

---

## Troubleshooting

### No working endpoint found after all attempts

**Possible causes:**
1. Firewall blocking UDP traffic
2. ISP blocking Cloudflare ranges
3. Outdated IP/port lists
4. WireGuard misconfiguration

**Solutions:**
```routeros
# Check firewall rules
/ip firewall filter print where chain=output

# Allow WireGuard UDP
/ip firewall filter add chain=output action=accept protocol=udp

# Increase attempts
:local maxAttempts 50

# Update endpoint lists (check Cloudflare docs)
```

### Script errors on import

**Error:** "syntax error"  
**Cause:** Incomplete copy/paste or file corruption  
**Fix:** Re-download and try again

**Error:** "expected end of command"  
**Cause:** RouterOS version too old  
**Fix:** Upgrade to RouterOS 7.20+

### Connection works but shows as "failed" in logs

**Cause:** Route configuration or test address unreachable  
**Fix:**
```routeros
# Try different test address
:local checkAddress "8.8.8.8"  # Google DNS
```

### Script runs but connection still doesn't work

**Check:**
1. WireGuard handshake: `/interface wireguard peers print`
2. Routing table: `/ip route print`
3. Firewall rules: `/ip firewall filter print`
4. DNS resolution: `/ping cloudflare.com`

### "No WireGuard peer found" error

**Cause:** Interface name mismatch or no peer configured

**Fix:**
```routeros
# List all interfaces and peers
/interface wireguard print
/interface wireguard peers print

# Update script with correct name
:local wgInterface "correct-name-here"
```

---

## Advanced Usage

### Can I test specific endpoints?

Yes, but requires script modification:

```routeros
# Force specific endpoint (for testing)
:local testIP "162.159.192.1"
:local testPort 500

# Skip random generation, use test values
/interface wireguard peers set $peerId \
  endpoint-address=$testIP \
  endpoint-port=$testPort
```

### Can I exclude certain IPs or ports?

Yes, create blocklist:

```routeros
# Add to script after generation
:local blockedIPs [:toarray "162.159.192.5,8.6.112.10"]
:if ([:typeof [:find $blockedIPs $endpointIP]] != "nil") do={
    # Skip this IP
    :continue
}
```

### How do I save the best endpoint permanently?

The script automatically saves it in the WireGuard peer configuration. View with:

```routeros
/interface wireguard peers print detail
```

To export configuration:
```routeros
/export file=wireguard-config
```

### Can I run multiple instances for different interfaces?

Yes! Create copies with different interface names:

```routeros
# Script 1: warp-finder-wgcf.rsc
:local wgInterface "wgcf"

# Script 2: warp-finder-wgcf2.rsc
:local wgInterface "wgcf2"
```

Schedule separately.

### How do I integrate with monitoring systems?

**Parse logs programmatically:**
```routeros
# Get last successful endpoint
/log print where message~"SUCCESS"
```

**Export to Syslog:**
```routeros
/system logging action set remote remote=192.168.1.100
/system logging add topics=script action=remote
```

**Email notifications (requires email setup):**
```routeros
/tool e-mail send to="admin@example.com" \
  subject="WARP Endpoint Updated" \
  body="New endpoint: $endpointIP:$endpointPort"
```

---

## Customization

### How do I reduce logging verbosity?

```routeros
# Disable debug logs
:global DEBUG 0
```

### How do I make it test faster?

```routeros
:local delayTime 1        # Reduce wait time
:local pingCount 1        # Fewer ping packets
:local maxAttempts 10     # Fewer attempts
```

**Warning:** Reducing delays may cause false negatives.

### How do I make it more thorough?

```routeros
:local delayTime 5        # Longer wait for slow connections
:local pingCount 10       # More comprehensive testing
:local maxAttempts 100    # More attempts
```

### Can I change the test method?

The script uses ping tests. Alternatives require modifications:

**TCP test (advanced):**
```routeros
# Test HTTPS connectivity instead of ping
/tool fetch url="https://1.1.1.1" keep-result=no
```

**Traceroute (advanced):**
```routeros
# Verify routing path
/tool traceroute 1.1.1.1 count=1
```

---

## Security & Privacy

### Does this send data to external servers?

Only standard ping (ICMP) packets to test connectivity. No personal data transmitted.

### Are my WireGuard keys exposed?

No. The script never reads or logs private keys.

### Can this be used to bypass restrictions?

This is a network management tool. Use responsibly and in compliance with your organization's policies and local laws.

### Is there telemetry or tracking?

No. The script runs entirely on your router with no external communication except connectivity tests.

---

## Compatibility

### RouterOS Versions

| Version    | Status                         |
| ---------- | ------------------------------ |
| 6.x        | ❌ Not supported (no WireGuard) |
| 7.0-7.19   | ⚠️ May work (untested)          |
| 7.20+      | ✅ Fully supported              |
| 7.x latest | ✅ Recommended                  |

### Hardware

Compatible with all MikroTik devices running RouterOS 7.20+:
- RB series (RB750, RB4011, etc.)
- hAP series
- CCR series
- CRS series with RouterOS
- CHR (Cloud Hosted Router)
- x86 installations

### WireGuard Providers

Optimized for Cloudflare WARP, but adaptable for:
- Mullvad VPN
- ProtonVPN
- Custom WireGuard servers
- Any multi-endpoint WireGuard service

---

## Support & Community

### Where can I get help?

1. **Read the documentation**
   - [README.md](README.md)
   - [Quick Start](QUICKSTART.md)
   - This FAQ

2. **Search existing issues**
   - [GitHub Issues](https://github.com/viktor45/ros-scripts/issues)

3. **Ask the community**
   - [MikroTik Forum](https://forum.mikrotik.com/)

4. **Report bugs**
   - [New Issue](https://github.com/viktor45/ros-scripts/issues/new)

### How do I contribute?

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

Quick start:
1. Fork the repository
2. Make improvements
3. Test thoroughly
4. Submit pull request

### Is there a changelog?

Yes! See [CHANGELOG.md](CHANGELOG.md) for version history.

---

## Still Have Questions?

Can't find your answer? 

🐛 [Report an Issue](https://github.com/viktor45/ros-scripts/issues/new)  

---

*Last updated: February 1, 2025*
