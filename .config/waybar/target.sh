#!/bin/bash

TARGET_FILE="${HOME}/.config/bin/target"

if [ ! -f "$TARGET_FILE" ]; then
    echo "󰓾 No target"
    exit 0
fi

ip_address=$(awk '{print $1}' "$TARGET_FILE")
machine_name=$(awk '{print $2}' "$TARGET_FILE")

if [ -n "$ip_address" ] && [ -n "$machine_name" ]; then
    echo "󰓾 $ip_address - $machine_name"
else
    echo "󰓾 No target"
fi

# Autor: Fravelz
