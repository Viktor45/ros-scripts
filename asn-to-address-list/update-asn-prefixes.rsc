# Script: update-asn-prefixes
# Version: 1.4.0
# Fetches IPv4/IPv6 prefixes from ipverse GitHub repo
# Compatible with RouterOS v7.10+

:global UAPASN
:global UAPLIST
:global UAPTMPPATH
:global UAPTYPE

# --- Configuration ---
:local tmpPath "usb1/tmp/"
:if ([:typeof $UAPTMPPATH] = "str") do={
    :if ([:len $UAPTMPPATH] > 0) do={
        :set tmpPath $UAPTMPPATH
    }
}

:local ipType "v4"
:if ([:typeof $UAPTYPE] = "str") do={
    :if ([:len $UAPTYPE] > 0) do={
        :set ipType $UAPTYPE
    }
}

:local asn ""
:local listName ""

# --- Validate and normalize ASN ---
:if ([:typeof $UAPASN] != "str") do={ :return }
:if ([:len $UAPASN] = 0) do={ :return }

:set asn $UAPASN
:if ([:find $asn "AS"] = 0) do={ :set asn [:pick $asn 2 [:len $asn]] }
:if ([:tonum $asn] = "") do={ :return }

# --- Validate LIST ---
:if ([:typeof $UAPLIST] != "str") do={ :return }
:if ([:len $UAPLIST] = 0) do={ :return }
:set listName $UAPLIST

:local targetComment ("ASN AS" . $asn)

:local url ""
:if ($ipType = "v6") do={
    :set url ("https://raw.githubusercontent.com/ipverse/as-ip-blocks/master/as/" . $asn . "/ipv6-aggregated.txt")
} else={
    :set url ("https://raw.githubusercontent.com/ipverse/as-ip-blocks/master/as/" . $asn . "/ipv4-aggregated.txt")
}

:local tempFile ($tmpPath . "asn-" . $asn . "-" . $ipType . ".txt")

# --- Fetch file ---
:do { /file remove $tempFile } on-error={}
/tool fetch url=$url dst-path=$tempFile mode=https

# Wait for download to complete
:delay 2s

# Read and process
:do {
    :local content [/file get $tempFile contents]
#    :log info ("[DEBUG] Content length: " . [:len $content])

    # --- Parse lines manually ---
#    :log info "[DEBUG] Starting manual line parsing"
#    :log info ("[DEBUG] First 100 chars: " . [:pick $content 0 100])
    
    :local lines [:toarray ""]
    :local currentLine ""
    :local lineCount 0
    :local contentLen [:len $content]
    
    :for i from=0 to=($contentLen - 1) do={
        :local char [:pick $content $i ($i + 1)]
        
        :if ($char = "\n") do={
            :if ([:len $currentLine] > 0) do={
                :set ($lines->$lineCount) $currentLine
                :set lineCount ($lineCount + 1)
            }
            :set currentLine ""
        } else={
            :if ($char != "\r") do={
                :set currentLine ($currentLine . $char)
            }
        }
    }
    
    # Add last line if exists
    :if ([:len $currentLine] > 0) do={
        :set ($lines->$lineCount) $currentLine
        :set lineCount ($lineCount + 1)
    }
    
    :local total $lineCount

    # --- Remove old entries ---
    /ip firewall address-list remove [/ip firewall address-list find list=$listName comment=$targetComment]

    # --- Process each line ---
    :local added 0
    :local skipped 0
    
    :for i from=0 to=($total - 1) do={
        :local line ($lines->$i)
        :local lineLen [:len $line]
        
        # Skip empty lines
        :if ($lineLen = 0) do={
            :set skipped ($skipped + 1)
        } else={
            # Skip comment lines
            :local firstChar [:pick $line 0 1]
            :if ($firstChar = "#") do={
                :set skipped ($skipped + 1)
            } else={
                :do {
                    :if ($ipType = "v6") do={
                        /ipv6 firewall address-list add address=$line list=$listName comment=$targetComment
                    } else={
                        /ip firewall address-list add address=$line list=$listName comment=$targetComment
                    }
                    :set added ($added + 1)
                } on-error={}
            }
        }
    }

    :log info ("update-asn-prefixes: SUCCESS - Added $added " . $ipType . " prefixes for ASN AS$asn")
    /file remove $tempFile

} on-error={
    :log error "update-asn-prefixes: Processing failed"
    :do { /file remove $tempFile } on-error={}
}