# Initialize global arrays using working method
:global ipPrefixes [:toarray "8.6.112.,8.34.70.,8.34.146.,8.35.211.,8.39.125.,8.39.204.,8.39.214.,8.47.69.,162.159.192.,162.159.193.,162.159.195.,188.114.96.,188.114.97.,188.114.98.,188.114.99."];
:global ports [:toarray "500,854,859,864,878,880,890,891,894,903,908,928,934,939,942,943,945,946,955,968,987,988,1002,1010,1014,1018,1070,1074,1180,1387,1701,1843,2371,2408,2506,3138,3476,3581,3854,4177,4198,4233,4500,5279,5956,7103,7152,7156,7281,7559,8319,8742,8854,8886"];

# Script configuration variables
:local wgInterface "cloudflare-interface";
:local checkAddress "1.1.1.1";
:local maxAttempts 10;
:local pingCount 2;
:local delayTime 2;
:global DEBUG 1;

# Debug output function
:global debugPrint do={
    :if ($DEBUG) do={
        :log warning ($1);
    }
};

# Check if route exists, create if not
:local routeCIDR ($checkAddress . "/32");
:local routeExists [/ip route find dst-address=$routeCIDR];
:if ($routeExists = "") do={
    [$debugPrint] ("DEBUG: Adding route to " . $checkAddress . " via interface " . $wgInterface);
    /ip route add dst-address=$routeCIDR gateway=$wgInterface;
    :local routeAdded true;
} else={
    [$debugPrint] ("DEBUG: Route to " . $checkAddress . " already exists");
    :local routeAdded false;
};

# Debug output to verify arrays
[$debugPrint] ("DEBUG: IP prefixes array length: " . [:len $ipPrefixes]);
[$debugPrint] ("DEBUG: Ports array length: " . [:len $ports]);

# Script for automatic WireGuard endpoint selection
# Generates random IP:port and checks availability

[$debugPrint] ("=== Starting WireGuard endpoint selection script ===");
[$debugPrint] ("Interface name: " . $wgInterface);
[$debugPrint] ("Check address: " . $checkAddress);

# Main endpoint selection loop
[$debugPrint] ("DEBUG: Starting main loop");
:local attempt 0;
:local endpointFound false;

:while (($attempt < $maxAttempts) && (!$endpointFound)) do={
    :set attempt ($attempt + 1);
    [$debugPrint] ("DEBUG: Attempt " . $attempt);
    
    # Initialize variables
    :local endpointAddress "";
    :local endpointPort 0;
    
    # Generate better random seed using system values
    :local timeValue [/system clock get time];
    :local uptimeValue [/system resource get uptime];
    
    # Convert time to string and extract numbers
    :local timeStr [:tostr $timeValue];
    :local uptimeStr [:tostr $uptimeValue];
    
    # Simple hash function
    :local hash 1;
    :local i 0;
    :while ($i < [:len $timeStr]) do={
        :local char [:pick $timeStr $i];
        :set hash ($hash + (:tonum $char 0));
        :set i ($i + 1);
    }
    
    :local i2 0;
    :while ($i2 < [:len $uptimeStr]) do={
        :local char [:pick $uptimeStr $i2];
        :set hash ($hash + (:tonum $char 0));
        :set i2 ($i2 + 1);
    }
    
    :local seed ($hash + $attempt * 1000);
    [$debugPrint] ("DEBUG: Using seed: " . $seed);
    
    # Generate random IP part (1-254)
    [$debugPrint] ("DEBUG: Generating random IP part");
    :local randomIPPart (($seed * 17 + $attempt) % 254);
    :if ($randomIPPart = 0) do={ :set randomIPPart 1; }
    [$debugPrint] ("DEBUG: Generated random IP part: " . $randomIPPart);
    
    # Generate random IP from list
    [$debugPrint] ("DEBUG: Generating random IP from list");
    :local prefixesLen [:len $ipPrefixes];
    [$debugPrint] ("DEBUG: Number of IP prefixes: " . $prefixesLen);
    :if ($prefixesLen > 0) do={
        :local randIndex (($seed * 19 + $attempt * 7) % $prefixesLen);
        [$debugPrint] ("DEBUG: Random index for IP prefix: " . $randIndex);
        :local prefix ($ipPrefixes->($randIndex));
        [$debugPrint] ("DEBUG: Selected IP prefix: " . $prefix);
        :set endpointAddress ($prefix . $randomIPPart);
        [$debugPrint] ("DEBUG: Complete IP: " . $endpointAddress);
    } else={
        [$debugPrint] ("ERROR: IP prefixes array is empty");
        :set endpointAddress "";
    }
    
    # Generate random port
    [$debugPrint] ("DEBUG: Generating random port");
    :local portsLen [:len $ports];
    [$debugPrint] ("DEBUG: Number of ports: " . $portsLen);
    :if ($portsLen > 0) do={
        :local randIndex2 ((($seed * 23 + $attempt * 11) + 1) % $portsLen);
        [$debugPrint] ("DEBUG: Random index for port: " . $randIndex2);
        :local portValue ($ports->($randIndex2));
        :set endpointPort $portValue;
        [$debugPrint] ("DEBUG: Selected port: " . $endpointPort);
    } else={
        [$debugPrint] ("ERROR: Ports array is empty");
        :set endpointPort 0;
    }
    
    [$debugPrint] ("DEBUG: Generated values - IP: " . $endpointAddress . ", Port: " . $endpointPort);
    
    # Validate generated values
    :if (($endpointAddress != "") && ($endpointPort != 0)) do={
        :log warning ("Attempt " . $attempt . ": Testing endpoint " . $endpointAddress . ":" . $endpointPort);
        
        # Set new endpoint for wgcf peer
        [$debugPrint] ("DEBUG: Finding peer for interface " . $wgInterface);
        :local peerId [interface wireguard peers find interface=$wgInterface];
        [$debugPrint] ("DEBUG: Peer ID found: " . $peerId);
        :if ($peerId != "") do={
            # Generate random listen port for interface (500-64500)
            :local randomListenPort (500 + (($seed * 29 + $attempt * 13) % 64001));
            [$debugPrint] ("DEBUG: Generated random listen port: " . $randomListenPort);
            
            # Disable peer first
            [$debugPrint] ("DEBUG: Disabling peer " . $peerId);
            /interface wireguard peers set $peerId disabled=yes;
            
            # Wait a moment
            :delay 1;
            
            # Change interface listen port
            [$debugPrint] ("DEBUG: Setting interface " . $wgInterface . " listen-port to " . $randomListenPort);
            /interface wireguard set $wgInterface listen-port=$randomListenPort;
            
            # Set new endpoint
            [$debugPrint] ("DEBUG: Setting endpoint-address=" . $endpointAddress . " endpoint-port=" . $endpointPort);
            /interface wireguard peers set $peerId endpoint-address=$endpointAddress endpoint-port=$endpointPort;
            
            # Enable peer
            [$debugPrint] ("DEBUG: Enabling peer " . $peerId);
            /interface wireguard peers set $peerId disabled=no;
            
            # Wait for settings to apply
            [$debugPrint] ("DEBUG: Waiting " . $delayTime . " seconds for settings to apply");
            :delay $delayTime;
            
            # Check availability with single ping
            [$debugPrint] ("DEBUG: Testing connectivity to " . $checkAddress);
            :local pingResult [/ping $checkAddress count=$pingCount];
            [$debugPrint] ("DEBUG: Ping result: " . $pingResult . " successful pings");
            
            :if ($pingResult > 0) do={
                :log warning ("Success! Endpoint " . $endpointAddress . ":" . $endpointPort . " is working. " . $pingResult . " of " . $pingCount . " pings successful.");
                :set endpointFound true;
            } else={
                :log warning ("Endpoint " . $endpointAddress . ":" . $endpointPort . " is not working, trying next...");
            }
        } else={
            :log warning ("Error: Peer not found for interface " . $wgInterface);
            :return;
        }
    } else={
        :log warning ("Attempt " . $attempt . ": Invalid endpoint generated, skipping...");
    }
};

# Clean up - remove route if it was added
:if ($routeAdded) do={
    [$debugPrint] ("DEBUG: Removing route to " . $checkAddress);
    /ip route remove [find dst-address=$routeCIDR];
    :log warning ("Route to " . $checkAddress . " removed");
};

:if (!$endpointFound) do={
    :log warning ("Failed to find working endpoint after " . $maxAttempts . " attempts");
} else={
    :log warning ("=== Script completed successfully ===");
};