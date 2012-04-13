bash -c '

version=`lsb_release -r -s`
eval major=${version/./ minor=}

if [ ! -f /usr/bin/chef-client ]; then
  apt-get update
  apt-get install -y ruby ruby1.8-dev build-essential wget
  if [ ${major} -lt 12 ]; then
    apt-get install -y libruby-extras libruby1.8-extras
  fi
  cd /tmp
  wget http://production.cf.rubygems.org/rubygems/rubygems-1.6.2.tgz
  tar zxf rubygems-1.6.2.tgz
  cd rubygems-1.6.2
  ruby setup.rb --no-format-executable

  gem update --no-rdoc --no-ri
  gem install ohai --no-rdoc --no-ri --verbose
  gem install chef --no-rdoc --no-ri --verbose --version 0.10.8
  gem install rake --no-rdoc --no-ri --verbose
fi

mkdir -p /etc/chef'
