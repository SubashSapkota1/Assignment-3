#!/bin/bash

# Check for verbose mode
verbose=false

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -verbose) verbose=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Function to run commands on the remote server
run_remote() {
    local server=$1
    local name=$2
    local ip=$3
    local hostentry_name=$4
    local hostentry_ip=$5
    ssh remoteadmin@"$server" -- /root/configure-host.sh -name "$name" -ip "$ip" -hostentry "$hostentry_name" "$hostentry_ip"
}

# Copy the configure-host.sh script to each server
scp configure-host.sh remoteadmin@server1-mgmt:/root
run_remote server1-mgmt loghost 192.168.16.3 webhost 192.168.16.4

scp configure-host.sh remoteadmin@server2-mgmt:/root
run_remote server2-mgmt webhost 192.168.16.4 loghost 192.168.16.3

# Update local /etc/hosts
if [ "$verbose" = true ]; then
    ./configure-host.sh -hostentry loghost 192.168.16.3 -verbose
    ./configure-host.sh -hostentry webhost 192.168.16.4 -verbose
else
    ./configure-host.sh -hostentry loghost 192.168.16.3
    ./configure-host.sh -hostentry webhost 192.168.16.4
fi
