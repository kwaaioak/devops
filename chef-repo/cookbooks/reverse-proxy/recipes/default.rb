#
# Cookbook Name:: reverse-proxy
# Recipe:: default
#
# Copyright 2014 Kwaai Oak, Inc.
#
# All rights reserved - Do Not Redistribute
#

include_recipe "reverse-proxy::web_app_proxy"
include_recipe "reverse-proxy::ssl_proxy"
