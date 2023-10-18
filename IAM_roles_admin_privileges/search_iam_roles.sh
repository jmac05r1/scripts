#!/bin/bash

# Prompt for the AWS region
read -p "Enter AWS region (e.g., us-east-1): " aws_region

# Set the AWS region
export AWS_DEFAULT_REGION="$aws_region"

# Output CSV file
output_file="admin_roles.csv"

# Create CSV file with header
echo "RoleName,PolicyName,IsAdminPolicy" > "$output_file"

# List all IAM roles
roles=$(aws iam list-roles --query 'Roles[*].RoleName' --output text)

# Loop through each IAM role
for role in $roles; do
  # List attached policies for the role
  policies=$(aws iam list-attached-role-policies --role-name "$role" --query 'AttachedPolicies[*].PolicyName' --output text)
  
  # Loop through each attached policy
  for policy in $policies; do
    # Check if the policy exists
    policy_exists=$(aws iam get-policy --policy-arn "arn:aws:iam::aws:policy/$policy" 2>&1)
    
    if [[ $policy_exists =~ "NoSuchEntity" ]]; then
      # Policy does not exist or is not accessible
      is_admin_policy="N/A"
    else
      # Get the policy document
      policy_document=$(aws iam get-policy --policy-arn "arn:aws:iam::aws:policy/$policy" --query 'Policy.DefaultVersion.Document' --output json)
      
      # Check if the policy document is not null
      if [ "$policy_document" != "null" ]; then
        # Check if the policy document grants administrative permissions
        if echo "$policy_document" | jq -e 'select(.Statement[].Action | index("iam:*"))' >/dev/null; then
          is_admin_policy="Yes"
        else
          is_admin_policy="No"
        fi
      else
        # Policy document is null or invalid
        is_admin_policy="N/A"
      fi
    fi
    
    # Append the role, policy, and admin status to the CSV file
    echo "$role,$policy,$is_admin_policy" >> "$output_file"
  done
done

echo "CSV file '$output_file' created with results."