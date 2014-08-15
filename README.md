DevOps Server
=============

A one-stop built-it-yourself server for managing an engineering project.
Storage is managed using block storage (e.g. EBS) and snapshots are taken on a regular basis.

Can install the following:
* Atlassian JIRA
* Atlassian Stash
* Chef
* Jenkins CI

The following provisioning software/clouds are supported:
* Vagrant
* Amazon Web Services
* Microsoft Azure (storage not yet supported)

Dependencies
============
* Ruby
* Berkshelf (http://berkshelf.com)

ATTENTION: Manual hack needed
======================
The chef omnibus installer doesn't currently have a version for Ubuntu 14.04, but the 12.04 version
seems to work just fine. To make this work, you'll need to modify ~/.berkshelf/cookbooks/chef-server-2.1.6/libraries/omnitruck_client.rb:
    Change
        url << "&pv=#{platform_version}"
    to
        url << "&pv=12.10"

Creating a Dev/Ops server with Vagrant
======================================
Pre-requisites:
    $ sudo vagrant plugin install vagrant-berkshelf --plugin-version 2.0.1

Run the following:
    $ vagrant up

Creating a Dev/Ops Server on Amazon
===================================
* Make sure you have an access key and secret access key in AWS with the following permissions:
    AmazonEC2FullAccess
    AmazonRoute53FullAccess
    AmazonS3FullAccess
    CloudFormation (there isn't a policy for this, so create a custom policy with full access to CloudFormation)
    IAMFullAccess (you may want a restricted set of permissions, but the CloudFormation template will create an IAM user just for the stack)
* Customize any values you want from aws/config.rb and save it as aws/config.local.rb
* Make sure you have the following settings in your knife.rb
    knife[:aws_access_key_id]
    knife[:aws_secret_access_key]
* You need to create a Route53 zone (this cannot be automated) called @stack_name.@domain_root
* Finally, run the following
    $ sudo gem install bundler
    $ sudo bundle install
    $ (cd aws && rake )

=====================================
    $ berks vendor -b Berksfile chef-repo/cookbooks
    $ BERKSHELF_PATH=chef-repo berks install -b Berksfile
    $ BERKSHELF_PATH=chef-repo berks install -b chef-repo/cookbooks/jira/Berksfile
    $ BERKSHELF_PATH=chef-repo berks install -b chef-repo/cookbooks/mysql-backup/Berksfile
    $ BERKSHELF_PATH=chef-repo berks install -b chef-repo/cookbooks/reverse-proxy/Berksfile
    $ BERKSHELF_PATH=chef-repo berks install -b chef-repo/cookbooks/stash/Berksfile
    $ BERKSHELF_PATH=chef-repo berks install -b chef-repo/cookbooks/storage/Berksfile
