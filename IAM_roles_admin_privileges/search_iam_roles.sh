#!/bin/bash

# Prompt for the AWS region
read -p "Enter AWS region (e.g., us-east-1): " aws_region

# Set the AWS region
export AWS_DEFAULT_REGION="$aws_region"

# Output CSV file
output_file="admin_roles_with_privileges.csv"

# Create CSV file with header
echo "RoleName,AdministratorAccessPolicyAttached,AdministrativePrivileges" > "$output_file"

# List all IAM roles
roles=$(aws iam list-roles --query 'Roles[].RoleName' --output text)

for role in $roles; do
    role_policies=$(aws iam list-attached-role-policies --role-name "$role" --query 'AttachedPolicies[].PolicyName' --output text)
    has_administrator_access="No"
    has_admin_privileges="No"
    
    # Check if the role has AdministratorAccess policy attached
    if [[ $role_policies == *"AdministratorAccess"* ]]; then
        has_administrator_access="Yes"
    fi

    # Loop through the attached policies for the role
    for policy in $role_policies; do
        # Get the policy document
        policy_document=$(aws iam get-policy --policy-arn "arn:aws:iam::aws:policy/$policy" --query 'Policy.DefaultVersion.Document' --output json 2>/dev/null)
      
        # Check if the policy document is not null and is valid JSON
        if [ -n "$policy_document" ] && jq -e . >/dev/null 2>&1 <<<"$policy_document"; then
            # Check if the policy document contains administrative actions
            if echo "$policy_document" | jq -e 'any(.Statement[] | select(.Effect == "Allow" and (.Action[] | contains("admin") or (.Action[] | contains("iam:*") or (.Action[] | contains("ec2:*") or (.Action[] | contains("rds:*") or (.Action[] | contains("lambda:*") or (.Action[] | contains("s3:*")))))))))' >/dev/null; then
                has_admin_privileges="Yes"
                break
            fi
        fi
    done

    # Check if either AdministratorAccess or AdministrativePrivileges is "Yes"
    if [ "$has_administrator_access" == "Yes" ] || [ "$has_admin_privileges" == "Yes" ]; then
        # Append the role, policy, and admin status to the CSV file
        echo "$role,$has_administrator_access,$has_admin_privileges" >> "$output_file"
    fi
done

echo "CSV file '$output_file' created with results."
