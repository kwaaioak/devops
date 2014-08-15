#
# Cookbook Name:: mysql-backup
# Recipe:: default
#
# Copyright 2014 Kwaai Oak, Inc.
#
# All rights reserved - Do Not Redistribute
#

directory File.dirname(node['mysql-backup']['backup_file']) do
  mode 0755
  action :create
end

template '/etc/cron.d/mysql-backup' do
  source 'cron.d.erb'
  variables(
    :schedule => node['mysql-backup']['schedule'],
    :backup_file => node['mysql-backup']['backup_file'],
    :mysql_user => node['mysql-backup']['mysql_user'],
    :mysql_password => node['mysql-backup']['mysql_password'],
    :log_file => '/var/log/mysql-backup.log'
  )
  owner 'root'
  group 'root'
  mode 0600
end

template '/etc/init/mysql-backup.conf' do
  source 'upstart.conf.erb'
  variables(
    :backup_file => node['mysql-backup']['backup_file'],
    :mysql_user => node['mysql-backup']['mysql_user'],
    :mysql_password => node['mysql-backup']['mysql_password'],
    :log_file => '/var/log/mysql-backup.log'
  )
  owner 'root'
  group 'root'
  mode 0600
end
