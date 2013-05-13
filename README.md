[![Build Status](https://travis-ci.org/mcourtois/hiera-mongodb.png)](https://travis-ci.org/mcourtois/hiera-mongodb)

Hiera MongoDB backend
=============

Configuration
=============

Here is a example hiera config file.

    ---
    :hierarchy:
      - 'fqdn/%{fqdn}'
      - common
    
    :backends:
      - psql
    
    :mongodb:
      :connection:
        :dbname: hiera
        :collection: config
        :host: localhost

