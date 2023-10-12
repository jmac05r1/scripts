#!/bin/bash

# Prompt for AWS region
while [[ -z "$aws_region" ]]; do
    read -p "Please enter the AWS region (e.g. us-west-2): " aws_region
done
export AWS_DEFAULT_REGION=$aws_region

# Create the CSV header
echo "Instance ID,OS,State,SSM Installed,SSM Version" > output.csv

# List instance IDs, platforms, and states
instances=$(aws ec2 describe-instances --region $aws_region --filters "Name=tag:Patch Group,Values=*" --query "Reservations[].Instances[].{ID: InstanceId, Platform: Platform, State: State.Name}" --output json)

# Loop through instances
echo "$instances" | jq -c '.[]' | while read -r instance; do
    instance_id=$(echo "$instance" | jq -r '.ID')
    platform=$(echo "$instance" | jq -r '.Platform')
    state=$(echo "$instance" | jq -r '.State')

    if [ "$state" = "stopped" ]; then
        echo "$instance_id,Not Applicable,stopped,No,Not available" >> output.csv
        continue
    fi

    ssm_installed="No"
    ssm_version="Not available"

    if [ "$platform" = "null" ]; then
        platform="linux"
    fi

    if [ "$platform" = "linux" ]; then
        document_name="AWS-RunShellScript"
        command='ver=$(amazon-ssm-agent -version 2>/dev/null); if [ -z "$ver" ]; then snap services amazon-ssm-agent 2>&1; else echo $ver; fi'
    else
        document_name="AWS-RunPowerShellScript"
        command='$ssmAgentVersion = & "C:\Program Files\Amazon\SSM\amazon-ssm-agent.exe" -version 2>&1; if (-not $ssmAgentVersion -or $ssmAgentVersion -like "*error*") { $ssmService = Get-Service AmazonSSMAgent; if ($ssmService.Status -eq "Running") { $ssmAgent = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq "Amazon SSM Agent" }; if ($ssmAgent) { $ssmAgentVersion = $ssmAgent.Version } else { $ssmAgentVersion = "SSM Agent not found in installed programs list" } } else { $ssmAgentVersion = "SSM Agent service not running" } } $ssmAgentVersion'
    fi

    escaped_command=$(printf '%s' "$command" | jq -R .)

    # Execute command
    command_id=$(aws ssm send-command --instance-ids "$instance_id" --document-name "$document_name" --parameters "{\"commands\":[$escaped_command]}" --query 'Command.CommandId' --output text)

    sleep 10  # Giving time for command to execute

    # Retrieve command output
    output=$(aws ssm get-command-invocation --instance-id "$instance_id" --command-id "$command_id")
    
    status=$(echo "$output" | jq -r '.Status')

    if [ "$status" = "Success" ]; then
        ssm_installed="Yes"
        ssm_version=$(echo "$output" | jq -r '.StandardOutputContent')
    fi

    # Output to CSV
    echo "$instance_id,$platform,$state,$ssm_installed,$ssm_version" >> output.csv
done
