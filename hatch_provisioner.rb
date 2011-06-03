require 'net/scp'

class HatchProvisioner < Vagrant::Provisioners::ChefSolo
  class Config < Vagrant::Provisioners::ChefSolo::Config
  end
  
  def provision!
    super
    download!('/etc/chef/validation.pem', './validation.pem')
  end
  
  def download!(from, to)
    vm.ssh.execute do |ssh|
      scp = Net::SCP.new(ssh.session)
      scp.download!(from, to)
    end
  end
end