#!/bin/bash

# 4.1.1.3 Ensure audit logs are not automatically deleted

# Function to check and set max_log_file_action to keep_logs
ensure_max_log_file_action() {
    local config_file="/etc/audit/auditd.conf"
    local setting="max_log_file_action"
    local expected_value="keep_logs"    
    
    # Check if the setting is already correct
    if grep -qE "^[\s]*(?i)$setting(?-i)[\s]*=[\s]*(?i)$expected_value(?-i)[\s]*$" "$config_file"; then
        echo "The setting '$setting' is already set to '$expected_value' in $config_file"
    else
        # If the setting exists but is not correct, update it
        if grep -qE "^[\s]*(?i)$setting(?-i)[\s]*=" "$config_file"; then
            sed -i "s/^[\s]*(?i)$setting(?-i)[\s]*=.*/$setting = $expected_value $comment/" "$config_file"
            echo "Updated the setting '$setting' to '$expected_value' in $config_file"
        else
            # If the setting does not exist, add it
            echo -e "\n$setting = $expected_value $comment" >> "$config_file"
            echo "Added the setting '$setting' with value '$expected_value' to $config_file"
        fi
    fi
}

# Ensure the audit logs are not automatically deleted
ensure_max_log_file_action
