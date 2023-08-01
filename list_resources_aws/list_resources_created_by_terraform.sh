#!/bin/bash

#######################################################################
# This protion of script will look for tags of Key Instem:Terraform & Value true
#######################################################################
echo "Creating a CSV file of AWS resources with progress details"

echo "region,service,resource_id,resource_name,hourly,daily,weekly,monthly,none" > aws_resources.csv

# Get the account ID dynamically
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

# Array of AWS regions, you can add or remove as per your needs
declare -a regions=("eu-west-1")

for region in "${regions[@]}"
do
    echo "Processing Region: $region"

    # EC2 instances
    echo "Fetching EC2 instances..."
    aws ec2 describe-instances --region $region | jq -c '.Reservations[].Instances[]' | while read instance
    do
        instanceId=$(echo $instance | jq -r .InstanceId)
        instanceName=$(echo $instance | jq -r '.Tags[] | select(.Key=="Name") | .Value')
        instemTerraformTag=$(echo $instance | jq -r '.Tags[] | select(.Key=="Instem:Terraform" and .Value=="true") | .Value')

        if [ -z "$instanceName" ]; then
            instanceName="N/A"
        fi

        if [ "$instemTerraformTag" = "true" ]; then
            echo "$region,EC2,$instanceId,$instanceName,,,," >> aws_resources.csv
        fi
    done

    # DynamoDB tables
    echo "Fetching DynamoDB tables..."
    aws dynamodb list-tables --region $region | jq -r '.TableNames[]' | while read table
    do
        instemTerraformTag=$(aws dynamodb list-tags-of-resource --region $region --resource-arn arn:aws:dynamodb:$region:$ACCOUNT_ID:table/$table | jq -r '.Tags[] | select(.Key=="Instem:Terraform" and .Value=="true") | .Value')

        if [ "$instemTerraformTag" = "true" ]; then
            echo "$region,DynamoDB,$table,$table,,,," >> aws_resources.csv
        fi
    done

    # S3 buckets
    echo "Fetching S3 buckets..."
    aws s3api list-buckets --region $region | jq -r '.Buckets[].Name' | while read bucket
    do
        instemTerraformTag=$(aws s3api get-bucket-tagging --region $region --bucket $bucket 2> /dev/null | jq -r '.TagSet[] | select(.Key=="Instem:Terraform" and .Value=="true") | .Value')

        if [ "$instemTerraformTag" = "true" ]; then
            echo "$region,S3,$bucket,$bucket,,,," >> aws_resources.csv
        fi
    done

    # EBS Volumes
    echo "Fetching EBS volumes..."
    aws ec2 describe-volumes --region $region | jq -c '.Volumes[]' | while read volume
    do
        volumeId=$(echo $volume | jq -r .VolumeId)
        volumeName=$(echo $volume | jq -r 'if .Tags then (.Tags[] | select(.Key=="Name") | .Value) else "N/A" end')
        instemTerraformTag=$(echo $volume | jq -r 'if .Tags then (.Tags[] | select(.Key=="Instem:Terraform" and .Value=="true") | .Value) else "N/A" end')

        if [ -z "$volumeName" ] || [ "$volumeName" = "null" ]; then
            volumeName="N/A"
        fi

        if [ "$instemTerraformTag" = "true" ]; then
            echo "$region,EBS,$volumeId,$volumeName,,,," >> aws_resources.csv
        fi
    done    

    # Neptune clusters
    echo "Fetching Neptune clusters..."
    aws neptune describe-db-clusters --region $region | jq -r '.DBClusters[].DBClusterIdentifier' | while read cluster
    do
        instemTerraformTag=$(aws neptune list-tags-for-resource --region $region --resource-name arn:aws:rds:$region:$ACCOUNT_ID:cluster:$cluster | jq -r '.TagList[] | select(.Key=="Instem:Terraform" and .Value=="true") | .Value')

        if [ "$instemTerraformTag" = "true" ]; then
            echo "$region,Neptune,$cluster,$cluster,,,," >> aws_resources.csv
        fi
    done

    # CloudFormation stacks
    echo "Fetching CloudFormation stacks..."
    aws cloudformation list-stacks --region $region | jq -r '.StackSummaries[].StackId' | while read stack
    do
        instemTerraformTag=$(aws cloudformation describe-stacks --region $region --stack-name $stack | jq -r '.Stacks[].Tags[] | select(.Key=="Instem:Terraform" and .Value=="true") | .Value')

        if [ "$instemTerraformTag" = "true" ]; then
            stackName=$(aws cloudformation describe-stacks --region $region --stack-name $stack | jq -r '.Stacks[].StackName')
            if [ -z "$stackName" ]; then
                stackName="N/A"
            fi
            echo "$region,CloudFormation,$stack,$stackName,,,," >> aws_resources.csv
        fi
    done

    # RDS instances
    echo "Fetching RDS instances..."
    aws rds describe-db-instances --region $region | jq -c '.DBInstances[]' | while read instance
    do
        instanceId=$(echo $instance | jq -r .DBInstanceIdentifier)
        instemTerraformTag=$(aws rds list-tags-for-resource --region $region --resource-name arn:aws:rds:$region:$ACCOUNT_ID:db:$instanceId | jq -r '.TagList[] | select(.Key=="Instem:Terraform" and .Value=="true") | .Value')

        if [ "$instemTerraformTag" = "true" ]; then
            echo "$region,RDS,$instanceId,$instanceId,,,," >> aws_resources.csv
        fi
    done

    # Aurora clusters
    echo "Fetching Aurora clusters..."
    aws rds describe-db-clusters --region $region | jq -c '.DBClusters[]' | while read cluster
    do
        clusterId=$(echo $cluster | jq -r .DBClusterIdentifier)
        instemTerraformTag=$(aws rds list-tags-for-resource --region $region --resource-name arn:aws:rds:$region:$ACCOUNT_ID:cluster:$clusterId | jq -r '.TagList[] | select(.Key=="Instem:Terraform" and .Value=="true") | .Value')

        if [ "$instemTerraformTag" = "true" ]; then
            echo "$region,Aurora,$clusterId,$clusterId,,,," >> aws_resources.csv
        fi
    done

    echo "Finished processing region: $region"
done

echo "CSV file creation completed successfully!"