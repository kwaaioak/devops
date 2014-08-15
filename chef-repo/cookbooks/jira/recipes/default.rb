#
# Cookbook Name:: jira
# Recipe:: default
#
# Copyright 2014 Kwaai Oak, Inc.
#
# All rights reserved - Do Not Redistribute
#

# Workaround for
# /usr/lib/ruby/1.9.1/rubygems/custom_require.rb:36:in `require': cannot load such file -- mkmf (LoadError)
if platform_family?('debian')
  package "ruby-dev" do
    action :install
  end
end

#
# Database configuration
#
include_recipe "database::mysql"

mysql_admin_connection_info = {
  :host     => node['jira']['mysql']['host'],
  :username => node['jira']['mysql']['admin_username'],
  :password => node['jira']['mysql']['admin_password']
}

mysql_database node['jira']['mysql']['dbname'] do
  connection mysql_admin_connection_info
  collation 'utf8_bin'
  encoding 'utf8'
  action :create
end

mysql_database_user node['jira']['mysql']['app_username'] do
  connection    mysql_admin_connection_info
  password      node['jira']['mysql']['app_password']
  database_name node['jira']['mysql']['dbname']
  host          'localhost'
  privileges    [:all]
  action        :grant
end

#
# JIRA application configuration
#
remote_file "#{node['jira']['install_cache']}/atlassian-jira-#{node['jira']['revision']}-x64.bin" do
  source "http://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-#{node['jira']['revision']}-x64.bin"
  mode 0555
  not_if { File.directory?("#{node['jira']['prefix_dir']}/jira") } 
  action :create_if_missing
end

user node['jira']['user'] do
  uid 2001
  shell "/bin/false"
  home "/home/#{node['jira']['user']}"
  supports :manage_home => true
  action :create
end

directory "/home/#{node['jira']['user']}" do
  owner node['jira']['user']
  mode 0755
end

directory node['jira']['home'] do
  owner node['jira']['user']
  mode 0755
end

directory "#{node['jira']['prefix_dir']}/jira" do
  owner node['jira']['user']
  mode 0755
end

template "#{node['jira']['home']}/dbconfig.xml" do
  source "dbconfig.xml.erb"
  mode 0664
  owner node['jira']['user']
  variables({
    :db_name => node['jira']['mysql']['dbname'],
    :db_username => node['jira']['mysql']['app_username'],
    :db_password => node['jira']['mysql']['app_password'],
  })
end

template "#{node['jira']['install_cache']}/response.varfile" do
  source "response.varfile.erb"
  mode 0660
  owner node['jira']['user']
  variables({
    :install_dir => "#{node['jira']['prefix_dir']}/jira",
    :jira_home => node['jira']['home'],
    :user_dir => "/home/#{node['jira']['user']}"
  })
end

ark 'mysql-connector' do
  url 'http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.30.tar.gz'
end
directory "#{node['jira']['prefix_dir']}/jira/lib" do
  owner node['jira']['user']
  mode 0755
end
link "#{node['jira']['prefix_dir']}/jira/lib/mysql-connector-java-5.1.30-bin.jar" do
  to "#{node['ark']['prefix_root']}/mysql-connector/mysql-connector-java-5.1.30-bin.jar"
end

execute "jira install" do
  user node['jira']['user']
  command "#{node['jira']['install_cache']}/atlassian-jira-#{node['jira']['revision']}-x64.bin -q -varfile #{node['jira']['install_cache']}/response.varfile"
  not_if { ::File.exists?("#{node['jira']['prefix_dir']}/jira/README.txt") }
end

#
# Daemon/service configuration
#
template "/etc/init.d/jira" do
  source "init.d.erb"
  mode 0755
  variables({
    :install_dir => "#{node['jira']['prefix_dir']}/jira",
    :run_user    => node['jira']['user']
  })
end

service 'jira' do
  supports :start => true, :stop => true
  init_command "service jira"
  action [ :enable ]
end
