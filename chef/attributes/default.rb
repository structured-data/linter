default[:rails_env] = node.chef_environment.sub("_default", "production")

default[:linter][:user] = "linter"
default[:linter][:group] = "linter"
default[:linter][:name] = "linter"
default[:linter][:repository] = "git://github.com/structured-data/linter.git"
default[:linter][:document_root] = "/var/www/rack-apps/linter"

default[:linter][:ruby_version] = "2.0.0-p353"
