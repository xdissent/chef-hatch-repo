name "chef_server"
description "A Chef server"

run_list(
    "role[chef_client]",
    "recipe[build-essential]",
    "recipe[chef-server::rubygems-install]",
    "recipe[chef-server]"
)

default_attributes({
  :chef_server => {
    :webui_enabled => true
  }
})