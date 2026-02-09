#!/bin/bash

ip=$(ip addr show wlp0s20f3 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
echo "$ip"

# Autor: Fravelz
