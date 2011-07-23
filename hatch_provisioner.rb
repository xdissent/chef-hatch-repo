class HatchProvisioner < Vagrant::Provisioners::ChefSolo

  extend Vagrant::Util::Counter    

  class Config < Vagrant::Provisioners::ChefSolo::Config

    # Provided by ChefSolo::Config
    # attr_accessor :cookbooks_path
    # attr_accessor :roles_path
    # attr_accessor :data_bags_path
    # attr_accessor :recipe_url
    # attr_accessor :nfs

    # Would be provided by ChefServer::Config
    # attr_accessor :chef_server_url  # Determined during prepare
    attr_accessor :validation_key_path
    attr_accessor :validation_client_name
    attr_accessor :client_key_path
    attr_accessor :environment
    
    # Hatch-specific
    attr_accessor :client_name
    
    def initialize
      super
      @roles_path = "roles"
      @validation_key_path = ".chef/validation.pem"
      @validation_client_name = "chef-validator"
      @client_key_path = ".chef/hatch.pem"
      @environment = "_default"
      @client_name = "hatch"
    end

    def validate(errors)
      super
    end
  end
  
  def prepare
    super
  end
  
  # Converts paths to a list of properly expanded paths with types.
  def expanded_folders(paths)
    # Convert the path to an array if it is a string or just a single
    # path element which contains the folder location (:host or :vm)
    paths = [paths] if paths.is_a?(String) || paths.first.is_a?(Symbol)
  
    paths.map do |path|
      path = [:host, path] if !path.is_a?(Array)
      type, path = path
  
      # Create the local/remote path based on whether this is a host
      # or VM path.
      local_path = nil
      local_path = File.expand_path(path, env.root_path) if type == :host
      remote_path = type == :host ? "#{config.provisioning_path}/chef-solo-#{self.class.get_and_update_counter}" : path
  
      # Return the result
      [type, local_path, remote_path]
    end
  end
  
  # Shares the given folders with the given prefix. The folders should
  # be of the structure resulting from the `expanded_folders` function.
  def share_folders(prefix, folders)
    index = 0
    folders.each do |type, local_path, remote_path|
      if type == :host
        env.config.vm.share_folder("v-#{prefix}-#{type}-#{index}",
                                   remote_path, local_path, :nfs => config.nfs)
        index += 1
      end
    end
  end
  
  def provision!
  
    vm.ssh.execute do |ssh|
      env.ui.info "Running hatch bootstrap"
      ssh.exec!("sudo sh /vagrant/.chef/bootstrap/vagrant-hatch.sh")
    end
  
    super
    
    vm.ssh.execute do |ssh|
      env.ui.info "Creating chef user #{config.client_name}"
      ssh.exec!("cd /vagrant && sudo rake hatch:init['#{config.client_name}']")
      
      env.ui.info "Grabbing client key"
      ssh.exec!("sudo cp /tmp/#{config.client_name}.pem /vagrant/#{config.client_key_path}")
      
      env.ui.info "Grabbing validation key"
      ssh.exec!("sudo cp /etc/chef/validation.pem /vagrant/#{config.validation_key_path}")
    end
    
    setup_knife_config
    
    `knife cookbook upload --all`
    `for role in roles/*.rb ; do knife role from file $role ; done`
    
    n = config.node_name || env.config.vm.host_name
    
    vm.ssh.execute do |ssh|
      ssh.exec!("cd /vagrant && sudo rake hatch:finish['#{n}','#{config.run_list.join(' ')}']")
      ssh.exec!("sudo /etc/init.d/chef-client restart")
    end

  end
  
  def setup_knife_config
    cwd = File.expand_path(File.dirname(__FILE__))
    conf = <<-END_CONF
      log_level                #{config.log_level}
      log_location             STDOUT
      node_name                '#{config.client_name}'
      client_key               '#{cwd}/#{config.client_key_path}'
      validation_client_name   '#{config.validation_client_name}'
      validation_key           '#{cwd}/#{config.validation_key_path}'
      chef_server_url          'http://192.168.10.10:4000'
      cache_type               'BasicFile'
      cache_options( :path => '#{cwd}/.chef/checksums' )
      cookbook_path [ '#{cwd}/cookbooks' ]
    END_CONF
    config_file = File.new("#{cwd}/.chef/knife.rb", "w")
    config_file.write(conf)
    config_file.close
  end
end
