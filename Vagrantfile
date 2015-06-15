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

    config.nfs.map_uid=0
    config.nfs.map_gid=0
    config.vm.synced_folder   "./cache/apt/archives", "/var/cache/apt/archives", type: "nfs"
    config.vm.synced_folder   "./cache/install", "/var/cache/install", type: "nfs"
    config.vm.synced_folder   "./cache/chef", "/var/chef/cache", type: "nfs"
    config.vm.synced_folder   "./storage", "/mnt/storage", type: "nfs", map_uid: 0, map_gid: 0
    config.vm.post_up_message = "DevOps server is running - now add host entries for jira, stash, jenkins, and chef to /etc/hosts"

    config.vm.provision 'chef_zero' do |chef|
        chef.log_level = :debug
        chef.cookbooks_path = "chef-repo/cookbooks"
        chef.roles_path = "chef-repo/roles"
        chef.add_role 'developer'
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
                    :bamboo => {
                        :node_name => 'bamboo.local.kwaaioak.com',
                        :port => 8085
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
                    :certificate_chain_file => '/mnt/storage/ssl/local.kwaaioak.com/server.crt',
                    :certificate => {
                        :common_name => '*.local.kwaaioak.com'
                    }
                }
            },
            :storage => {
                :mount_path           => '/mnt/storage',
                :bind_dirs                 => [
                    '/var/lib/stash',
                    '/var/lib/git',
                    '/var/lib/jenkins',
                    '/var/lib/jira',
                    '/var/lib/bamboo',
                    '/var/opt/opscode'
                ]
            },
            :apache => {
                :version              => "2.4",
                :listen_ports         => %w[80]
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
            :bamboo => {
                :node_name                => 'bamboo.local.kwaaioak.com',
                :install_root             => '/mnt/storage',
                :home                     => '/mnt/storage/bamboo'
            },
            :'chef-server' => {
                :'api_fqdn' => 'chef.local.kwaaioak.com',
                :configuration => {
                    :nginx => {
                        :enable_non_ssl     => true,
                        :non_ssl_port       => 8083,
                        :ssl_port           => 4433
                    },
                    :'opscode-erchef' => {
                        :base_resource_url  => 'https://chef.local.kwaaioak.com'
                    },
                    :bookshelf => {
                        :external_url       => 'https://chef.local.kwaaioak.com'
                    }
                }
            }
        }

    end
end

# -*- mode: ruby -*-
# vi: set ft=ruby :
