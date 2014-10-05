name                "reverse-proxy"
maintainer          "Kwaai Oak, Inc."
maintainer_email    "darren@kwaaioak.com"
license             "All rights reserved"
description         "Installs/configures a reverse proxy web site"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version             "0.1.0"
recipe              "reverse-proxy", "Configures reverse proxy virtual hosts for multiple web application installs"
recipe              "reverse-proxy::web_app_proxy", "Configures a web application reverse proxu"
recipe              "reverse-proxy::ssl_proxy", "Configures an SSL reverse proxy for all web apps"
supports            "debian"
depends             "apache2"
depends             "ssl_certificate"
