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

directory File.dirname(node['reverse-proxy']['ssl']['certificate_key_file']) do
    owner 'www-data'
    group 'www-data'
    recursive true
end

directory File.dirname(node['reverse-proxy']['ssl']['certificate_file']) do
    owner 'www-data'
    group 'www-data'
    recursive true
end

ssl_certificate node['reverse-proxy']['ssl']['certificate']['common_name'] do
    namespace node['reverse-proxy']['ssl']['certificate']
    key_path  node['reverse-proxy']['ssl']['certificate_key_file']
    cert_path node['reverse-proxy']['ssl']['certificate_file']
    notifies :restart, "service[apache2]"
end

web_app "proxy_ssl" do
    template "proxy_ssl.conf.erb"
    only_if { node['reverse-proxy']['enable-ssl'] }
end
