name "chef_server"
description "A Chef server"

run_list(
    "role[chef_client]",
    "recipe[chef-server::rubygems-install]",
    "recipe[chef-server]"
)