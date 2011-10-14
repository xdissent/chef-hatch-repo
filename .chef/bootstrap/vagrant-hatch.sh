bash -c '
if [ ! -f /usr/bin/chef-client ]; then
  apt-get update
  apt-get install -y ruby ruby1.8-dev build-essential wget libruby-extras libruby1.8-extras git-core
  cd /tmp
  wget http://production.cf.rubygems.org/rubygems/rubygems-1.3.7.tgz
  tar zxf rubygems-1.3.7.tgz
  cd rubygems-1.3.7
  ruby setup.rb --no-format-executable

  gem install rake --no-rdoc --no-ri --verbose
  gem install ohai --no-rdoc --no-ri --verbose

  cd /tmp
  git clone git://github.com/opscode/chef.git
  cd chef/chef
  rake install
fi

mkdir -p /etc/chef'
