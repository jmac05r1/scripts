
list_all_resources.sh provides a list of resources in the region choosen

list_resource_created_by_terraform.sh script provides a list of resources on desired account & region in AWS that have tag "Key Instem:Terraform	 & Value true"

Resources it will look for include:
EC2 instances
DynamoDB tables
S3 buckets
EBS Volumes
Neptune clusters
CloudFormation stacks
RDS instances
Aurora clusters

Change "declare" state to your region on account

#######################################################################
# need to update where you're prompt for region
#######################################################################