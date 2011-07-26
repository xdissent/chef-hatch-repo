#
# Cookbook Name:: dbag
# Recipe:: default
#
# Copyright 2011, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

dbags = data_bag("dbag")
dbags.each do |did|
  db = data_bag_item("dbag", did)
  Chef::Log.info "Found dbag: #{did} and he hates #{db['hates']}"
end
