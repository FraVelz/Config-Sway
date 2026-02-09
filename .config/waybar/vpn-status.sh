#!/bin/bash
 
# Detecta si tun0 está activo y muestra la IP

IFACE=$(ip addr show tun0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)

if [ -n "$IFACE" ]; then
    echo "󰆧 $IFACE"
else
    echo "󰆧 Disconnected"
fi

# Autor: Fravelz
