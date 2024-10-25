#!/bin/bash

# Script: audit_system_file_perms.sh
# 6.1.1 Audit system file permissions

# Log file to store the results of the audit
LOG_FILE="/var/log/audit_system_file_permissions.log"

# Function to audit system file permissions using rpm -Va
audit_permissions() {
  # Check for discrepancies in all installed packages
  rpm -Va > "$LOG_FILE"
}

# Function to correct discrepancies
correct_discrepancies() {
  local log_file="$1"

  # Read the log file and process each discrepancy
  while read -r line; do
    if [[ $line =~ ^(.*)[[:space:]](.*)$ ]]; then
      local file="${BASH_REMATCH[2]}"
      local package
      package=$(rpm -qf "$file")

      echo "Correcting permissions for $file (Package: $package)"
      rpm --setperms "$package"
      rpm --setugids "$package"
    fi
  done < "$log_file"
}

# Function to perform the audit and correction
perform_audit() {
  echo "Starting system file permissions audit..."
  audit_permissions

  if [ -s "$LOG_FILE" ]; then
    echo "Discrepancies found. Correcting permissions..."
    correct_discrepancies "$LOG_FILE"
    echo "Permissions corrected. Re-running audit to verify..."
    audit_permissions

    if [ -s "$LOG_FILE" ]; then
      echo "Discrepancies still exist after correction. Please review $LOG_FILE for details."
    else
      echo "No discrepancies found after correction."
    fi
  else
    echo "No discrepancies found."
  fi
}

# Ensure the log file exists
if [ ! -f "$LOG_FILE" ]; then
  touch "$LOG_FILE"
fi

# Perform the audit and correction
perform_audit

echo "System file permissions audit complete. Check $LOG_FILE for details."
