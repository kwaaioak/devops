name             "storage"
maintainer       "Kwaai Oak, Inc."
maintainer_email "darren@kwaaioak.com"
license          "All rights reserved"
description      "Installs/Configures storage"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"
recipe           "stash", "Configures and builds block storage"

recipe 'storage', 'Initializes a storage devices and configures snapshot backups (EBS)'
recipe 'storage::snapshot', 'Takes a snapshot of the storage device (EBS)'

supports 'debian'

depends 'aws'
depends 'xfs'
