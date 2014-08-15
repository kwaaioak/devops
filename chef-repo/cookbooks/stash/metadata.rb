name             "stash"
maintainer       "Kwaai Oak, Inc."
maintainer_email "darren@kwaaioak.com"
license          "All rights reserved"
description      "Installs/Configures stash"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"
recipe           "stash", "Configures and builds Atlassian stash source code management"

supports 'debian'

depends 'java'
depends 'ark'
depends 'database'
depends 'git'
