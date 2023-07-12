#!/bin/bash

#######################################################################
# Checks Public IP's 
#######################################################################

#IP_ADDRESS=x.x.x.x
#REGION=us-east-1
#
## Check EC2 instances
#echo "Checking EC2 instances in region $REGION..."
#aws ec2 describe-instances --region $REGION --query 'Reservations[*].Instances[*].PublicIpAddress' --output text | grep -q $IP_ADDRESS && echo "IP $IP_ADDRESS is associated with an EC2 instance in $REGION"
#
## Check Elastic IPs
#echo "Checking Elastic IPs in region $REGION..."
#aws ec2 describe-addresses --region $REGION --query 'Addresses[*].PublicIp' --output text | grep -q $IP_ADDRESS && echo "IP $IP_ADDRESS is associated with an Elastic IP in $REGION"
#
## Check NAT Gateways
#echo "Checking NAT Gateways in region $REGION..."
#aws ec2 describe-nat-gateways --region $REGION --query 'NatGateways[*].NatGatewayAddresses[*].PublicIp' --output text | grep -q $IP_ADDRESS && echo "IP $IP_ADDRESS is associated with a NAT Gateway in $REGION"


#######################################################################
# Checks Private IP's
#######################################################################

ip="x.x.x.x"
REGION=us-east-1
echo "Searching EC2 instances in $REGION region"
aws ec2 describe-instances --region $REGION --query "Reservations[*].Instances[*].{ID:InstanceId,IP:PrivateIpAddress}" --output text | grep $ip
if [ $? -eq 0 ]; then
  echo "IP belongs to an EC2 instance"
  exit
fi

echo "Searching NAT Gateways in $REGION region"
aws ec2 describe-nat-gateways --region $REGION --query "NatGateways[*].{ID:NatGatewayId,IP:PrivateIp}" --output text | grep $ip
if [ $? -eq 0 ]; then
  echo "IP belongs to a NAT gateway"
  exit
fi

echo "Searching Network Interfaces in $REGION region"
aws ec2 describe-network-interfaces --region $REGION --query "NetworkInterfaces[*].{ID:NetworkInterfaceId,IP:PrivateIpAddress}" --output text | grep $ip
if [ $? -eq 0 ]; then
  echo "IP belongs to a Network Interface"
  exit
fi

echo "IP address not found"

