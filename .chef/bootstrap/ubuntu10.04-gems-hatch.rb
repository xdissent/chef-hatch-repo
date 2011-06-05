bash -c '
<%= "export http_proxy=\"#{knife_config[:bootstrap_proxy]}\"" if knife_config[:bootstrap_proxy] -%>

if [ ! -f /usr/bin/chef-client ]; then
  apt-get update
  apt-get install -y ruby ruby1.8-dev build-essential wget libruby-extras libruby1.8-extras
  cd /tmp
  wget <%= "--proxy=on " if knife_config[:bootstrap_proxy] %>http://production.cf.rubygems.org/rubygems/rubygems-1.6.2.tgz
  tar zxf rubygems-1.6.2.tgz
  cd rubygems-1.6.2
  ruby setup.rb --no-format-executable
fi

gem update --system
gem update
gem install ohai --no-rdoc --no-ri --verbose
gem install chef --no-rdoc --no-ri --verbose <%= bootstrap_version_string %>

mkdir -p /etc/chef

cd /tmp && tar -zxvf chef-hatch.tgz

(
cat <<'EOP'
<%= { "run_list" => @run_list }.to_json %>
EOP
) > /tmp/chef-hatch/dna.json

/usr/bin/chef-solo -c /tmp/chef-hatch/solo.rb -j /tmp/chef-hatch/dna.json'
