#
# Cookbook Name:: storage
# Recipe:: default
#
# Copyright 2014 Kwaai Oak, Inc.
#
# All rights reserved - Do Not Redistribute
#

require 'fileutils'

include_recipe 'aws'

directory node['storage']['mount_path'] do
  mode 0755
  action :create
end

#
# Attach the storage device
#
if node['storage']['mount_type'] == 'aws_ebs'
  include_recipe 'xfs'

  aws_ebs_volume "storage_volume" do
    aws_access_key node['storage']['aws']['access_key']
    aws_secret_access_key node['storage']['aws']['secret_access_key']
    device node['storage']['mount_device']
    volume_id node['storage']['aws']['volume_id']

    action :attach
  end

  ruby_block "wait_for_ebs_volume" do
    block do
      timeout = 0
      until File.blockdev?(node['storage']['mount_device']) || timeout == 1000
        Chef::Log.debug("Device #{node['storage']['mount_device']} not ready - sleeping 10s")
        timeout += 10
        sleep 10
      end
    end
  end

  execute "mkfs.xfs #{node['storage']['mount_device']}" do
    only_if "xfs_admin -l #{node['storage']['mount_device']} 2>&1 | grep -qx 'xfs_admin: #{node['storage']['mount_device']} is not a valid XFS filesystem (unexpected SB magic number 0x00000000)'"
  end

  mount node['storage']['mount_path'] do
    device node['storage']['mount_device']
    fstype "xfs"
    action [ :mount, :enable ]
  end  
end

#
# Bind mount directories that need permanent storage
#
node['storage']['bind_dirs'].each do |dir|
  dest = File.basename(dir)

  ruby_block "copy source directory" do
    block do
      FileUtils.cp_r(dir, "#{node['storage']['mount_path']}/#{dest}")
      FileUtils.rm_rf(dir)
    end
    
    only_if { File.directory?(dir) }
    not_if { File.directory?("#{node['storage']['mount_path']}/#{dest}") }
  end

  # Make sure both the source and destination directories exist  
  directory "#{node['storage']['mount_path']}/#{dest}"
  directory dir

  mount dir do
    device "#{node['storage']['mount_path']}/#{dest}"
    fstype "none"
    options "bind,rw"
    action [ :mount, :enable ]
  end
end

#
# Symlink directories that need permanent storage
#
node['storage']['dirs'].each do |dir|
  dest = File.basename(dir)
  
  ruby_block "copy source directory" do
    block do
      FileUtils.cp_r(dir, "#{node['storage']['mount_path']}/#{dest}")
      FileUtils.rm_rf(dir)
    end
    
    only_if { File.directory?(dir) }
    not_if { File.directory?("#{node['storage']['mount_path']}/#{dest}") }
  end
  
  directory "#{node['storage']['mount_path']}/#{dest}"

  link dir do
    to "#{node['storage']['mount_path']}/#{dest}"
  end
end

#
# Backup scheduler
#
if node['storage']['mount_type'] == 'aws_ebs'
  template '/etc/chef/snapshot.json' do
    source 'snapshot.json.erb'
    variables(
      :output => {
        'storage' => {
          'aws' => {
            'access_key' => node['storage']['aws']['access_key'],
            'secret_access_key' => node['storage']['aws']['secret_access_key'],
            'volume_id' => node['storage']['aws']['volume_id']
          },
          'snapshots_to_keep' => '7',
          'mount_device' => node['storage']['mount_device'],
          'description' => node['storage']['description']
        },
        'run_list' => [
          'recipe[storage::snapshot]'
        ]
      }
    )
    owner 'root'
    group 'root'
    mode 0600
  end

  template '/etc/cron.d/snapshot' do
    source 'cron.d.erb'
    variables(
      :json_attribs => '/etc/chef/snapshot.json',
      :schedule => node['storage']['backup']['schedule'],
      :log_level => 'info',
      :log_file => '/var/log/snapshot.log'
    )
    owner 'root'
    group 'root'
    mode 0600
  end

  #
  # Create an initial snapshot
  #
  include_recipe "storage::snapshot"
end
