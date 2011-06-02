name "base_example"
description "Example base role applied to all nodes."

run_list(
    "recipe[chef-client]",
    "recipe[chef-server::rubygems-install]",
    "recipe[chef-server]"
)