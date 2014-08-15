name		     "jira"
maintainer       "Kwaai Oak, Inc."
maintainer_email "darren@kwaaioak.com"
license          "All rights reserved"
description      "Installs/Configures jira"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"
recipe           "jira", "Configures and builds Atlassian JIRA"

supports 'debian'

depends 'database'
depends 'apache2'
depends 'ark'
