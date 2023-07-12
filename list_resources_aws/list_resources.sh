#!/bin/bash

echo "Creating a CSV file of AWS resources with progress details"

echo "region,service,resource_id,resource_name,hourly,daily,weekly,monthly,none" > aws_resources.csv

# Array of AWS regions, you can add or remove as per your needs
# declare -a regions=("us-east-1" "us-west-1")
declare -a regions=("us-east-1")

for region in "${regions[@]}"
do
    echo "Processing Region: $region"

    # EC2 instances
    echo "Fetching EC2 instances..."
    aws ec2 describe-instances --region $region | jq -c '.Reservations[].Instances[]' | while read instance
    do
        instanceId=$(echo $instance | jq -r .InstanceId)
        instanceName=$(echo $instance | jq -r '.Tags[] | select(.Key=="Name") | .Value')
        if [ -z "$instanceName" ]; then
            instanceName="N/A"
        fi
        echo "$region,EC2,$instanceId,$instanceName,,,," >> aws_resources.csv
    done

    # DynamoDB tables - DynamoDB tables don't have names separate from their IDs
    echo "Fetching DynamoDB tables..."
    aws dynamodb list-tables --region $region | jq -r '.TableNames[]' | while read table
    do
        echo "$region,DynamoDB,$table,$table,,,," >> aws_resources.csv
    done

    # S3 buckets - S3 buckets don't have names separate from their IDs
    echo "Fetching S3 buckets..."
    aws s3api list-buckets | jq -r '.Buckets[].Name' | while read bucket
    do
        echo "$region,S3,$bucket,$bucket,,,," >> aws_resources.csv
    done

    # EBS Volumes
    echo "Fetching EBS volumes..."
    aws ec2 describe-volumes --region $region | jq -c '.Volumes[]' | while read volume
    do
        volumeId=$(echo $volume | jq -r .VolumeId)
        volumeName=$(echo $volume | jq -r '.Tags[] | select(.Key=="Name") | .Value')
        if [ -z "$volumeName" ]; then
            volumeName="N/A"
        fi
        echo "$region,EBS,$volumeId,$volumeName,,,," >> aws_resources.csv
    done

    # EFS File Systems - EFS File systems don't have names separate from their IDs
    echo "Fetching EFS file systems..."
    aws efs describe-file-systems --region $region | jq -r '.FileSystems[].FileSystemId' | while read filesystem
    do
        echo "$region,EFS,$filesystem,$filesystem,,,," >> aws_resources.csv
    done

    # FSx File Systems - FSx File systems don't have names separate from their IDs
    echo "Fetching FSx file systems..."
    aws fsx describe-file-systems --region $region | jq -r '.FileSystems[].FileSystemId' | while read filesystem
    do
        echo "$region,FSx,$filesystem,$filesystem,,,," >> aws_resources.csv
    done

    # DocumentDB clusters - DocumentDB clusters don't have names separate from their IDs
    echo "Fetching DocumentDB clusters..."
    aws docdb describe-db-clusters --region $region | jq -r '.DBClusters[].DBClusterIdentifier' | while read dbCluster
    do
        echo "$region,DocumentDB,$dbCluster,$dbCluster,,,," >> aws_resources.csv
    done

    # Neptune clusters - Neptune clusters don't have names separate from their IDs
    echo "Fetching Neptune clusters..."
    aws neptune describe-db-clusters --region $region | jq -r '.DBClusters[].DBClusterIdentifier' | while read neptuneCluster
    do
        echo "$region,Neptune,$neptuneCluster,$neptuneCluster,,,," >> aws_resources.csv
    done

    # RDS instances
    echo "Fetching RDS instances..."
    aws rds describe-db-instances --region $region | jq -c '.DBInstances[]' | while read instance
    do
        instanceId=$(echo $instance | jq -r .DBInstanceIdentifier)
        instanceName=$(echo $instance | jq -r '.DBInstanceIdentifier')
        echo "$region,RDS,$instanceId,$instanceName,,,," >> aws_resources.csv
    done

    # Aurora clusters
    echo "Fetching Aurora clusters..."
    aws rds describe-db-clusters --region $region | jq -c '.DBClusters[]' | while read cluster
    do
        clusterId=$(echo $cluster | jq -r .DBClusterIdentifier)
        clusterName=$(echo $cluster | jq -r .DBClusterIdentifier)
        echo "$region,Aurora,$clusterId,$clusterName,,,," >> aws_resources.csv
    done

    # Backup plans
    echo "Fetching Backup plans..."
    aws backup list-backup-plans --region $region | jq -c '.BackupPlansList[]' | while read plan
    do
        planId=$(echo $plan | jq -r .BackupPlanId)
        planName=$(echo $plan | jq -r .BackupPlanName)
        if [ -z "$planName" ]; then
            planName="N/A"
        fi
        echo "$region,Backup,$planId,$planName,,,," >> aws_resources.csv
    done

    # Storage Gateway - Storage Gateway doesn't have names separate from their IDs
    echo "Fetching Storage Gateways..."
    aws storagegateway list-gateways --region $region | jq -r '.Gateways[].GatewayARN' | while read gateway
    do
        echo "$region,StorageGateway,$gateway,$gateway,,,," >> aws_resources.csv
    done

    # CloudFormation stacks
    echo "Fetching CloudFormation stacks..."
    aws cloudformation list-stacks --region $region | jq -c '.StackSummaries[]' | while read stack
    do
        stackId=$(echo $stack | jq -r .StackId)
        stackName=$(echo $stack | jq -r .StackName)
        if [ -z "$stackName" ]; then
            stackName="N/A"
        fi
        echo "$region,CloudFormation,$stackId,$stackName,,,," >> aws_resources.csv
    done

    echo "Finished processing region: $region"
done

echo "CSV file creation completed successfully!"