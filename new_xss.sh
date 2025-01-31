#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Domain to test
DOMAIN="$1"  # Replace with your target URL

# Results file
RESULTS_FILE="results/${DOMAIN}.txt"

# Create results directory if it doesn't exist
mkdir -p results

# Generate parameters using paramspider
echo -e "${BLUE}Generating parameters with paramspider...${RESET}"
paramspider -d "$DOMAIN" > "$RESULTS_FILE"

# Check if results file was created
if [[ ! -f "$RESULTS_FILE" ]]; then
    echo -e "${RED}Failed to create results file: $RESULTS_FILE${RESET}"
    exit 1
fi

# Read URLs from the results file
echo -e "${YELLOW}Testing URLs from ${RESULTS_FILE}...${RESET}"

while IFS= read -r URL; do
    # Extract all parameter names
    PARAMS=$(echo "$URL" | grep -oP '[^?&=]+(?==)')

    # Create a new URL with all parameter values replaced by 'trabbit'
    NEW_URL="$URL"
    for PARAM in $PARAMS; do
        NEW_URL=$(echo "$NEW_URL" | sed "s/${PARAM}=[^&]*/${PARAM}=trabbit/")
    done

    echo -e "${BLUE}Testing URL: $NEW_URL${RESET}"

    # Fetch the page content
    PAGE_CONTENT=$(curl -s "$NEW_URL")

    # Check if 'trabbit' is displayed in the title
    if echo "$PAGE_CONTENT" | grep -q "<title>.*trabbit.*</title>"; then
        echo -e "${GREEN}Found 'trabbit' in title for URL: $NEW_URL${RESET}"

        # Create modified URL with H1 tag
        MODIFIED_URL="$URL"
        for PARAM in $PARAMS; do
            MODIFIED_URL=$(echo "$MODIFIED_URL" | sed "s/${PARAM}=[^&]*/${PARAM}=</title><h1>trabbit</h1>/")
        done
        
        # Fetch the modified page content
        MODIFIED_CONTENT=$(curl -s "$MODIFIED_URL")

        # Check if the H1 tag appears in the page
        if echo "$MODIFIED_CONTENT" | grep -q "<h1>trabbit</h1>"; then
            echo -e "${GREEN}Found H1 tag in page for modified URL: $MODIFIED_URL${RESET}"
        else
            echo -e "${RED}H1 tag not found in page for modified URL: $MODIFIED_URL${RESET}"
        fi
    else
        echo -e "${RED}'trabbit' not found in title for URL: $NEW_URL${RESET}"
    fi
done < "$RESULTS_FILE"

echo -e "${BLUE}Testing complete.${RESET}"
