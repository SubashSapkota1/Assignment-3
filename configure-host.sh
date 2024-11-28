#!/bin/bash

# Function to log changes
log_change() {
    logger "$1"
    if [ "$verbose" = true ]; then
        echo "$1"
    fi
}

# Ignore TERM, HUP, and INT signals
trap '' TERM HUP INT

# Default values
verbose=false

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -verbose) verbose=true ;;
        -name) desiredName="$2"; shift ;;
        -ip) desiredIPAddress="$2"; shift ;;
        -hostentry) desiredHostName="$2"; desiredHostIP="$3"; shift 2 ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Function to update hostname
update_hostname() {
    currentName=$(cat /etc/hostname)
    if [ "$currentName" != "$desiredName" ]; then
        echo "$desiredName" > /etc/hostname
        sed -i "s/^$currentName/$desiredName/" /etc/hosts
        log_change "Changed hostname from $currentName to $desiredName"
        hostname "$desiredName"
    elif [ "$verbose" = true ]; then
        echo "Hostname is already set to $desiredName"
    fi
}

# Function to update IP address
update_ip() {
    currentIPAddress=$(grep -w "$(hostname)" /etc/hosts | awk '{print $1}')
    if [ "$currentIPAddress" != "$desiredIPAddress" ]; then
        sed -i "s/$currentIPAddress/$desiredIPAddress/" /etc/hosts
        sed -i "s/address: $currentIPAddress/address: $desiredIPAddress/" /etc/netplan/*.yaml
        log_change "Changed IP address from $currentIPAddress to $desiredIPAddress"
        netplan apply
    elif [ "$verbose" = true ]; then
        echo "IP address is already set to $desiredIPAddress"
    fi
}

# Function to ensure host entry in /etc/hosts
ensure_host_entry() {
    if ! grep -q "$desiredHostName" /etc/hosts; then
        echo "$desiredHostIP $desiredHostName" >> /etc/hosts
        log_change "Added host entry: $desiredHostName with IP $desiredHostIP"
    elif [ "$verbose" = true ]; then
        echo "Host entry for $desiredHostName already exists"
    fi
}

# Execute functions based on provided arguments
if [ ! -z "$desiredName" ]; then
    update_hostname
fi

if [ ! -z "$desiredIPAddress" ]; then
    update_ip
fi

if [ ! -z "$desiredHostName" ] && [ ! -z "$desiredHostIP" ]; then
    ensure_host_entry
fi
