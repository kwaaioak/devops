#
# Cookbook Name:: bamboo
# Recipe:: default
#
# Copyright 2014 Kwaai Oak, Inc.
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'java'
include_recipe 'git'

# Workaround for
# /usr/lib/ruby/1.9.1/rubygems/custom_require.rb:36:in `require': cannot load such file -- mkmf (LoadError)
if platform_family?('debian')
    package "ruby-dev" do
        action :install
    end
end

#
# User configuration
#
user "bamboo" do
    home node['bamboo']['home']
end

#
# Database configuration
#
include_recipe "database::mysql"

mysql_admin_connection_info = {
  :host     => node['bamboo']['mysql']['host'],
  :username => node['bamboo']['mysql']['admin_username'],
  :password => node['bamboo']['mysql']['admin_password']
}

mysql_database node['bamboo']['mysql']['dbname'] do
  connection mysql_admin_connection_info
  collation 'utf8_bin'
  encoding 'utf8'
  action :create
end

mysql_database_user node['bamboo']['mysql']['app_username'] do
  connection    mysql_admin_connection_info
  password      node['bamboo']['mysql']['app_password']
  database_name node['bamboo']['mysql']['dbname']
  host          'localhost'
  privileges    [:all]
  action        :grant
end

#
# Bamboo application configuration
#
directory "#{node['bamboo']['home']}/logs" do
  owner "bamboo"
  group "bamboo"
  mode 0750
  action :create
end

ark 'bamboo' do
    url "http://www.atlassian.com/software/bamboo/downloads/binary/atlassian-bamboo-#{node['bamboo']['revision']}.tar.gz"
end

template "#{node['ark']['prefix_root']}/bamboo/atlassian-bamboo/WEB-INF/classes/bamboo-init.properties" do
	source "bamboo-init.properties.erb"
	mode 0664
	variables({
	    :home_dir => node['bamboo']['home']
	})
end

template "#{node['bamboo']['home']}/bamboo.cfg.xml" do
	source "bamboo.cfg.xml.erb"
	mode 0664
	variables({
    	:db_name => node['bamboo']['mysql']['dbname'],
    	:db_username => node['bamboo']['mysql']['app_username'],
    	:db_password => node['bamboo']['mysql']['app_password'],
    	:server_id => node['bamboo']['server_id'],
    	:license_string => node['bamboo']['license_string'],
	})
end

## Configure maximum and minimum memory
## sed -i 's!\(JVM_MINIMUM_MEMORY="\).*\(m"\)!\1'$STASH_MINIMUM_MEMORY'\2!g' /opt/atlassian/stash/bin/setenv.sh
## sed -i 's!\(JVM_MAXIMUM_MEMORY="\).*\(m"\)!\1'$STASH_MAXIMUM_MEMORY'\2!g' /opt/atlassian/stash/bin/setenv.sh

ark 'mysql-connector' do
    url 'http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.30.tar.gz'
end
link "#{node['ark']['prefix_root']}/bamboo/lib/mysql-connector-java-5.1.30-bin.jar" do
    to "/usr/local/mysql-connector/mysql-connector-java-5.1.30-bin.jar"
end

# Overwrite server.xml, allowing us to support an HTTPS reverse proxy
template "#{node['ark']['prefix_root']}/bamboo/conf/server.xml" do
  source "server.xml.erb"
  mode 0664
  variables({
    :node_name => node['bamboo']['node_name'],
    :port      => node['bamboo']['port'],
    :ssl_port  => node['bamboo']['ssl_port']
  })
end

#
# Add the self-signed cert (if there is one) to the JIRA keystore
#
if node.attribute?('jira') and node['jira']['node_name'] and node.attribute?('reverse-proxy') and node['reverse-proxy']['ssl']['enabled'] then
    execute "import-bamboo-cert" do
        command "$JAVA_HOME/bin/keytool -noprompt -storepass changeit -import -alias #{node['jira']['node_name']} -keystore $JAVA_HOME/lib/security/cacerts -file #{node['reverse-proxy']['ssl']['certificate_file']}"
        environment ({
            "JAVA_HOME" => "/usr/lib/jvm/java-7-openjdk-amd64/jre"
        })

        not_if "export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/jre; $JAVA_HOME/bin/keytool -list -storepass changeit -keystore $JAVA_HOME/lib/security/cacerts -alias #{node['jira']['node_name']}"
    end
end

ruby_block "Disable Java SSE extensions" do
    block do
        fe = Chef::Util::FileEdit.new("#{node['ark']['prefix_root']}/bamboo/bin/setenv.sh")
        fe.search_file_replace_line(
            /^JVM_SUPPORT_RECOMMENDED_ARGS=/,
            "JVM_SUPPORT_RECOMMENDED_ARGS=\"#{node['bamboo']['jvm']['extra_args']}\"")
        fe.write_file
    end
end

ruby_block "Set Bamboo catalina.out" do
    block do
        fe = Chef::Util::FileEdit.new("#{node['ark']['prefix_root']}/bamboo/bin/setenv.sh")
        fe.insert_line_if_no_match(
            /^CATALINA_OUT=/,
            "CATALINA_OUT=\"#{node['bamboo']['home']}/logs/catalina.out\"")
        fe.write_file
    end
end

#
# Daemon/service configuration
#

template "/etc/init.d/bamboo" do
	source "bamboo.initd.erb"
	mode 0755
	variables({
    	:install_dir => "#{node['ark']['prefix_root']}/bamboo",
    	:home_dir    => node['bamboo']['home']
	})
end

service 'bamboo' do
  supports :start => true, :stop => true, :restart => true
  init_command "/etc/init.d/bamboo"
  action [ :enable, :start ]
end
