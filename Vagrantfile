# -*- mode: ruby -*-
# vi: set ft=ruby :

nodes = {
    'swift-package-cache' => [1, 20],
    'swift-keystone' => [1, 50],
    # 'swift-lbssl' => [1, 30],
    'swift-proxy'   => [1, 100],
    'swift-storage' => [3, 200],
    'grafana'       => [1, 150],
}

Vagrant.configure("2") do |config|
    config.vm.provider :libvirt do |libvirt|
      libvirt.qemu_use_session = false
      # if the above doesn't work, try uncommenting the following instead
      #libvirt.uri = 'qemu:///system'
    end
end

Vagrant.configure("2") do |config|
    config.vm.box = "eurolinux-vagrant/centos-stream-9"
    config.vm.box_url = "https://app.vagrantup.com/eurolinux-vagrant/boxes/centos-stream-9/versions/9.0.28/providers/libvirt.box"

    nodes.each do |prefix, (count, ip_start)|
        count.times do |i|
            hostname = "%s-%02d" % [prefix, (i+1)]

            config.vm.provider :libvirt do |v|
                v.memory = 3072
            end

            config.vm.define "#{hostname}" do |box|
                puts "working on #{hostname} with ip of 192.168.100.#{ip_start+i}"

                box.vm.hostname = "#{hostname}.example.com"

                #
                # Networks
                #

                # Public
                box.vm.network :private_network, :ip => "192.168.100.#{ip_start+i}", :netmask => "255.255.255.0"

                # SSL and loadbalancing
                box.vm.network :private_network, :ip => "10.0.10.#{ip_start+i}", :netmask => "255.255.255.0"

                # Internal
                box.vm.network :private_network, :ip => "10.0.20.#{ip_start+i}", :netmask => "255.255.255.0"

                # Replication
                box.vm.network :private_network, :ip => "10.0.30.#{ip_start+i}", :netmask => "255.255.255.0"

            end
        end
    end
end
