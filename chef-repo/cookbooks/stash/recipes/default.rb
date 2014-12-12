#
# Cookbook Name:: stash
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
# Database configuration
#
include_recipe "database::mysql"

mysql_admin_connection_info = {
  :host     => node['stash']['mysql']['host'],
  :username => node['stash']['mysql']['admin_username'],
  :password => node['stash']['mysql']['admin_password']
}

mysql_database node['stash']['mysql']['dbname'] do
  connection mysql_admin_connection_info
  collation 'utf8_bin'
  encoding 'utf8'
  action :create
end

mysql_database_user node['stash']['mysql']['app_username'] do
  connection    mysql_admin_connection_info
  password      node['stash']['mysql']['app_password']
  database_name node['stash']['mysql']['dbname']
  host          'localhost'
  privileges    [:all]
  action        :grant
end

#
# Stash application configuration
#
directory "#{node['stash']['home']}/shared" do
  owner "root"
  group "root"
  mode 0750
  recursive true
  action :create
end

template "#{node['stash']['home']}/shared/stash-config.properties" do
	source "stash-config.properties.erb"
	mode 0664
	variables({
    	:db_name => node['stash']['mysql']['dbname'],
    	:db_username => node['stash']['mysql']['app_username'],
    	:db_password => node['stash']['mysql']['app_password'],
	})
end

ark 'stash' do
    url "http://www.atlassian.com/software/stash/downloads/binary/atlassian-stash-#{node['stash']['revision']}.tar.gz"
end

## Configure maximum and minimum memory
## sed -i 's!\(JVM_MINIMUM_MEMORY="\).*\(m"\)!\1'$STASH_MINIMUM_MEMORY'\2!g' /opt/atlassian/stash/bin/setenv.sh
## sed -i 's!\(JVM_MAXIMUM_MEMORY="\).*\(m"\)!\1'$STASH_MAXIMUM_MEMORY'\2!g' /opt/atlassian/stash/bin/setenv.sh

ark 'mysql-connector' do
    url 'http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.30.tar.gz'
    #path '/usr/local/stash/lib'
    #creates 'mysql-connector-java-5.1.30/mysql-connector-java-5.1.30-bin.jar'
    #action :cherry_pick
end
link "/usr/local/stash/lib/mysql-connector-java-5.1.30-bin.jar" do
    to "/usr/local/mysql-connector/mysql-connector-java-5.1.30-bin.jar"
end

# Overwrite server.xml, allowing us to support an HTTPS reverse proxy
template "#{node['ark']['prefix_root']}/stash/conf/server.xml" do
  source "server.xml.erb"
  mode 0664
  variables({
    :node_name => node['stash']['node_name'],
    :port      => node['stash']['port'],
    :ssl_port  => node['stash']['ssl_port']
  })
end

#
# Add the self-signed cert (if there is one) to the JIRA keystore
#
if node.attribute?('jira') and node.attribute?('reverse-proxy') and node['reverse-proxy']['ssl']['enabled'] then
    execute "import-stash-cert" do
        command "$JAVA_HOME/bin/keytool -noprompt -storepass changeit -import -alias #{node['jira']['node_name']} -keystore $JAVA_HOME/lib/security/cacerts -file #{node['reverse-proxy']['ssl']['certificate_file']}"
        environment ({
            "JAVA_HOME" => "/usr/lib/jvm/java-7-openjdk-amd64/jre"
        })

        not_if "export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/jre; $JAVA_HOME/bin/keytool -list -storepass changeit -keystore $JAVA_HOME/lib/security/cacerts -alias #{node['jira']['node_name']}"
    end
end

# Recent versions (3.5.0) of Stash have an embedded non-ASCII character
# Chef::Util::FileEdit can't handle this, so we need to strip them out
# See https://jira.atlassian.com/browse/STASH-6885
execute "Remove non-ASCII characters from Stash setenv.sh" do
    command "sed -i 's/\xA0/ /g' #{node['ark']['prefix_root']}/stash/bin/setenv.sh"
end

ruby_block "Disable Java SSE extensions" do
    block do
        fe = Chef::Util::FileEdit.new("#{node['ark']['prefix_root']}/stash/bin/setenv.sh")
        fe.search_file_replace_line(
            /^JVM_SUPPORT_RECOMMENDED_ARGS=/,
            "JVM_SUPPORT_RECOMMENDED_ARGS=\"#{node['stash']['jvm']['extra_args']}\"")
        fe.write_file
    end
end

#
# Daemon/service configuration
#

template "/etc/init.d/stash" do
	source "stash.initd.erb"
	mode 0755
	variables({
    	:install_dir => "#{node['ark']['prefix_root']}/stash",
    	:home_dir    => node['stash']['home']
	})
end

service 'stash' do
  supports :start => true, :stop => true, :restart => true
  init_command "/etc/init.d/stash"
  action [ :enable, :start ]
end
