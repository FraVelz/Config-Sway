#!/bin/bash
 
ip_address=$(/bin/cat /home/fravelz/.config/bin/target | awk '{print $1}')
machine_name=$(/bin/cat /home/fravelz/.config/bin/target | awk '{print $2}')
 
if [ -n "$ip_address" ] && [ -n "$machine_name" ]; then
    echo "󰓾 $ip_address - $machine_name"
else
    echo "󰓾 No target"
fi

# Autor: Fravelz
