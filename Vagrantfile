# -*- mode: ruby -*-
# vi: set ft=ruby :

nodes = {
  'swift-package-cache' => [1, 20],
  'swift-keystone'      => [1, 50],
  # 'swift-lbssl'       => [1, 30],
  'swift-proxy'         => [1, 100],
  'swift-storage'       => [3, 200],
  'grafana'             => [1, 150],
}

# Select box based on ENV variable
selected_box = ENV['VM_BOX'] || "centos"

box_config = {
  "centos" => {
    box:     "eurolinux-vagrant/centos-stream-9",
    box_url: "https://app.vagrantup.com/eurolinux-vagrant/boxes/centos-stream-9/versions/9.0.28/providers/libvirt.box"
  },
  "ubuntu" => {
    box:     "ubuntu/ubuntu-24.04",
    box_url: "https://app.vagrantup.com/ubuntu/boxes/ubuntu-24.04"
  }
}

unless box_config[selected_box]
  abort "Unsupported VM_BOX '#{selected_box}'. Supported options: #{box_config.keys.join(', ')}"
end

Vagrant.configure("2") do |config|
  config.vm.box     = box_config[selected_box][:box]
  config.vm.box_url = box_config[selected_box][:box_url]

  config.vm.provider :libvirt do |libvirt|
    libvirt.qemu_use_session = false
    # libvirt.uri = 'qemu:///system' # fallback if the above line doesn't work
  end

  nodes.each do |prefix, (count, ip_start)|
    count.times do |i|
      hostname = "%s-%02d" % [prefix, (i + 1)]


      config.vm.define "#{hostname}" do |box|
        puts "Working on #{hostname} (#{selected_box}) at 192.168.100.#{ip_start + i}"

        box.vm.hostname = "#{hostname}.example.com"

        box.vm.provider :libvirt do |v|
          v.memory = 1024 #3072
        end

        # ------- Networks  
        # Public
        box.vm.network :private_network, ip: "192.168.100.#{ip_start + i}", netmask: "255.255.255.0"
        # SSL and loadbalancing
        box.vm.network :private_network, ip: "10.0.10.#{ip_start + i}",   netmask: "255.255.255.0"
        # Internal
        box.vm.network :private_network, ip: "10.0.20.#{ip_start + i}",   netmask: "255.255.255.0"
        # Replication
        box.vm.network :private_network, ip: "10.0.30.#{ip_start + i}",   netmask: "255.255.255.0"
      end
    end
  end
end
