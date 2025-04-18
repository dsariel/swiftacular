```
  _________       .__  _____  __                      .__                
 /   _____/_  _  _|__|/ ____\/  |______    ____  __ __|  | _____ _______ 
 \_____  \\ \/ \/ /  \   __\\   __\__  \ _/ ___\|  |  \  | \__  \\_  __ \
 /        \\     /|  ||  |   |  |  / __ \\  \___|  |  /  |__/ __ \|  | \/
/_______  / \/\_/ |__||__|   |__| (____  /\___  >____/|____(____  /__|   
        \/                             \/     \/                \/       
```

# OpenStack Swift and Ansible

This repository will create a virtualized OpenStack Swift cluster using Vagrant, libvirt, Ansible.

#### Table of Contents

- [OpenStack Swift and Ansible](#openstack-swift-and-ansible)
      - [Table of Contents](#table-of-contents)
  - [tl;dr](#tldr)
  - [Supported Operating Systems and OpenStack Releases](#supported-operating-systems-and-openstack-releases)
    - [Fedora 40](#fedora-40)
    - [Ubuntu 24.04](#ubuntu-2404)
  - [Features](#features)
  - [Requirements](#requirements)
  - [Virtual machines created](#virtual-machines-created)
  - [Networking setup](#networking-setup)
  - [Self-signed certificates](#self-signed-certificates)
  - [Using the swift command line client](#using-the-swift-command-line-client)
  - [Starting over](#starting-over)
  - [Development environment](#development-environment)
  - [Modules](#modules)
  - [Future work](#future-work)
  - [Issues](#issues)
  - [Notes](#notes)

## tl;dr

*Note this will start seven virtual machines on your computer.*

```bash
$ git clone https://github.com/dsariel/swiftacular.git
$ cd swiftacular
# Install prerequisites on the host
$ ./install_prereqs.sh
# Deploy Swift and monitoring dashboards
$ ./bootstrap_swift_with_monitoring.sh
```

## Supported Operating Systems and OpenStack Releases

### Fedora 40
| VM              | Swift Version           | Status    |
|-----------------|-------------------------|-----------|
| CentOS Stream 9 | OpenStack stable/2025.1 | Supported |
| Ubuntu 24.04    | OpenStack stable/2025.1 | WIP       |

### Ubuntu 24.04
| VM              | Swift Version           | Status    |
|-----------------|-------------------------|-----------|
| CentOS Stream 9 | OpenStack stable/2025.1 | Supported |
| Ubuntu 24.04    | OpenStack stable/2025.1 | WIP       |


By default, vagrant will use CentOS Stream 9:
```bash
$ vagrant up
```

To use Ubuntu 24.04 instead:

```bash
$ VM_BOX=ubuntu vagrant up
```

## Features

* Run OpenStack Swift in vms on your local computer, but with multiple servers
* Replication network is used, which means this could be a basis for a geo-replication system
* SSL - Keystone is configured to use SSL and the Swift Proxy is proxied by an SSL server
* Sparse files to back Swift disks
* Tests for uploading files into Swift
* Use of [gauntlt](http://gauntlt.org/) attacks to verify installation


## Requirements

* Vagrant and Virtualbox
 * For Ubuntu I am using the official Vagrant Precise64 images
 * For CentOS 6 I am using the [Vagrant box](http://puppet-vagrant-boxes.puppetlabs.com/centos-65-x64-virtualbox-nocm.box) provided by Puppet Labs
* Enough resources on your computer to run seven vms

## Virtual machines created

Seven Vagrant-based virtual machines are used for this playbook:

* __package_cache__ - One apt-cacher-ng server so that you don't have to download packages from the Internet over and over again, only once
* __authentication__ - One Keystone server for authentication
* __lbssl__ - One SSL termination server that will be used to proxy connections to the Swift Proxy server
* __swift-proxy__ - One Swift proxy server
* __swift-storage__ - Three Swift storage nodes

## Networking setup

Each vm will have four networks (technically five including the Vagrant network). In a real production system every server would not need to be attached to every network, and in fact you would want to avoid that. In this case, they are all attached to every network.

* __eth0__ - Used by Vagrant
* __eth1__ - 192.168.100.0/24 - The "public" network that users would connect to
* __eth2__ - 10.0.10.0/24 - This is the network between the SSL terminator and the Swift Proxy
* __eth3__ - 10.0.20.0/24 - The local Swift internal network
* __eth4__ - 10.0.30.0/24 - The replication network which is a feature of OpenStack Swift starting with the Havana release

## Self-signed certificates

Because this playbook configures self-signed SSL certificates and by default the swift client will complain about that fact, either the <code>--insecure</code> option needs to be used or alternatively the <code>SWIFTCLIENT_INSECURE</code> environment variable can be set to true.

## Using the swift command line client

You can install the swift client anywhere that you have access to the SSL termination point and Keystone. So you could put it on your local laptop as well, probably with:

```bash
$ pip install python-swiftclient
```

However, I usually login to the package_cache server and use swift from there.

```bash
$ vagrant ssh swift-package-cache-01
vagrant@swift-package-cache-01:~$ . /vagrant/testrc 
vagrant@swift-package-cache-01:~$ swift list
vagrant@swift-package-cache-01:~$ echo "swift is cool" > swift.txt
vagrant@swift-package-cache-01:~$ swift upload swifty swift.txt 
swift.txt
vagrant@swift-package-cache-01:~$ swift list
swifty
vagrant@swift-package-cache-01:~$ swift list swifty
swift.txt
```

## Starting over

If you want to redo the installation there are a few ways. 

To restart completely:

```bash
$ vagrant destroy -f
$ vagrant up
# wait...
$ ansible-playbook deploy_swift_cluster.yml
```

There is a script to destroy and rebuild everything but the package cache:

```bash
$ ./bin/redo
$ ansible -m ping all # just to check if networking is up
$ ansible-playbook deploy_swift_cluster.yml
```

To remove and redo only the rings and fake/sparse disks without destroying any virtual machines:

```bash
$ ansible-playbook playbooks/remove_rings.yml
$ ansible-playbook deploy_swift_cluster.yml
```

To remove the keystone database and redo the endpoints, users, regions, etc:

```bash
$ ansible-playbook ./playbook/remove_keystone.yml
$ ansible-playbook deploy_swift_cluster.yml
```

## Development environment

This playbook was developed in the following environment:

* OSX 10.8.2
* Ansible 1.4
* Virtualbox 4.2.6
* Vagrant 1.3.5

## Modules

There is an swift-ansible-modules directory in the library directory that contains a couple of modules taken from the official Ansible modules as well as the [openstack-ansible-modules](https://github.com/lorin/openstack-ansible) and for now both have been modified to allow the "insecure" option, which means self-signed certificates. I hope to get those changes into their respective repositories soon.

## Future work

See the [issues](https://github.com/curtisgithub/swiftacular/issues) in the tracking system on Github for Swiftacular with the enhancement label.

## Issues

See the [issues](https://github.com/curtisgithub/swiftacular/issues) in the tracking tracking system on Github for Swiftacular.

## Notes

* I know that Vagrant can automatically start Ansible playbooks on the creation of a vm, but I prefer to run the playbook manually
* LXC is likely a better fit than Virtualbox given all the vms are the same OS and we don't need to boot any vms within vms inception style
* Starting the vms is a bit slow I believe because of the extra networks
