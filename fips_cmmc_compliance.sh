#!/usr/bin/env bash

################################################################################
### Validate Required Arguments ################################################
################################################################################
validate_env_set() {
  (
    set +o nounset

    if [ -z "${!1}" ]; then
      echo "Packer variable '$1' was not set. Aborting"
      exit 1
    fi
  )
}

yum update -y

################################################################################
### Enable FIPS ################################################################
################################################################################
echo "Enable FIPS"
sudo yum install -y dracut-fips
sudo dracut -f
sudo /sbin/grubby --update-kernel=ALL --args="fips=1"
openssl version


################################################################################
### Setting up time servers      ###############################################
################################################################################
echo "pool time.nist.gov iburst maxsources 1" > /etc/chrony.d/ntp-pool.sources

################################################################################
### Setting up system banner     ###############################################
################################################################################
echo "You are accessing an managed system. This information system contains information with specific requirements imposed by the U.S. Government. Lifebit reserves the right to monitor, record, and audit information system usage. The information system may be subject to other specified requirement associated with certain types of information. Unauthorized use is prohibited and may result in organizational sanctions and/or criminal and civil penalties." >> /etc/motd
echo "You are accessing an managed system. This information system contains information with specific requirements imposed by the U.S. Government. Lifebit reserves the right to monitor, record, and audit information system usage. The information system may be subject to other specified requirement associated with certain types of information. Unauthorized use is prohibited and may result in organizational sanctions and/or criminal and civil penalties." > /etc/issue
echo "You are accessing an managed system. This information system contains information with specific requirements imposed by the U.S. Government. Lifebit reserves the right to monitor, record, and audit information system usage. The information system may be subject to other specified requirement associated with certain types of information. Unauthorized use is prohibited and may result in organizational sanctions and/or criminal and civil penalties." > /etc/issue.net
sudo chown root:root /etc/motd
sudo chmod 644 /etc/motd
sudo chown root:root /etc/issue
sudo chmod 644 /etc/issue
sudo chown root:root /etc/issue.net
sudo chmod 644 /etc/issue.net

################################################################################
### Remove Overwritten mktemp used during install ##############################
################################################################################

rm -rf /workdir/binaries/mktemp

################################################################################
### Remove Yum Update from cloud-init config ###################################
################################################################################
sudo sed -i \
  's/ - package-update-upgrade-install/# Removed so that nodes do not have version skew based on when the node was started.\n# - package-update-upgrade-install/' \
  /etc/cloud/cloud.cfg

################################################################################
### Begin STIG Harden ###################################
################################################################################

# Set password policies
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   7/' /etc/login.defs
sed -i 's/^PASS_MIN_LEN.*/PASS_MIN_LEN    14/' /etc/login.defs
sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   7/' /etc/login.defs

# Configure PAM to enforce password policies
echo "Configuring PAM to enforce password policies..."
cat <<EOL > /etc/security/pwquality.conf
minlen = 14
dcredit = -1
ucredit = -1
ocredit = -1
lcredit = -1
EOL

# Configure account lockout policy
echo "Configuring account lockout policy..."
echo "auth required pam_tally2.so deny=5 onerr=fail unlock_time=900" >> /etc/pam.d/system-auth

# Configure SSH settings
echo "Configuring SSH settings..."
sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#UseDNS.*/UseDNS no/' /etc/ssh/sshd_config
sed -i 's/^#ClientAliveInterval.*/ClientAliveInterval 300/' /etc/ssh/sshd_config
sed -i 's/^#ClientAliveCountMax.*/ClientAliveCountMax 0/' /etc/ssh/sshd_config
echo "AllowUsers ec2-user" >> /etc/ssh/sshd_config
systemctl restart sshd

# Set file permissions and ownership
chmod 600 /etc/ssh/sshd_config
chown root:root /etc/ssh/sshd_config

# Disable unused filesystems
echo "install cramfs /bin/true" >> /etc/modprobe.d/disable-filesystems.conf
echo "install freevxfs /bin/true" >> /etc/modprobe.d/disable-filesystems.conf
echo "install jffs2 /bin/true" >> /etc/modprobe.d/disable-filesystems.conf
echo "install hfs /bin/true" >> /etc/modprobe.d/disable-filesystems.conf
echo "install hfsplus /bin/true" >> /etc/modprobe.d/disable-filesystems.conf
echo "install squashfs /bin/true" >> /etc/modprobe.d/disable-filesystems.conf
echo "install udf /bin/true" >> /etc/modprobe.d/disable-filesystems.conf

# Enable and configure the firewall
yum install -y firewalld
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --set-default-zone=drop
firewall-cmd --permanent --zone=drop --add-service=ssh
firewall-cmd --reload

# Disable root login
passwd -l root

# Set correct permissions for sensitive files
chmod 600 /etc/passwd-
chmod 600 /etc/shadow
chmod 700 /root

# Enable auditing
if ! rpm -q audit > /dev/null 2>&1; then
  echo "auditd is not installed. Installing..."
  yum install -y audit
else
  echo "auditd is already installed."
fi
systemctl enable auditd
systemctl start auditd



# Ensure system logs are retained
sed -i 's/^#SystemMaxUse=.*/SystemMaxUse=500M/' /etc/systemd/journald.conf
sed -i 's/^#SystemKeepFree=.*/SystemKeepFree=50M/' /etc/systemd/journald.conf
systemctl restart systemd-journald

# Install and configure AIDE
yum install -y aide
aide --init
cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db
(crontab -l 2>/dev/null; echo "0 5 * * * /usr/sbin/aide --check") | crontab -

# Configure time synchronization
echo "Configuring time synchronization..."
yum install -y chrony
systemctl enable chronyd
systemctl start chronyd
sed -i 's/^pool.*/server time.cloudflare.com iburst/' /etc/chrony.conf
echo "server 169.254.169.123 prefer iburst" >> /etc/chrony.conf
systemctl restart chronyd

# Ensure no unneeded services are running
systemctl disable avahi-daemon
systemctl disable cups
systemctl disable isc-dhcp-server
systemctl disable isc-dhcp-server6
systemctl disable slapd
systemctl disable nfs-server
systemctl disable rpcbind
systemctl disable bind
systemctl disable vsftpd
systemctl disable httpd
systemctl disable dovecot
systemctl disable smb
systemctl disable squid
systemctl disable snmpd

# Configure kernel parameters
echo "Configuring kernel parameters..."
cat <<EOL >> /etc/sysctl.conf
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_timestamps = 0
kernel.randomize_va_space = 2
EOL
sysctl -p

# Ensure no duplicate UIDs or GIDs
echo "Checking for duplicate UIDs and GIDs..."
awk -F: '{print $3}' /etc/passwd | sort | uniq -d | while read x; do echo "Duplicate UID: $x"; done
awk -F: '{print $3}' /etc/group | sort | uniq -d | while read x; do echo "Duplicate GID: $x"; done

# Remove unnecessary packages
yum remove -y xinetd ypbind tftp-server telnet-server rsh-server
