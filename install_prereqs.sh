#!/bin/bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run this script as root or using sudo!"
  exit 1
fi

USERNAME="stack"

check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed."
        exit 1
    fi
}

user_exists() {
    id "$1" &>/dev/null
}

ensure_user_exists() {
    if user_exists "$USERNAME"; then
        echo "User $USERNAME already exists."
    else
        adduser "$USERNAME"
        check_success "adduser $USERNAME"

        echo "swiftaucular" | passwd "$USERNAME" --stdin
        check_success "setting password for user $USERNAME"
    fi
}

post_install_common() {
    # Although the performancecopilot.metrics collection requires no special permissions,
    # Enabling pmcd/pmlogger services does. We could start them manually, but it's better
    # to spare the effort of managing logging, config, and monitoring, and instead rely on systemd.
    systemctl enable pmcd
    check_success "systemctl enable pmcd"
    systemctl enable pmlogger
    check_success "systemctl enable pmlogger"
    systemctl start pmcd
    check_success "systemctl start pmcd"
    systemctl start pmlogger
    check_success "systemctl start pmlogger"


    # Enable and start libvirt
    systemctl enable --now libvirtd
    check_success "enable/start libvirtd"

    # Add user to libvirt group
    usermod -a -G libvirt "$USERNAME"
    check_success "usermod -a -G libvirt $USERNAME"

    # Install grafana-client
    pip3 install grafana-client || pip install grafana-client
    check_success "install grafana-client"

    # Add eurolinux-vagrant/centos-stream-9
    # this operation requires no sudo privilages
    # we need it at preparation stage to prevent
    # 'vagrant up' failure.
    ./eurolinux_vagrant_centos_stream_9.sh
    check_success "run ./eurolinux_vagrant_centos_stream_9.sh"
}

install_for_fedora() {
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

    yum -y groupinstall "Development tools"
    check_success "yum groupinstall Development tools"

    #dnf install -y golang-github-jsonnet-bundler
    #check_success "install jsonnet bundler"

    pip uninstall -y resolvelib
    pip install --user resolvelib==0.5.5
}

install_for_ubuntu() {
    apt-get update
    check_success "apt-get update"
    apt-get install -y \
        qemu-kvm \
        libvirt-dev \
        libvirt-daemon-system \
        libvirt-clients \
        build-essential \
        python3-pip \
        ruby-dev \
        rsync \
        libxml2-dev \
        libxslt1-dev \
        zlib1g-dev \
        software-properties-common \
        pkg-config \
        golang-go \
        pcp

    check_success "apt install packages"

    pip install --user ansible
    check_success "pip install --user ansible"

    grep -qxF 'export PATH=$HOME/.local/bin:$PATH' ~/.bashrc || echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc



    wget https://releases.hashicorp.com/vagrant/2.4.0/vagrant_2.4.0-1_amd64.deb
    sudo apt install ./vagrant_2.4.0-1_amd64.deb
    check_success "apt install vagrant"

    # Avoid Permission denied ~/swiftacular/.vagrant/bundler error
    chown -R "$USER:$USER" .vagrant
    check_success "chown -R ... .vagrant"
}

ensure_user_exists

OS_ID=$(grep -oP '^ID=\K.*' /etc/os-release | tr -d '"')
VERSION_ID=$(grep -oP '^VERSION_ID=\K.*' /etc/os-release | tr -d '"')

case "$OS_ID" in
  fedora)
    if [[ "$VERSION_ID" != "40" ]]; then
      echo "Only Fedora 40 is supported. Detected: Fedora $VERSION_ID"
      exit 1
    fi
    install_for_fedora
    ;;
  ubuntu)
    if [[ "$VERSION_ID" != "24.04" ]]; then
      echo "Only Ubuntu 24.04 is supported. Detected: Ubuntu $VERSION_ID"
      exit 1
    fi
    install_for_ubuntu
    ;;
  *)
    echo "Unsupported OS: $OS_ID $VERSION_ID. Only Fedora 40 and Ubuntu 24.04 are supported."
    exit 1
    ;;
esac

post_install_common

echo "System preparation for $OS_ID $VERSION_ID completed successfully."
