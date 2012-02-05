I18n.load_path << File.expand_path("../locales/en.yml", __FILE__)

class HatchProvisioner < Vagrant::Provisioners::ChefSolo

  class HatchError < Vagrant::Errors::VagrantError
    error_namespace("vagrant.provisioners.hatch")
  end

  class Config < Vagrant::Provisioners::ChefSolo::Config

    # Provided by ChefSolo::Config
    # attr_accessor :cookbooks_path
    # attr_accessor :roles_path
    # attr_accessor :data_bags_path
    # attr_accessor :recipe_url
    # attr_accessor :nfs

    # Would be provided by ChefClient::Config
    attr_accessor :validation_key_path
    attr_accessor :validation_client_name
    attr_accessor :client_key_path
    attr_accessor :environment
    
    # Hatch-specific
    attr_accessor :client_name
    attr_accessor :chef_ip
    
    def initialize
      super
      @roles_path = "roles"
      @data_bags_path = "data_bags"
      @validation_key_path = ".chef/validation.pem"
      @validation_client_name = "chef-validator"
      @client_key_path = ".chef/hatch.pem"
      @environment = "_default"
      @client_name = "hatch"
    end

    def validate(env, errors)
      super
    end
  end

  def self.config_class
    Config
  end

  def prepare
    if ((env[:vm].config.vm.networks[0] || [])[1] || [])[0].nil?
      raise HatchError, :require_chef_ip if config.chef_ip.nil?
    end
    super
  end

  def provision!
    env[:ui].info "Running hatch bootstrap"
    env[:vm].channel.sudo("sh /vagrant/.chef/bootstrap/vagrant-hatch.sh")
  
    super

    env[:ui].info "Creating chef user #{config.client_name}"
    env[:vm].channel.sudo("cd /vagrant && rake hatch:init['#{config.client_name}']")
    env[:ui].info "Grabbing client key"
    env[:vm].channel.sudo("cp /tmp/#{config.client_name}.pem /vagrant/#{config.client_key_path}")
      
    env[:ui].info "Grabbing validation key"
    env[:vm].channel.sudo("cp /etc/chef/validation.pem /vagrant/#{config.validation_key_path}")

    setup_knife_config
    
    # Upload cookbooks and roles
    env[:ui].info "Uploading cookbooks"
    `knife cookbook upload --all`

    env[:ui].info "Uploading roles"
    `for role in roles/*.rb ; do knife role from file $role ; done`

    # Find and upload all data bags
    dbag_glob = File.expand_path(File.join(File.dirname(__FILE__), config.data_bags_path)) + "/*/*.json"
    dbags = []
    Dir.glob(dbag_glob) do |f|
      bag = File.basename(File.dirname(f))
      item = File.basename(f)
      unless dbags.include? bag
        dbags << bag
        env[:ui].info "Creating data bag"
        `knife data bag create #{bag}`
      end
      env[:ui].info "Uploading data bag item #{item} in #{bag}"
      `knife data bag from file #{bag} #{item}`
    end

    # Create environments
    env_glob = File.expand_path(File.join(File.dirname(__FILE__), "/environments")) + "/*.rb"
    Dir.glob(env_glob) do |f|
      env[:ui].info "Uploading environment #{f}"
      `knife environment from file #{File.basename(f)}`
    end
    
    n = config.node_name || env.config.vm.host_name

    env[:ui].info "Running hatch finish rake task"
    env[:vm].channel.sudo("cd /vagrant && rake hatch:finish['#{n}','#{config.run_list.join(' ')}','#{config.environment}']")
    env[:ui].info "Restarting chef client"
    env[:vm].channel.sudo("/etc/init.d/chef-client restart")

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
      chef_server_url          'http://#{config.chef_ip || env[:vm].config.vm.networks[0][1][0]}:4000'
      cache_type               'BasicFile'
      cache_options( :path => '#{cwd}/.chef/checksums' )
      cookbook_path [ '#{cwd}/cookbooks' ]
    END_CONF
    config_file = File.new("#{cwd}/.chef/knife.rb", "w")
    config_file.write(conf)
    config_file.close
    env[:ui].info "Wrote config:"
    env[:ui].info(conf)
  end
end
