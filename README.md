Overview
========

Getting started with Chef can be difficult. Hatch aims to get you up and 
running quickly, either locally using virtual machines or EC2 instances.

There also exists the chicken-or-the-egg problem of deploying a live Chef
server without a pre-existing Chef server to manage it. If you're uncomfortable
(or prohibited from) using the Opscode Platform, Hatch can make it trivial
to bootstrap a live, self-managed Chef server using Chef Solo remotely.


How it works
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

* Virtualbox
* Vagrant
* Chef (>= 0.10.0)


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
    [chef] Importing base box 'lucid64-chef-0.10.0'...
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
    [chef] [Sat, 04 Jun 2011 13:37:35 -0700] INFO: *** Chef 0.10.0 ***
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