require 'net/scp'

class HatchProvisioner < Vagrant::Provisioners::ChefSolo
  class Config < Vagrant::Provisioners::ChefSolo::Config
  end
  
  def provision!
    super
    vm.ssh.execute do |ssh|
      ssh.exec!('sudo cp /etc/chef/validation.pem /tmp/validation.pem && sudo chmod 666 /tmp/validation.pem')
      scp = Net::SCP.new(ssh.session)
      scp.download!('/tmp/validation.pem', './validation.pem')
      ssh.exec!('sudo rm /tmp/validation.pem')
    end
  end
end