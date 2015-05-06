name             "bamboo"
maintainer       "Kwaai Oak, Inc."
maintainer_email "darren@kwaaioak.com"
license          "All rights reserved"
description      "Installs/Configures Atlassian Bamboo"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"
recipe           "bamboo", "Configures and builds Atlassian Bamboo Continuous Integration"

supports 'debian'

depends 'java'
depends 'ark'
depends 'database', '~> 2.3.0'
depends 'git'
