#
# Cookbook Name:: storage
# Recipe:: snapshot
#
# Copyright 2014 Kwaai Oak, Inc.
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'aws'
include_recipe 'xfs'

aws_ebs_volume "#{node['storage']['mount_device']}-snapshot" do
  aws_access_key node['storage']['aws']['access_key']
  aws_secret_access_key node['storage']['aws']['secret_access_key']
  device node['storage']['mount_device']
  volume_id node['storage']['aws']['volume_id']
  snapshots_to_keep node['storage']['snapshots_to_keep']
  description "#{node['storage']['description']} - Snapshot Backup"

  action :snapshot
end
