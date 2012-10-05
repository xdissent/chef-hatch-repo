### Chef Solo
#
#
### Opscode Hosted Chef Server
#
#     export KNIFE_USER="jdoe"
#     export KNIFE_ORGNAME="acmeco"
#
# * Your Opscode client key should be at `~/.chef.d/opscode-jdoe.pem`.
# * Your Opscode validation key should be at `~/.chef.d/opscode-acmeco-validator.pem`.
#
### Chef Server
#
#    export KNIFE_USER="hsolo"
#    export KNIFE_SERVER_NAME="widgetinc"
#    export KNIFE_SERVER_URL="https://chef.widgetinc.com"
#
# * Your Chef Server client key should be at `~/.chef.d/widgetinc-hsolo.pem`.
# * Your Chef Server validation key should be at `~/.chef.d/widgetinc-validator.pem`.
#

current_dir = File.dirname(__FILE__)
home_dir    = ENV['HOME']
chef_dir    = "#{home_dir}/.chef"
chefd_dir   = "#{home_dir}/.chef.d"

user        = ENV['KNIFE_USER'] || ENV['USER']
orgname     = ENV['KNIFE_ORGNAME']
server_name = ENV['KNIFE_SERVER_NAME']
server_url  = ENV['KNIFE_SERVER_URL']

# path to cookbooks
cookbook_path             ["#{current_dir}/../cookbooks",
                          "#{current_dir}/../site-cookbooks"]

# logging details
log_level                 :info
log_location              STDOUT

# user/client and private key to authenticate to a Chef Server, if needed
node_name                 user

if orgname
  # if KNIFE_ORGNAME is given, then we're talking to the Opscode Hosted Chef
  # Server
  validation_client_name  "#{orgname}-validator"
  client_key              "#{chefd_dir}/opscode-#{user}.pem"
  validation_key          "#{chefd_dir}/opscode-#{orgname}-validator.pem"
  chef_server_url         "https://api.opscode.com/organizations/#{orgname}"
elsif server_name
  # if KNIFE_SERVER_NAME is defined, then we're talking to a Chef Server
  validation_client_name  "chef-validator"
  client_key              "#{chefd_dir}/#{server_name}-#{user}.pem"
  validation_key          "#{chefd_dir}/#{server_name}-validator.pem"
  chef_server_url         server_url
end

# set default chef environment when bootstrapping
environment               "stable"

# caching options
cache_type                'BasicFile'
cache_options( :path =>   "#{home_dir}/.chef/checksums" )

file_backup_path          "#{chef_dir}/backups"

# new cookbook defaults
cookbook_copyright        ENV['KNIFE_COOKBOOK_COPYRIGHT'] ||
                          %x{git config --get user.name}.chomp
cookbook_email            ENV['KNIFE_COOKBOOK_EMAIL'] ||
                          %x{git config --get user.email}.chomp
cookbook_license          "apachev2"

# rackspace configuration
if ENV['RACKSPACE_USERNAME'] && ENV['RACKSPACE_API_KEY']
  knife[:rackspace_api_username]  = ENV['RACKSPACE_USERNAME']
  knife[:rackspace_api_key]       = ENV['RACKSPACE_API_KEY']
end

# aws ec2 configuration
if ENV['AWS_AWS_ACCESS_KEY_ID'] && ENV['AWS_AWS_SECRET_ACCESS_KEY']
  ##
  # Searches the ENV hash for keys starting with "AWS_" and converts them
  # to knife config settings. For example:
  #
  #     ENV['AWS_AWS_ACCESS_KEY_ID'] = "abcabc"
  #     ENV['AWS_FLAVOR'] = "t1.small"
  #
  # becomes:
  #
  #     knife[:aws_access_key_id] = "abcabc"
  #     knife[:flavor] = "t1.small"
  aws_attrs = ENV.keys.select { |k| k =~ /^AWS_/ }

  aws_attrs.each do |key|
    knife.send(:[]=, key.sub(/^AWS_/, '').downcase.to_sym, ENV[key])
  end
end

# linode configuration
if ENV['LINODE_API_KEY']
  knife[:linode_api_key] = ENV['LINODE_API_KEY']
end

# bluebox configuration
if ENV['BLUEBOX_CUSTOMER_ID'] && ENV['BLUEBOX_API_KEY']
  knife[:bluebox_customer_id] = ENV['BLUEBOX_CUSTOMER_ID']
  knife[:bluebox_api_key]     = ENV['BLUEBOX_API_KEY']
end
