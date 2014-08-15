#
# Cookbook Name:: reverse-proxy
# Recipe:: ssl_proxy
#
# Copyright 2014 Kwaai Oak, Inc.
#
# All rights reserved - Do Not Redistribute
#

include_recipe "apache2::mod_ssl"
include_recipe "apache2::mod_proxy"
include_recipe "apache2::mod_proxy_http"

web_app "proxy_ssl" do
  template "proxy_ssl.conf.erb"
  only_if { node['reverse-proxy']['enable-ssl'] }
end
