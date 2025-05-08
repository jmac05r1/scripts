#!/bin/bash
_file=$1
USER=$2

# Prompt for the password securely
read -s -p "Enter Password: " PASSWORD
echo

for x in $(cat $HOME/notes/scripts/patching_script/$_file)
do
        _os=$(sshpass -p $PASSWORD ssh -tq -o PubkeyAuthentication=no -o StrictHostKeyChecking=accept-new $USER@${x} "sudo grep 'PRETTY_NAME' /etc/os-release | awk -F'\"' '{printf \"%s\", \$2}'")
        _dp=$(sshpass -p $PASSWORD ssh -tq -o PubkeyAuthentication=no -o StrictHostKeyChecking=accept-new $USER@${x} "sudo yum -q history 2>/dev/null| egrep 'U |Up' | head -1 | awk -F'|' '{printf \"%s\", \$3}'")
        _dr=$(sshpass -p $PASSWORD ssh -tq -o PubkeyAuthentication=no -o StrictHostKeyChecking=accept-new $USER@${x} "sudo uptime | awk -F',' '{ printf \"%s\", \$1}'")
        _dt=$(sshpass -p $PASSWORD ssh -tq -o PubkeyAuthentication=no -o StrictHostKeyChecking=accept-new $USER@${x} "sudo date '+%m/%d/%y' | awk '{ printf \"%s\", \$0}'")
        printf "%-30s %-25s %14s %20s %6s %8s\n" "$x" "$_os" "$_dp" "$_dr" "as of:" "$_dt"
