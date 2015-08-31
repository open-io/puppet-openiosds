OpenIOSDS
=============

Author: Romain Acciari <romain.acciari@openio.io>
Copyright (c) 2015, OpenIO.


ABOUT
=====

This module manages [OpenIO SDS solution](http://openio.io/). You can deploy the different services needed to create an OpenIO SDS namespace.

INSTALLATION
============

The module can be obtained from the [Puppet Forge](https://forge.puppetlabs.com/openio/openiosds).  Select `Download` which downloads a tar.gz file.  Upload the tar.gz file to your Puppet Master.  Untar the file.  This will create a new directory called `openio-openiosds-${version_number}`.  Rename this directory to just **openiosds** and place it in your [modulepath](http://docs.puppetlabs.com/learning/modules1.html#modules). 

You can also use the [puppet-module tool](https://github.com/puppetlabs/puppet-module-tool).  Just run this command from your modulepath.
`puppet-module install openio/openiosds`

REQUIREMENTS
============

 * Puppet >=3.7
 * Puppetlabs/stdlib module.  Can be obtained here http://forge.puppetlabs.com/puppetlabs/stdlib or with the command `puppet-module install puppetlabs/stdlib`


CONFIGURATION
=============

You must declare a namespace class
There is one class (bacula) that needs to be declared on all nodes managing any component of bacula.
These nodes are configured using one of two methods.

 1. Using Top Scope (e.g. Dashboard) parameters 
 2. Declare the bacula class on node definitions in your manifest.

NOTE: The two methods can be mixed and matched, but take care not to create the same Top Scope parameter and class parameter simultaneously (See below for class parameters and their matching Top Scope parameter) as you may get unexpected results.
Order of parameter precendence:

 * Class Parameter
 * Top Scope Parameter
 * Hard Coded value

