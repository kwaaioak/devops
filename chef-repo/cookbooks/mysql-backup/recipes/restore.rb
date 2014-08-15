#
# Cookbook Name:: mysql-backup
# Recipe:: restore
#
# Copyright 2014 Kwaai Oak, Inc.
#
# All rights reserved - Do Not Redistribute
#

directory node['mysql-backup']['data_dir'] do
  mode 0755
  action :create
end

execute "mysql restore" do
  command "gzip -c -d #{node['mysql-backup']['backup_file']} | mysql --user=#{node['mysql-backup']['mysql_user']} --password=#{node['mysql-backup']['mysql_password']} && mysql --user=#{node['mysql-backup']['mysql_user']} --password=#{node['mysql-backup']['mysql_password']} -e 'flush privileges;' && touch #{node['mysql-backup']['data_dir']}/mysql-backup-restored-stamp"
  only_if { File.exists?("#{node['mysql-backup']['backup_file']}") }
  not_if { File.exists?("#{node['mysql-backup']['data_dir']}/mysql-backup-restored-stamp") }
end
