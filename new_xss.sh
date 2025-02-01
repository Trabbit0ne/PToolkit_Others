#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Check if at least one argument is provided
if [ "$#" -lt 1 ]; then
    echo -e "${RED}Usage: $0 domain/url OR $0 -l list_file${RESET}"
    exit 1
fi

mkdir -p results

# Normalize URL (remove query parameters)
normalize_url() {
    local url="$1"
    # Remove the query parameters for deduplication
    url=$(echo "$url" | sed -E 's/\?.*$//')
    echo "$url"
}

test_domain() {
    local DOMAIN="$1"
    local RESULTS_FILE="results/${DOMAIN}.txt"
    
    echo -e "${BLUE}Gathering URLs with parameters for ${DOMAIN}...${RESET}"
    paramspider -d "$DOMAIN" 2>/dev/null | sort | uniq | grep '?.*=' > "$RESULTS_FILE"
    waybackurls "$DOMAIN" 2>/dev/null | sort | uniq | grep '?.*=' >> "$RESULTS_FILE"
    
    # Add the search.php?s= explicitly
    echo "https://www.kghospital.com/search.php?s=" >> "$RESULTS_FILE"
    
    sort -u "$RESULTS_FILE" -o "$RESULTS_FILE"
    
    if [[ ! -s "$RESULTS_FILE" ]]; then
        echo -e "${RED}No URLs with parameters found for: $DOMAIN${RESET}"
        return
    fi
    
    echo -e "${YELLOW}Testing URLs from ${RESULTS_FILE}...${RESET}"
    declare -A seen_urls
    while IFS= read -r URL; do
        # Normalize URL for deduplication (remove query parameters)
        norm_url=$(normalize_url "$URL")
        
        # Skip duplicate normalized URLs instantly
        if [[ -n "${seen_urls[$norm_url]}" ]]; then
            continue
        fi
        seen_urls[$norm_url]=1

        PARAMS=$(echo "$URL" | grep -oP '[^?&=]+(?==)')
        NEW_URL="$URL"
        for PARAM in $PARAMS; do
            NEW_URL=$(echo "$NEW_URL" | sed "s/${PARAM}=[^&]*/${PARAM}=trabbit/")
        done
        
        echo -e "${BLUE}Testing URL: $NEW_URL${RESET}"
        
        # Set curl max-time to 10 seconds (adjust as needed)
        PAGE_CONTENT=$(curl -s --max-time 10 "$NEW_URL")
        
        if echo "$PAGE_CONTENT" | grep -q "<title>.*trabbit.*</title>"; then
            echo -e "${GREEN}Found 'trabbit' in title for URL: $NEW_URL${RESET}"
            MODIFIED_URL="${NEW_URL}</title><h1>trabbit</h1>"
            MODIFIED_CONTENT=$(curl -s --max-time 10 "$MODIFIED_URL")
            
            if echo "$MODIFIED_CONTENT" | grep -q "<h1>trabbit</h1>"; then
                echo -e "${GREEN}Found H1 tag in page for modified URL: $MODIFIED_URL${RESET}"
            else
                echo -e "${RED}H1 tag not found in page for modified URL: $MODIFIED_URL${RESET}"
            fi
        else
            echo -e "${RED}'trabbit' not found in title for URL: $NEW_URL${RESET}"
        fi
    done < "$RESULTS_FILE"
    
    echo -e "${BLUE}Testing complete for ${DOMAIN}.${RESET}"
}

if [ "$1" == "-l" ] && [ -f "$2" ]; then
    while IFS= read -r DOMAIN; do
        test_domain "$DOMAIN"
    done < "$2"
else
    test_domain "$1"
fi
