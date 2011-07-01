require './hatch_provisioner'

Vagrant::Config.run do |config|

  # Configure a chef server
  config.vm.define :chef do |vm_config|

    vm_config.vm.host_name = "chef.local"
    vm_config.vm.network("192.168.10.10")
    vm_config.vm.box = "lucid64-chef-0.10.0"
    vm_config.vm.box_url = "http://dev.cjadvertising.com/lucid64-chef-0.10.0.box"
    vm_config.vm.provision HatchProvisioner do |chef|
      chef.node_name = "chef.local"
      chef.add_role("chef_server")
    end
  end
  
  # Configure a demo server
  config.vm.define :demo do |vm_config|
    vm_config.vm.host_name = "demo.local"
    vm_config.vm.network("192.168.10.11")
    vm_config.vm.box = "lucid64-chef-0.10.0"
    vm_config.vm.box_url = "http://dev.cjadvertising.com/lucid64-chef-0.10.0.box"
    vm_config.vm.provision :chef_server do |chef|
      chef.chef_server_url = "http://192.168.10.10:4000"
      chef.validation_key_path = ".chef/validation.pem"
      chef.add_recipe("apache2")
    end
  end
end
