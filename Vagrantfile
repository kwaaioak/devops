# encoding: utf-8

Vagrant.configure("2") do |config|

  config.vm.provider "virtualbox" do |v|
    v.name = "devops"
    v.memory = 8196
    v.cpus = 4
  end

  config.vm.box = "ubuntu/trusty64"
  config.ssh.forward_agent = true

  config.vm.network "private_network", ip: "10.11.12.17"

  config.berkshelf.enabled = true
  config.nfs.map_uid=0
  config.nfs.map_gid=0
  config.vm.synced_folder   "./cache/apt/archives", "/var/cache/apt/archives", type: "nfs", nfs: true
  config.vm.synced_folder   "./cache/install", "/var/cache/install", type: "nfs", nfs: true
  config.vm.synced_folder   "./cache/chef", "/var/chef/cache", type: "nfs", nfs: true
  config.vm.synced_folder   "./storage", "/mnt/storage", type: "nfs", nfs: true, map_uid: 0, map_gid: 0
  config.vm.post_up_message = "DevOps server is running - now add host entries for jira, stash, jenkins, and chef to /etc/hosts"

  config.vm.provision :chef_solo do |chef|
    chef.log_level = :debug
    chef.cookbooks_path = "chef-repo/cookbooks"
    chef.add_recipe 'apt'
    chef.add_recipe 'storage'
    chef.add_recipe 'postfix'
    chef.add_recipe 'mysql::server'
    chef.add_recipe 'mysql-backup'
    chef.add_recipe 'mysql-backup::restore'
    chef.add_recipe 'apache2'
    chef.add_recipe 'reverse-proxy'
    chef.add_recipe 'jira'
    chef.add_recipe 'stash'
    chef.add_recipe 'chef-server'
    chef.add_recipe 'jenkins::master'
    chef.json = {
      :'reverse-proxy' => {
        :apps => {
            :jira => {
                :node_name => 'jira.local.kwaaioak.com',
                :port => 8080
            },
            :stash => {
                :node_name => 'stash.local.kwaaioak.com',
                :port => 7990
            },
            :jenkins => {
                :node_name => 'jenkins.local.kwaaioak.com',
                :port => 8090,
                :force_ssl => true
            },
            :chef => {
                :node_name => 'chef.local.kwaaioak.com',
                :port => 8083,
                :force_ssl => false
            }
        },
        :ssl => {
            :enabled => true,
            :certificate_file => '/mnt/storage/ssl/local.kwaaioak.com/server.crt',
            :certificate_key_file => '/mnt/storage/ssl/local.kwaaioak.com/server.key',
            :certificate_chain_file => '/mnt/storage/ssl/local.kwaaioak.com/server.crt'
        }
      },
      :storage => {
        :mount_path           => '/mnt/storage',
        :dirs                 => [ '/var/lib/stash', '/var/lib/git', '/var/lib/jenkins', '/var/lib/jira' ]
      },
      :apache => {
        :version              => "2.4",
        :listen_ports         => %w[80, 8081]
      },
      :mysql  => {
        :server_root_password   => "password",
        :server_repl_password   => "password",
        :server_debian_password => "password",
        :bind_address           => "0.0.0.0",
        :root_network_acl       => [ "0.0.0.0/32" ],
        :allow_remote_root      => true,
        :template_source        => 'my.cnf.erb',
        :data_dir               => '/var/lib/mysql'
      },
      :'mysql-backup' => {
        :mysql_user             => "root",
        :mysql_password         => "password",
        :backup_file            => '/mnt/storage/mysql/mysql-backup.sql.gz'
      },
      :java => {
        :jdk_version            => '7'
      },
      :jira => {
        :install_cache          => '/var/cache/install'
      },
      :stash => {
        :home                   => '/mnt/storage/stash'
      },
      :jenkins => {
        :master => {
          :install_method       => 'package',
          :port                 => '8090'
        }
      },
      :'chef-server' => {
        :configuration => {
          :nginx => {
            :non_ssl_port       => 8083,
            :ssl_port           => 4433
          },
          :rabbitmq => {
            :data_dir           => '/mnt/storage/chef-server/rabbitmq/data'
          },
          :'chef-solr' => {
            :data_dir           => '/mnt/storage/chef-server/chef-solr/data'
          },
          :bookshelf => {
            :data_dir           => '/mnt/storage/chef-server/bookshelf/data'
          },
          :postgresql => {
            :data_dir           => '/mnt/storage/chef-server/postgresql/data'
          }
        }
      }
    }
  end

end

# -*- mode: ruby -*-
# vi: set ft=ruby :
