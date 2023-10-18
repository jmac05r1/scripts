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

# Define a list of administrative actions to search for
admin_actions=("iam:*" "ec2:*" "s3:*" "lambda:*" "cloudformation:*" "organizations:*" "sts:*")

# Loop through each IAM role
for role in $roles; do
  # List attached policies for the role
  policies=$(aws iam list-attached-role-policies --role-name "$role" --query 'AttachedPolicies[*].PolicyName' --output text)
  
  # Loop through each attached policy
  for policy in $policies; do
    # Get the policy document
    policy_document=$(aws iam get-policy --policy-arn "arn:aws:iam::aws:policy/$policy" --query 'Policy.DefaultVersion.Document' --output json 2>/dev/null)
    
    # Check if the policy document is not null and is valid JSON
    if [ -n "$policy_document" ] && jq -e . >/dev/null 2>&1 <<<"$policy_document"; then
      # Check if the policy document contains administrative actions
      if echo "$policy_document" | jq -e --argjson admin_actions "${admin_actions[*]}" \
        'select(.Statement[].Action[] as $a | any($admin_actions[]; $a == "*") or any($admin_actions[]; $a == $a))' >/dev/null; then
        is_admin_policy="Yes"
      else
        is_admin_policy="No"
      fi
    else
      # Policy document is null, invalid, or inaccessible
      is_admin_policy="N/A"
    fi
    
    # Append the role, policy, and admin status to the CSV file
    echo "$role,$policy,$is_admin_policy" >> "$output_file"
  done
done

echo "CSV file '$output_file' created with results."
