require 'rake/clean'

CONFIG='config.rb'
CONFIG_LOCAL='config.local.rb'

load CONFIG
load CONFIG_LOCAL if File.exist?(CONFIG_LOCAL)

task :'upload-chef-repo' do
    berks_opts="--config=#{@berks_config}" if @berks_config
    sh %{ berks install #{berks_opts} && berks upload #{berks_opts} }

    knife_opts="--config=#{@knife_config}" if @knife_config
    sh %{ cd } + '"' + File.dirname(__FILE__) + '/chef-repo' + '"' + %{ && knife upload #{knife_opts} --chef-repo-path=. . --force }
end

import "aws/Rakefile"

task :upgrade, [ :snapshot_id ] => [ @cloud + ':upgrade' ] do |t, args|
end

task :up, [ :snapshot_id ] => [ @cloud + ':up' ] do |t, args|
end

task :destroy, [ :snapshot_id ] => [ @cloud + ':destroy' ] do |t, args|
end
