# MikroTik Cloudflare DDNS Script

Automatically update Cloudflare DNS records when your MikroTik router's public IP address changes. Supports both IPv4 and IPv6.

## Features

- ✅ IPv4 and IPv6 support
- ✅ Multiple domains/subdomains
- ✅ Cloudflare proxy toggle (orange/gray cloud)
- ✅ Efficient IP change detection
- ✅ Automatic API updates
- ✅ Compatible with RouterOS 7.20+

## Prerequisites

1. **MikroTik Router** running RouterOS 7.20 or later
2. **Cloudflare Account** with:
   - Domain(s) added to Cloudflare
   - API Token with DNS edit permissions
3. **IP Cloud Service** enabled on MikroTik

## Installation

### Step 1: Enable IP Cloud

```bash
/ip cloud set ddns-enabled=yes
```

### Step 2: Get Cloudflare API Credentials

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Go to **My Profile** → **API Tokens**
3. Click **Create Token**
4. Use the **Edit zone DNS** template or create custom token with:
   - Permissions: `Zone → DNS → Edit`
   - Zone Resources: `Include → Specific zone → [Your Domain]`
5. Copy the generated token

### Step 3: Get Zone ID and Record ID

#### Get Zone ID:
1. Go to your domain in Cloudflare Dashboard
2. Scroll down on the **Overview** page
3. Find **Zone ID** in the right sidebar

#### Get Record ID:
Use Cloudflare API or this curl command:

```bash
curl -X GET "https://api.cloudflare.com/client/v4/zones/ZONE_ID/dns_records" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json"
```

Find your domain's record in the response and copy its `id`.

### Step 4: Configure the Script

1. Open the script file
2. Replace `CF_AUTH_TOKEN` with your actual Cloudflare API token
3. Configure your domains in the array:

```routeros
:local domains {
    "example.com,zone_id,record_id,true,v4";
    "ipv6.example.com,zone_id,record_id,false,v6";
    "subdomain.example.com,zone_id,record_id,true,v4"
}
```

**Array format:** `"domain,zone_id,record_id,proxied,ip_version"`

- `domain`: Your domain/subdomain
- `zone_id`: Cloudflare Zone ID
- `record_id`: DNS Record ID
- `proxied`: `true` (orange cloud) or `false` (gray cloud)
- `ip_version`: `v4` for IPv4 or `v6` for IPv6

### Step 5: Add Script to MikroTik

1. Copy the entire script
2. In MikroTik terminal or WebFig/WinBox:
   - Go to **System → Scripts**
   - Click **Add New**
   - Name: `cloudflare-ddns`
   - Paste the script
   - Click **OK**

### Step 6: Create Scheduler

```bash
/system scheduler add \
  name=cloudflare-ddns-update \
  on-event=cloudflare-ddns \
  interval=5m \
  start-time=startup
```

This runs the script every 5 minutes and on router startup.

## Configuration Examples

### IPv4 Only
```routeros
:local domains {
    "home.example.com,abc123zone,xyz789record,true,v4"
}
```

### IPv6 Only
```routeros
:local domains {
    "ipv6.example.com,abc123zone,xyz789record,false,v6"
}
```

### Multiple Domains (IPv4 and IPv6)
```routeros
:local domains {
    "example.com,abc123zone,rec1id,true,v4";
    "www.example.com,abc123zone,rec2id,true,v4";
    "ipv6.example.com,abc123zone,rec3id,false,v6";
    "*.example.com,abc123zone,rec4id,true,v4"
}
```

### Same Domain - Dual Stack (A + AAAA records)
```routeros
:local domains {
    "example.com,abc123zone,ipv4_record_id,true,v4";
    "example.com,abc123zone,ipv6_record_id,true,v6"
}
```

## Verification

### Check Script Logs
```bash
/log print where topics~"script"
```

You should see messages like:
```
✅ Updated example.com (A) → 203.0.113.45
✅ Updated ipv6.example.com (AAAA) → 2001:db8::1
```

### Manual Test Run
```bash
/system script run cloudflare-ddns
```

### Check Global Variables
```bash
/system script environment print
```

Look for `lastCloudflareIPv4` and `lastCloudflareIPv6`.

## Troubleshooting

### Script Not Running
- Verify scheduler is enabled: `/system scheduler print`
- Check if IP Cloud is working: `/ip cloud print`

### API Errors
- Verify API token has correct permissions
- Check Zone ID and Record ID are correct
- Ensure token hasn't expired

### IPv6 Not Working
- Verify IPv6 is configured on your router
- Check IP Cloud has IPv6 address: `/ip cloud print`
- Ensure your ISP provides public IPv6

### No Updates Happening
- IP might not have changed
- Check logs: `/log print where topics~"script"`
- Verify domains array format is correct

## Security Notes

⚠️ **Important:** Your API token has DNS edit permissions. Keep it secure!

- Don't share your script with the token included
- Use environment variables or separate config if sharing
- Regularly rotate API tokens
- Use minimal permissions (only DNS edit for specific zones)

## Customization

### Change Update Interval
Modify the scheduler interval:
```bash
/system scheduler set cloudflare-ddns-update interval=10m
```

### Change TTL
Edit the `ttl` value in the script (default is 300 seconds):
```routeros
:local json ("{\"type\":\"" . $recordType . "\",\"name\":\"" . $domain . \
            "\",\"content\":\"" . $currentIP . \
            "\",\"ttl\":120,\"proxied\":" . $proxied . "}")
```

### Disable Rate Limiting Delay
Remove or adjust the delay between updates:
```routeros
:delay 1s
```

## Uninstallation

```bash
/system scheduler remove cloudflare-ddns-update
/system script remove cloudflare-ddns
/system script environment remove lastCloudflareIPv4
/system script environment remove lastCloudflareIPv6
```

## License

MIT License - Feel free to modify and distribute

## Contributing

Issues and pull requests are welcome!

## Credits

Created for MikroTik RouterOS 7.20+ with Cloudflare DNS integration