#
# Cookbook Name:: linter
# Recipe:: rbenv
#

# FIXME: this has been problematic, although it's not a good idea to
# use the embedded version of Ruby. It ends up not finding the right
# version of Ruby the first time, and does the second time, but
# the run of passenger-install-apache2-module does not get triggered,
# as it should form passenger::source. As a result the mod_passenger.so
# is never built
include_recipe "rbenv::default"
include_recipe "rbenv::ruby_build"

# Create temporary directory, used in imontor version of rbenv.sh.erb
directory "#{node[:rbenv][:root]}/tmp" do
  owner node[:rbenv][:user]
  group node[:rbenv][:group]
  mode "0775"
end

# Use our version of rbenv.sh
begin
  r = resources(:template => "/etc/profile.d/rbenv.sh")
  r.cookbook "linter"
rescue Chef::Exceptions::ResourceNotFound
  Chef::Log.warn "could not find template to override!"
end

rbenv_ruby node[:linter][:ruby_version] do
  global true
end
rbenv_gem "bundler" do
  gem_binary "#{node[:rbenv][:root]}/shims/gem"
end
