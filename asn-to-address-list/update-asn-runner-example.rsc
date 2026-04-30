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
:local hosterASNs "174,8560,8849,9009,14061,16276,16509,16625,20473,21100,21859,24940,24961,25198,26383,30058,30083,33993,35042,36530,40021,48014,48282,48753,49453,49981,53667,53755,56630,56971,58061,60068,62240,62563,63018,63023,63150,63473,63949,135682,137409,197540,200019,20473,204957,209847,211301,212238,213887,214172,215540,215730,216071,394177,396356,396982"

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