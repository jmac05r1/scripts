#!/bin/bash

# Prompt for the AWS region
read -p "Enter AWS region (e.g., us-east-1): " aws_region

# Set the AWS region
export AWS_DEFAULT_REGION="$aws_region"

# Get a list of all RDS instances in your AWS account
instances=$(aws rds describe-db-instances --query "DBInstances[*].[DBInstanceIdentifier,AutoMinorVersionUpgrade]" --output text)

# Create a CSV file and write header
csv_file="databases.csv"
echo "Database Name,Enable auto minor version upgrade" > "$csv_file"

# Loop through each RDS instance and check if auto minor version upgrade is enabled
while read -r instance auto_minor_upgrade; do
  if [ "$auto_minor_upgrade" == "True" ]; then
    echo "$instance,Yes" >> "$csv_file"
  else
    echo "$instance,No" >> "$csv_file"
  fi
done <<< "$instances"

echo "Results written to $csv_file."