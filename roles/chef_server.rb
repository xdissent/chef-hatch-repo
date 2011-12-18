name "chef_server"
description "A Chef server"

run_list(
    "role[chef_client]",
    "recipe[chef-server::rubygems-install]",
    "recipe[chef-server]"
)

default_attributes({
  :chef_server => {
    :webui_enabled => true
  },
  :chef_client => {
    :server_url => "http://127.0.0.1:4000"
  }
})
