#!/bin/bash

if [ $(id -u) -ne 0 ]
  then echo Please run this script as root or using sudo!
  exit
fi

# Define the username variable
USERNAME="stack"

# Function to check if the last command executed successfully
check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed."
        exit 1
    fi
}

# Function to check if a user exists
user_exists() {
    id "$1" &>/dev/null
}

# Add user if it doesn't exist
if user_exists $USERNAME; then
    echo "User $USERNAME already exists."
else
    adduser $USERNAME
    check_success "adduser $USERNAME"

    # Set password for user
    echo "swiftaucular" | passwd $USERNAME --stdin
    check_success "setting password for user $USERNAME"
fi

# Install necessary packages
yum install -y yum-utils \
               libvirt-devel \
               qemu-kvm \
               pcp-devel \
               pcp-system-tools \
               libxml2-devel \
               libxslt-devel \
               zlib-devel \
               ruby-devel \
               rsync
check_success "yum install packages"

# Add HashiCorp repository and install Vagrant
# https://developer.hashicorp.com/vagrant/downloads
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
check_success "yum-config-manager --add-repo"
yum -y install vagrant
check_success "yum install vagrant"

# Install development tools
yum -y groupinstall "Development tools"
check_success "yum groupinstall Development tools"

# Install performancecopilot.metrics (no need in sudo permissions) 
ansible-galaxy collection install performancecopilot.metrics
check_success "ansible-galaxy collection install performancecopilot.metrics"

# Enable and start PCP services
systemctl enable pmcd
check_success "systemctl enable pmcd"
systemctl enable pmlogger
check_success "systemctl enable pmlogger"
systemctl start pmcd
check_success "systemctl start pmcd"
systemctl start pmlogger
check_success "systemctl start pmlogger"

# Start and enable libvirtd service
systemctl start libvirtd
check_success "systemctl start libvirtd"
systemctl enable libvirtd
check_success "systemctl enable libvirtd"

# Add user to the libvirt group
usermod -a -G libvirt $USERNAME
check_success "usermod -a -G libvirt $USERNAME"

# Install grafana-client
pip install grafana-client

# Install golang-github-jsonnet-bundler
dnf install -y golang-github-jsonnet-bundler

# Add eurolinux-vagrant/centos-stream-9
# this operation requires no sudo privilages
# we need it at preparation stage to prevent
# 'vagrant up' failure.
./eurolinux_vagrant_centos_stream_9.sh

echo "System preparation completed successfully."
