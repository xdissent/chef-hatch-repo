Overview
========

Getting started with Chef can be difficult. Hatch aims to get you up and 
running quickly, either locally using virtual machines or remotely with
EC2 instances.

There also exists the chicken-or-the-egg problem of deploying a live Chef
server without a pre-existing Chef server to manage it. If you're uncomfortable
(or prohibited from) using the Opscode Platform, Hatch can make it trivial
to bootstrap a live, self-managed Chef server using Chef Solo remotely.


How It Works
============

Hatch contains a Knife plugin and Vagrant provisioner that are capable of
bootstrapping a live Chef server. The server is automatically pre-seeded 
with all the cookbooks and roles from your Chef repository and provisioned
to your liking with Chef Solo. After the initial Chef Solo run, management
is handed off to the Chef server running on the host. For remote (EC2) 
hosts, Hatch copies your Chef repository over the wire and bootstraps the
Chef server using Chef Solo.

A local Knife configuration file (`chef-hatch-repo/.chef/knife.rb` by 
default) is generated along with an admin Chef client (`hatch` by default), 
allowing instant control over the hatched Chef server from the command
line.

Hatch uses the `chef-server` and `chef-client` cookbooks from the official
Opscode cookbooks repository.


Requirements
============

* Virtualbox (>= 4.1.0)
* Vagrant (>= 1.0.0)
* Chef (>= 0.10.8)


Suggested
=========

* RVM (project `.rvmrc` included)


Getting Started
===============

The Hatch repository has been forked from the official Opscode chef-repo
repository. That means it's a convenient starting point for your own Chef
repository. To begin, clone the Hatch repository::

    Stewart:Code xdissent$ git clone https://github.com/xdissent/chef-hatch-repo.git
    Cloning into chef-hatch-repo...
    remote: Counting objects: 570, done.
    remote: Compressing objects: 100% (294/294), done.
    remote: Total 570 (delta 208), reused 518 (delta 187)
    Receiving objects: 100% (570/570), 156.65 KiB, done.
    Resolving deltas: 100% (208/208), done.
    Stewart:Code xdissent$ cd chef-hatch-repo/

    
Then hatch a Chef server in a virtual machine::

    Stewart:chef-hatch-repo(master) xdissent$ vagrant up chef
    [chef] Provisioning enabled with HatchProvisioner...
    [chef] Importing base box 'lucid64-chef-0.10.2'...
    [chef] Matching MAC address for NAT networking...
    [chef] Running any VM customizations...
    [chef] Clearing any previously set forwarded ports...
    [chef] Forwarding ports...
    [chef] -- ssh: 22 => 2222 (adapter 1)
    [chef] Creating shared folders metadata...
    [chef] Preparing host only network...
    [chef] Booting VM...
    [chef] Waiting for VM to boot. This can take a few minutes.
    [chef] VM booted and ready for use!
    [chef] Enabling host only network...
    [chef] Setting host name...
    [chef] Mounting shared folders...
    [chef] -- v-csc-0: /tmp/vagrant-chef/cookbooks-0
    [chef] -- v-root: /vagrant
    [chef] -- v-csr-0: /tmp/vagrant-chef/roles-0
    [chef] Running provisioner: HatchProvisioner...
    [chef] Generating chef JSON and uploading...
    [chef] Running chef-solo...
    [chef] [Sat, 04 Jun 2011 13:37:35 -0700] INFO: *** Chef 0.10.2 ***
    : stdout
    [chef] [Sat, 04 Jun 2011 13:37:36 -0700] DEBUG: Building node object for chef.local
    : stdout
    [chef] [Sat, 04 Jun 2011 13:37:36 -0700] DEBUG: Extracting run list from JSON attributes provided on command line
    …
    [chef] [Sat, 04 Jun 2011 13:49:43 -0700] INFO: Running report handlers
    : stdout
    [chef] [Sat, 04 Jun 2011 13:49:43 -0700] INFO: Report handlers complete
    : stdout
    [chef] [Sat, 04 Jun 2011 13:49:43 -0700] DEBUG: Exiting
    : stdout
    [chef] : stdout
    [chef] Creating chef user hatch
    [chef] Grabbing client key
    [chef] Grabbing validation key


The Chef server can be managed using the `knife` command::

    Stewart:chef-hatch-repo(master) xdissent$ knife status
    5 minutes ago, chef.local, chef.local, 10.0.2.15, ubuntu 10.04.
    Stewart:chef-hatch-repo(master) xdissent$ knife cookbook list
    apache2           0.99.3
    apt               1.1.1
    bluepill          0.2.0
    build-essential   1.0.0
    chef-client       0.99.5
    chef-server       0.99.11
    couchdb           0.14.1
    daemontools       0.9.0
    erlang            0.8.2
    gecode            0.99.0
    java              1.1.0
    openssl           0.1.0
    runit             0.14.2
    ucspi-tcp         1.0.0
    xml               0.1.0
    zlib              0.1.0


By default, the Chef WebUI is enabled and running at 
`http://<chef-server-url>:4040` (`http://192.168.10.10:4040` by default for
virtual machines).

A `demo` virtual machine is defined in Hatch's `Vagrantfile` to demonstrate
how to launch a node to be managed by the hatched Chef server:

    Stewart:chef-hatch-repo(master) xdissent$ vagrant up demo
    [demo] Fixed port collision 'ssh'. Now on port 2200.
    [demo] Provisioning enabled with chef_server...
    [demo] Importing base box 'lucid64-chef-0.10.2'...
    [demo] Matching MAC address for NAT networking...
    [demo] Running any VM customizations...
    [demo] Clearing any previously set forwarded ports...
    [demo] Forwarding ports...
    [demo] -- ssh: 22 => 2200 (adapter 1)
    [demo] Creating shared folders metadata...
    [demo] Preparing host only network...
    [demo] Booting VM...
    [demo] Waiting for VM to boot. This can take a few minutes.
    [demo] VM booted and ready for use!
    [demo] Enabling host only network...
    [demo] Setting host name...
    [demo] Mounting shared folders...
    [demo] -- v-root: /vagrant
    [demo] Running provisioner: Vagrant::Provisioners::ChefServer...
    [demo] Creating folder to hold client key...
    [demo] Uploading chef client validation key...
    [demo] Generating chef JSON and uploading...
    [demo] Running chef-client...
    …
    [demo] [Sat, 04 Jun 2011 14:34:26 -0700] INFO: Chef Run complete in 29.351055 seconds
    : stdout
    [demo] [Sat, 04 Jun 2011 14:34:26 -0700] INFO: Running report handlers
    : stdout
    [demo] [Sat, 04 Jun 2011 14:34:26 -0700] INFO: Report handlers complete
    : stdout
    [demo] : stdout
    Stewart:chef-hatch-repo(master) xdissent$ knife status
    7 minutes ago, chef.local, chef.local, 10.0.2.15, ubuntu 10.04.
    2 minutes ago, demo.local, demo.local, 10.0.2.15, ubuntu 10.04.


Working With EC2
================

The Hatch Knife plugin launches and provisions a live chef server as an EC2 
instance. It takes the same options as the `knife-ec2` plugin's 
`knife ec2 server create`:

    Stewart:chef-hatch-repo(master) xdissent$ knife hatch -f m1.small -I ami-e4d42d8d -G chef,ssh,default -Z us-east-1c -N chef.xdissent.com -S xdissent -x ubuntu -i ~/.ssh/aws-xdissent.pem -A <aws-key-id> -K <aws-secret> --region us-east-1
    WARNING: No knife configuration file found
    Instance ID: i-d5d35ebb
    Flavor: m1.small
    Image: ami-e4d42d8d
    Availability Zone: us-east-1c
    Security Groups: chef, ssh, default
    SSH Key: xdissent
    
    Waiting for server...........................
    Public DNS Name: ec2-50-19-143-129.compute-1.amazonaws.com
    Public IP Address: 50.19.143.129
    Private DNS Name: ip-10-91-27-138.ec2.internal
    Private IP Address: 10.91.27.138
    
    Waiting for sshd..done
    Creating temporary directory
    Creating solo config
    Copying files to temporary directory
    Creating chef-hatch tarball
    …
    Copying chef-hatch tarball to host
    Warning: Permanently added '50.19.143.129' (RSA) to the list of known hosts.
    chef-hatch.tgz                                                                                                                                                                                          100%   71KB  70.6KB/s   00:00    
    Bootstrapping Chef on ec2-50-19-143-129.compute-1.amazonaws.com
    0% [Working]3-129.compute-1.amazonaws.com 
    Get:1 http://security.ubuntu.com lucid-security Release.gpg [198B]
    Ign http://security.ubuntu.com/ubuntu/ lucid-security/main Translation-en_US   
    Ign http://security.ubuntu.com/ubuntu/ lucid-security/universe Translation-en_US
    96% [Connecting to us-east-1.ec2.archive.ubuntu.com (10.252.111.96)]           
    Get:2 http://security.ubuntu.com lucid-security Release [44.7kB]    
    0% [Connecting to us-east-1.ec2.archive.ubuntu.com (10.252.111.96)] [2 Release 
    …
    ec2-50-19-143-129.compute-1.amazonaws.com [Sun, 05 Jun 2011 03:06:47 +0000] INFO: Chef Run complete in 440.602521 seconds
    ec2-50-19-143-129.compute-1.amazonaws.com [Sun, 05 Jun 2011 03:06:47 +0000] INFO: Running report handlers
    ec2-50-19-143-129.compute-1.amazonaws.com [Sun, 05 Jun 2011 03:06:47 +0000] INFO: Report handlers complete
    Creating admin user
    Copying keys
    Downloading keys
    validation.pem                                                                                                                                                                                          100% 1675     1.6KB/s   00:00    
    hatch.pem                                                                                                                                                                                               100% 1679     1.6KB/s   00:00    
    Creating knife.rb
    Uploading all cookbooks
    Uploading all roles
    Finishing hatching and restarting chef-client
    Removing temporary directory
    
    Instance ID: i-d5d35ebb
    Flavor: m1.small
    Image: ami-e4d42d8d
    Availability Zone: us-east-1c
    Security Groups: default, ssh, chef
    Public DNS Name: ec2-50-19-143-129.compute-1.amazonaws.com
    Public IP Address: 50.19.143.129
    Private DNS Name: ip-10-91-27-138.ec2.internal
    SSH Key: xdissent
    Private IP Address: 10.91.27.138
    Root Device Type: instance-store
    Environment: _default
    Run List: role[chef_server]
    Stewart:chef-hatch-repo(master) xdissent$ knife status
    2 minutes ago, chef.xdissent.com, ec2-50-19-143-129.compute-1.amazonaws.com, 50.19.143.129, ubuntu 10.04.

Like the `knife ec2 server create` command, `knife hatch` may be configured 
using a `knife.rb` file, but **this file will be overwritten** each time you
hatch a chef server! This will change in the future.
