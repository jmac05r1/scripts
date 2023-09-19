#!/bin/bash

#######################################################################
# PreReq
#######################################################################
# apt install jq  # On Ubuntu/Debian
# brew install jq # Mac (need homebrew installed)
# check jq version "jq --version"

#######################################################################
# Name of the tag. In this case, it's the 'Name' tag which usually holds the hostname
#######################################################################
TAG_NAME="Name"

#######################################################################
# Prompt for the hostname you're looking for
#######################################################################
read -p "Enter the hostname (or part of it) you want to search for: " SEARCH_HOSTNAME

#######################################################################
# Convert the search string to lowercase
#######################################################################
SEARCH_HOSTNAME=$(echo "$SEARCH_HOSTNAME" | tr '[:upper:]' '[:lower:]')

#######################################################################
# Get a list of all AWS regions. We're using us-west-1 just to fetch the list
#######################################################################
REGIONS=$(aws ec2 describe-regions --region us-west-1 --query "Regions[].RegionName" --output text)

#######################################################################
# Loop through each region and search for the instance.
####################################################################### 
for region in $REGIONS; do
    echo "Searching in region $region..."
    
    # Fetch all instances in the region.
    instances=$(aws ec2 describe-instances --region $region --query "Reservations[].Instances[]" --output json)

    # Use jq to filter instances based on the Name tag, case-insensitively.
    matching_ids=$(echo "$instances" | jq -r --arg tag "$TAG_NAME" --arg value "$SEARCH_HOSTNAME" \
        '.[] | select((.Tags[]? | select(.Key == $tag and (.Value | ascii_downcase | contains($value))))? != null) | .InstanceId')

    if [[ ! -z $matching_ids ]]; then
        echo "Found instance(s) in region $region with ID(s): $matching_ids"
    fi
done
