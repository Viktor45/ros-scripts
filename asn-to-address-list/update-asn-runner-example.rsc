# ###
# This is pure example code, not intended for production use without proper testing and adjustments.
# ###
# DO NOT USE THIS SCRIPT IN PRODUCTION ENVIRONMENT
# ###

# Script: update-asn-runner-example
# Version: 1.0.0
# Updates firewall address list with known hosting provider ASNs
# Compatible with RouterOS v7.10+
# Requires: update-asn-prefixes script

# List of hosting provider ASNs
# Format: ASN numbers only, comma-separated
:local hosterASNs "174,1273,6142,8075,8560,8849,9009,9838,10929,12876,13213,13335,13727,14061,15169,16276,16509,16625,20054,20473,20860,21100,21130,21859,24940,24961,25198,25369,25788,26383,29447,29873,30058,30083,31898,32181,32934,33993,35042,36530,40021,40676,42065,42708,42831,44907,48014,48282,48753,49453,49981,51167,51430,51765,53667,53755,54113,54253,54600,56630,56971,58061,58065,59930,60068,62014,62041,62240,62563,63018,63023,63150,63473,63949,135682,136744,137409,140443,141995,151338,197540,199524,200019,200325,202053,202422,202662,202675,203020,204957,209847,211157,211301,212238,212317,213230,213887,214172,215540,215730,216071,263702,263812,393515,394177,396356,396982,397571,398343,399622"

# Configuration
:global UAPASN $hosterASNs
:global UAPLIST "hosters"
:global UAPTYPE "v4"

# Optional: Set custom temp path (uncomment if needed)
# :global UAPTMPPATH "tmpfs1/"

# Run the main update script
:log info "update-asn-runner-example: Starting update for hosting providers"
/system script run update-asn-prefixes
:log info "update-asn-runner-example: Update completed"