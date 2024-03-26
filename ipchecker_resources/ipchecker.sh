#!/bin/bash

#######################################################################
# Prompt for Region and IP Address
#######################################################################
read -p "Enter the AWS region: " REGION
read -p "Enter the IP address to check: " IP_ADDRESS

#######################################################################
# Variables
#######################################################################
FOUND_IP=false

#######################################################################
# Checks Public IP's 
#######################################################################
echo "checking public IP's"

# Check EC2 instances
EC2_INSTANCE=$(aws ec2 describe-instances --region $REGION --query "Reservations[*].Instances[?PublicIpAddress=='$IP_ADDRESS'].{ID:InstanceId}" --output text)
if [ ! -z "$EC2_INSTANCE" ]; then
  echo "IP $IP_ADDRESS is associated with an EC2 instance, Instance ID: $EC2_INSTANCE"
  FOUND_IP=true
fi

# Check Elastic IPs
ELASTIC_IP=$(aws ec2 describe-addresses --region $REGION --query "Addresses[?PublicIp=='$IP_ADDRESS'].{ID:AllocationId}" --output text)
if [ ! -z "$ELASTIC_IP" ]; then
  echo "IP $IP_ADDRESS is associated with an Elastic IP, Allocation ID: $ELASTIC_IP"
  FOUND_IP=true
fi

# Check NAT Gateways
NAT_GATEWAY=$(aws ec2 describe-nat-gateways --region $REGION --query "NatGateways[?NatGatewayAddresses[?PublicIp=='$IP_ADDRESS']].{ID:NatGatewayId}" --output text)
VPC_ID=$(aws ec2 describe-nat-gateways --region $REGION --query "NatGateways[?NatGatewayAddresses[?PublicIp=='$IP_ADDRESS']].VpcId" --output text)
if [ ! -z "$NAT_GATEWAY" ]; then
  echo "IP $IP_ADDRESS is associated with a NAT Gateway, NAT Gateway ID: $NAT_GATEWAY, VPC ID: $VPC_ID"
  FOUND_IP=true
fi

#######################################################################
# Checks Private IP's
#######################################################################
echo "checking private IP's"

# Searching EC2 instances
EC2_INSTANCE_PRIVATE=$(aws ec2 describe-instances --region $REGION --query "Reservations[*].Instances[?PrivateIpAddress=='$IP_ADDRESS'].{ID:InstanceId}" --output text)
if [ ! -z "$EC2_INSTANCE_PRIVATE" ]; then
  echo "IP $IP_ADDRESS belongs to an EC2 instance, Instance ID: $EC2_INSTANCE_PRIVATE"
  FOUND_IP=true
fi

# Searching NAT Gateways for private IPs
NAT_GATEWAY_PRIVATE=$(aws ec2 describe-nat-gateways --region $REGION --query "NatGateways[*].NatGatewayAddresses[?PrivateIp=='$IP_ADDRESS'].{ID:NatGatewayId}" --output text)
SUBNET_ID=$(aws ec2 describe-nat-gateways --region $REGION --query "NatGateways[?NatGatewayAddresses[?PrivateIp=='$IP_ADDRESS']].SubnetId" --output text)
VPC_ID_PRIVATE=$(aws ec2 describe-subnets --region $REGION --subnet-ids $SUBNET_ID --query "Subnets[0].VpcId" --output text)
if [ ! -z "$NAT_GATEWAY_PRIVATE" ]; then
  echo "Private IP $IP_ADDRESS belongs to a NAT gateway, NAT Gateway ID: $NAT_GATEWAY_PRIVATE, VPC ID: $VPC_ID_PRIVATE"
  FOUND_IP=true
fi

# Searching Network Interfaces
NETWORK_INTERFACE=$(aws ec2 describe-network-interfaces --region $REGION --query "NetworkInterfaces[?PrivateIpAddress=='$IP_ADDRESS'].{ID:NetworkInterfaceId}" --output text)
if [ ! -z "$NETWORK_INTERFACE" ]; then
  echo "IP $IP_ADDRESS belongs to a Network Interface, Network Interface ID: $NETWORK_INTERFACE"
  FOUND_IP=true
fi

if ! $FOUND_IP; then
  echo "IP address not found"
fi