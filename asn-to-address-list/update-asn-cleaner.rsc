# Script: update-asn-cleaner
# Version: 1.0.0
# Removes ASN-related entries from firewall address lists
# Compatible with RouterOS v7.10+

:global UAPASN
:global UAPLIST

:local listName ""
:local asnList [:toarray ""]
:local asnCount 0

# Check if UAPLIST is specified
:if ([:typeof $UAPLIST] = "str") do={
    :if ([:len $UAPLIST] > 0) do={
        :set listName $UAPLIST
    }
}

# Check if UAPASN is specified
:if ([:typeof $UAPASN] = "str") do={
    :if ([:len $UAPASN] > 0) do={
        # Parse comma-separated ASNs
        :local currentASN ""
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
    }
}

# Determine cleanup mode
:if ($asnCount > 0) do={
    # Mode 1: Clean specific ASN(s)
    :log info ("update-asn-cleaner: Removing entries for $asnCount ASN(s)")

    :local totalRemoved 0

    :for asnIdx from=0 to=($asnCount - 1) do={
        :local asnRaw ($asnList->$asnIdx)
        :local asn $asnRaw

        # Normalize ASN (remove AS prefix if present)
        :if ([:find $asn "AS"] = 0) do={
            :set asn [:pick $asn 2 [:len $asn]]
        }

        # Validate ASN is numeric
        :if ([:tonum $asn] = "") do={
            :log warning ("update-asn-cleaner: Invalid ASN '$asnRaw' - skipping")
        } else={
            :local targetComment ("ASN AS" . $asn)
            :local removed 0

            # Remove IPv4 entries
            :if ([:len $listName] > 0) do={
                # Remove from specific list
                :do {
                    :local count [:len [/ip firewall address-list find list=$listName comment=$targetComment]]
                    :if ($count > 0) do={
                        /ip firewall address-list remove [find list=$listName comment=$targetComment]
                        :set removed ($removed + $count)
                    }
                } on-error={}
            } else={
                # Remove from all lists
                :do {
                    :local count [:len [/ip firewall address-list find comment=$targetComment]]
                    :if ($count > 0) do={
                        /ip firewall address-list remove [find comment=$targetComment]
                        :set removed ($removed + $count)
                    }
                } on-error={}
            }

            # Remove IPv6 entries
            :if ([:len $listName] > 0) do={
                # Remove from specific list
                :do {
                    :local count [:len [/ipv6 firewall address-list find list=$listName comment=$targetComment]]
                    :if ($count > 0) do={
                        /ipv6 firewall address-list remove [find list=$listName comment=$targetComment]
                        :set removed ($removed + $count)
                    }
                } on-error={}
            } else={
                # Remove from all lists
                :do {
                    :local count [:len [/ipv6 firewall address-list find comment=$targetComment]]
                    :if ($count > 0) do={
                        /ipv6 firewall address-list remove [find comment=$targetComment]
                        :set removed ($removed + $count)
                    }
                } on-error={}
            }

            :set totalRemoved ($totalRemoved + $removed)
            :if ($removed > 0) do={
                :log info ("update-asn-cleaner: AS$asn - Removed $removed entries")
            } else={
                :log info ("update-asn-cleaner: AS$asn - No entries found")
            }
        }
    }

    :log info ("update-asn-cleaner: SUCCESS - Removed $totalRemoved total entries")

} else={
    # Mode 2: Clean ALL ASN entries (no UAPASN specified)
    :log info "update-asn-cleaner: Removing ALL ASN entries (no UAPASN specified)"

    :local totalRemoved 0

    # Remove all IPv4 entries with comment starting with "ASN AS"
    :if ([:len $listName] > 0) do={
        # Remove from specific list
        :do {
            :local count [:len [/ip firewall address-list find list=$listName comment~"^ASN AS"]]
            :if ($count > 0) do={
                /ip firewall address-list remove [find list=$listName comment~"^ASN AS"]
                :set totalRemoved ($totalRemoved + $count)
                :log info ("update-asn-cleaner: Removed $count IPv4 entries from list '$listName'")
            }
        } on-error={}
    } else={
        # Remove from all lists
        :do {
            :local count [:len [/ip firewall address-list find comment~"^ASN AS"]]
            :if ($count > 0) do={
                /ip firewall address-list remove [find comment~"^ASN AS"]
                :set totalRemoved ($totalRemoved + $count)
                :log info ("update-asn-cleaner: Removed $count IPv4 entries from all lists")
            }
        } on-error={}
    }

    # Remove all IPv6 entries with comment starting with "ASN AS"
    :if ([:len $listName] > 0) do={
        # Remove from specific list
        :do {
            :local count [:len [/ipv6 firewall address-list find list=$listName comment~"^ASN AS"]]
            :if ($count > 0) do={
                /ipv6 firewall address-list remove [find list=$listName comment~"^ASN AS"]
                :set totalRemoved ($totalRemoved + $count)
                :log info ("update-asn-cleaner: Removed $count IPv6 entries from list '$listName'")
            }
        } on-error={}
    } else={
        # Remove from all lists
        :do {
            :local count [:len [/ipv6 firewall address-list find comment~"^ASN AS"]]
            :if ($count > 0) do={
                /ipv6 firewall address-list remove [find comment~"^ASN AS"]
                :set totalRemoved ($totalRemoved + $count)
                :log info ("update-asn-cleaner: Removed $count IPv6 entries from all lists")
            }
        } on-error={}
    }

    :log info ("update-asn-cleaner: SUCCESS - Removed $totalRemoved total entries")
}