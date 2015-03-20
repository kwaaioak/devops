DevOps Server
=============

A one-stop built-it-yourself server for managing an engineering project.
Storage is managed using block storage (e.g. EBS) and snapshots are taken on a regular basis.

Can install the following:
    * Atlassian JIRA
    * Atlassian Stash
    * Atlassian Bamboo
    * Chef
    * Jenkins CI

The following provisioning software/clouds are supported:
    * Vagrant
    * Amazon Web Services
    * Microsoft Azure (storage not yet supported)

Getting Started for First Run
-----------------------------
You'll need to install:

* Vagrant (http://vagrantup.com)
* Virtual Box (http://virtualbox.com)
* ChefDK (https://downloads.chef.io/chef-dk)
    (even though Chef is run inside the VM, the Berkshelf plugin manager requires ChefDK to be installed on the host)

Once installed, run the following to install additional plugins:

```bash
$ vagrant plugin install vagrant-berkshelf
```

Add the following entry to your /etc/hosts file:

    10.11.12.17 jira.local.kwaaioak.com
    10.11.12.17 stash.local.kwaaioak.com
    10.11.12.17 bamboo.local.kwaaioak.com
    10.11.12.17 jenkins.local.kwaaioak.com
    10.11.12.17 chef.local.kwaaioak.com

ATTENTION: Manual hack needed
======================
The chef omnibus installer doesn't currently have a version for Ubuntu 14.04, but the 12.04 version
seems to work just fine. To make this work, you'll need to modify ~/.berkshelf/cookbooks/chef-server-2.1.6/libraries/omnitruck_client.rb:

```
    Change
        url << "&pv=#{platform_version}"
    to
        url << "&pv=12.10"
```

Creating a DevOps server with Vagrant
======================================
Pre-requisites:
```bash
    $ sudo vagrant plugin install vagrant-berkshelf --plugin-version 2.0.1
```

Run the following:
```bash
    $ vagrant up
```

Creating a DevOps Server on Amazon
===================================
* Make sure you have an access key and secret access key in AWS with the following permissions:
    AmazonEC2FullAccess
    IAMFullAccess (you may want a restricted set of permissions, but the CloudFormation template will create an IAM user just for the stack)
    AmazonRoute53FullAccess
    AmazonS3FullAccess
    CloudFormation (there isn't a policy for this, so create a custom policy with full access to CloudFormation)
* Create an EC2 Key Pair in the region you'll be using (e.g. KWAAIOAK_DEVOPS_USEAST)
    * Download the .pem to ~/.ssh/ (and fix permissions to 0600)
* Create an S3 bucket
* Customize any values you want from aws/config.rb and save it as aws/config.local.rb
    * Add the EC2 Key Pair name to @key_name
    * Use the S3 bucket just created in @devops_bucket
* Make sure you have the following settings in your knife.rb
```ruby
    knife[:aws_access_key_id]
    knife[:aws_secret_access_key]
    knife[:region]
```
* You need to create a Route53 zone (this cannot be automated) called @stack_name.@domain_root
* Finally, run the following
```bash
    $ sudo gem install bundler
    $ sudo bundle install
    $ rake up (or rake up[snapshot_id], to restore from a snapshot backup)
```
