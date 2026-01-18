# ============================================================================
# MikroTik DNS Resolution Script
# Description: Resolves IP addresses for specific firewall address lists
# Version: 3.0 (RouterOS v7.20) - IPv4 & IPv6 Support
# ============================================================================

# ============================================================================
# CONFIGURATION SECTION - Modify these variables as needed
# ============================================================================

# DNS server to use for resolution (e.g., 1.1.1.1, 8.8.8.8, 208.67.222.222)
:local dnsServer "1.1.1.1"

# IP version to process: "ipv4", "ipv6", or "both"
:local ipVersion "both"

# Array of IPv4 address list names to process
# Add or remove list names as needed
:local ipv4ListsToResolve {
    "Trap";
    "MYDNS";
    "MyCustomList";
}

# Array of IPv6 address list names to process
# Add or remove list names as needed
:local ipv6ListsToResolve {
    "Trap-v6";
    "MYDNS-v6";
    "MyCustomList-v6";
}

# ============================================================================
# SCRIPT EXECUTION - Do not modify below unless you know what you're doing
# ============================================================================

# Variable declarations
:local ipres
:local newcmt
:local oldcmt
:local currentList
:local shouldProcess

# Process IPv4 address lists
:if ($ipVersion = "ipv4" or $ipVersion = "both") do={
    # :log info ("*** Processing IPv4 addresses - DNS Server: " . $dnsServer);
    
    # Loop through each entry in the IPv4 firewall address list
    :foreach i in=[/ip firewall address-list find] do={
        
        # Get the full list name
        :set currentList [/ip firewall address-list get $i list]
        # :log info ("Checking list: " . $currentList);
        
        # Check if this list should be processed
        :set shouldProcess false
        :foreach listName in=$ipv4ListsToResolve do={
            :if ($currentList = $listName) do={
                :set shouldProcess true
            };
        };
        
        # Process only lists that match our configuration
        :if ($shouldProcess = true) do={
            # :log info ("Processing entry in list: " . $currentList);
            
            # Get current IP address and comment
            :set ipres [/ip firewall address-list get $i address]
            :set oldcmt [/ip firewall address-list get $i comment]
            # :log info ("IPv4 address: " . $ipres);
            
            # Resolve IP address if comment is empty
            :if ($oldcmt = "") do={
                # :log info ("Resolving " . $ipres . " from list '" . $currentList . "' using DNS " . $dnsServer);
                
                # Attempt DNS resolution using configured DNS server
                :do {
                    :set newcmt [:resolve $ipres server=$dnsServer];
                } on-error={
                    :set newcmt "error"
                };
                
                # :log info ("Resolved: " . $newcmt . " (previous: " . $oldcmt . ")");
                
                # Update comment if resolution was successful and different
                :if ($newcmt != $oldcmt) do={
                    # :log info ("Updating comment to: " . $newcmt);
                    /ip firewall address-list set $i comment=$newcmt;
                };
            };
        };
    };
    
    # :log info ("*** IPv4 resolving done");
}

# Process IPv6 address lists
:if ($ipVersion = "ipv6" or $ipVersion = "both") do={
    # :log info ("*** Processing IPv6 addresses - DNS Server: " . $dnsServer);
    
    # Loop through each entry in the IPv6 firewall address list
    :foreach i in=[/ipv6 firewall address-list find] do={
        
        # Get the full list name
        :set currentList [/ipv6 firewall address-list get $i list]
        # :log info ("Checking list: " . $currentList);
        
        # Check if this list should be processed
        :set shouldProcess false
        :foreach listName in=$ipv6ListsToResolve do={
            :if ($currentList = $listName) do={
                :set shouldProcess true
            };
        };
        
        # Process only lists that match our configuration
        :if ($shouldProcess = true) do={
            # :log info ("Processing entry in list: " . $currentList);
            
            # Get current IP address and comment
            :set ipres [/ipv6 firewall address-list get $i address]
            :set oldcmt [/ipv6 firewall address-list get $i comment]
            # :log info ("IPv6 address: " . $ipres);
            
            # Resolve IP address if comment is empty
            :if ($oldcmt = "") do={
                # :log info ("Resolving " . $ipres . " from list '" . $currentList . "' using DNS " . $dnsServer);
                
                # Attempt DNS resolution using configured DNS server
                :do {
                    :set newcmt [:resolve $ipres server=$dnsServer];
                } on-error={
                    :set newcmt "error"
                };
                
                # :log info ("Resolved: " . $newcmt . " (previous: " . $oldcmt . ")");
                
                # Update comment if resolution was successful and different
                :if ($newcmt != $oldcmt) do={
                    # :log info ("Updating comment to: " . $newcmt);
                    /ipv6 firewall address-list set $i comment=$newcmt;
                };
            };
        };
    };
    
    # :log info ("*** IPv6 resolving done");
}