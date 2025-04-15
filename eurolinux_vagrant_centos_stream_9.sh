#!/bin/bash

# Check if the 'eurolinux-vagrant/centos-stream-9' is already added
if ! vagrant box list | grep -q 'eurolinux-vagrant/centos-stream-9'; then
    echo "Adding the 'eurolinux-vagrant/centos-stream-9' box..."
    vagrant box add eurolinux-vagrant/centos-stream-9 --provider libvirt
else
    echo "'eurolinux-vagrant/centos-stream-9' box is already added."
fi
