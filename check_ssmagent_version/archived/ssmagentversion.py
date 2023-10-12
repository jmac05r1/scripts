import boto3
import time

# Initialize a session using Amazon S3
session = boto3.session.Session(region_name='us-west-2')  # Change the region accordingly

# Create EC2 and SSM client objects
ec2_client = session.client('ec2')
ssm_client = session.client('ssm')

# Fetch instances with "Patch Group" tag
response = ec2_client.describe_instances(
    Filters=[
        {
            'Name': 'tag:Patch Group',
            'Values': ['*']
        }
    ]
)

instance_ids = []

# Extract the instance IDs and platforms
for reservation in response['Reservations']:
    for instance in reservation['Instances']:
        instance_id = instance['InstanceId']
        platform = instance.get('Platform', 'Linux')
        instance_ids.append((instance_id, platform))

# Commands to check Amazon SSM Agent status and version
linux_commands = ['pgrep amazon-ssm-agent', 'amazon-ssm-agent -version']
windows_commands = ['Get-Process amazon-ssm-agent -ErrorAction SilentlyContinue', '(Get-Command "$env:ProgramFiles\\Amazon\\Amazon SSM Agent\\amazon-ssm-agent.exe").FileVersionInfo.FileVersion']

# Execute commands
for instance_id, platform in instance_ids:
    if platform == 'Windows':
        commands = windows_commands
        document_name = "AWS-RunPowerShellScript"
    else:
        commands = linux_commands
        document_name = "AWS-RunShellScript"

    for command in commands:
        response = ssm_client.send_command(
            InstanceIds=[instance_id],
            DocumentName=document_name,
            Parameters={
                'commands': [command]
            }
        )
        
        command_id = response['Command']['CommandId']
        time.sleep(10)

        # Retrieve the command output with error handling
        output = ssm_client.get_command_invocation(
            CommandId=command_id,
            InstanceId=instance_id,
        )

        if output.get('StatusDetails') == 'Success':
            if command in linux_commands:
                if command == linux_commands[0]:
                    running_status = "Running" if output['StandardOutputContent'].strip() else "Not Running"
                    print(f"Instance ID: {instance_id}, Platform: {platform}, AmazonSSMAgent Status: {running_status}")
                else:
                    print(f"Instance ID: {instance_id}, Platform: {platform}, AmazonSSMAgent Version: {output['StandardOutputContent']}")
            else:
                if command == windows_commands[0]:
                    running_status = "Running" if "amazon-ssm-agent" in output['StandardOutputContent'].strip() else "Not Running"
                    print(f"Instance ID: {instance_id}, Platform: {platform}, AmazonSSMAgent Status: {running_status}")
                else:
                    print(f"Instance ID: {instance_id}, Platform: {platform}, AmazonSSMAgent Version: {output['StandardOutputContent']}")
        else:
            print(f"Instance ID: {instance_id}, Platform: {platform}, Command failed: {output.get('StandardErrorContent', 'Unknown error')}")
            print(f"Instance ID: {instance_id}, Platform: {platform}, AmazonSSMAgent might not be installed.")
