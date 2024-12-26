#!/bin/bash

# clear the screen
clear

# VARIABLES

# Colors
RED="\e[31m"        # Classic RED
GREEN="\e[32m"      # Classic GREEN
YELLOW="\e[33m"     # Classic YELLOW
BLUE="\e[34m"       # Classic BLUE
PURPLE="\e[35m"     # Classic PURPLE
BG_RED="\e[41m"     # Background RED
BG_GREEN="\e[42m"   # Background GREEN
BG_YELLOW="\e[43m"  # Background YELLOW
BG_BLUE="\e[44m"    # Background BLUE
BG_PURPLE="\e[45m"  # Background PURPLE
NE="\e[0m"          # No color


# Check if a domain or URL is provided as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <domain_or_url>"
    exit 1
fi

# Extract the domain from a URL if needed
input=$1
domain=$(echo $input | sed -E 's|https?://||; s|/.*||')

# Resolve the domain to an IP address
ip_address=$(dig +short "$domain" | grep -Eo '^[0-9\.]+')

if [ -n "$ip_address" ]; then
    echo -e "$ip_address"
else
    echo -e "${RED}Unable to resolve $domain to an IP address.${NE}"
fi
