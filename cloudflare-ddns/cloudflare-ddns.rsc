# ============================================================================
# CLOUDFLARE DYNAMIC DNS UPDATE SCRIPT - IPv4/IPv6
# For MikroTik RouterOS 7.20+
# ============================================================================

:log info "=== STARTING CLOUDFLARE DDNS SCRIPT ==="

# ============================================================================
# CONFIGURATION
# ============================================================================

:local authToken "CF_AUTH_TOKEN"

# Format: "domain.com,zone_id,record_id,proxied,ip_version"
# ip_version: v4 or v6
:local domains {
    "domain2.com,ZONE2_ID,RECORD2_ID,true,v4";
    "domain3.com,ZONE3_ID,RECORD3_ID,false,v6"
}

# ============================================================================
# RETRIEVE CURRENT PUBLIC IP ADDRESSES
# ============================================================================

:local currentIPv4 ""
:local currentIPv6 ""

:do {
    :set currentIPv4 [/ip/cloud/get public-address as-string-value]
} on-error={
    :log warning "Failed to retrieve IPv4 address"
}

:do {
    :set currentIPv6 [/ip/cloud/get public-address-ipv6 as-string-value]
} on-error={
    :log warning "Failed to retrieve IPv6 address"
}

:if ($currentIPv4 != "") do={ :log info ("Current IPv4: " . $currentIPv4) }
:if ($currentIPv6 != "") do={ :log info ("Current IPv6: " . $currentIPv6) }

# ============================================================================
# CHECK IF IP HAS CHANGED
# ============================================================================

:global lastCloudflareIPv4
:global lastCloudflareIPv6

:local ipv4Changed false
:local ipv6Changed false

:if ([:typeof $lastCloudflareIPv4] = "nothing") do={
    :set lastCloudflareIPv4 ""
}

:if ([:typeof $lastCloudflareIPv6] = "nothing") do={
    :set lastCloudflareIPv6 ""
}

:if ($currentIPv4 != $lastCloudflareIPv4 && $currentIPv4 != "") do={
    :log info ("IPv4 changed: " . $lastCloudflareIPv4 . " → " . $currentIPv4)
    :set ipv4Changed true
    :set lastCloudflareIPv4 $currentIPv4
}

:if ($currentIPv6 != $lastCloudflareIPv6 && $currentIPv6 != "") do={
    :log info ("IPv6 changed: " . $lastCloudflareIPv6 . " → " . $currentIPv6)
    :set ipv6Changed true
    :set lastCloudflareIPv6 $currentIPv6
}

# ============================================================================
# UPDATE DNS RECORDS
# ============================================================================

:if ($ipv4Changed || $ipv6Changed) do={
    :local successCount 0
    :local failCount 0

    :foreach domainEntry in=$domains do={
        :local comma1 [:find $domainEntry ","]
        :local comma2 [:find $domainEntry "," ($comma1 + 1)]
        :local comma3 [:find $domainEntry "," ($comma2 + 1)]
        :local comma4 [:find $domainEntry "," ($comma3 + 1)]

        :if ($comma1 != "" && $comma2 != "" && $comma3 != "" && $comma4 != "") do={
            :local domain [:pick $domainEntry 0 $comma1]
            :local zoneId [:pick $domainEntry ($comma1 + 1) $comma2]
            :local recordId [:pick $domainEntry ($comma2 + 1) $comma3]
            :local proxied [:pick $domainEntry ($comma3 + 1) $comma4]
            :local ipVersion [:pick $domainEntry ($comma4 + 1) [:len $domainEntry]]

            :local shouldUpdate false
            :local currentIP ""
            :local recordType ""

            :if ($ipVersion = "v4" && $ipv4Changed) do={
                :set shouldUpdate true
                :set currentIP $currentIPv4
                :set recordType "A"
            }

            :if ($ipVersion = "v6" && $ipv6Changed) do={
                :set shouldUpdate true
                :set currentIP $currentIPv6
                :set recordType "AAAA"
            }

            :if ($shouldUpdate && $currentIP != "") do={
                :local json ("{\"type\":\"" . $recordType . "\",\"name\":\"" . $domain . \
                            "\",\"content\":\"" . $currentIP . \
                            "\",\"ttl\":300,\"proxied\":" . $proxied . "}")

                :local authHeader ("Authorization: Bearer " . $authToken)

                :do {
                    /tool fetch \
                        url=("https://api.cloudflare.com/client/v4/zones/" . $zoneId . "/dns_records/" . $recordId) \
                        http-method=patch \
                        http-header=$authHeader \
                        http-data=$json \
                        output=user

                    :log info ("✅ Updated " . $domain . " (" . $recordType . ") → " . $currentIP)
                    :set successCount ($successCount + 1)
                } on-error={
                    :log error ("❌ Failed to update " . $domain)
                    :set failCount ($failCount + 1)
                }

                :delay 1s
            }
        } else={
            :log error ("Invalid domain entry format: " . $domainEntry)
            :set failCount ($failCount + 1)
        }
    }

    :log info ("Summary: " . $successCount . " successful, " . $failCount . " failed")
} else={
    :log info "No IP changes detected. Skipping updates."
}

:log info "=== CLOUDFLARE DDNS SCRIPT FINISHED ==="