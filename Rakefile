#
# Rakefile for Chef Server Repository
#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'rubygems'
require 'chef'
require 'json'

# Load constants from rake config file.
require File.join(File.dirname(__FILE__), 'config', 'rake')

# Detect the version control system and assign to $vcs. Used by the update
# task in chef_repo.rake (below). The install task calls update, so this
# is run whenever the repo is installed.
#
# Comment out these lines to skip the update.

if File.directory?(File.join(TOPDIR, ".svn"))
  $vcs = :svn
elsif File.directory?(File.join(TOPDIR, ".git"))
  $vcs = :git
end

# Load common, useful tasks from Chef.
# rake -T to see the tasks this loads.

load 'chef/tasks/chef_repo.rake'

desc "Bundle a single cookbook for distribution"
task :bundle_cookbook => [ :metadata ]
task :bundle_cookbook, :cookbook do |t, args|
  tarball_name = "#{args.cookbook}.tar.gz"
  temp_dir = File.join(Dir.tmpdir, "chef-upload-cookbooks")
  temp_cookbook_dir = File.join(temp_dir, args.cookbook)
  tarball_dir = File.join(TOPDIR, "pkgs")
  FileUtils.mkdir_p(tarball_dir)
  FileUtils.mkdir(temp_dir)
  FileUtils.mkdir(temp_cookbook_dir)

  child_folders = [ "cookbooks/#{args.cookbook}", "site-cookbooks/#{args.cookbook}" ]
  child_folders.each do |folder|
    file_path = File.join(TOPDIR, folder, ".")
    FileUtils.cp_r(file_path, temp_cookbook_dir) if File.directory?(file_path)
  end

  system("tar", "-C", temp_dir, "-cvzf", File.join(tarball_dir, tarball_name), "./#{args.cookbook}")

  FileUtils.rm_rf temp_dir
end

namespace :hatch do
  task :init, :client_name do |t, args|
    puts "Registering #{args.client_name}"
    Chef::Config.from_file("/etc/chef/client.rb")
    r = Chef::REST.new(Chef::Config[:registration_url], Chef::Config[:validation_client_name], Chef::Config[:validation_key])
    r.register(args.client_name, "/tmp/#{args.client_name}.pem")
    c = Chef::ApiClient.cdb_load(args.client_name)
    c.admin(true)
    c.cdb_save
    puts "Created #{args.client_name} admin client."
  end
  task :finish do |t, args|
    genes = JSON.parse(File.open("/tmp/chef-hatch-genes.json", 'r') { |f| f.read })
    run_list = genes.run_list.dup
    run_list.delete "recipe[hatch]"
    n = Chef::Node.cdb_load(genes.name)
    n.chef_environment(genes.chef_environment)
    n.run_list.reset!(run_list)
    n.normal_attrs = genes.normal_attrs
    n.cdb_save
    File.delete("/tmp/chef-hatch-genes.json")
  end
end