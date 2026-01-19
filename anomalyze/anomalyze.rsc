# ====================================================================
# MikroTik Connection Anomaly Detection & Blocking Script
# RouterOS 7.20+
# ====================================================================
# Detects asymmetric connections (potential timeouts/scans) and 
# automatically blocks suspicious IPs
# ====================================================================

# -------------------- CONFIGURATION SECTION --------------------
:global cfgEnabled true
:global cfgMonitoredPorts {443; 80; 8443}
:global cfgProtocols {"tcp"; "udp"}
:global cfgMinOrigPackets 3
:global cfgMaxReplPackets 3
:global cfgBlockTimeout "1d"
:global cfgLoopDelay 2
:global cfgAddressList "tls_block"
:global cfgAllowlistName "allowlist"
:global cfgLogLevel "warning"
:global cfgRemoveTCPConn false
:global cfgCheckLocalAddr true
:global cfgMaxConnPerCycle 50

# -------------------- INITIALIZATION --------------------
:local scriptName "ConnectionMonitor"

# Create address-list if it doesn't exist
:if ([:len [/ip firewall address-list find where list=$cfgAddressList]] = 0) do={
    :log info "[$scriptName] Creating address-list: $cfgAddressList"
}

# -------------------- HELPER FUNCTIONS --------------------

# Check if IP is in allowlist
:local isAllowlisted do={
    :local checkIP $1
    :local alName $2
    :return [:tobool [/ip firewall address-list find where list=$alName and address=$checkIP]]
}

# Check if IP is local/own address
:local isLocalIP do={
    :local checkIP $1
    :return [:tobool [/ip address find where address~"$checkIP"]]
}

# Parse IP and port from address string
:local parseAddress do={
    :local addrString $1
    :local colonPos [:find $addrString ":" -1]
    
    :if ([:typeof $colonPos] = "nil") do={
        :return {ip=""; port=""}
    }
    
    :local ip [:pick $addrString 0 $colonPos]
    :local port [:pick $addrString ($colonPos + 1) [:len $addrString]]
    
    :return {ip=$ip; port=$port}
}

# Log with level control
:local logMsg do={
    :local level $1
    :local msg $2
    :local cfgLevel $3
    
    :local levels {debug=0; info=1; warning=2; error=3}
    :local cfgLevelNum ($levels->$cfgLevel)
    :local msgLevelNum ($levels->$level)
    
    :if ($msgLevelNum >= $cfgLevelNum) do={
        :if ($level = "debug") do={:log debug $msg}
        :if ($level = "info") do={:log info $msg}
        :if ($level = "warning") do={:log warning $msg}
        :if ($level = "error") do={:log error $msg}
    }
}

# -------------------- MAIN DETECTION LOGIC --------------------

:local detectBlock do={
    :local connCount 0
    
    # Build connection filter query
    :local queryFilter "("
    :foreach proto in=$cfgProtocols do={
        :if ([:len $queryFilter] > 1) do={:set queryFilter ($queryFilter . " or ")}
        :set queryFilter ($queryFilter . "protocol=\"$proto\"")
    }
    :set queryFilter ($queryFilter . ") and orig-packets>$cfgMinOrigPackets and repl-packets<$cfgMaxReplPackets")
    
    :set ($logMsg "debug" "[$scriptName] Query: $queryFilter" $cfgLogLevel)
    
    :foreach conn in=[/ip firewall connection find where $queryFilter] do={
        :if ($connCount >= $cfgMaxConnPerCycle) do={
            :set ($logMsg "warning" "[$scriptName] Max connections per cycle reached ($cfgMaxConnPerCycle)" $cfgLogLevel)
            :return false
        }
        :set connCount ($connCount + 1)
        
        :do {
            # Get connection details
            :local connInfo [/ip firewall connection get $conn]
            :local dstAddress ($connInfo->"dst-address")
            :local protocol ($connInfo->"protocol")
            :local srcAddress ($connInfo->"src-address")
            
            # Parse destination address
            :local parsed [$parseAddress $dstAddress]
            :local dstIP ($parsed->"ip")
            :local dstPort ($parsed->"port")
            
            # Validation checks
            :if ([:len $dstIP] = 0) do={
                :set ($logMsg "debug" "[$scriptName] Skipping: empty destination IP" $cfgLogLevel)
                :return false
            }
            
            # Check if port is monitored
            :local portMatch false
            :foreach monPort in=$cfgMonitoredPorts do={
                :if ($dstPort = [:tostr $monPort]) do={
                    :set portMatch true
                }
            }
            
            :if (!$portMatch) do={
                :set ($logMsg "debug" "[$scriptName] Skipping: port $dstPort not monitored" $cfgLogLevel)
                :return false
            }
            
            # Check if destination is local IP (skip blocking own IPs)
            :if ($cfgCheckLocalAddr and [$isLocalIP $dstIP]) do={
                :set ($logMsg "debug" "[$scriptName] Skipping: $dstIP is local address" $cfgLogLevel)
                :return false
            }
            
            # Check allowlist
            :if ([:len [/ip firewall address-list find where list=$cfgAllowlistName]] > 0) do={
                :if ([$isAllowlisted $dstIP $cfgAllowlistName]) do={
                    :set ($logMsg "info" "[$scriptName] Skipping allowlisted IP: $dstIP" $cfgLogLevel)
                    :return false
                }
            }
            
            # Log detected anomaly
            :set ($logMsg "warning" "[$scriptName] Detected asymmetric $protocol connection: $srcAddress -> $dstIP:$dstPort (orig>$cfgMinOrigPackets, repl<=$cfgMaxReplPackets)" $cfgLogLevel)
            
            # Add to block list if not already present
            :if ([:len [/ip firewall address-list find where list=$cfgAddressList and address=$dstIP]] = 0) do={
                /ip firewall address-list add \
                    list=$cfgAddressList \
                    address=$dstIP \
                    timeout=$cfgBlockTimeout \
                    comment="Auto-blocked: $protocol asymmetric conn from $([:pick $srcAddress 0 [:find $srcAddress ":"]])"
                
                :set ($logMsg "info" "[$scriptName] Added $dstIP to $cfgAddressList (timeout: $cfgBlockTimeout)" $cfgLogLevel)
            } else={
                :set ($logMsg "debug" "[$scriptName] $dstIP already in $cfgAddressList" $cfgLogLevel)
            }
            
            # Remove TCP connection if configured
            :if ($cfgRemoveTCPConn and $protocol = "tcp") do={
                /ip firewall connection remove $conn
                :set ($logMsg "debug" "[$scriptName] Removed TCP connection" $cfgLogLevel)
            }
            
        } on-error={
            :set ($logMsg "error" "[$scriptName] Error processing connection $conn" $cfgLogLevel)
        }
    }
    
    :if ($connCount > 0) do={
        :set ($logMsg "info" "[$scriptName] Processed $connCount suspicious connections" $cfgLogLevel)
    }
}

# -------------------- MAIN LOOP --------------------

:log info "[$scriptName] Starting with config: ports={$cfgMonitoredPorts}, protocols={$cfgProtocols}, delay=$cfgLoopDelay s"

:do {
    :if ($cfgEnabled) do={
        $detectBlock
    }
    :delay ($cfgLoopDelay . "s")
} while=(true) on-error={
    :log error "[$scriptName] Critical error in main loop - script stopped"
}