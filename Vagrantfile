#!/usr/bin/env ruby
#^syntax detection

Vagrant::Config.run do |config|
  config.vm.define :chef do |vm_config|
    vm_config.vm.host_name = "chef.vm"
    vm_config.vm.box = "precise64"
    vm_config.vm.box_url = "http://files.vagrantup.com/precise64.box"
    vm_config.vm.network :hostonly, "192.168.33.11"
    vm_config.vm.customize ["modifyvm", :id, "--memory", 1024]
  end

  config.vm.define :demo do |vm_config|
    vm_config.vm.host_name = "demo.vm"
    vm_config.vm.box = "precise64"
    vm_config.vm.box_url = "http://files.vagrantup.com/precise64.box"
    vm_config.vm.network :hostonly, "192.168.33.12"
    vm_config.vm.customize ["modifyvm", :id, "--memory", 1024]
  end
end