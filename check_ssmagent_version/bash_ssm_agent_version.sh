#!/bin/bash

# Prompt for AWS region
while [[ -z "$aws_region" ]]; do
    read -p "Please enter the AWS region (e.g. us-west-2): " aws_region
done
export AWS_DEFAULT_REGION=$aws_region

# List instance IDs, platforms, and states
instances=$(aws ec2 describe-instances --region $aws_region --filters "Name=tag:Patch Group,Values=*" --query "Reservations[].Instances[].{ID: InstanceId, Platform: Platform, State: State.Name}" --output json)

# Loop through instances
echo "$instances" | jq -c '.[]' | while read -r instance; do
    instance_id=$(echo "$instance" | jq -r '.ID')
    platform=$(echo "$instance" | jq -r '.Platform')
    state=$(echo "$instance" | jq -r '.State')

    if [ "$state" = "stopped" ]; then
        echo -e "Instance ID: $instance_id, State: stopped\n\n"
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
        command='$ssmService = Get-Service AmazonSSMAgent; if ($ssmService.Status -eq "Running") { $ssmAgent = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq "Amazon SSM Agent" }; if ($ssmAgent) { $ssmAgent.Version } else { & "C:\Program Files\Amazon\SSM\amazon-ssm-agent.exe" -version } } else { "SSM Agent not running" }'
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

    echo -e "Instance ID: $instance_id, OS: $platform, State: $state, SSM Installed: $ssm_installed, SSM Version: $ssm_version\n\n"
done










# #!/bin/bash

# # AWS region
# aws_region="us-west-2"
# export AWS_DEFAULT_REGION=$aws_region

# # List instance IDs, platforms, and states
# instances=$(aws ec2 describe-instances --region $aws_region --filters "Name=tag:Patch Group,Values=*" --query "Reservations[].Instances[].{ID: InstanceId, Platform: Platform, State: State.Name}" --output json)

# # Loop through instances
# echo "$instances" | jq -c '.[]' | while read -r instance; do
#     instance_id=$(echo "$instance" | jq -r '.ID')
#     platform=$(echo "$instance" | jq -r '.Platform')
#     state=$(echo "$instance" | jq -r '.State')

#     if [ "$state" = "stopped" ]; then
#         echo "Instance ID: $instance_id, State: stopped"
#         continue
#     fi

#     ssm_installed="No"
#     ssm_version="Not available"

#     if [ "$platform" = "null" ]; then
#         platform="linux"
#     fi

#     if [ "$platform" = "windows" ]; then
#         document_name="AWS-RunPowerShellScript"
#         command='$ssmAgent = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq "Amazon SSM Agent" }; if ($ssmAgent) { $ssmAgent.Version } else { "SSM Agent not found in the installed programs list." }'
#         escaped_command=$(printf '%s' "$command" | jq -R .)
#     else
#         document_name="AWS-RunShellScript"
#         command='amazon-ssm-agent -version 2>&1 || echo "Not installed"'
#         escaped_command=$(printf '%s' "$command" | jq -R .)
#     fi

#     # Execute command
#     command_id=$(aws ssm send-command --instance-ids "$instance_id" --document-name "$document_name" --parameters "{\"commands\":[$escaped_command]}" --query 'Command.CommandId' --output text)

#     sleep 10  # Giving time for command to execute

#     # Retrieve command output
#     output=$(aws ssm get-command-invocation --instance-id "$instance_id" --command-id "$command_id")
    
#     status=$(echo "$output" | jq -r '.Status')

#     if [ "$status" = "Success" ]; then
#         ssm_installed="Yes"
#         ssm_version=$(echo "$output" | jq -r '.StandardOutputContent')
#     fi

#     echo "Instance ID: $instance_id, OS: $platform, State: $state, SSM Installed: $ssm_installed, SSM Version: $ssm_version"
# done
