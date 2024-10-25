#!/bin/bash

# 4.1.1.1 Ensure audit log storage size is configured

CONFIG_FILE="/etc/audit/auditd.conf"
PARAMETER="max_log_file"
VALUE="32"

# Function to add or update the parameter in the configuration file
set_parameter() {
  local file="$1"
  local parameter="$2"
  local value="$3"
  if grep -q "^\\s*${parameter}\\s*=" "$file"; then
    sed -i "s/^\\s*${parameter}\\s*=.*/${parameter} = ${value}/" "$file"
    echo "Updated ${parameter} in ${file}"
  else
    echo "${parameter} = ${value}" >> "$file"
    echo "Added ${parameter} to ${file}"
  fi
}

# Ensure the configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
  touch "$CONFIG_FILE"
fi

# Set the parameter
set_parameter "$CONFIG_FILE" "$PARAMETER" "$VALUE"

echo "The required parameter has been ensured in $CONFIG_FILE."
