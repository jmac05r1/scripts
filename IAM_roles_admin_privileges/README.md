Here's a breakdown of what the script does:

It defines the name of the output CSV file.

It lists all IAM roles in your AWS account.

For each IAM role, it lists the attached policies.

For each attached policy, it retrieves the policy document and checks if it grants administrative permissions by looking for administrative actions

It writes the results (RoleName, PolicyName, IsAdminPolicy) to the CSV file.

Finally, it prints a message indicating that the CSV file has been created.

After running the script, you should have a CSV file (admin_roles.csv) that contains the IAM roles and their associated policies with an indication of whether they have administrative privileges or not.
