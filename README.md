# openiosds

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with [openiosds]](#setup)
    * [What [openiosds] affects](#what-[openiosds]-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with [openiosds]](#beginning-with-[openiosds])
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Description

Official module to deploy the OpenIO open source object storage solution on RedHat/CentOS/Fedora using Puppet 3.7 and newer.

This module helps you deploy the multiple services required to create an OpenIO SDS namespace. 
It prepares destination directories, user and group rights, installs packages, configures services and starts them using OpenIO's GridInit service management.

## Setup

### Beginning with [openiosds]	

For a standalone simple OpenIO namespace, you must declare a namespace and deploy the required services.

Here is an example for a namespace called 'OPENIO':

```
openiosds::namespace {'OPENIO':
  ns => 'OPENIO',
  conscience_url => "${ipaddress}:6000",
}
openiosds::sdsagent {'sds-agent-0':
}
openiosds::conscience {'conscience-1':
  num            => '1',
  ns             => 'OPENIO',
}
openiosds::meta0 {'meta0-1':
  num => '1',
  ns => 'OPENIO',
}  
openiosds::meta1 {'meta1-1':
  num => '1',
  ns => 'OPENIO',
}
openiosds::meta2 {'meta2-1':
  num => '1',
  ns => 'OPENIO',
}
openiosds::rawx {'rawx-1':
  num => '1',
  ns => 'OPENIO',
}
openiosds::rdir {'rdir-1':
  num => '1',
  ns => 'OPENIO',
}
```

## Reference

A number of defined types are availables:    
* openiosds::namespace  
* openiosds::conscience  
* openiosds::meta0  
* openiosds::meta1  
* openiosds::meta2  
* openiosds::rawx  
* openiosds::rdir
* openiosds::account  
* openiosds::oioeventagent  
* openiosds::zookeeper  
* openiosds::sdsagent  
* openiosds::oioswift  
* openiosds::oioproxy  

## Limitations

The module works under the latest stable RedHat, CentOS and Fedora, Debian and Ubuntu (LTS & latest).

## Development

You can report issues or request informations using [GitHub](https://github.com/open-io/puppet-openiosds/issues).

## Release Notes/Contributors/Etc.

Author: Romain Acciari <romain.acciari@openio.io>  
Copyright (c) 2015, OpenIO.  
Released under Apache License v2.  


