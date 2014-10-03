#
# Cookbook Name:: reverse-proxy
# Recipe:: web_app_proxy
#
# Copyright 2014 Kwaai Oak, Inc.
#
# All rights reserved - Do Not Redistribute
#

include_recipe "apache2::mod_proxy"
include_recipe "apache2::mod_proxy_http"

node['reverse-proxy']['apps'].each do |name, app|
  web_app name do
    server_name app.node_name
    server_port app.port
    force_ssl   app.attribute?('force_ssl') ? app.force_ssl : false
  end
end
