# ============================================================================
# WireGuard Endpoint Finder Script
# ============================================================================
# Description: Automatically finds and tests working WireGuard endpoints
#              by trying random IP:port combinations from predefined lists
# RouterOS Version: 7.20 or higher
# ============================================================================

# ----------------------------------------------------------------------------
# CONFIGURATION SECTION
# ----------------------------------------------------------------------------

# WireGuard interface name
:local wgInterface "your-cloudflare-interface-name"

# Address to ping for connectivity testing
:local checkAddress "1.1.1.1"

# Maximum number of endpoint attempts
:local maxAttempts 10

# Number of ping packets to send per test
:local pingCount 2

# Delay in seconds after changing endpoint (allows WireGuard handshake)
:local delayTime 2

# Enable debug logging (0=disabled, 1=enabled)
:global DEBUG 0

# ----------------------------------------------------------------------------
# ENDPOINT LISTS
# ----------------------------------------------------------------------------

# List of IP address prefixes for Cloudflare WARP endpoints
:global ipPrefixes [:toarray "8.6.112.,8.34.70.,8.34.146.,8.35.211.,8.39.125.,\
8.39.204.,8.39.214.,8.47.69.,162.159.192.,162.159.193.,162.159.195.,\
188.114.96.,188.114.97.,188.114.98.,188.114.99."]

# List of known working UDP ports for WARP
:global ports [:toarray "500,854,859,864,878,880,890,891,894,903,908,928,934,\
939,942,943,945,946,955,968,987,988,1002,1010,1014,1018,1070,1074,1180,1387,\
1701,1843,2371,2408,2506,3138,3476,3581,3854,4177,4198,4233,4500,5279,5956,\
7103,7152,7156,7281,7559,8319,8742,8854,8886"]

# ----------------------------------------------------------------------------
# HELPER FUNCTIONS
# ----------------------------------------------------------------------------

# Debug logging function
:global debugPrint do={
    :if ($DEBUG = 1) do={
        :log warning "DEBUG: $1"
    }
}

# Random number generator using system entropy
:local generateRandom do={
    :local multiplier $1
    :local modulo $2
    :local offset $3
    
    # Get system values for entropy
    :local timeValue [/system clock get time]
    :local uptimeValue [/system resource get uptime]
    
    # Convert to strings and create hash
    :local timeStr [:tostr $timeValue]
    :local uptimeStr [:tostr $uptimeValue]
    
    # Simple hash function
    :local hash 1
    :for i from=0 to=([:len $timeStr] - 1) do={
        :local char [:pick $timeStr $i]
        :set hash ($hash + [:tonum $char])
    }
    :for i from=0 to=([:len $uptimeStr] - 1) do={
        :local char [:pick $uptimeStr $i]
        :set hash ($hash + [:tonum $char])
    }
    
    # Apply multiplier and modulo
    :local result (($hash * $multiplier + $offset) % $modulo)
    :return $result
}

# ----------------------------------------------------------------------------
# INITIALIZATION
# ----------------------------------------------------------------------------

[$debugPrint] "=== WireGuard Endpoint Finder Starting ==="
[$debugPrint] "Interface: $wgInterface"
[$debugPrint] "Test address: $checkAddress"
[$debugPrint] "IP prefixes loaded: $([:len \$ipPrefixes])"
[$debugPrint] "Ports loaded: $([:len \$ports])"

# Verify arrays are populated
:if ([:len $ipPrefixes] = 0) do={
    :log error "FATAL: IP prefixes array is empty!"
    :error "Cannot proceed without IP prefixes"
}
:if ([:len $ports] = 0) do={
    :log error "FATAL: Ports array is empty!"
    :error "Cannot proceed without ports"
}

# ----------------------------------------------------------------------------
# ROUTING SETUP
# ----------------------------------------------------------------------------

# Create temporary route for connectivity testing
:local routeCIDR "$checkAddress/32"
:local routeExists [/ip route find dst-address=$routeCIDR]
:local routeAdded false

:if ([:len $routeExists] = 0) do={
    [$debugPrint] "Creating temporary route to $checkAddress via $wgInterface"
    /ip route add dst-address=$routeCIDR gateway=$wgInterface comment="temp-wg-test"
    :set routeAdded true
} else={
    [$debugPrint] "Route to $checkAddress already exists"
}

# ----------------------------------------------------------------------------
# MAIN ENDPOINT DISCOVERY LOOP
# ----------------------------------------------------------------------------

:local attempt 0
:local endpointFound false

:while (($attempt < $maxAttempts) && (!$endpointFound)) do={
    :set attempt ($attempt + 1)
    
    # ========================================
    # Generate Random Endpoint
    # ========================================
    
    # Generate random IP from prefix list
    :local prefixIndex [$generateRandom (17 + $attempt) [:len $ipPrefixes] ($attempt * 7)]
    :local ipPrefix ($ipPrefixes->$prefixIndex)
    
    # Generate random last octet (1-254)
    :local lastOctet [$generateRandom (19 + $attempt) 254 ($attempt * 3)]
    :if ($lastOctet = 0) do={ :set lastOctet 1 }
    
    # Construct full IP address
    :local endpointIP "$ipPrefix$lastOctet"
    
    # Generate random port from list
    :local portIndex [$generateRandom (23 + $attempt) [:len $ports] ($attempt * 11)]
    :local endpointPort ($ports->$portIndex)
    
    [$debugPrint] "Attempt $attempt/$maxAttempts"
    :log info "Testing endpoint: $endpointIP:$endpointPort"
    
    # ========================================
    # Configure WireGuard Peer
    # ========================================
    
    # Find the WireGuard peer
    :local peerId [/interface wireguard peers find interface=$wgInterface]
    
    :if ([:len $peerId] = 0) do={
        :log error "No WireGuard peer found for interface $wgInterface"
        :error "WireGuard peer configuration error"
    }
    
    # Generate random listen port (avoid conflicts)
    :local listenPort (500 + [$generateRandom (29 + $attempt) 64001 ($attempt * 13)])
    
    # Disable peer before making changes
    [$debugPrint] "Disabling peer temporarily"
    /interface wireguard peers set $peerId disabled=yes
    :delay 1s
    
    # Update interface listen port
    [$debugPrint] "Setting listen port: $listenPort"
    /interface wireguard set $wgInterface listen-port=$listenPort
    
    # Update peer endpoint
    [$debugPrint] "Setting endpoint: $endpointIP:$endpointPort"
    /interface wireguard peers set $peerId \
        endpoint-address=$endpointIP \
        endpoint-port=$endpointPort
    
    # Re-enable peer
    [$debugPrint] "Re-enabling peer"
    /interface wireguard peers set $peerId disabled=no
    
    # ========================================
    # Test Connectivity
    # ========================================
    
    # Wait for WireGuard handshake
    [$debugPrint] "Waiting $delayTime seconds for handshake"
    :delay "$delayTime"s
    
    # Perform ping test
    [$debugPrint] "Pinging $checkAddress ($pingCount packets)"
    :local pingSuccess [/ping $checkAddress count=$pingCount interface=$wgInterface]
    
    # ========================================
    # Evaluate Results
    # ========================================
    
    :if ($pingSuccess > 0) do={
        :log info "SUCCESS: Endpoint $endpointIP:$endpointPort is working!"
        :log info "Ping results: $pingSuccess/$pingCount packets received"
        :set endpointFound true
    } else={
        :log warning "FAILED: Endpoint $endpointIP:$endpointPort not responding"
    }
}

# ----------------------------------------------------------------------------
# CLEANUP
# ----------------------------------------------------------------------------

# Remove temporary route if we created it
:if ($routeAdded = true) do={
    [$debugPrint] "Removing temporary route"
    :local tempRoute [/ip route find dst-address=$routeCIDR comment="temp-wg-test"]
    :if ([:len $tempRoute] > 0) do={
        /ip route remove $tempRoute
    }
}

# ----------------------------------------------------------------------------
# FINAL REPORT
# ----------------------------------------------------------------------------

:if ($endpointFound = true) do={
    :log info "=== Endpoint Discovery Completed Successfully ==="
    
    # Display final configuration
    :local peerId [/interface wireguard peers find interface=$wgInterface]
    :local finalEndpoint [/interface wireguard peers get $peerId endpoint-address]
    :local finalPort [/interface wireguard peers get $peerId endpoint-port]
    :log info "Active endpoint: $finalEndpoint:$finalPort"
} else={
    :log error "=== Endpoint Discovery Failed ==="
    :log error "No working endpoint found after $maxAttempts attempts"
    :log error "Suggestions:"
    :log error "  1. Verify WireGuard interface is configured correctly"
    :log error "  2. Check firewall rules allow UDP traffic"
    :log error "  3. Increase maxAttempts value"
    :log error "  4. Verify IP prefixes and ports are current"
}

[$debugPrint] "=== Script Execution Finished ==="
