#!/bin/bash

# Script Name: ensure_audit_privileged_functions.sh
# Compliance Check: 4.1.21 Ensure auditing of all privileged functions - setuid 32 bit and setgid 64 bit

# Ensure the script runs with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Define the audit rules
audit_rule_setuid_32="-a always,exit -F arch=b32 -S execve -C uid!=euid -F euid=0 -k setuid"
audit_rule_setuid_64="-a always,exit -F arch=b64 -S execve -C uid!=euid -F euid=0 -k setuid"
audit_rule_setgid_32="-a always,exit -F arch=b32 -S execve -C gid!=egid -F egid=0 -k setgid"
audit_rule_setgid_64="-a always,exit -F arch=b64 -S execve -C gid!=egid -F egid=0 -k setgid"

# Function to add the audit rule if it doesn't exist
add_audit_rule() {
  rule=$1
  file=$2
  if ! grep -F -- "$rule" "$file" &> /dev/null; then
    echo "Adding rule: $rule"
    echo "$rule" | sudo tee -a "$file"
  else
    echo "Rule already exists: $rule"
  fi
}

# Check and add rules to /etc/audit/rules.d/50-privileged.rules
add_audit_rule "$audit_rule_setuid_32" "/etc/audit/rules.d/50-privileged.rules"
add_audit_rule "$audit_rule_setuid_64" "/etc/audit/rules.d/50-privileged.rules"
add_audit_rule "$audit_rule_setgid_32" "/etc/audit/rules.d/50-privileged.rules"
add_audit_rule "$audit_rule_setgid_64" "/etc/audit/rules.d/50-privileged.rules"

# Check and add rules to /etc/audit/audit.rules
add_audit_rule "$audit_rule_setuid_32" "/etc/audit/audit.rules"
add_audit_rule "$audit_rule_setuid_64" "/etc/audit/audit.rules"
add_audit_rule "$audit_rule_setgid_32" "/etc/audit/audit.rules"
add_audit_rule "$audit_rule_setgid_64" "/etc/audit/audit.rules"

# Load the audit rules
sudo augenrules --load

# Verify the auditd service status
if sudo systemctl status auditd | grep -q "active (running)"; then
  echo "Audit rules for privileged functions have been configured and applied successfully."
else
  echo "Failed to apply audit rules for privileged functions. Please check the auditd service status."
fi

# Check if reboot is required
if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
    printf "Reboot required to load rules\n"
fi

echo "Script execution completed."
