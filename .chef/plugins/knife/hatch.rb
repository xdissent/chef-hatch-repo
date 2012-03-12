gem 'chef', '=0.10.8'

module HatchKnifePlugins

  class Hatch < Chef::Knife
  
    banner "knife hatch (options)"
    
    deps do
      require 'chef/knife/bootstrap'
      Chef::Knife::Bootstrap.load_deps
      require 'fog'
      require 'socket'
      require 'net/ssh/multi'
      require 'net/scp'
      require 'readline'
      require 'chef/json_compat'
      require 'tempfile'
    end
    
    attr_accessor :initial_sleep_delay
   
    option :flavor,
      :short => "-f FLAVOR",
      :long => "--flavor FLAVOR",
      :description => "The flavor of server (m1.small, m1.medium, etc)",
      :proc => Proc.new { |f| Chef::Config[:knife][:flavor] = f },
      :default => "m1.small"
   
    option :image,
      :short => "-I IMAGE",
      :long => "--image IMAGE",
      :description => "The AMI for the server",
      :proc => Proc.new { |i| Chef::Config[:knife][:image] = i }
   
    option :security_groups,
      :short => "-G X,Y,Z",
      :long => "--groups X,Y,Z",
      :description => "The security groups for this server",
      :default => ["default"],
      :proc => Proc.new { |groups| groups.split(',') }
   
    option :availability_zone,
      :short => "-Z ZONE",
      :long => "--availability-zone ZONE",
      :description => "The Availability Zone",
      :default => "us-east-1b",
      :proc => Proc.new { |key| Chef::Config[:knife][:availability_zone] = key }
   
    option :chef_node_name,
      :short => "-N NAME",
      :long => "--node-name NAME",
      :description => "The Chef node name for your new node"
   
    option :ssh_key_name,
      :short => "-S KEY",
      :long => "--ssh-key KEY",
      :description => "The AWS SSH key id",
      :proc => Proc.new { |key| Chef::Config[:knife][:aws_ssh_key_id] = key }
   
    option :ssh_user,
      :short => "-x USERNAME",
      :long => "--ssh-user USERNAME",
      :description => "The ssh username",
      :default => "root"
   
    option :ssh_password,
      :short => "-P PASSWORD",
      :long => "--ssh-password PASSWORD",
      :description => "The ssh password"
   
    option :identity_file,
      :short => "-i IDENTITY_FILE",
      :long => "--identity-file IDENTITY_FILE",
      :description => "The SSH identity file used for authentication"
   
    option :aws_access_key_id,
      :short => "-A ID",
      :long => "--aws-access-key-id KEY",
      :description => "Your AWS Access Key ID",
      :proc => Proc.new { |key| Chef::Config[:knife][:aws_access_key_id] = key }
   
    option :aws_secret_access_key,
      :short => "-K SECRET",
      :long => "--aws-secret-access-key SECRET",
      :description => "Your AWS API Secret Access Key",
      :proc => Proc.new { |key| Chef::Config[:knife][:aws_secret_access_key] = key }
   
    option :prerelease,
      :long => "--prerelease",
      :description => "Install the pre-release chef gems"
   
    option :bootstrap_version,
      :long => "--bootstrap-version VERSION",
      :description => "The version of Chef to install",
      :proc => Proc.new { |v| Chef::Config[:knife][:bootstrap_version] = v }
   
    option :region,
      :long => "--region REGION",
      :description => "Your AWS region",
      :default => "us-east-1",
      :proc => Proc.new { |key| Chef::Config[:knife][:region] = key }
   
    option :distro,
      :short => "-d DISTRO",
      :long => "--distro DISTRO",
      :description => "Bootstrap a distro using a template",
      :proc => Proc.new { |d| Chef::Config[:knife][:distro] = d },
      :default => "ubuntu10.04-gems"
   
    option :template_file,
      :long => "--template-file TEMPLATE",
      :description => "Full path to location of template to use",
      :proc => Proc.new { |t| Chef::Config[:knife][:template_file] = t },
      :default => false
   
    option :ebs_size,
      :long => "--ebs-size SIZE",
      :description => "The size of the EBS volume in GB, for EBS-backed instances"
   
    option :ebs_no_delete_on_term,
      :long => "--ebs-no-delete-on-term",
      :description => "Do not delete EBS volumn on instance termination"
   
    option :run_list,
      :short => "-r RUN_LIST",
      :long => "--run-list RUN_LIST",
      :description => "Comma separated list of roles/recipes to apply",
      :proc => lambda { |o| o.split(/[\s,]+/) },
      :default => ["role[chef_server]"]
   
    option :subnet_id,
      :short => "-s SUBNET-ID",
      :long => "--subnet SUBNET-ID",
      :description => "create node in this Virtual Private Cloud Subnet ID (implies VPC mode)",
      :default => false
   
    option :no_host_key_verify,
      :long => "--no-host-key-verify",
      :description => "Disable host key verification",
      :boolean => true,
      :default => false

    option :ec2_api_endpoint,
      :long => "--ec2-api-endpoint ENDPOINT",
      :description => "Your EC2 API endpoint",
      :proc => Proc.new { |endpoint| Chef::Config[:knife][:ec2_api_endpoint] = endpoint }
   
    option :ensure_public_ip,
      :long => "--ensure-public-ip",
      :description => "Ensure server gets a public IP",
      :boolean => true,
      :default => false

    option :ip,
      :long => "--ip IP",
      :description => "Force the public IP",
      :default => nil

    def tcp_test_ssh(hostname)
      tcp_socket = TCPSocket.new(hostname, 22)
      readable = IO.select([tcp_socket], nil, nil, 5)
      if readable
        Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
        yield
        true
      else
        false
      end
    rescue Errno::ETIMEDOUT
      false
    rescue Errno::EPERM
      false
    rescue Errno::ECONNREFUSED
      sleep 2
      false
    # This happens on EC2 quite often
    rescue Errno::EHOSTUNREACH
      sleep 2
      false
    ensure
      tcp_socket && tcp_socket.close
    end
   
    def run
   
      $stdout.sync = true
   
      connection = Fog::Compute.new(
        :provider => 'AWS',
        :aws_access_key_id => Chef::Config[:knife][:aws_access_key_id],
        :aws_secret_access_key => Chef::Config[:knife][:aws_secret_access_key],
        :region => locate_config_value(:region),
        :endpoint => Chef::Config[:knife][:ec2_api_endpoint]
      )
   
      ami = connection.images.get(locate_config_value(:image))
   
      if ami.nil?
        ui.error("You have not provided a valid image (AMI) value.  Please note the short option for this value recently changed from '-i' to '-I'.")
        exit 1
      end
   
      server_def = {
        :image_id => locate_config_value(:image),
        :groups => config[:security_groups],
        :flavor_id => locate_config_value(:flavor),
        :key_name => Chef::Config[:knife][:aws_ssh_key_id],
        :availability_zone => Chef::Config[:knife][:availability_zone]
      }
      server_def[:subnet_id] = config[:subnet_id] if config[:subnet_id]
   
      if ami.root_device_type == "ebs"
        ami_map = ami.block_device_mapping.first
        ebs_size = begin
                     if config[:ebs_size]
                       Integer(config[:ebs_size]).to_s
                     else
                       ami_map["volumeSize"].to_s
                     end
                   rescue ArgumentError
                     puts "--ebs-size must be an integer"
                     msg opt_parser
                     exit 1
                   end
        delete_term = if config[:ebs_no_delete_on_term]
                        "false"
                      else
                        ami_map["deleteOnTermination"]
                      end
        server_def[:block_device_mapping] =
          [{
             'DeviceName' => ami_map["deviceName"],
             'Ebs.VolumeSize' => ebs_size,
             'Ebs.DeleteOnTermination' => delete_term
           }]
      end
      server = connection.servers.create(server_def)
   
      puts "#{ui.color("Instance ID", :cyan)}: #{server.id}"
      puts "#{ui.color("Flavor", :cyan)}: #{server.flavor_id}"
      puts "#{ui.color("Image", :cyan)}: #{server.image_id}"
      puts "#{ui.color("Availability Zone", :cyan)}: #{server.availability_zone}"
      puts "#{ui.color("Security Groups", :cyan)}: #{server.groups.join(", ")}"
      puts "#{ui.color("SSH Key", :cyan)}: #{server.key_name}"
      puts "#{ui.color("Subnet ID", :cyan)}: #{server.subnet_id}" if vpc_mode?
   
      print "\n#{ui.color("Waiting for server", :magenta)}"
   
      display_name = if vpc_mode?
        server.private_ip_address
      else
        server.dns_name
      end
   
      # wait for it to be ready to do stuff
      server.wait_for { print "."; ready? }
   
      puts("\n")
   
      if !vpc_mode?
        puts "#{ui.color("Public DNS Name", :cyan)}: #{server.dns_name}"
        puts "#{ui.color("Public IP Address", :cyan)}: #{server.public_ip_address}"
        puts "#{ui.color("Private DNS Name", :cyan)}: #{server.private_dns_name}"
      end
      puts "#{ui.color("Private IP Address", :cyan)}: #{server.private_ip_address}"
   
      print "\n#{ui.color("Waiting for sshd", :magenta)}"

      ssh_address = server.dns_name
      public_dns_name = server.dns_name
      if ( config[:ip] || (config[:ensure_public_ip] and server.public_ip_address == server.private_ip_address) )
        public_ip = set_public_ip(connection, server, config[:ip])
        if public_ip.nil?
          ui.error("Unable to assign a public IP to instance #{server.id}")
          exit 1
        end
        public_dns_name = public_ip
        ssh_address = public_ip
        print "\n#{ui.color("\nServer got public IP #{public_ip}", :magenta)}"
      end

      ip_to_test = vpc_mode? ? server.private_ip_address : ssh_address
      print(".") until tcp_test_ssh(ip_to_test) {
        sleep @initial_sleep_delay ||= (vpc_mode? ? 40 : 10)
        puts("done")
      }
   
      bootstrap_for_node(server, ip_to_test)
   
      puts "\n"
      puts "#{ui.color("Instance ID", :cyan)}: #{server.id}"
      puts "#{ui.color("Flavor", :cyan)}: #{server.flavor_id}"
      puts "#{ui.color("Image", :cyan)}: #{server.image_id}"
      puts "#{ui.color("Availability Zone", :cyan)}: #{server.availability_zone}"
      puts "#{ui.color("Security Groups", :cyan)}: #{server.groups.join(", ")}"
      if vpc_mode?
        puts "#{ui.color("Subnet ID", :cyan)}: #{server.subnet_id}"
      else
        puts "#{ui.color("Public DNS Name", :cyan)}: #{public_dns_name}"
        puts "#{ui.color("Public IP Address", :cyan)}: #{ssh_address}"
        puts "#{ui.color("Private DNS Name", :cyan)}: #{server.private_dns_name}"
      end
      puts "#{ui.color("SSH Key", :cyan)}: #{server.key_name}"
      puts "#{ui.color("Private IP Address", :cyan)}: #{server.private_ip_address}"
      puts "#{ui.color("Root Device Type", :cyan)}: #{server.root_device_type}"
      if server.root_device_type == "ebs"
        device_map = server.block_device_mapping.first
        puts "#{ui.color("Root Volume ID", :cyan)}: #{device_map['volumeId']}"
        puts "#{ui.color("Root Device Name", :cyan)}: #{device_map['deviceName']}"
        puts "#{ui.color("Root Device Delete on Terminate", :cyan)}: #{device_map['deleteOnTermination']}"
        if config[:ebs_size]
          if ami.block_device_mapping.first['volumeSize'].to_i < config[:ebs_size].to_i
            puts ("#{ui.color("Warning", :yellow)}: #{config[:ebs_size]}GB " +
                  "EBS volume size is larger than size set in AMI of " +
                  "#{ami.block_device_mapping.first['volumeSize']}GB.\n" +
                  "Use file system tools to make use of the increased volume size.")
          end
        end
      end
      puts "#{ui.color("Environment", :cyan)}: #{config[:environment] || '_default'}"
      puts "#{ui.color("Run List", :cyan)}: #{config[:run_list].join(', ')}"
    end
   
    def bootstrap_for_node(server, ssh_address)
      bootstrap = Chef::Knife::Bootstrap.new
      bootstrap.name_args = [ ssh_address ]
      bootstrap.config[:run_list] = config[:run_list]
      bootstrap.config[:ssh_user] = config[:ssh_user]
      bootstrap.config[:identity_file] = config[:identity_file]
      bootstrap.config[:chef_node_name] = config[:chef_node_name] || server.id
      bootstrap.config[:prerelease] = config[:prerelease]
      bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
      bootstrap.config[:distro] = locate_config_value(:distro)
      bootstrap.config[:use_sudo] = true unless config[:ssh_user] == 'root'
      bootstrap.config[:template_file] = locate_config_value(:template_file)
      bootstrap.config[:environment] = config[:environment]
      # may be needed for vpc_mode
      bootstrap.config[:no_host_key_verify] = config[:no_host_key_verify]
      # Always use hatch distro
      bootstrap.config[:distro] = 'ubuntu10.04-gems-hatch'
      
      # Package files to send
      puts "#{ui.color("Creating temporary directory", :cyan)}"
      temp_base = Dir.tmpdir
      temp_dir = File.join(temp_base, "chef-hatch")
      FileUtils.remove_dir(temp_dir, :force => true)
      FileUtils.mkdir(temp_dir)
      
      puts "#{ui.color("Creating solo config", :cyan)}"
      solo_config = <<-END_CONFIG
        node_name "#{bootstrap.config[:chef_node_name]}"
        file_cache_path "/tmp/chef-hatch/cache"
        cookbook_path ["/tmp/chef-hatch/cookbooks"]
        role_path "/tmp/chef-hatch/roles"
        log_level :info
        data_bag_path ["/tmp/chef-hatch/data_bags"]
      END_CONFIG
      config_file = File.new("#{temp_dir}/solo.rb", "w")
      config_file.write(solo_config)
      config_file.close
      
      puts "#{ui.color("Copying files to temporary directory", :cyan)}"
      files = ["cookbooks", "roles", "data_bags", "environments", "Rakefile", "config"]
      files.each do |f|
        FileUtils.cp_r("./#{f}", "#{temp_dir}/#{f}") if File.exists?(f)
      end

      puts "#{ui.color("Creating chef-hatch tarball", :cyan)}"
      tar_file = "chef-hatch.tgz"
      tar_file_path = File.join(temp_base, tar_file)
      system("tar", "-C", temp_base, "-cvzf", tar_file_path, "chef-hatch")
      
      puts "#{ui.color("Copying chef-hatch tarball to host", :cyan)}"
      system("scp", "-o", "StrictHostKeyChecking=no", "-i", config[:identity_file], tar_file_path, "#{config[:ssh_user]}@#{ssh_address}:/tmp/#{tar_file}")
      
      bootstrap.run
      
      Net::SSH.start(ssh_address, config[:ssh_user], :keys => [config[:identity_file]]) do |ssh|
        puts "#{ui.color("Creating admin user", :cyan)}"
        ssh.exec! "cd /tmp/chef-hatch && sudo rake hatch:init['hatch']"
        
        puts "#{ui.color("Copying keys", :cyan)}"
        ssh.exec! "sudo chmod 666 /tmp/hatch.pem"
        ssh.exec! "sudo cp /etc/chef/validation.pem /tmp/chef-hatch/validation.pem"
        ssh.exec! "sudo chmod 666 /tmp/chef-hatch/validation.pem"
      end
      
      puts "#{ui.color("Downloading keys", :cyan)}"
      system("scp", "-o", "StrictHostKeyChecking=no", "-i", config[:identity_file], "#{config[:ssh_user]}@#{ssh_address}:/tmp/chef-hatch/validation.pem", "./.chef/validation.pem")
      system("scp", "-o", "StrictHostKeyChecking=no", "-i", config[:identity_file], "#{config[:ssh_user]}@#{ssh_address}:/tmp/hatch.pem", "./.chef/hatch.pem")
      
      # Create knife.rb
      puts "#{ui.color("Creating knife.rb", :cyan)}"
      setup_knife_config(server, ssh_address)
      
      puts "#{ui.color("Uploading all cookbooks", :cyan)}"
      `knife cookbook upload --all`
      
      puts "#{ui.color("Uploading all roles", :cyan)}"
      `for role in roles/*.rb ; do knife role from file $role ; done`

      # Find and upload all data bags
      dbag_glob = File.expand_path("./data_bags") + "/*/*.json"
      dbags = []
      Dir.glob(dbag_glob) do |f|
        bag = File.basename(File.dirname(f))
        item = File.basename(f)
        unless dbags.include? bag
          dbags << bag
          msg = "Creating data bag #{bag}"
          puts "#{ui.color(msg, :cyan)}"
          `knife data bag create #{bag}`
        end
        msg = "Uploading data bag item #{item} in #{bag}"
        puts "#{ui.color(msg, :cyan)}"
        `knife data bag from file #{bag} #{item}`
      end

      # Create environments
      env_glob = File.expand_path("./environments") + "/*.rb"
      Dir.glob(env_glob) do |f|
        msg = "Uploading environment #{f}"
        puts "#{ui.color(msg, :cyan)}"
        `knife environment from file #{File.basename(f)}`
      end
      
      puts "#{ui.color("Finishing hatching and restarting chef-client", :cyan)}"
      Net::SSH.start(ssh_address, config[:ssh_user], :keys => [config[:identity_file]]) do |ssh|
        ssh.exec! "cd /tmp/chef-hatch && sudo rake hatch:finish['#{bootstrap.config[:chef_node_name]}','#{config[:run_list].join(' ')}','#{config[:environment]}']"
        ssh.exec! "sudo /etc/init.d/chef-client restart"
      end
      
      puts "#{ui.color("Removing temporary directory", :cyan)}"
      FileUtils.rm_rf temp_dir
      FileUtils.rm_rf tar_file_path
    end
   
    def locate_config_value(key)
      key = key.to_sym
      Chef::Config[:knife][key] || config[key]
    end
   
    def vpc_mode?
      # Amazon Virtual Private Cloud requires a subnet_id. If
      # present, do a few things differently
      !!config[:subnet_id]
    end
    
    def setup_knife_config(server, ssh_address)
      cwd = File.expand_path('./')
      conf = <<-END_CONF
        log_level                :info
        log_location             STDOUT
        node_name                'hatch'
        client_key               '#{cwd}/.chef/hatch.pem'
        validation_client_name   'chef-validator'
        validation_key           '#{cwd}/.chef/validation.pem'
        chef_server_url          'http://#{ssh_address}:4000'
        cache_type               'BasicFile'
        cache_options( :path => '#{cwd}/.chef/checksums' )
        cookbook_path [ '#{cwd}/cookbooks' ]
        knife[:aws_access_key_id]     = "#{locate_config_value(:aws_access_key_id)}"
        knife[:aws_secret_access_key] = "#{locate_config_value(:aws_secret_access_key)}"
      END_CONF
      config_file = File.new("#{cwd}/.chef/knife.rb", "w")
      config_file.write(conf)
      config_file.close
    end

    def set_public_ip(connection, server, forced_ip)
      ip = forced_ip || connection.describe_addresses.body["addressesSet"].find_all{|x| x["instanceId"] == nil }.map{ |x| x["publicIp"] }[0] || connection.allocate_address.body
      connection.associate_address(server.id, ip).body
      return ip
    end

  end
end
