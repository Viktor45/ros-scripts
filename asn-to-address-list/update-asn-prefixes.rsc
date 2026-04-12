# Script: update-asn-prefixes
# Version: 2.0.1
# Fetches IPv4/IPv6 prefixes from ipverse GitHub repo
# Compatible with RouterOS v7.10+
# Supports multiple ASNs in single run

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

:local listName ""

# --- Validate LIST ---
:if ([:typeof $UAPLIST] != "str") do={
    :log error "update-asn-prefixes: UAPLIST not defined"
    :return
}
:if ([:len $UAPLIST] = 0) do={
    :log error "update-asn-prefixes: UAPLIST is empty"
    :return
}
:set listName $UAPLIST

# --- Validate and parse ASN(s) ---
:if ([:typeof $UAPASN] != "str") do={
    :log error "update-asn-prefixes: UAPASN not defined"
    :return
}
:if ([:len $UAPASN] = 0) do={
    :log error "update-asn-prefixes: UAPASN is empty"
    :return
}

# Parse comma-separated ASNs into array
:local asnList [:toarray ""]
:local currentASN ""
:local asnCount 0
:local inputLen [:len $UAPASN]

:for i from=0 to=($inputLen - 1) do={
    :local char [:pick $UAPASN $i ($i + 1)]

    :if ($char = ",") do={
        :if ([:len $currentASN] > 0) do={
            :set ($asnList->$asnCount) $currentASN
            :set asnCount ($asnCount + 1)
            :set currentASN ""
        }
    } else={
        :if ($char != " ") do={
            :set currentASN ($currentASN . $char)
        }
    }
}

# Add last ASN
:if ([:len $currentASN] > 0) do={
    :set ($asnList->$asnCount) $currentASN
    :set asnCount ($asnCount + 1)
}

:if ($asnCount = 0) do={
    :log error "update-asn-prefixes: No valid ASNs found"
    :return
}

:log info ("update-asn-prefixes: Processing $asnCount ASN(s)")

# --- Process each ASN ---
:local totalAdded 0

:for asnIdx from=0 to=($asnCount - 1) do={
    :local asnRaw ($asnList->$asnIdx)
    :local asn $asnRaw

    # Normalize ASN (remove AS prefix if present)
    :if ([:find $asn "AS"] = 0) do={
        :set asn [:pick $asn 2 [:len $asn]]
    }

    # Validate ASN is numeric
    :if ([:tonum $asn] = "") do={
        :log warning ("update-asn-prefixes: Invalid ASN '$asnRaw' - skipping")
    } else={
        :local targetComment ("ASN AS" . $asn)

        :local url ""
        :if ($ipType = "v6") do={
            :set url ("https://raw.githubusercontent.com/ipverse/as-ip-blocks/master/as/" . $asn . "/ipv6-aggregated.txt")
        } else={
            :set url ("https://raw.githubusercontent.com/ipverse/as-ip-blocks/master/as/" . $asn . "/ipv4-aggregated.txt")
        }

        :local tempFile ($tmpPath . "asn-" . $asn . "-" . $ipType . ".txt")

        # Fetch file
        :do { /file remove $tempFile } on-error={}

        :do {
            /tool fetch url=$url dst-path=$tempFile mode=https
            :delay 2s

            # Read and process
            :local fsize [/file get $tempFile size]
            :local max 32768
            :local chunks (($fsize / $max) - 1)
            :if ($fsize > ($max * $chunks)) do={
                :set $chunks ($chunks + 1)
            }

            :local content
            :for i from=0 to=$chunks do={
            # Start each read from the next chunk
            :local offset ($i * $max)
            :local filechunk [/file/read file=$tempFile offset=$offset chunk-size=$max as-value]
            :set $content ($content . ($filechunk->"data"))
            }

            # Parse lines manually
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

            # Remove old entries for this ASN
            :do {
                /ip firewall address-list remove [/ip firewall address-list find list=$listName comment=$targetComment]
            } on-error={}
            :do {
                /ipv6 firewall address-list remove [/ipv6 firewall address-list find list=$listName comment=$targetComment]
            } on-error={}

            # Process each line
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

            :set totalAdded ($totalAdded + $added)
            :log info ("update-asn-prefixes: AS$asn - Added $added " . $ipType . " prefixes")

            # Cleanup
            /file remove $tempFile

        } on-error={
            :log error ("update-asn-prefixes: Failed to process AS$asn")
            :do { /file remove $tempFile } on-error={}
        }

        # Small delay between ASN processing to avoid rate limiting
        :if ($asnIdx < ($asnCount - 1)) do={
            :delay 1s
        }
    }
}

:log info ("update-asn-prefixes: SUCCESS - Total $totalAdded " . $ipType . " prefixes added for $asnCount ASN(s)")