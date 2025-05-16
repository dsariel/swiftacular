#!/bin/bash

GREEN='\033[32m'
NC='\033[0m' # No Color

# Check if the 'eurolinux-vagrant/centos-stream-9' is already added
if ! vagrant box list | grep -q 'eurolinux-vagrant/centos-stream-9'; then
    echo "Adding the 'eurolinux-vagrant/centos-stream-9' box..."
    vagrant box add eurolinux-vagrant/centos-stream-9 --provider libvirt
else
    echo "'eurolinux-vagrant/centos-stream-9' box is already added."
fi


# Check if the Ubuntu box is already added
if ! vagrant box list | grep -q 'generic/ubuntu2204'; then
    echo "Adding the 'generic/ubuntu220' box..."
    vagrant box add  generic/ubuntu2204 --provider libvirt
else
    echo "'generic/ubuntu2204' box is already added."
fi

# `qemu_use_session = false` in Vagrantfile implies system libvirt session is used
# i.e. without sudo the user session's libvirt daemon is connected rather then the system's session
echo -e "${GREEN}List all pools from either system's or user session's${NC}"
virsh pool-list --all
echo -e "${GREEN}List vol details from the default pool${NC}"
virsh vol-list --pool default --details