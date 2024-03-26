#!/bin/bash

# Prompt user to input region
read -p "Enter the AWS region you want to iterate through: " region

# Check if region is empty
if [ -z "$region" ]; then
    echo "Region cannot be empty. Exiting..."
    exit 1
fi

# Check if openpyxl is installed
if ! python3 -c "import openpyxl" &> /dev/null; then
    echo "Error: 'openpyxl' library is not installed. Please install it using 'pip install openpyxl'."
    exit 1
fi

# Create combined Excel file
combined_workbook="combined_info.xlsx"

# Get VPC information
vpcs=$(aws ec2 describe-vpcs --region "$region" --query 'Vpcs[*].[VpcId, Tags[?Key==`Name`].Value | [0]]' --output json)

# Get Security Group information
security_groups=$(aws ec2 describe-security-groups --region "$region" --query 'SecurityGroups[*].[GroupId, GroupName, Description]' --output json)

# Create Excel file
python3 << END
import json
import subprocess
from openpyxl import Workbook

# Create workbook and sheet
wb = Workbook()
aws_info_sheet = wb.active
aws_info_sheet.title = "AWS Info"
aws_info_sheet.append(["Region", "VPC ID", "VPC Name", "CIDR"])

security_groups_sheet = wb.create_sheet(title="Security Groups")
security_groups_sheet.append(["Region", "Security Group ID", "Name", "Description"])

# Write VPC information
vpcs_data = json.loads('''$vpcs''')
for vpc in vpcs_data:
    vpc_id = vpc[0]
    vpc_name = vpc[1] if vpc[1] else ''

    # Get CIDR blocks associated with the VPC
    cidr_blocks = subprocess.check_output(["aws", "ec2", "describe-vpcs", "--region", "$region", "--vpc-ids", vpc_id, "--query", "Vpcs[0].CidrBlockAssociationSet[*].CidrBlock", "--output", "json"]).decode().strip()
    cidrs = ', '.join(json.loads(cidr_blocks))

    aws_info_sheet.append(["$region", vpc_id, vpc_name, cidrs])

# Write Security Group information
security_groups_data = json.loads('''$security_groups''')
for sg in security_groups_data:
    security_groups_sheet.append(["$region"] + sg)

# Auto-size columns for VPC info sheet
for col in aws_info_sheet.columns:
    max_length = 0
    column = col[0].column_letter
    for cell in col:
        try:
            if len(str(cell.value)) > max_length:
                max_length = len(cell.value)
        except:
            pass
    adjusted_width = (max_length + 2)
    aws_info_sheet.column_dimensions[column].width = adjusted_width

# Auto-size columns for Security Groups sheet
for col in security_groups_sheet.columns:
    max_length = 0
    column = col[0].column_letter
    for cell in col:
        try:
            if len(str(cell.value)) > max_length:
                max_length = len(cell.value)
        except:
            pass
    adjusted_width = (max_length + 2)
    security_groups_sheet.column_dimensions[column].width = adjusted_width

# Save workbook
wb.save("$combined_workbook")
END

echo "All region sheets have been combined into $combined_workbook."
