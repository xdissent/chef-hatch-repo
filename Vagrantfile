require 'hatch_provisioner'

Vagrant::Config.run do |config|

  # Configure a chef server
  config.vm.define :chef do |vm_config|

    vm_config.vm.host_name = "chef.local"
    vm_config.vm.network("192.168.10.10")
    vm_config.vm.box = "lucid64-chef-0.10.0"
    vm_config.vm.box_url = "http://dev.cjadvertising.com/lucid64-chef-0.10.0.box"
    vm_config.vm.provision HatchProvisioner do |chef|
      chef.cookbooks_path = ["cookbooks"]
      chef.node_name = "chef.local"
      chef.roles_path = "roles"
      chef.add_role("chef_server")
      chef.json.merge!({
        :chef_environment => "dev"
      })
    end
  end
end