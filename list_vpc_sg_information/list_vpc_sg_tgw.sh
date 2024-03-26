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
vpcs=$(aws ec2 describe-vpcs --region "$region" --query 'Vpcs[*].[VpcId, Tags[?Key==`Name`].Value | [0], CidrBlockAssociationSet[*].CidrBlock]' --output json)

# Get Security Group information
security_groups=$(aws ec2 describe-security-groups --region "$region" --query 'SecurityGroups[*].[GroupId, GroupName, Description]' --output json)

# Get Transit Gateway information
transit_gateways=$(aws ec2 describe-transit-gateways --region "$region" --query 'TransitGateways[*].[TransitGatewayId, TransitGatewayArn, Description]' --output json)

# Create Excel file
python3 << END
import json
from openpyxl import Workbook

# Create workbook and sheets
wb = Workbook()
aws_info_sheet = wb.active
aws_info_sheet.title = "AWS Info"
aws_info_sheet.append(["Region", "VPC ID", "VPC Name", "CIDR"])

security_groups_sheet = wb.create_sheet(title="Security Groups")
security_groups_sheet.append(["Region", "Security Group ID", "Name", "Description"])

transit_gateway_sheet = wb.create_sheet(title="Transit Gateways")
transit_gateway_sheet.append(["Region", "Transit Gateway ID", "Transit Gateway ARN", "Description"])

# Write VPC information
vpcs_data = json.loads('''$vpcs''')
for vpc in vpcs_data:
    vpc_id = vpc[0]
    vpc_name = vpc[1] if vpc[1] else ''
    cidrs = ', '.join(vpc[2])
    aws_info_sheet.append(["$region", vpc_id, vpc_name, cidrs])

# Write Security Group information
security_groups_data = json.loads('''$security_groups''')
for sg in security_groups_data:
    security_groups_sheet.append(["$region"] + sg)

# Write Transit Gateway information
transit_gateway_data = json.loads('''$transit_gateways''')
for tg in transit_gateway_data:
    transit_gateway_sheet.append(["$region"] + tg)

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

# Auto-size columns for Transit Gateways sheet
for col in transit_gateway_sheet.columns:
    max_length = 0
    column = col[0].column_letter
    for cell in col:
        try:
            if len(str(cell.value)) > max_length:
                max_length = len(cell.value)
        except:
            pass
    adjusted_width = (max_length + 2)
    transit_gateway_sheet.column_dimensions[column].width = adjusted_width

# Save workbook
wb.save("$combined_workbook")
END

echo "All region sheets have been combined into $combined_workbook."
