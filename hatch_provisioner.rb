class HatchProvisioner < Vagrant::Provisioners::ChefSolo

  class Config < Vagrant::Provisioners::ChefSolo::Config

    # Provided by ChefSolo::Config
    # attr_accessor :cookbooks_path
    # attr_accessor :roles_path
    # attr_accessor :data_bags_path
    # attr_accessor :recipe_url

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
      @validation_key_path = "./chef/validation.pem"
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
  
  def provision!
    super
    
    vm.ssh.execute do |ssh|
      env.ui.info "Creating chef user #{config.client_name}"
      ssh.exec!("cd /vagrant && sudo rake hatch:init['#{config.client_name}']  || true")
      
      env.ui.info "Grabbing client key"
      ssh.exec!("sudo cp /tmp/#{config.client_name}.pem /vagrant/#{config.client_key_path}")
      
      env.ui.info "Grabbing validation key"
      ssh.exec!("sudo cp /etc/chef/validation.pem /vagrant/#{config.validation_key_path} || true")
    end
    
    setup_knife_config
    
    `knife cookbook upload --all`
    `for role in roles/*.rb ; do knife role from file $role ; done`
    
    vm.ssh.execute do |ssh|
      ssh.exec!("cd /vagrant && sudo rake hatch:finish['duh']")
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
#     setup_config("chef_solo_solo", "solo.rb", {
#       :node_name => config.node_name,
#       :provisioning_path => config.provisioning_path,
#       :cookbooks_path => cookbooks_path,
#       :recipe_url => config.recipe_url,
#       :roles_path => roles_path,
#       :data_bags_path => data_bags_path,
#     })
#     
#     conf = Erubis::Eruby.new(template, :trim => true).result(binding)
#     config_file = Vagrant::Util::TemplateRenderer.render("chef_solo_solo", {
#           :log_level => config.log_level.to_sym,
#           :http_proxy => config.http_proxy,
#           :http_proxy_user => config.http_proxy_user,
#           :http_proxy_pass => config.http_proxy_pass,
#           :https_proxy => config.https_proxy,
#           :https_proxy_user => config.https_proxy_user,
#           :https_proxy_pass => config.https_proxy_pass,
#           :no_proxy => config.no_proxy
#         }.merge(template_vars))
# 
#         vm.ssh.upload!(StringIO.new(config_file), File.join(config.provisioning_path, filename))
#   end
end