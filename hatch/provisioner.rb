I18n.load_path << File.expand_path("../locales/en.yml", __FILE__)

HATCH_ROOT = File.expand_path("..", File.dirname(__FILE__))

class HatchProvisioner < Vagrant::Provisioners::ChefSolo

  I18N_NAMESPACE = "vagrant.provisioners.hatch"

  class HatchError < Vagrant::Errors::VagrantError
    error_namespace(I18N_NAMESPACE)
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

    def validation_client_name; @validation_client_name || "chef-validator"; end
    def validation_key_path; @validation_key_path || ".chef/validation.pem"; end
    def client_key_path; @client_key_path || ".chef/hatch.pem"; end
    def roles_path; @roles_path || "roles"; end
    def data_bags_path; @data_bags_path || "data_bags"; end
    def client_name; @client_name || "hatch"; end
    def environment; @environment || "_default"; end
  end

  def self.config_class
    Config
  end

  def prepare
    if ((env[:vm].config.vm.networks[0] || [])[1] || [])[0].nil?
      raise HatchError, :require_chef_ip if config.chef_ip.nil?
    end
    config.add_recipe("hatch")
    super
  end

  def provision!
    env[:ui].info I18n.t("#{I18N_NAMESPACE}.running_bootstrap")
    env[:vm].channel.sudo("sh /vagrant/hatch/vagrant.sh")
  
    super

    env[:ui].info I18n.t("#{I18N_NAMESPACE}.creating_chef_user", :name => config.client_name)
    env[:vm].channel.sudo("cd /vagrant && rake hatch:init['#{config.client_name}']")
    env[:ui].info I18n.t("#{I18N_NAMESPACE}.copy_client_key")
    env[:vm].channel.sudo("cp /tmp/#{config.client_name}.pem /vagrant/#{config.client_key_path}")
      
    env[:ui].info I18n.t("#{I18N_NAMESPACE}.copy_validation_key")
    env[:vm].channel.sudo("cp /etc/chef/validation.pem /vagrant/#{config.validation_key_path}")

    setup_knife_config
    
    # Upload cookbooks and roles
    env[:ui].info I18n.t("#{I18N_NAMESPACE}.uploading_cookbooks")
    `knife cookbook upload --all`

    env[:ui].info I18n.t("#{I18N_NAMESPACE}.uploading_roles")
    `for role in roles/*.rb ; do knife role from file $role ; done`

    # Find and upload all data bags
    dbag_glob = File.join(HATCH_ROOT, config.data_bags_path) + "/*/*.json"
    dbags = []
    Dir.glob(dbag_glob) do |f|
      bag = File.basename(File.dirname(f))
      item = File.basename(f)
      unless dbags.include? bag
        dbags << bag
        env[:ui].info I18n.t("#{I18N_NAMESPACE}.creating_data_bag")
        `knife data bag create #{bag}`
      end
      env[:ui].info I18n.t("#{I18N_NAMESPACE}.uploading_data_bag", :item => item, :bag => bag)
      `knife data bag from file #{bag} #{item}`
    end

    # Create environments
    env_glob = File.join(HATCH_ROOT, "/environments") + "/*.rb"
    Dir.glob(env_glob) do |f|
      env[:ui].info I18n.t("#{I18N_NAMESPACE}.uploading_environment", :name => f)
      `knife environment from file #{File.basename(f)}`
    end
    
    n = config.node_name || env.config.vm.host_name

    env[:ui].info I18n.t("#{I18N_NAMESPACE}.running_hatch_finish")
    env[:vm].channel.sudo("cd /vagrant && rake hatch:finish")
    env[:ui].info I18n.t("#{I18N_NAMESPACE}.restarting_chef_client")
    env[:vm].channel.sudo("/etc/init.d/chef-client restart")

  end
  
  def setup_knife_config
    conf = <<-END_CONF
      log_level                #{config.log_level}
      log_location             STDOUT
      node_name                '#{config.client_name}'
      client_key               '#{HATCH_ROOT}/#{config.client_key_path}'
      validation_client_name   '#{config.validation_client_name}'
      validation_key           '#{HATCH_ROOT}/#{config.validation_key_path}'
      chef_server_url          'http://#{config.chef_ip || env[:vm].config.vm.networks[0][1][0]}:4000'
      cache_type               'BasicFile'
      cache_options( :path => '#{HATCH_ROOT}/.chef/checksums' )
      cookbook_path [ '#{HATCH_ROOT}/cookbooks' ]
    END_CONF
    config_file = File.new("#{HATCH_ROOT}/.chef/knife.rb", "w")
    config_file.write(conf)
    config_file.close
    env[:ui].info I18n.t("#{I18N_NAMESPACE}.wrote_configuration", :conf => conf)
  end
end
