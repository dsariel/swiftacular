#!/bin/bash

set -e

# Array of dashboard JSON files and their UIDs
declare -A dashboards
dashboards["swiftdbinfo.jsonnet"]="swiftdbinfo"
dashboards["pcp-redis-host-overview.jsonnet"]="pcp-host"

grafana_ip="192.168.100.150"

# Function to run ansible-playbook and log the time
run_playbook() {
  local playbook=$1
  local description=$2

  echo "Running $description..."
  local start_time=$(date +%s%3N)  # Get start time in epoch milliseconds

  ANSIBLE_CONFIG=ansible.cfg ANSIBLE_LIBRARY=library ansible-playbook -i hosts $playbook

  local end_time=$(date +%s%3N)  # Get end time in epoch milliseconds
  local duration=$((end_time - start_time))  # Duration in milliseconds

  local duration_seconds=$((duration / 1000))
  local minutes=$((duration_seconds / 60))
  local seconds=$((duration_seconds % 60))

  echo "$description completed in $minutes minutes and $seconds seconds."

  # Generate Grafana link with epoch milliseconds
  for dashboard in "${!dashboards[@]}"; do
    uid=${dashboards[$dashboard]}
    local grafana_link="http://${grafana_ip}:3000/d/${uid}/?from=${start_time}&to=${end_time}"
    echo "Grafana Dashboard for $description: $grafana_link"
  done
}

# Check if vagrant-libvirt plugin is installed
if ! vagrant plugin list | grep -q 'vagrant-libvirt'; then
    echo "Installing vagrant-libvirt plugin..."
    vagrant plugin install vagrant-libvirt
else
    echo "vagrant-libvirt plugin is already installed."
fi

# Check if the box 'eurolinux-vagrant/centos-stream-9' is already added
if ! vagrant box list | grep -q 'eurolinux-vagrant/centos-stream-9'; then
    echo "Adding the 'eurolinux-vagrant/centos-stream-9' box..."
    vagrant box add eurolinux-vagrant/centos-stream-9 --provider libvirt
else
    echo "'eurolinux-vagrant/centos-stream-9' box is already added."
fi

# Install community.general module
ansible-galaxy collection install community.general

# Install community.mysql
ansible-galaxy collection install community.mysql

# Run the playbooks with timing and logging
echo start
vagrant up
ANSIBLE_CONFIG=ansible.cfg ANSIBLE_LIBRARY=library ansible-playbook -i hosts monitor_swift_cluster.yml

# Install jsonnet on localhost
ansible-playbook -i 'localhost,' -c local jsonnet_install.yml

# Iterate over dashboard pairs and create each dashboard
for dashboard in "${!dashboards[@]}"; do
  uid=${dashboards[$dashboard]}
  python monitoring/grafana/configure_grafana.py create-dashboard ${grafana_ip}:3000 admin admin "monitoring/grafana/dashboards/${dashboard}" "${uid}"
  echo "Grafana Dashboard for ${dashboard}: http://${grafana_ip}:3000/d/${uid}/"
done

# Deploy Swift Cluster
cp group_vars/all.example group_vars/all
run_playbook "deploy_swift_cluster.yml" "Deploy Swift Cluster"

run_playbook "setup_workload_test.yml" "Setup Workload Test"
